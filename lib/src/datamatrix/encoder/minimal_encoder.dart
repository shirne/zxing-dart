/*
 * Copyright 2021 ZXing authors
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

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../common/detector/math_utils.dart';
import '../../common/minimal_eci_input.dart';
import 'high_level_encoder.dart';
import 'symbol_shape_hint.dart';

enum Mode { ASCII, C40, TEXT, X12, EDF, B256 }

class Edge {
  /* private */ static final List<int> allCodewordCapacities = [
    3, 5, 8, 10, 12, 16, 18, 22, 30, 32, 36, 44, 49, 62, 86, 114, //
    144, 174, 204, 280, 368, 456, 576, 696, 816, 1050, 1304, 1558
  ];
  /* private */ static final List<int> squareCodewordCapacities = [
    3, 5, 8, 12, 18, 22, 30, 36, 44, 62, 86, 114, 144, 174, 204, //
    280, 368, 456, 576, 696, 816, 1050, 1304, 1558
  ];
  /* private */ static final List<int> rectangularCodewordCapacities = [
    5, 10, 16, 33, 32, 49 //
  ];
  /* private */ final Input input;
  /* private */ final Mode mode; //the mode at the start of this edge.
  /* private */ final int fromPosition;
  /* private */ final int characterLength;
  /* private */ final Edge? previous;
  /* private */ late int cachedTotalSize;

  /* private */ Edge(this.input, this.mode, this.fromPosition,
      this.characterLength, this.previous) {
    assert(fromPosition + characterLength <= input.length);

    int size = previous?.cachedTotalSize ?? 0;

    Mode previousMode = this.previousMode;

    /*
    * Switching modes
    * ASCII -> C40: latch 230
    * ASCII -> TEXT: latch 239
    * ASCII -> X12: latch 238
    * ASCII -> EDF: latch 240
    * ASCII -> B256: latch 231
    * C40 -> ASCII: word(c1,c2,c3), 254
    * TEXT -> ASCII: word(c1,c2,c3), 254
    * X12 -> ASCII: word(c1,c2,c3), 254
    * EDIFACT -> ASCII: Unlatch character,0,0,0 or c1,Unlatch character,0,0 or c1,c2,Unlatch character,0 or
    * c1,c2,c3,Unlatch character
    * B256 -> ASCII: without latch after n bytes
    */
    switch (mode) {
      case Mode.ASCII:
        size++;
        if (input.isECI(fromPosition) ||
            MinimalEncoder.isExtendedASCII(
                input.charAt(fromPosition), input.fnc1Character)) {
          size++;
        }
        if (previousMode == Mode.C40 ||
            previousMode == Mode.TEXT ||
            previousMode == Mode.X12) {
          size++; //unatch 254 to ASCII
        }
        break;
      case Mode.B256:
        size++;
        if (previousMode != Mode.B256) {
          size++; //byte count
        } else if (getB256Size() == 250) {
          size++; //extra byte count
        }
        if (previousMode == Mode.ASCII) {
          size++; //latch to B256
        } else if (previousMode == Mode.C40 ||
            previousMode == Mode.TEXT ||
            previousMode == Mode.X12) {
          size += 2; //unlatch to ASCII, latch to B256
        }
        break;
      case Mode.C40:
      case Mode.TEXT:
      case Mode.X12:
        if (mode == Mode.X12) {
          size += 2;
        } else {
          List<int> charLen = [0];
          size += MinimalEncoder.getNumberOfC40Words(
                  input, fromPosition, mode == Mode.C40, charLen) *
              2;
        }

        if (previousMode == Mode.ASCII || previousMode == Mode.B256) {
          size++; //additional byte for latch from ASCII to this mode
        } else if (previousMode != mode &&
            (previousMode == Mode.C40 ||
                previousMode == Mode.TEXT ||
                previousMode == Mode.X12)) {
          size += 2; //unlatch 254 to ASCII followed by latch to this mode
        }
        break;
      case Mode.EDF:
        size += 3;
        if (previousMode == Mode.ASCII || previousMode == Mode.B256) {
          size++; //additional byte for latch from ASCII to this mode
        } else if (previousMode == Mode.C40 ||
            previousMode == Mode.TEXT ||
            previousMode == Mode.X12) {
          size += 2; //unlatch 254 to ASCII followed by latch to this mode
        }
        break;
    }
    cachedTotalSize = size;
  }

  /// does not count beyond 250
  int getB256Size() {
    int cnt = 0;
    Edge? current = this;
    while (current != null && current.mode == Mode.B256 && cnt <= 250) {
      cnt++;
      current = current.previous;
    }
    return cnt;
  }

  Mode get previousStartMode {
    return previous?.mode ?? Mode.ASCII;
  }

  Mode get previousMode {
    return previous?.endMode ?? Mode.ASCII;
  }

  /// Returns Mode.ASCII in case that:
  /// - Mode is EDIFACT and characterLength is less than 4 or the remaining characters can be encoded in at most 2
  ///   ASCII bytes.
  /// - Mode is C40, TEXT or X12 and the remaining characters can be encoded in at most 1 ASCII byte.
  /// Returns mode in all other cases.
  Mode get endMode {
    if (mode == Mode.EDF) {
      if (characterLength < 4) {
        return Mode.ASCII;
      }
      int lastASCII = getLastASCII(); // see 5.2.8.2 EDIFACT encodation Rules
      if (lastASCII > 0 &&
          getCodewordsRemaining(cachedTotalSize + lastASCII) <= 2 - lastASCII) {
        return Mode.ASCII;
      }
    }
    if (mode == Mode.C40 || mode == Mode.TEXT || mode == Mode.X12) {
      // see 5.2.5.2 C40 encodation rules and 5.2.7.2 ANSI X12 encodation rules
      if (fromPosition + characterLength >= input.length &&
          getCodewordsRemaining(cachedTotalSize) == 0) {
        return Mode.ASCII;
      }
      int lastASCII = getLastASCII();
      if (lastASCII == 1 && getCodewordsRemaining(cachedTotalSize + 1) == 0) {
        return Mode.ASCII;
      }
    }
    return mode;
  }

  Mode getMode() {
    return mode;
  }

  /// Peeks ahead and returns 1 if the postfix consists of exactly two digits, 2 if the postfix consists of exactly
  /// two consecutive digits and a non extended character or of 4 digits.
  /// Returns 0 in any other case
  int getLastASCII() {
    int length = input.length;
    int from = fromPosition + characterLength;
    if (length - from > 4 || from >= length) {
      return 0;
    }
    if (length - from == 1) {
      if (MinimalEncoder.isExtendedASCII(
          input.charAt(from), input.fnc1Character)) {
        return 0;
      }
      return 1;
    }
    if (length - from == 2) {
      if (MinimalEncoder.isExtendedASCII(
              input.charAt(from), input.fnc1Character) ||
          MinimalEncoder.isExtendedASCII(
              input.charAt(from + 1), input.fnc1Character)) {
        return 0;
      }
      if (HighLevelEncoder.isDigit(input.charAt(from)) &&
          HighLevelEncoder.isDigit(input.charAt(from + 1))) {
        return 1;
      }
      return 2;
    }
    if (length - from == 3) {
      if (HighLevelEncoder.isDigit(input.charAt(from)) &&
          HighLevelEncoder.isDigit(input.charAt(from + 1)) &&
          !MinimalEncoder.isExtendedASCII(
              input.charAt(from + 2), input.fnc1Character)) {
        return 2;
      }
      if (HighLevelEncoder.isDigit(input.charAt(from + 1)) &&
          HighLevelEncoder.isDigit(input.charAt(from + 2)) &&
          !MinimalEncoder.isExtendedASCII(
              input.charAt(from), input.fnc1Character)) {
        return 2;
      }
      return 0;
    }
    if (HighLevelEncoder.isDigit(input.charAt(from)) &&
        HighLevelEncoder.isDigit(input.charAt(from + 1)) &&
        HighLevelEncoder.isDigit(input.charAt(from + 2)) &&
        HighLevelEncoder.isDigit(input.charAt(from + 3))) {
      return 2;
    }
    return 0;
  }

  /// Returns the capacity in codewords of the smallest symbol that has enough capacity to fit the given minimal
  /// number of codewords.
  int getMinSymbolSize(int minimum) {
    switch (input.shapeHint) {
      case SymbolShapeHint.FORCE_SQUARE:
        for (int capacity in squareCodewordCapacities) {
          if (capacity >= minimum) {
            return capacity;
          }
        }
        break;
      case SymbolShapeHint.FORCE_RECTANGLE:
        for (int capacity in rectangularCodewordCapacities) {
          if (capacity >= minimum) {
            return capacity;
          }
        }
        break;
    }
    for (int capacity in allCodewordCapacities) {
      if (capacity >= minimum) {
        return capacity;
      }
    }
    return allCodewordCapacities[allCodewordCapacities.length - 1];
  }

  /// Returns the remaining capacity in codewords of the smallest symbol that has enough capacity to fit the given
  /// minimal number of codewords.
  int getCodewordsRemaining(int minimum) {
    return getMinSymbolSize(minimum) - minimum;
  }

  static Uint8List getBytes(int c, [int? c2]) {
    bool isNull = c2 == null;

    Uint8List result = Uint8List(isNull ? 1 : 2);
    result[0] = c;
    if (!isNull) {
      result[1] = c2;
    }
    return result;
  }

  static void setC40Word(Uint8List bytes, int offset, int c1, int c2, int c3) {
    int val16 = (1600 * (c1 & 0xff)) + (40 * (c2 & 0xff)) + (c3 & 0xff) + 1;
    bytes[offset] = (val16 ~/ 256);
    bytes[offset + 1] = (val16 % 256);
  }

  /* private */ static int getX12Value(int c) {
    return c == 13
        ? 0
        : c == 42
            ? 1
            : c == 62
                ? 2
                : c == 32
                    ? 3
                    : c >= 48 && c <= 57
                        ? c - 44
                        : c >= 65 && c <= 90
                            ? c - 51
                            : c;
  }

  Uint8List getX12Words() {
    assert(characterLength % 3 == 0);
    Uint8List result = Uint8List(characterLength ~/ 3 * 2);
    for (int i = 0; i < result.length; i += 2) {
      setC40Word(
          result,
          i,
          getX12Value(input.charAt(fromPosition + i ~/ 2 * 3)),
          getX12Value(input.charAt(fromPosition + i ~/ 2 * 3 + 1)),
          getX12Value(input.charAt(fromPosition + i ~/ 2 * 3 + 2)));
    }
    return result;
  }

  static int getShiftValue(int c, bool c40, int fnc1) {
    return (c40 && MinimalEncoder.isInC40Shift1Set(c) ||
            !c40 && MinimalEncoder.isInTextShift1Set(c))
        ? 0
        : (c40 && MinimalEncoder.isInC40Shift2Set(c, fnc1) ||
                !c40 && MinimalEncoder.isInTextShift2Set(c, fnc1))
            ? 1
            : 2;
  }

  /* private */ static int getC40Value(
      bool c40, int setIndex, int c, int fnc1) {
    if (c == fnc1) {
      assert(setIndex == 2);
      return 27;
    }
    if (c40) {
      return c <= 31
          ? c
          : c == 32
              ? 3
              : c <= 47
                  ? c - 33
                  : c <= 57
                      ? c - 44
                      : c <= 64
                          ? c - 43
                          : c <= 90
                              ? c - 51
                              : c <= 95
                                  ? c - 69
                                  : c <= 127
                                      ? c - 96
                                      : c;
    } else {
      return c == 0
          ? 0
          : setIndex == 0 && c <= 3
              ? c - 1
              : //is this a bug in the spec?
              setIndex == 1 && c <= 31
                  ? c
                  : c == 32
                      ? 3
                      : c >= 33 && c <= 47
                          ? c - 33
                          : c >= 48 && c <= 57
                              ? c - 44
                              : c >= 58 && c <= 64
                                  ? c - 43
                                  : c >= 65 && c <= 90
                                      ? c - 64
                                      : c >= 91 && c <= 95
                                          ? c - 69
                                          : c == 96
                                              ? 0
                                              : c >= 97 && c <= 122
                                                  ? c - 83
                                                  : c >= 123 && c <= 127
                                                      ? c - 96
                                                      : c;
    }
  }

  Uint8List getC40Words(bool c40, int fnc1) {
    List<int> c40Values = [];
    for (int i = 0; i < characterLength; i++) {
      int ci = input.charAt(fromPosition + i);
      if (c40 && HighLevelEncoder.isNativeC40(ci) ||
          !c40 && HighLevelEncoder.isNativeText(ci)) {
        c40Values.add(getC40Value(c40, 0, ci, fnc1));
      } else if (!MinimalEncoder.isExtendedASCII(ci, fnc1)) {
        int shiftValue = getShiftValue(ci, c40, fnc1);
        c40Values.add(shiftValue); //Shift[123]
        c40Values.add(getC40Value(c40, shiftValue, ci, fnc1));
      } else {
        int asciiValue = ((ci & 0xff) - 128);
        if (c40 && HighLevelEncoder.isNativeC40(asciiValue) ||
            !c40 && HighLevelEncoder.isNativeText(asciiValue)) {
          c40Values.add(1); //Shift 2
          c40Values.add(30); //Upper Shift
          c40Values.add(getC40Value(c40, 0, asciiValue, fnc1));
        } else {
          c40Values.add(1); //Shift 2
          c40Values.add(30); //Upper Shift
          int shiftValue = getShiftValue(asciiValue, c40, fnc1);
          c40Values.add(shiftValue); // Shift[123]
          c40Values.add(getC40Value(c40, shiftValue, asciiValue, fnc1));
        }
      }
    }

    if ((c40Values.length % 3) != 0) {
      assert((c40Values.length - 2) % 3 == 0 &&
          fromPosition + characterLength == input.length);
      c40Values.add(0); // pad with 0 (Shift 1)
    }

    Uint8List result = Uint8List(c40Values.length ~/ 3 * 2);
    int byteIndex = 0;
    for (int i = 0; i < c40Values.length; i += 3) {
      setC40Word(result, byteIndex, c40Values[i] & 0xff,
          c40Values[i + 1] & 0xff, c40Values[i + 2] & 0xff);
      byteIndex += 2;
    }
    return result;
  }

  Uint8List getEDFBytes() {
    int numberOfThirds = (characterLength / 4.0).ceil();
    Uint8List result = Uint8List(numberOfThirds * 3);
    int pos = fromPosition;
    int endPos = math.min(fromPosition + characterLength - 1, input.length - 1);
    for (int i = 0; i < numberOfThirds; i += 3) {
      List<int> edfValues = List.filled(4, 0);
      for (int j = 0; j < 4; j++) {
        if (pos <= endPos) {
          edfValues[j] = input.charAt(pos++) & 0x3f;
        } else {
          edfValues[j] = pos == endPos + 1 ? 0x1f : 0;
        }
      }
      int val24 = edfValues[0] << 18;
      val24 |= edfValues[1] << 12;
      val24 |= edfValues[2] << 6;
      val24 |= edfValues[3];
      result[i] = ((val24 >> 16) & 0xff);
      result[i + 1] = ((val24 >> 8) & 0xff);
      result[i + 2] = (val24 & 0xff);
    }
    return result;
  }

  Uint8List getLatchBytes() {
    switch (previousMode) {
      case Mode.ASCII:
      case Mode.B256: //after B256 ends (via length) we are back to ASCII
        switch (mode) {
          case Mode.B256:
            return getBytes(231);
          case Mode.C40:
            return getBytes(230);
          case Mode.TEXT:
            return getBytes(239);
          case Mode.X12:
            return getBytes(238);
          case Mode.EDF:
            return getBytes(240);
        }
        break;
      case Mode.C40:
      case Mode.TEXT:
      case Mode.X12:
        if (mode != previousMode) {
          switch (mode) {
            case Mode.ASCII:
              return getBytes(254);
            case Mode.B256:
              return getBytes(254, 231);
            case Mode.C40:
              return getBytes(254, 230);
            case Mode.TEXT:
              return getBytes(254, 239);
            case Mode.X12:
              return getBytes(254, 238);
            case Mode.EDF:
              return getBytes(254, 240);
          }
        }
        break;
      case Mode.EDF:
        //The rightmost EDIFACT edge always contains an unlatch character
        assert(mode == Mode.EDF);
        break;
    }
    return Uint8List(0);
  }

  // Important: The function does not return the length bytes (one or two) in case of B256 encoding
  Uint8List getDataBytes() {
    switch (mode) {
      case Mode.ASCII:
        if (input.isECI(fromPosition)) {
          return getBytes(241, input.getECIValue(fromPosition) + 1);
        } else if (MinimalEncoder.isExtendedASCII(
            input.charAt(fromPosition), input.fnc1Character)) {
          return getBytes(235, input.charAt(fromPosition) - 127);
        } else if (characterLength == 2) {
          return getBytes((input.charAt(fromPosition) - 48 /*'0'*/) * 10 +
              input.charAt(fromPosition + 1) -
              48 +
              130);
        } else if (input.isFNC1(fromPosition)) {
          return getBytes(232);
        } else {
          return getBytes(input.charAt(fromPosition) + 1);
        }
      case Mode.B256:
        return getBytes(input.charAt(fromPosition));
      case Mode.C40:
        return getC40Words(true, input.fnc1Character);
      case Mode.TEXT:
        return getC40Words(false, input.fnc1Character);
      case Mode.X12:
        return getX12Words();
      case Mode.EDF:
        return getEDFBytes();
    }
    assert(false);
    return Uint8List(0);
  }
}

class Result {
  /* private */ late Uint8List _bytes;

  Result(Edge solution) {
    Input input = solution.input;
    int size = 0;
    List<int> bytesAL = [];
    List<int> randomizePostfixLength = [];
    List<int> randomizeLengths = [];
    if ((solution.mode == Mode.C40 ||
            solution.mode == Mode.TEXT ||
            solution.mode == Mode.X12) &&
        solution.endMode != Mode.ASCII) {
      size += prepend(Edge.getBytes(254), bytesAL);
    }
    Edge? current = solution;
    while (current != null) {
      size += prepend(current.getDataBytes(), bytesAL);

      if (current.previous == null ||
          current.previousStartMode != current.getMode()) {
        if (current.getMode() == Mode.B256) {
          if (size <= 249) {
            bytesAL.insert(0, size);
            size++;
          } else {
            bytesAL.insert(0, (size % 250));
            bytesAL.insert(0, (size ~/ 250 + 249));
            size += 2;
          }
          randomizePostfixLength.add(bytesAL.length);
          randomizeLengths.add(size);
        }
        prepend(current.getLatchBytes(), bytesAL);
        size = 0;
      }

      current = current.previous;
    }
    if (input.macroId == 5) {
      size += prepend(Edge.getBytes(236), bytesAL);
    } else if (input.macroId == 6) {
      size += prepend(Edge.getBytes(237), bytesAL);
    }

    if (input.fnc1Character > 0) {
      size += prepend(Edge.getBytes(232), bytesAL);
    }
    for (int i = 0; i < randomizePostfixLength.length; i++) {
      applyRandomPattern(
        bytesAL,
        bytesAL.length - randomizePostfixLength[i],
        randomizeLengths[i],
      );
    }
    //add padding
    int capacity = solution.getMinSymbolSize(bytesAL.length);
    if (bytesAL.length < capacity) {
      bytesAL.add(129);
    }
    while (bytesAL.length < capacity) {
      bytesAL.add(randomize253State(bytesAL.length + 1));
    }

    _bytes = Uint8List.fromList(bytesAL);
  }

  static int prepend(Uint8List bytes, List<int> into) {
    for (int i = bytes.length - 1; i >= 0; i--) {
      into.insert(0, bytes[i]);
    }
    return bytes.length;
  }

  static int randomize253State(int codewordPosition) {
    int pseudoRandom = ((149 * codewordPosition) % 253) + 1;
    int tempVariable = 129 + pseudoRandom;
    return tempVariable <= 254 ? tempVariable : tempVariable - 254;
  }

  static void applyRandomPattern(
    List<int> bytesAL,
    int startPosition,
    int length,
  ) {
    for (int i = 0; i < length; i++) {
      //See "B.1 253-state algorithm
      int padCodewordPosition = startPosition + i;
      int padCodewordValue = bytesAL[padCodewordPosition] & 0xff;
      int pseudoRandomNumber = ((149 * (padCodewordPosition + 1)) % 255) + 1;
      int tempVariable = padCodewordValue + pseudoRandomNumber;
      bytesAL[padCodewordPosition] =
          (tempVariable <= 255 ? tempVariable : tempVariable - 256);
    }
  }

  Uint8List get bytes => _bytes;
}

class Input extends MinimalECIInput {
  /* private */ final SymbolShapeHint shape;
  /* private */ final int macroId;

  Input(String stringToEncode, Encoding? priorityCharset, int fnc1, this.shape,
      this.macroId)
      : super(stringToEncode, priorityCharset, fnc1);

  SymbolShapeHint get shapeHint => shape;
}

/// Encoder that encodes minimally
///
/// Algorithm:
///
/// Uses Dijkstra to produce mathematically minimal encodings that are in some cases smaller than the results produced
/// by the algorithm described in annex S in the specification ISO/IEC 16022:200(E). The biggest improvment of this
/// algorithm over that one is the case when the algorithm enters the most inefficient mode, the B256 mode. The
/// algorithm from the specification algorithm will exit this mode only if it encounters digits so that arbitrarily
/// inefficient results can be produced if the postfix contains no digits.
///
/// Multi ECI support and ECI switching:
///
/// For multi language content the algorithm selects the most compact representation using ECI modes. Note that unlike
/// the compaction algorithm used for QR-Codes, this implementation operates in two stages and therfore is not
/// mathematically optimal. In the first stage, the input string is encoded minimally as a stream of ECI character set
/// selectors and bytes encoded in the selected encoding. In this stage the algorithm might for example decide to
/// encode ocurrences of the characters "\u0150\u015C" (O-double-acute, S-circumflex) in UTF-8 by a single ECI or
/// alternatively by multiple ECIs that switch between IS0-8859-2 and ISO-8859-3 (e.g. in the case that the input
/// contains many * characters from ISO-8859-2 (Latin 2) and few from ISO-8859-3 (Latin 3)).
/// In a second stage this stream of ECIs and bytes is minimally encoded using the various Data Matrix encoding modes.
/// While both stages encode mathematically minimally it is not ensured that the result is mathematically minimal since
/// the size growth for inserting an ECI in the first stage can only be approximated as the first stage does not know
/// in which mode the ECI will occur in the second stage (may, or may not require an extra latch to ASCII depending on
/// the current mode). The reason for this shortcoming are difficulties in implementing it in a straightforward and
/// readable manner.
///
/// GS1 support
///
/// FNC1 delimiters can be encoded in the input string by using the FNC1 character specified in the encoding function.
/// When a FNC1 character is specified then a leading FNC1 will be encoded and all ocurrences of delimiter characters
/// while result in FNC1 codewords in the symbol.
///
/// @author Alex Geller
class MinimalEncoder {
  static final List<int> C40_SHIFT2_CHARS = [
    '!',
    '"',
    '#',
    '\$',
    '%',
    '&',
    '\'',
    '(',
    ')',
    '*',
    '+',
    ',',
    '-',
    '.',
    '/',
    ':',
    ';',
    '<',
    '=',
    '>',
    '?',
    '@',
    '[',
    '\\',
    ']',
    '^',
    '_'
  ].map((e) => e.codeUnitAt(0)).toList();

  /* private */ MinimalEncoder();

  static bool isExtendedASCII(int ch, int fnc1) {
    return ch != fnc1 && ch >= 128 && ch <= 255;
  }

  /* private */ static bool isInC40Shift1Set(int ch) {
    return ch <= 31;
  }

  /* private */ static bool isInC40Shift2Set(int ch, int fnc1) {
    for (int c40Shift2Char in C40_SHIFT2_CHARS) {
      if (c40Shift2Char == ch) {
        return true;
      }
    }
    return ch == fnc1;
  }

  /* private */ static bool isInTextShift1Set(int ch) {
    return isInC40Shift1Set(ch);
  }

  /* private */ static bool isInTextShift2Set(int ch, int fnc1) {
    return isInC40Shift2Set(ch, fnc1);
  }

  /// Performs message encoding of a DataMatrix message
  ///
  /// @param msg the message
  /// @param priorityCharset The preferred {@link Charset}. When the value of the argument is null, the algorithm
  ///   chooses charsets that leads to a minimal representation. Otherwise the algorithm will use the priority
  ///   charset to encode any character in the input that can be encoded by it if the charset is among the
  ///   supported charsets.
  /// @param fnc1 denotes the character in the input that represents the FNC1 character or -1 if this is not a GS1
  ///   bar code. If the value is not -1 then a FNC1 is also prepended.
  /// @param shape requested shape.
  /// @return the encoded message (the char values range from 0 to 255)
  static String encodeHighLevel(
    String msg, [
    Encoding? priorityCharset,
    int fnc1 = -1,
    SymbolShapeHint shape = SymbolShapeHint.FORCE_NONE,
  ]) {
    int macroId = 0;
    if (msg.startsWith(HighLevelEncoder.MACRO_05_HEADER) &&
        msg.endsWith(HighLevelEncoder.MACRO_TRAILER)) {
      macroId = 5;
      msg = msg.substring(
        HighLevelEncoder.MACRO_05_HEADER.length,
        msg.length - 2,
      );
    } else if (msg.startsWith(HighLevelEncoder.MACRO_06_HEADER) &&
        msg.endsWith(HighLevelEncoder.MACRO_TRAILER)) {
      macroId = 6;
      msg = msg.substring(
        HighLevelEncoder.MACRO_06_HEADER.length,
        msg.length - 2,
      );
    }
    final rst = encode(msg, priorityCharset, fnc1, shape, macroId);
    return latin1.decode(rst);
  }

  /// Encodes input minimally and returns an array of the codewords
  ///
  /// @param input The string to encode
  /// @param priorityCharset The preferred {@link Charset}. When the value of the argument is null, the algorithm
  ///   chooses charsets that leads to a minimal representation. Otherwise the algorithm will use the priority
  ///   charset to encode any character in the input that can be encoded by it if the charset is among the
  ///   supported charsets.
  /// @param fnc1 denotes the character in the input that represents the FNC1 character or -1 if this is not a GS1
  ///   bar code. If the value is not -1 then a FNC1 is also prepended.
  /// @param shape requested shape.
  /// @param macroId Prepends the specified macro function in case that a value of 5 or 6 is specified.
  /// @return An array of bytes representing the codewords of a minimal encoding.
  static Uint8List encode(
    String input,
    Encoding? priorityCharset,
    int fnc1,
    SymbolShapeHint shape,
    int macroId,
  ) {
    return encodeMinimally(Input(
      input,
      priorityCharset,
      fnc1,
      shape,
      macroId,
    )).bytes;
  }

  static void addEdge(List<List<Edge?>> edges, Edge edge) {
    int vertexIndex = edge.fromPosition + edge.characterLength;
    if (edges[vertexIndex][edge.endMode.index] == null ||
        edges[vertexIndex][edge.endMode.index]!.cachedTotalSize >
            edge.cachedTotalSize) {
      edges[vertexIndex][edge.endMode.index] = edge;
    }
  }

  ///  The number of characters encoded is returned in characterLength.
  ///  The number of characters encoded is also minimal in the sense that the algorithm stops as soon
  ///  as a character encoding fills a C40 word competely (three C40 values). An exception is at the
  ///  end of the string where two C40 values are allowed (according to the spec the third c40 value
  ///  is filled  with 0 (Shift 1) in this case).
  static int getNumberOfC40Words(
      Input input, int from, bool c40, List<int> characterLength) {
    int thirdsCount = 0;
    for (int i = from; i < input.length; i++) {
      if (input.isECI(i)) {
        characterLength[0] = 0;
        return 0;
      }
      int ci = input.charAt(i);
      if (c40 && HighLevelEncoder.isNativeC40(ci) ||
          !c40 && HighLevelEncoder.isNativeText(ci)) {
        thirdsCount++; //native
      } else if (!MinimalEncoder.isExtendedASCII(ci, input.fnc1Character)) {
        thirdsCount += 2; //shift
      } else {
        int asciiValue = ci & 0xff;
        if (asciiValue >= 128 &&
            (c40 && HighLevelEncoder.isNativeC40((asciiValue - 128)) ||
                !c40 && HighLevelEncoder.isNativeText((asciiValue - 128)))) {
          thirdsCount += 3; // shift, Upper shift
        } else {
          thirdsCount += 4; // shift, Upper shift, shift
        }
      }

      if (thirdsCount % 3 == 0 ||
          ((thirdsCount - 2) % 3 == 0 && i + 1 == input.length)) {
        characterLength[0] = i - from + 1;
        return (thirdsCount / 3.0).ceil();
      }
    }
    characterLength[0] = 0;
    return 0;
  }

  static void addEdges(
      Input input, List<List<Edge?>> edges, int from, Edge? previous) {
    if (input.isECI(from)) {
      addEdge(edges, Edge(input, Mode.ASCII, from, 1, previous));
      return;
    }

    int ch = input.charAt(from);
    if (previous == null || previous.endMode != Mode.EDF) {
      //not possible to unlatch a full EDF edge to something
      //else
      if (HighLevelEncoder.isDigit(ch) &&
          input.haveNCharacters(from, 2) &&
          HighLevelEncoder.isDigit(input.charAt(from + 1))) {
        // two digits ASCII encoded
        addEdge(edges, Edge(input, Mode.ASCII, from, 2, previous));
      } else {
        // one ASCII encoded character or an extended character via Upper Shift
        addEdge(edges, Edge(input, Mode.ASCII, from, 1, previous));
      }

      final List<Mode> modes = [Mode.C40, Mode.TEXT];
      for (Mode mode in modes) {
        List<int> characterLength = [0];
        if (getNumberOfC40Words(
                input, from, mode == Mode.C40, characterLength) >
            0) {
          addEdge(edges, Edge(input, mode, from, characterLength[0], previous));
        }
      }

      if (input.haveNCharacters(from, 3) &&
          HighLevelEncoder.isNativeX12(input.charAt(from)) &&
          HighLevelEncoder.isNativeX12(input.charAt(from + 1)) &&
          HighLevelEncoder.isNativeX12(input.charAt(from + 2))) {
        addEdge(edges, Edge(input, Mode.X12, from, 3, previous));
      }

      addEdge(edges, Edge(input, Mode.B256, from, 1, previous));
    }

    //We create 4 EDF edges,  with 1, 2 3 or 4 characters length. The fourth normally doesn't have a latch to ASCII
    //unless it is 2 characters away from the end of the input.
    int i;
    for (i = 0; i < 3; i++) {
      int pos = from + i;
      if (input.haveNCharacters(pos, 1) &&
          HighLevelEncoder.isNativeEDIFACT(input.charAt(pos))) {
        addEdge(edges, Edge(input, Mode.EDF, from, i + 1, previous));
      } else {
        break;
      }
    }
    if (i == 3 &&
        input.haveNCharacters(from, 4) &&
        HighLevelEncoder.isNativeEDIFACT(input.charAt(from + 3))) {
      addEdge(edges, Edge(input, Mode.EDF, from, 4, previous));
    }
  }

  static Result encodeMinimally(Input input) {
    //@SuppressWarnings("checkstyle:lineLength")
    /* The minimal encoding is computed by Dijkstra. The acyclic graph is modeled as follows:
     * A vertex represents a combination of a position in the input and an encoding mode where position 0
     * denotes the position left of the first character, 1 the position left of the second character and so on.
     * Likewise the end vertices are located after the last character at position input.length().
     * For any position there might be up to six vertices, one for each of the encoding types ASCII, C40, TEXT, X12,
     * EDF and B256.
     *
     * As an example consider the input string "ABC123" then at position 0 there is only one vertex with the default
     * ASCII encodation. At position 3 there might be vertices for the types ASCII, C40, X12, EDF and B256.
     *
     * An edge leading to such a vertex encodes one or more of the characters left of the position that the vertex
     * represents. It encodes the characters in the encoding mode of the vertex that it ends on. In other words,
     * all edges leading to a particular vertex encode the same characters (the length of the suffix can vary) using the same
     * encoding mode.
     * As an example consider the input string "ABC123" and the vertex (4,EDF). Possible edges leading to this vertex
     * are:
     *   (0,ASCII)  --EDF(ABC1)--> (4,EDF)
     *   (1,ASCII)  --EDF(BC1)-->  (4,EDF)
     *   (1,B256)   --EDF(BC1)-->  (4,EDF)
     *   (1,EDF)    --EDF(BC1)-->  (4,EDF)
     *   (2,ASCII)  --EDF(C1)-->   (4,EDF)
     *   (2,B256)   --EDF(C1)-->   (4,EDF)
     *   (2,EDF)    --EDF(C1)-->   (4,EDF)
     *   (3,ASCII)  --EDF(1)-->    (4,EDF)
     *   (3,B256)   --EDF(1)-->    (4,EDF)
     *   (3,EDF)    --EDF(1)-->    (4,EDF)
     *   (3,C40)    --EDF(1)-->    (4,EDF)
     *   (3,X12)    --EDF(1)-->    (4,EDF)
     *
     * The edges leading to a vertex are stored in such a way that there is a fast way to enumerate the edges ending
     * on a particular vertex.
     *
     * The algorithm processes the vertices in order of their position thereby performing the following:
     *
     * For every vertex at position i the algorithm enumerates the edges ending on the vertex and removes all but the
     * shortest from that list.
     * Then it processes the vertices for the position i+1. If i+1 == input.length() then the algorithm ends
     * and chooses the the edge with the smallest size from any of the edges leading to vertices at this position.
     * Otherwise the algorithm computes all possible outgoing edges for the vertices at the position i+1
     *
     * Examples:
     * The process is illustrated by showing the graph (edges) after each iteration from left to right over the input:
     * An edge is drawn as follows "(" + fromVertex + ") -- " + encodingMode + "(" + encodedInput + ") (" +
     * accumulatedSize + ") --> (" + toVertex + ")"
     *
     * Example 1 encoding the string "ABCDEFG":
     *
     *
     * Situation after adding edges to the start vertex (0,ASCII)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII)
     * (0,ASCII) B256(A) (3) --> (1,B256)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF)
     * (0,ASCII) C40(ABC) (3) --> (3,C40)
     * (0,ASCII) TEXT(ABC) (5) --> (3,TEXT)
     * (0,ASCII) X12(ABC) (3) --> (3,X12)
     * (0,ASCII) EDF(ABC) (4) --> (3,EDF)
     * (0,ASCII) EDF(ABCD) (4) --> (4,EDF)
     *
     * Situation after adding edges to vertices at position 1
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII)
     * (0,ASCII) B256(A) (3) --> (1,B256)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF)
     * (0,ASCII) C40(ABC) (3) --> (3,C40)
     * (0,ASCII) TEXT(ABC) (5) --> (3,TEXT)
     * (0,ASCII) X12(ABC) (3) --> (3,X12)
     * (0,ASCII) EDF(ABC) (4) --> (3,EDF)
     * (0,ASCII) EDF(ABCD) (4) --> (4,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) B256(B) (4) --> (2,B256)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) EDF(BC) (5) --> (3,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) C40(BCD) (4) --> (4,C40)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) TEXT(BCD) (6) --> (4,TEXT)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) X12(BCD) (4) --> (4,X12)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) EDF(BCD) (5) --> (4,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) EDF(BCDE) (5) --> (5,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) ASCII(B) (4) --> (2,ASCII)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256)
     * (0,ASCII) B256(A) (3) --> (1,B256) EDF(BC) (6) --> (3,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) C40(BCD) (5) --> (4,C40)
     * (0,ASCII) B256(A) (3) --> (1,B256) TEXT(BCD) (7) --> (4,TEXT)
     * (0,ASCII) B256(A) (3) --> (1,B256) X12(BCD) (5) --> (4,X12)
     * (0,ASCII) B256(A) (3) --> (1,B256) EDF(BCD) (6) --> (4,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) EDF(BCDE) (6) --> (5,EDF)
     *
     * Edge "(1,ASCII) ASCII(B) (2) --> (2,ASCII)" is minimal for the vertex (2,ASCII) so that edge "(1,B256) ASCII(B) (4) --> (2,ASCII)" is removed.
     * Edge "(1,B256) B256(B) (3) --> (2,B256)" is minimal for the vertext (2,B256) so that the edge "(1,ASCII) B256(B) (4) --> (2,B256)" is removed.
     *
     * Situation after adding edges to vertices at position 2
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII)
     * (0,ASCII) B256(A) (3) --> (1,B256)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF)
     * (0,ASCII) C40(ABC) (3) --> (3,C40)
     * (0,ASCII) TEXT(ABC) (5) --> (3,TEXT)
     * (0,ASCII) X12(ABC) (3) --> (3,X12)
     * (0,ASCII) EDF(ABC) (4) --> (3,EDF)
     * (0,ASCII) EDF(ABCD) (4) --> (4,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) EDF(BC) (5) --> (3,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) C40(BCD) (4) --> (4,C40)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) TEXT(BCD) (6) --> (4,TEXT)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) X12(BCD) (4) --> (4,X12)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) EDF(BCD) (5) --> (4,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) EDF(BCDE) (5) --> (5,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256)
     * (0,ASCII) B256(A) (3) --> (1,B256) EDF(BC) (6) --> (3,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) C40(BCD) (5) --> (4,C40)
     * (0,ASCII) B256(A) (3) --> (1,B256) TEXT(BCD) (7) --> (4,TEXT)
     * (0,ASCII) B256(A) (3) --> (1,B256) X12(BCD) (5) --> (4,X12)
     * (0,ASCII) B256(A) (3) --> (1,B256) EDF(BCD) (6) --> (4,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) EDF(BCDE) (6) --> (5,EDF)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF) ASCII(C) (5) --> (3,ASCII)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF) B256(C) (6) --> (3,B256)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF) EDF(CD) (7) --> (4,EDF)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF) C40(CDE) (6) --> (5,C40)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF) TEXT(CDE) (8) --> (5,TEXT)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF) X12(CDE) (6) --> (5,X12)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF) EDF(CDE) (7) --> (5,EDF)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF) EDF(CDEF) (7) --> (6,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) ASCII(C) (3) --> (3,ASCII)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) B256(C) (5) --> (3,B256)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) EDF(CD) (6) --> (4,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) C40(CDE) (5) --> (5,C40)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) TEXT(CDE) (7) --> (5,TEXT)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) X12(CDE) (5) --> (5,X12)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) EDF(CDE) (6) --> (5,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) EDF(CDEF) (6) --> (6,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) ASCII(C) (4) --> (3,ASCII)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) B256(C) (4) --> (3,B256)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) EDF(CD) (6) --> (4,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) C40(CDE) (5) --> (5,C40)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) TEXT(CDE) (7) --> (5,TEXT)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) X12(CDE) (5) --> (5,X12)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) EDF(CDE) (6) --> (5,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) EDF(CDEF) (6) --> (6,EDF)
     *
     * Edge "(2,ASCII) ASCII(C) (3) --> (3,ASCII)" is minimal for the vertex (3,ASCII) so that edges "(2,EDF) ASCII(C) (5) --> (3,ASCII)"
     * and "(2,B256) ASCII(C) (4) --> (3,ASCII)" can be removed.
     * Edge "(0,ASCII) EDF(ABC) (4) --> (3,EDF)" is minimal for the vertex (3,EDF) so that edges "(1,ASCII) EDF(BC) (5) --> (3,EDF)"
     * and "(1,B256) EDF(BC) (6) --> (3,EDF)" can be removed.
     * Edge "(2,B256) B256(C) (4) --> (3,B256)" is minimal for the vertex (3,B256) so that edges "(2,ASCII) B256(C) (5) --> (3,B256)"
     * and "(2,EDF) B256(C) (6) --> (3,B256)" can be removed.
     *
     * This continues for vertices 3 thru 7
     *
     * Situation after adding edges to vertices at position 7
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII)
     * (0,ASCII) B256(A) (3) --> (1,B256)
     * (0,ASCII) EDF(AB) (4) --> (2,EDF)
     * (0,ASCII) C40(ABC) (3) --> (3,C40)
     * (0,ASCII) TEXT(ABC) (5) --> (3,TEXT)
     * (0,ASCII) X12(ABC) (3) --> (3,X12)
     * (0,ASCII) EDF(ABC) (4) --> (3,EDF)
     * (0,ASCII) EDF(ABCD) (4) --> (4,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) C40(BCD) (4) --> (4,C40)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) TEXT(BCD) (6) --> (4,TEXT)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) X12(BCD) (4) --> (4,X12)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) EDF(BCDE) (5) --> (5,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256)
     * (0,ASCII) C40(ABC) (3) --> (3,C40) C40(DEF) (5) --> (6,C40)
     * (0,ASCII) X12(ABC) (3) --> (3,X12) X12(DEF) (5) --> (6,X12)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) ASCII(C) (3) --> (3,ASCII)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) C40(CDE) (5) --> (5,C40)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) TEXT(CDE) (7) --> (5,TEXT)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) X12(CDE) (5) --> (5,X12)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) EDF(CDEF) (6) --> (6,EDF)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) C40(BCD) (4) --> (4,C40) C40(EFG) (6) --> (7,C40)    //Solution 1
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) X12(BCD) (4) --> (4,X12) X12(EFG) (6) --> (7,X12)    //Solution 2
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) B256(C) (4) --> (3,B256)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) ASCII(C) (3) --> (3,ASCII) ASCII(D) (4) --> (4,ASCII)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) ASCII(C) (3) --> (3,ASCII) TEXT(DEF) (8) --> (6,TEXT)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) ASCII(C) (3) --> (3,ASCII) EDF(DEFG) (7) --> (7,EDF)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) B256(C) (4) --> (3,B256) B256(D) (5) --> (4,B256)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) ASCII(C) (3) --> (3,ASCII) ASCII(D) (4) --> (4,ASCII) ASCII(E) (5) --> (5,ASCII)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) ASCII(C) (3) --> (3,ASCII) ASCII(D) (4) --> (4,ASCII) TEXT(EFG) (9) --> (7,TEXT)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) B256(C) (4) --> (3,B256) B256(D) (5) --> (4,B256) B256(E) (6) --> (5,B256)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) ASCII(C) (3) --> (3,ASCII) ASCII(D) (4) --> (4,ASCII) ASCII(E) (5) --> (5,ASCII) ASCII(F) (6) --> (6,ASCII)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) B256(C) (4) --> (3,B256) B256(D) (5) --> (4,B256) B256(E) (6) --> (5,B256) B256(F) (7) --> (6,B256)
     * (0,ASCII) ASCII(A) (1) --> (1,ASCII) ASCII(B) (2) --> (2,ASCII) ASCII(C) (3) --> (3,ASCII) ASCII(D) (4) --> (4,ASCII) ASCII(E) (5) --> (5,ASCII) ASCII(F) (6) --> (6,ASCII) ASCII(G) (7) --> (7,ASCII)
     * (0,ASCII) B256(A) (3) --> (1,B256) B256(B) (3) --> (2,B256) B256(C) (4) --> (3,B256) B256(D) (5) --> (4,B256) B256(E) (6) --> (5,B256) B256(F) (7) --> (6,B256) B256(G) (8) --> (7,B256)
     *
     * Hence a minimal encoding of "ABCDEFG" is either ASCII(A),C40(BCDEFG) or ASCII(A), X12(BCDEFG) with a size of 5 bytes.
     */

    int inputLength = input.length;

    // Array that represents vertices. There is a vertex for every character and mode.
    // The last dimension in the array below encodes the 6 modes ASCII, C40, TEXT, X12, EDF and B256
    List<List<Edge?>> edges = List.generate(
      inputLength + 1,
      (index) => List.filled(6, null),
    );
    addEdges(input, edges, 0, null);

    for (int i = 1; i <= inputLength; i++) {
      for (int j = 0; j < 6; j++) {
        if (edges[i][j] != null && i < inputLength) {
          addEdges(input, edges, i, edges[i][j]);
        }
      }
      //optimize memory by removing edges that have been passed.
      edges[i - 1].fillRange(0, 6, null);
    }

    int minimalJ = -1;
    int minimalSize = MathUtils.MAX_VALUE;
    for (int j = 0; j < 6; j++) {
      if (edges[inputLength][j] != null) {
        Edge edge = edges[inputLength][j]!;
        //C40, TEXT and X12 need an extra unlatch at the end
        int size = (j >= 1 && j <= 3)
            ? edge.cachedTotalSize + 1
            : edge.cachedTotalSize;
        if (size < minimalSize) {
          minimalSize = size;
          minimalJ = j;
        }
      }
    }

    if (minimalJ < 0) {
      throw Exception("Internal error: failed to encode \"$input\"");
    }
    return Result(edges[inputLength][minimalJ]!);
  }
}
