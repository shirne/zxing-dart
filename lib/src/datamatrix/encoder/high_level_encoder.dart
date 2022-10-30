/*
 * Copyright 2006-2007 Jeremias Maerki.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:math' as math;
import 'dart:typed_data';

import '../../common/detector/math_utils.dart';
import '../../dimension.dart';
import 'ascii_encoder.dart';
import 'base256_encoder.dart';
import 'c40_encoder.dart';
import 'edifact_encoder.dart';
import 'encoder.dart';
import 'encoder_context.dart';
import 'symbol_shape_hint.dart';
import 'text_encoder.dart';
import 'x12_encoder.dart';

/// DataMatrix ECC 200 data encoder following the algorithm described in ISO/IEC 16022:200(E) in
/// annex S.
class HighLevelEncoder {
  /// Padding character
  static const int _PAD = 129;

  /// mode latch to C40 encodation mode
  static const int LATCH_TO_C40 = 230;

  /// mode latch to Base 256 encodation mode
  static const int LATCH_TO_BASE256 = 231;

  /// FNC1 Codeword
  //static const int _FNC1 = 232;
  /// Structured Append Codeword
  //static const int _STRUCTURED_APPEND = 233;
  /// Reader Programming
  //static const int _READER_PROGRAMMING = 234;
  /// Upper Shift chr
  static const int UPPER_SHIFT = 235;

  /// 05 Macro
  static const int _MACRO_05 = 236;

  /// 06 Macro
  static const int _MACRO_06 = 237;

  /// mode latch to ANSI X.12 encodation mode
  static const int LATCH_TO_ANSIX12 = 238;

  /// mode latch to Text encodation mode
  static const int LATCH_TO_TEXT = 239;

  /// mode latch to EDIFACT encodation mode
  static const int LATCH_TO_EDIFACT = 240;

  /// ECI character (Extended Channel Interpretation)
  //static const int _ECI = 241;

  /// Unlatch from C40 encodation
  static const int C40_UNLATCH = 254;

  /// Unlatch from X12 encodation
  static const int X12_UNLATCH = 254;

  /// 05 Macro header
  static const String MACRO_05_HEADER = '[)>\u001E05\u001D';

  /// 06 Macro header
  static const String MACRO_06_HEADER = '[)>\u001E06\u001D';

  /// Macro trailer
  static const String MACRO_TRAILER = '\u001E\u0004';

  static const int ASCII_ENCODATION = 0;
  static const int C40_ENCODATION = 1;
  static const int TEXT_ENCODATION = 2;
  static const int X12_ENCODATION = 3;
  static const int EDIFACT_ENCODATION = 4;
  static const int BASE256_ENCODATION = 5;

  HighLevelEncoder._();

  static int _randomize253State(int codewordPosition) {
    final pseudoRandom = ((149 * codewordPosition) % 253) + 1;
    final tempVariable = _PAD + pseudoRandom;
    return tempVariable <= 254 ? tempVariable : tempVariable - 254;
  }

  /// Performs message encoding of a DataMatrix message using the algorithm described in annex P
  /// of ISO/IEC 16022:2000(E).
  ///
  /// @param msg     the message
  /// @param shape   requested shape. May be {@code SymbolShapeHint.FORCE_NONE},
  ///                {@code SymbolShapeHint.FORCE_SQUARE} or {@code SymbolShapeHint.FORCE_RECTANGLE}.
  /// @param minSize the minimum symbol size constraint or null for no constraint
  /// @param maxSize the maximum symbol size constraint or null for no constraint
  /// @return the encoded message (the char values range from 0 to 255)
  static String encodeHighLevel(
    String msg, [
    SymbolShapeHint shape = SymbolShapeHint.FORCE_NONE,
    Dimension? minSize,
    Dimension? maxSize,
    bool forceC40 = false,
  ]) {
    //the codewords 0..255 are encoded as Unicode characters
    final c40Encoder = C40Encoder();
    final encoders = <Encoder>[
      ASCIIEncoder(),
      c40Encoder,
      TextEncoder(),
      X12Encoder(),
      EdifactEncoder(),
      Base256Encoder()
    ];

    final context = EncoderContext(msg);
    context.setSymbolShape(shape);
    context.setSizeConstraints(minSize, maxSize);

    if (msg.startsWith(MACRO_05_HEADER) && msg.endsWith(MACRO_TRAILER)) {
      context.writeCodeword(_MACRO_05);
      context.skipAtEnd = 2;
      context.pos += MACRO_05_HEADER.length;
    } else if (msg.startsWith(MACRO_06_HEADER) && msg.endsWith(MACRO_TRAILER)) {
      context.writeCodeword(_MACRO_06);
      context.skipAtEnd = 2;
      context.pos += MACRO_06_HEADER.length;
    }

    //Default mode
    int encodingMode = ASCII_ENCODATION;

    if (forceC40) {
      c40Encoder.encodeMaximal(context);
      encodingMode = context.newEncoding;
      context.resetEncoderSignal();
    }

    while (context.hasMoreCharacters) {
      encoders[encodingMode].encode(context);
      if (context.newEncoding >= 0) {
        encodingMode = context.newEncoding;
        context.resetEncoderSignal();
      }
    }
    final len = context.codewordCount;
    context.updateSymbolInfo();
    final capacity = context.symbolInfo!.dataCapacity;
    if (len < capacity &&
        encodingMode != ASCII_ENCODATION &&
        encodingMode != BASE256_ENCODATION &&
        encodingMode != EDIFACT_ENCODATION) {
      context.writeCodeword('\u00fe'); //Unlatch (254)
    }
    //Padding
    final codewords = context.codewords;
    if (codewords.length < capacity) {
      codewords.writeCharCode(_PAD);
    }
    while (codewords.length < capacity) {
      codewords.writeCharCode(_randomize253State(codewords.length + 1));
    }

    return context.codewords.toString();
  }

  static int lookAheadTest(String msg, int startPos, int currentMode) {
    final newMode = lookAheadTestIntern(msg, startPos, currentMode);
    if (currentMode == X12_ENCODATION && newMode == X12_ENCODATION) {
      final endPos = math.min(startPos + 3, msg.length);
      for (int i = startPos; i < endPos; i++) {
        if (!isNativeX12(msg.codeUnitAt(i))) {
          return ASCII_ENCODATION;
        }
      }
    } else if (currentMode == EDIFACT_ENCODATION &&
        newMode == EDIFACT_ENCODATION) {
      final endPos = math.min(startPos + 4, msg.length);
      for (int i = startPos; i < endPos; i++) {
        if (!isNativeEDIFACT(msg.codeUnitAt(i))) {
          return ASCII_ENCODATION;
        }
      }
    }
    return newMode;
  }

  static int lookAheadTestIntern(String msg, int startPos, int currentMode) {
    if (startPos >= msg.length) {
      return currentMode;
    }
    List<double> charCounts;
    //step J
    if (currentMode == ASCII_ENCODATION) {
      charCounts = [0, 1, 1, 1, 1, 1.25];
    } else {
      charCounts = [1, 2, 2, 2, 2, 2.25];
      charCounts[currentMode] = 0;
    }

    int charsProcessed = 0;
    final mins = Uint8List(6);
    final intCharCounts = Uint8List(6);
    while (true) {
      //step K
      if ((startPos + charsProcessed) == msg.length) {
        mins.fillRange(0, mins.length, 0);
        intCharCounts.fillRange(0, mins.length, 0);
        final min =
            _findMinimums(charCounts, intCharCounts, MathUtils.MAX_VALUE, mins);
        int minCount = _getMinimumCount(mins);

        if (intCharCounts[ASCII_ENCODATION] == min) {
          return ASCII_ENCODATION;
        }
        if (minCount == 1) {
          if (mins[BASE256_ENCODATION] > 0) {
            return BASE256_ENCODATION;
          }
          if (mins[EDIFACT_ENCODATION] > 0) {
            return EDIFACT_ENCODATION;
          }
          if (mins[TEXT_ENCODATION] > 0) {
            return TEXT_ENCODATION;
          }
          if (mins[X12_ENCODATION] > 0) {
            return X12_ENCODATION;
          }
        }

        // to fix result
        final dmin = charCounts.fold<double>(
          MathUtils.MAX_VALUE.toDouble(),
          (previousValue, element) => math.min(previousValue, element),
        );
        minCount = charCounts.where((element) => element == dmin).length;

        if (charCounts[ASCII_ENCODATION] == dmin) {
          return ASCII_ENCODATION;
        }
        if (minCount == 1) {
          return charCounts.indexOf(dmin);
        }

        return C40_ENCODATION;
      }

      final c = msg.codeUnitAt(startPos + charsProcessed);
      charsProcessed++;

      //step L
      if (isDigit(c)) {
        charCounts[ASCII_ENCODATION] += 0.5;
      } else if (isExtendedASCII(c)) {
        charCounts[ASCII_ENCODATION] =
            (charCounts[ASCII_ENCODATION]).ceil().toDouble();
        charCounts[ASCII_ENCODATION] += 2.0;
      } else {
        charCounts[ASCII_ENCODATION] =
            (charCounts[ASCII_ENCODATION]).ceil().toDouble();
        charCounts[ASCII_ENCODATION]++;
      }

      //step M
      if (isNativeC40(c)) {
        charCounts[C40_ENCODATION] += 2.0 / 3.0; //0.6666667;
      } else if (isExtendedASCII(c)) {
        charCounts[C40_ENCODATION] += 8.0 / 3.0; //2.6666667;
      } else {
        charCounts[C40_ENCODATION] += 4.0 / 3.0; //1.3333334;
      }

      //step N
      if (isNativeText(c)) {
        charCounts[TEXT_ENCODATION] += 2.0 / 3.0; //0.6666667;
      } else if (isExtendedASCII(c)) {
        charCounts[TEXT_ENCODATION] += 8.0 / 3.0; //2.6666667;
      } else {
        charCounts[TEXT_ENCODATION] += 4.0 / 3.0; //1.3333334;
      }

      //step O
      if (isNativeX12(c)) {
        charCounts[X12_ENCODATION] += 2.0 / 3.0; //0.6666667;
      } else if (isExtendedASCII(c)) {
        charCounts[X12_ENCODATION] += 13.0 / 3.0; //4.3333335;
      } else {
        charCounts[X12_ENCODATION] += 10.0 / 3.0; //3.3333333;
      }

      //step P
      if (isNativeEDIFACT(c)) {
        charCounts[EDIFACT_ENCODATION] += 0.75; //3.0 / 4.0;
      } else if (isExtendedASCII(c)) {
        charCounts[EDIFACT_ENCODATION] += 4.25; //17.0 / 4.0;
      } else {
        charCounts[EDIFACT_ENCODATION] += 3.25; //13.0 / 4.0;
      }

      // step Q
      if (_isSpecialB256(c)) {
        charCounts[BASE256_ENCODATION] += 4.0;
      } else {
        charCounts[BASE256_ENCODATION]++;
      }

      //step R
      if (charsProcessed >= 4) {
        mins.fillRange(0, mins.length, 0);
        intCharCounts.fillRange(0, mins.length, 0);
        _findMinimums(charCounts, intCharCounts, MathUtils.MAX_VALUE, mins);

        if (intCharCounts[ASCII_ENCODATION] <
            min([
              intCharCounts[BASE256_ENCODATION],
              intCharCounts[C40_ENCODATION],
              intCharCounts[TEXT_ENCODATION],
              intCharCounts[X12_ENCODATION],
              intCharCounts[EDIFACT_ENCODATION],
            ])) {
          return ASCII_ENCODATION;
        }
        if (intCharCounts[BASE256_ENCODATION] <
                intCharCounts[ASCII_ENCODATION] ||
            intCharCounts[BASE256_ENCODATION] + 1 <
                min([
                  intCharCounts[C40_ENCODATION],
                  intCharCounts[TEXT_ENCODATION],
                  intCharCounts[X12_ENCODATION],
                  intCharCounts[EDIFACT_ENCODATION],
                ])) {
          return BASE256_ENCODATION;
        }
        if (intCharCounts[EDIFACT_ENCODATION] + 1 <
            min([
              intCharCounts[BASE256_ENCODATION],
              intCharCounts[C40_ENCODATION],
              intCharCounts[TEXT_ENCODATION],
              intCharCounts[X12_ENCODATION],
              intCharCounts[ASCII_ENCODATION],
            ])) {
          return EDIFACT_ENCODATION;
        }
        if (intCharCounts[TEXT_ENCODATION] + 1 <
            min([
              intCharCounts[BASE256_ENCODATION],
              intCharCounts[C40_ENCODATION],
              intCharCounts[EDIFACT_ENCODATION],
              intCharCounts[X12_ENCODATION],
              intCharCounts[ASCII_ENCODATION],
            ])) {
          return TEXT_ENCODATION;
        }
        if (intCharCounts[X12_ENCODATION] + 1 <
            min([
              intCharCounts[BASE256_ENCODATION],
              intCharCounts[C40_ENCODATION],
              intCharCounts[EDIFACT_ENCODATION],
              intCharCounts[TEXT_ENCODATION],
              intCharCounts[ASCII_ENCODATION],
            ])) {
          return X12_ENCODATION;
        }
        if (intCharCounts[C40_ENCODATION] + 1 <
            min([
              intCharCounts[ASCII_ENCODATION],
              intCharCounts[BASE256_ENCODATION],
              intCharCounts[EDIFACT_ENCODATION],
              intCharCounts[TEXT_ENCODATION]
            ])) {
          if (intCharCounts[C40_ENCODATION] < intCharCounts[X12_ENCODATION]) {
            return C40_ENCODATION;
          }
          if (intCharCounts[C40_ENCODATION] == intCharCounts[X12_ENCODATION]) {
            int p = startPos + charsProcessed + 1;
            while (p < msg.length) {
              final tc = msg.codeUnitAt(p);
              if (_isX12TermSep(tc)) {
                return X12_ENCODATION;
              }
              if (!isNativeX12(tc)) {
                break;
              }
              p++;
            }
            return C40_ENCODATION;
          }
        }
      }
    }
  }

  static int min(List<int> lists) {
    return lists.fold(
      lists.first,
      (previousValue, element) => math.min(previousValue, element),
    );
  }

  static int _findMinimums(
    List<double> charCounts,
    List<int> intCharCounts,
    int min,
    Uint8List mins,
  ) {
    for (int i = 0; i < 6; i++) {
      final current = (intCharCounts[i] = charCounts[i].ceil());

      if (min > current) {
        min = current;
        mins.fillRange(0, mins.length, 0);
      }
      if (min == current) {
        mins[i]++;
      }
    }
    return min;
  }

  static int _getMinimumCount(Uint8List mins) {
    int minCount = 0;
    for (int i = 0; i < 6; i++) {
      minCount += mins[i];
    }
    return minCount;
  }

  static bool isDigit(int chr) {
    return chr >= 48 /* 0 */ && chr <= 57 /* 9 */;
  }

  static bool isExtendedASCII(dynamic chr) {
    int ch = 0;
    if (chr is String) {
      ch = chr.codeUnitAt(0);
    } else {
      ch = chr as int;
    }
    return ch >= 128 && ch <= 255;
  }

  static bool isNativeC40(dynamic chr) {
    int ch = 0;
    if (chr is String) {
      ch = chr.codeUnitAt(0);
    } else {
      ch = chr as int;
    }
    return (ch == 32 /*   */) ||
        (ch >= 48 /* 0 */ && ch <= 57 /* 9 */) ||
        (ch >= 65 /* A */ && ch <= 90 /* Z */);
  }

  static bool isNativeText(dynamic chr) {
    int ch = 0;
    if (chr is String) {
      ch = chr.codeUnitAt(0);
    } else {
      ch = chr as int;
    }
    return (ch == 32 /*   */) ||
        (ch >= 48 /* 0 */ && ch <= 57 /* 9 */) ||
        (ch >= 97 /* a */ && ch <= 122 /* z */);
  }

  static bool isNativeX12(int chr) {
    return _isX12TermSep(chr) ||
        (chr == 32 /*   */) ||
        (chr >= 48 /* 0 */ && chr <= 57 /* 9 */) ||
        (chr >= 65 /* A */ && chr <= 90 /* Z */);
  }

  static bool _isX12TermSep(int chr) {
    return (chr == 13) //CR
        ||
        (chr == 42 /* * */) ||
        (chr == 62 /* > */);
  }

  static bool isNativeEDIFACT(int chr) {
    return chr >= 32 /*   */ && chr <= 94 /* ^ */;
  }

  static bool _isSpecialB256(dynamic chr) {
    return false; //TODO NOT IMPLEMENTED YET!!!
  }

  /// Determines the number of consecutive characters that are encodable using numeric compaction.
  ///
  /// @param msg      the message
  /// @param startPos the start position within the message
  /// @return the requested character count
  static int determineConsecutiveDigitCount(String msg, int startPos) {
    final len = msg.length;
    int idx = startPos;
    while (idx < len && isDigit(msg.codeUnitAt(idx))) {
      idx++;
    }
    return idx - startPos;
  }

  static void illegalCharacter(int c) {
    String hex = (c).toRadixString(16);
    hex = hex.padLeft(4, '0');
    throw ArgumentError('Illegal character: chr($c) (0x$hex)');
  }
}
