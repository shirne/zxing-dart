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
  static const int _pad = 129;

  /// mode latch to C40 encodation mode
  static const int latchToC40 = 230;

  /// mode latch to Base 256 encodation mode
  static const int latchToBase256 = 231;

  /// FNC1 Codeword
  //static const int _FNC1 = 232;
  /// Structured Append Codeword
  //static const int _STRUCTURED_APPEND = 233;
  /// Reader Programming
  //static const int _READER_PROGRAMMING = 234;
  /// Upper Shift chr
  static const int upperShift = 235;

  /// 05 Macro
  static const int _macro05 = 236;

  /// 06 Macro
  static const int _macro06 = 237;

  /// mode latch to ANSI X.12 encodation mode
  static const int latchToAnsix12 = 238;

  /// mode latch to Text encodation mode
  static const int latchToText = 239;

  /// mode latch to EDIFACT encodation mode
  static const int latchToEdifact = 240;

  /// ECI character (Extended Channel Interpretation)
  //static const int _ECI = 241;

  /// Unlatch from C40 encodation
  static const int c40Unlatch = 254;

  /// Unlatch from X12 encodation
  static const int x12Unlatch = 254;

  /// 05 Macro header
  static const String macro05Header = '[)>\u001E05\u001D';

  /// 06 Macro header
  static const String macro06Header = '[)>\u001E06\u001D';

  /// Macro trailer
  static const String macroTrailer = '\u001E\u0004';

  static const int asciiEncodation = 0;
  static const int c40Encodation = 1;
  static const int textEncodation = 2;
  static const int x12Encodation = 3;
  static const int edifactEncodation = 4;
  static const int base256Encodation = 5;

  HighLevelEncoder._();

  static int _randomize253State(int codewordPosition) {
    final pseudoRandom = ((149 * codewordPosition) % 253) + 1;
    final tempVariable = _pad + pseudoRandom;
    return tempVariable <= 254 ? tempVariable : tempVariable - 254;
  }

  /// Performs message encoding of a DataMatrix message using the algorithm described in annex P
  /// of ISO/IEC 16022:2000(E).
  ///
  /// @param msg     the message
  /// @param shape   requested shape. May be [SymbolShapeHint.forceNone],
  ///                [SymbolShapeHint.forceSquare] or [SymbolShapeHint.forceRectangle].
  /// @param minSize the minimum symbol size constraint or null for no constraint
  /// @param maxSize the maximum symbol size constraint or null for no constraint
  /// @return the encoded message (the char values range from 0 to 255)
  static String encodeHighLevel(
    String msg, [
    SymbolShapeHint shape = SymbolShapeHint.forceNone,
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
      Base256Encoder(),
    ];

    final context = EncoderContext(msg);
    context.setSymbolShape(shape);
    context.setSizeConstraints(minSize, maxSize);

    if (msg.startsWith(macro05Header) && msg.endsWith(macroTrailer)) {
      context.writeCodeword(_macro05);
      context.skipAtEnd = 2;
      context.pos += macro05Header.length;
    } else if (msg.startsWith(macro06Header) && msg.endsWith(macroTrailer)) {
      context.writeCodeword(_macro06);
      context.skipAtEnd = 2;
      context.pos += macro06Header.length;
    }

    //Default mode
    int encodingMode = asciiEncodation;

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
        encodingMode != asciiEncodation &&
        encodingMode != base256Encodation &&
        encodingMode != edifactEncodation) {
      context.writeCodeword('\u00fe'); //Unlatch (254)
    }
    //Padding
    final codewords = context.codewords;
    if (codewords.length < capacity) {
      codewords.writeCharCode(_pad);
    }
    while (codewords.length < capacity) {
      codewords.writeCharCode(_randomize253State(codewords.length + 1));
    }

    return context.codewords.toString();
  }

  static int lookAheadTest(String msg, int startPos, int currentMode) {
    final newMode = lookAheadTestIntern(msg, startPos, currentMode);
    if (currentMode == x12Encodation && newMode == x12Encodation) {
      final endPos = math.min(startPos + 3, msg.length);
      for (int i = startPos; i < endPos; i++) {
        if (!isNativeX12(msg.codeUnitAt(i))) {
          return asciiEncodation;
        }
      }
    } else if (currentMode == edifactEncodation &&
        newMode == edifactEncodation) {
      final endPos = math.min(startPos + 4, msg.length);
      for (int i = startPos; i < endPos; i++) {
        if (!isNativeEDIFACT(msg.codeUnitAt(i))) {
          return asciiEncodation;
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
    if (currentMode == asciiEncodation) {
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
            _findMinimums(charCounts, intCharCounts, MathUtils.maxValue, mins);
        int minCount = _getMinimumCount(mins);

        if (intCharCounts[asciiEncodation] == min) {
          return asciiEncodation;
        }
        if (minCount == 1) {
          if (mins[base256Encodation] > 0) {
            return base256Encodation;
          }
          if (mins[edifactEncodation] > 0) {
            return edifactEncodation;
          }
          if (mins[textEncodation] > 0) {
            return textEncodation;
          }
          if (mins[x12Encodation] > 0) {
            return x12Encodation;
          }
        }

        // to fix result
        final dmin = charCounts.fold<double>(
          MathUtils.maxValue.toDouble(),
          (previousValue, element) => math.min(previousValue, element),
        );
        minCount = charCounts.where((element) => element == dmin).length;

        if (charCounts[asciiEncodation] == dmin) {
          return asciiEncodation;
        }
        if (minCount == 1) {
          return charCounts.indexOf(dmin);
        }

        return c40Encodation;
      }

      final c = msg.codeUnitAt(startPos + charsProcessed);
      charsProcessed++;

      //step L
      if (isDigit(c)) {
        charCounts[asciiEncodation] += 0.5;
      } else if (isExtendedASCII(c)) {
        charCounts[asciiEncodation] =
            (charCounts[asciiEncodation]).ceil().toDouble();
        charCounts[asciiEncodation] += 2.0;
      } else {
        charCounts[asciiEncodation] =
            (charCounts[asciiEncodation]).ceil().toDouble();
        charCounts[asciiEncodation]++;
      }

      //step M
      if (isNativeC40(c)) {
        charCounts[c40Encodation] += 2.0 / 3.0; //0.6666667;
      } else if (isExtendedASCII(c)) {
        charCounts[c40Encodation] += 8.0 / 3.0; //2.6666667;
      } else {
        charCounts[c40Encodation] += 4.0 / 3.0; //1.3333334;
      }

      //step N
      if (isNativeText(c)) {
        charCounts[textEncodation] += 2.0 / 3.0; //0.6666667;
      } else if (isExtendedASCII(c)) {
        charCounts[textEncodation] += 8.0 / 3.0; //2.6666667;
      } else {
        charCounts[textEncodation] += 4.0 / 3.0; //1.3333334;
      }

      //step O
      if (isNativeX12(c)) {
        charCounts[x12Encodation] += 2.0 / 3.0; //0.6666667;
      } else if (isExtendedASCII(c)) {
        charCounts[x12Encodation] += 13.0 / 3.0; //4.3333335;
      } else {
        charCounts[x12Encodation] += 10.0 / 3.0; //3.3333333;
      }

      //step P
      if (isNativeEDIFACT(c)) {
        charCounts[edifactEncodation] += 0.75; //3.0 / 4.0;
      } else if (isExtendedASCII(c)) {
        charCounts[edifactEncodation] += 4.25; //17.0 / 4.0;
      } else {
        charCounts[edifactEncodation] += 3.25; //13.0 / 4.0;
      }

      // step Q
      if (_isSpecialB256(c)) {
        charCounts[base256Encodation] += 4.0;
      } else {
        charCounts[base256Encodation]++;
      }

      //step R
      if (charsProcessed >= 4) {
        mins.fillRange(0, mins.length, 0);
        intCharCounts.fillRange(0, mins.length, 0);
        _findMinimums(charCounts, intCharCounts, MathUtils.maxValue, mins);

        if (intCharCounts[asciiEncodation] <
            min([
              intCharCounts[base256Encodation],
              intCharCounts[c40Encodation],
              intCharCounts[textEncodation],
              intCharCounts[x12Encodation],
              intCharCounts[edifactEncodation],
            ])) {
          return asciiEncodation;
        }
        if (intCharCounts[base256Encodation] < intCharCounts[asciiEncodation] ||
            intCharCounts[base256Encodation] + 1 <
                min([
                  intCharCounts[c40Encodation],
                  intCharCounts[textEncodation],
                  intCharCounts[x12Encodation],
                  intCharCounts[edifactEncodation],
                ])) {
          return base256Encodation;
        }
        if (intCharCounts[edifactEncodation] + 1 <
            min([
              intCharCounts[base256Encodation],
              intCharCounts[c40Encodation],
              intCharCounts[textEncodation],
              intCharCounts[x12Encodation],
              intCharCounts[asciiEncodation],
            ])) {
          return edifactEncodation;
        }
        if (intCharCounts[textEncodation] + 1 <
            min([
              intCharCounts[base256Encodation],
              intCharCounts[c40Encodation],
              intCharCounts[edifactEncodation],
              intCharCounts[x12Encodation],
              intCharCounts[asciiEncodation],
            ])) {
          return textEncodation;
        }
        if (intCharCounts[x12Encodation] + 1 <
            min([
              intCharCounts[base256Encodation],
              intCharCounts[c40Encodation],
              intCharCounts[edifactEncodation],
              intCharCounts[textEncodation],
              intCharCounts[asciiEncodation],
            ])) {
          return x12Encodation;
        }
        if (intCharCounts[c40Encodation] + 1 <
            min([
              intCharCounts[asciiEncodation],
              intCharCounts[base256Encodation],
              intCharCounts[edifactEncodation],
              intCharCounts[textEncodation],
            ])) {
          if (intCharCounts[c40Encodation] < intCharCounts[x12Encodation]) {
            return c40Encodation;
          }
          if (intCharCounts[c40Encodation] == intCharCounts[x12Encodation]) {
            int p = startPos + charsProcessed + 1;
            while (p < msg.length) {
              final tc = msg.codeUnitAt(p);
              if (_isX12TermSep(tc)) {
                return x12Encodation;
              }
              if (!isNativeX12(tc)) {
                break;
              }
              p++;
            }
            return c40Encodation;
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
