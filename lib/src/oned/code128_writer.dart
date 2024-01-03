/*
 * Copyright 2010 ZXing authors
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

import '../barcode_format.dart';
import '../common/detector/math_utils.dart';
import '../encode_hint.dart';
import 'code128_reader.dart';
import 'one_dimensional_code_writer.dart';

enum _CType {
  uncodable,
  oneDigit,
  twoDigits,
  fnc1,
}

enum Charset {
  A,
  B,
  C,
  none,
}

enum Latch {
  A,
  B,
  C,
  shift,
  none,
}

/// Encodes minimally using Divide-And-Conquer with Memoization
class MinimalEncoder {
  static final List<int> A =
      " !\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\u0000\u0001\u0002"
              '\u0003\u0004\u0005\u0006\u0007\u0008\u0009\n\u000B\u000C\r\u000E\u000F\u0010\u0011'
              '\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001A\u001B\u001C\u001D\u001E\u001F'
              '\u00FF'
          .codeUnits;
  static final List<int> B =
      " !\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqr"
              'stuvwxyz{|}~\u007F\u00FF'
          .codeUnits;

  static final int codeShift = 98;

  List<List<int>>? memoizedCost;
  List<List<Latch>>? minPath;

  List<bool> encode(String contents) {
    memoizedCost = List.generate(4, (index) => List.filled(contents.length, 0));
    minPath =
        List.generate(4, (index) => List.filled(contents.length, Latch.none));

    encodeCharset(contents, Charset.none, 0);

    final patterns = <List<int>>[];
    final checkSum = [0];
    final checkWeight = [1];
    final length = contents.length;
    Charset charset = Charset.none;
    for (int i = 0; i < length; i++) {
      final latch = minPath![charset.index][i];
      switch (latch) {
        case Latch.A:
          charset = Charset.A;
          addPattern(
            patterns,
            i == 0 ? Code128Writer._codeStartA : Code128Writer._codeCodeA,
            checkSum,
            checkWeight,
            i,
          );
          break;
        case Latch.B:
          charset = Charset.B;
          addPattern(
            patterns,
            i == 0 ? Code128Writer._codeStartB : Code128Writer._codeCodeB,
            checkSum,
            checkWeight,
            i,
          );
          break;
        case Latch.C:
          charset = Charset.C;
          addPattern(
            patterns,
            i == 0 ? Code128Writer._codeStartC : Code128Writer._codeCodeC,
            checkSum,
            checkWeight,
            i,
          );
          break;
        case Latch.shift:
          addPattern(patterns, codeShift, checkSum, checkWeight, i);
          break;
        default:
          break;
      }
      if (charset == Charset.C) {
        if (contents.codeUnitAt(i) == Code128Writer._escapeFnc1) {
          addPattern(
            patterns,
            Code128Writer._codeFnc1,
            checkSum,
            checkWeight,
            i,
          );
        } else {
          addPattern(
            patterns,
            int.parse(contents.substring(i, i + 2)),
            checkSum,
            checkWeight,
            i,
          );

          //the algorithm never leads to a single trailing digit in character set C
          assert(i + 1 < length);

          if (i + 1 < length) {
            i++;
          }
        }
      } else {
        // charset A or B
        int patternIndex;
        switch (contents.codeUnitAt(i)) {
          case Code128Writer._escapeFnc1:
            patternIndex = Code128Writer._codeFnc1;
            break;
          case Code128Writer._escapeFnc2:
            patternIndex = Code128Writer._codeFnc2;
            break;
          case Code128Writer._escapeFnc3:
            patternIndex = Code128Writer._codeFnc3;
            break;
          case Code128Writer._escapeFnc4:
            if (charset == Charset.A && latch != Latch.shift ||
                charset == Charset.B && latch == Latch.shift) {
              patternIndex = Code128Writer._codeFnc4A;
            } else {
              patternIndex = Code128Writer._codeFnc4B;
            }
            break;
          default:
            patternIndex = contents.codeUnitAt(i) - 32 /*' '*/;
        }
        if ((charset == Charset.A && latch != Latch.shift ||
                charset == Charset.B && latch == Latch.shift) &&
            patternIndex < 0) {
          patternIndex += 96 /*'`'*/;
        }
        addPattern(patterns, patternIndex, checkSum, checkWeight, i);
      }
    }
    memoizedCost = null;
    minPath = null;
    return Code128Writer.produceResult(patterns, checkSum[0]);
  }

  static void addPattern(
    List<List<int>> patterns,
    int patternIndex,
    List<int> checkSum,
    List<int> checkWeight,
    int position,
  ) {
    patterns.add(Code128Reader.codePatterns[patternIndex]);
    if (position != 0) {
      checkWeight[0]++;
    }
    checkSum[0] += patternIndex * checkWeight[0];
  }

  static bool isDigit(int c) {
    return c >= 48 /*'0'*/ && c <= 57 /*'9'*/;
  }

  bool canEncode(String contents, Charset charset, int position) {
    final c = contents.codeUnitAt(position);

    switch (charset) {
      case Charset.A:
        return c == Code128Writer._escapeFnc1 ||
            c == Code128Writer._escapeFnc2 ||
            c == Code128Writer._escapeFnc3 ||
            c == Code128Writer._escapeFnc4 ||
            A.contains(c);
      case Charset.B:
        return c == Code128Writer._escapeFnc1 ||
            c == Code128Writer._escapeFnc2 ||
            c == Code128Writer._escapeFnc3 ||
            c == Code128Writer._escapeFnc4 ||
            B.contains(c);
      case Charset.C:
        return c == Code128Writer._escapeFnc1 ||
            (position + 1 < contents.length &&
                isDigit(c) &&
                isDigit(contents.codeUnitAt(position + 1)));
      default:
        return false;
    }
  }

  /// Encode the string starting at position position starting with the character set charset
  int encodeCharset(String contents, Charset charset, int position) {
    assert(position < contents.length);
    final mCost = memoizedCost![charset.index][position];
    if (mCost > 0) {
      return mCost;
    }

    int minCost = MathUtils.maxValue;
    Latch minLatch = Latch.none;
    final atEnd = position + 1 >= contents.length;

    final sets = [Charset.A, Charset.B];
    for (int i = 0; i <= 1; i++) {
      if (canEncode(contents, sets[i], position)) {
        int cost = 1;
        Latch latch = Latch.none;
        if (charset != sets[i]) {
          cost++;
          latch = Latch.values[sets[i].index];
        }
        if (!atEnd) {
          cost += encodeCharset(contents, sets[i], position + 1);
        }
        if (cost < minCost) {
          minCost = cost;
          minLatch = latch;
        }
        cost = 1;
        if (charset == sets[(i + 1) % 2]) {
          cost++;
          latch = Latch.shift;
          if (!atEnd) {
            cost += encodeCharset(contents, charset, position + 1);
          }
          if (cost < minCost) {
            minCost = cost;
            minLatch = latch;
          }
        }
      }
    }
    if (canEncode(contents, Charset.C, position)) {
      int cost = 1;
      Latch latch = Latch.none;
      if (charset != Charset.C) {
        cost++;
        latch = Latch.C;
      }
      final advance =
          contents.codeUnitAt(position) == Code128Writer._escapeFnc1 ? 1 : 2;
      if (position + advance < contents.length) {
        cost += encodeCharset(contents, Charset.C, position + advance);
      }
      if (cost < minCost) {
        minCost = cost;
        minLatch = latch;
      }
    }
    if (minCost == MathUtils.maxValue) {
      throw ArgumentError('Bad character in input: '
          'ASCII value=${contents.codeUnitAt(position)}');
    }
    memoizedCost![charset.index][position] = minCost;
    minPath![charset.index][position] = minLatch;
    return minCost;
  }
}

/// This object renders a CODE128 code as a [BitMatrix].
///
/// @author erik.barbara@gmail.com (Erik Barbara)
class Code128Writer extends OneDimensionalCodeWriter {
  static const int _codeStartA = 103;
  static const int _codeStartB = 104;
  static const int _codeStartC = 105;
  static const int _codeCodeA = 101;
  static const int _codeCodeB = 100;
  static const int _codeCodeC = 99;
  static const int _codeStop = 106;

  // Dummy characters used to specify control characters in input
  static const int _escapeFnc1 = 0xf1; //'\u00f1';
  static const int _escapeFnc2 = 0xf2; //'\u00f2';
  static const int _escapeFnc3 = 0xf3; //'\u00f3';
  static const int _escapeFnc4 = 0xf4; //'\u00f4';

  static const int _codeFnc1 = 102; // Code A, Code B, Code C
  static const int _codeFnc2 = 97; // Code A, Code B
  static const int _codeFnc3 = 96; // Code A, Code B
  static const int _codeFnc4A = 101; // Code A
  static const int _codeFnc4B = 100; // Code B

  /// Results of minimal lookahead for code C
  //@protected
  @override
  List<BarcodeFormat> get supportedWriteFormats => [BarcodeFormat.code128];

  @override
  List<bool> encodeContent(
    String contents, [
    EncodeHint? hints,
  ]) {
    final forcedCodeSet = _check(contents, hints);

    final hasCompactionHint = hints?.code128Compact ?? false;

    return hasCompactionHint
        ? MinimalEncoder().encode(contents)
        : encodeFast(contents, hints, forcedCodeSet);
  }

  static int _check(String contents, EncodeHint? hints) {
    // Check for forced code set hint.
    int forcedCodeSet = -1;
    if (hints?.forceCodeSet != null) {
      final codeSetHint = hints!.forceCodeSet!;
      switch (codeSetHint) {
        case 'A':
          forcedCodeSet = _codeCodeA;
          break;
        case 'B':
          forcedCodeSet = _codeCodeB;
          break;
        case 'C':
          forcedCodeSet = _codeCodeC;
          break;
        default:
          throw ArgumentError('Unsupported code set hint: $codeSetHint');
      }
    }

    // Check content
    for (int i = 0; i < contents.length; i++) {
      final c = contents.codeUnitAt(i);
      // check for non ascii characters that are not special GS1 characters
      switch (c) {
        // special function characters
        case _escapeFnc1:
        case _escapeFnc2:
        case _escapeFnc3:
        case _escapeFnc4:
          break;
        // non ascii characters
        default:
          if (c > 127) {
            // no full Latin-1 character set available at the moment
            // shift and manual code change are not supported
            throw ArgumentError('Bad character in input: ASCII value=: $c');
          }
      }
      // check characters for compatibility with forced code set
      switch (forcedCodeSet) {
        case _codeCodeA:
          // allows no ascii above 95 (no lower caps, no special symbols)
          if (c > 95 && c <= 127) {
            throw ArgumentError('Bad character in input for forced code set A:'
                ' ASCII value=$c');
          }
          break;
        case _codeCodeB:
          // allows no ascii below 32 (terminal symbols)
          if (c < 32) {
            throw ArgumentError('Bad character in input for forced code set B:'
                ' ASCII value=$c');
          }
          break;
        case _codeCodeC:
          // allows only numbers and no FNC 2/3/4
          if (c < 48 ||
              (c > 57 && c <= 127) ||
              c == _escapeFnc2 ||
              c == _escapeFnc3 ||
              c == _escapeFnc4) {
            throw ArgumentError('Bad character in input for forced code set C:'
                ' ASCII value=$c');
          }
          break;
      }
    }
    return forcedCodeSet;
  }

  static List<bool> encodeFast(
    String contents,
    EncodeHint? hints,
    int forcedCodeSet,
  ) {
    final length = contents.length;
    final patterns = <List<int>>[]; // temporary storage for patterns
    int checkSum = 0;
    int checkWeight = 1;
    int codeSet = 0; // selected code (CODE_CODE_B or CODE_CODE_C)
    int position = 0; // position in contents

    while (position < length) {
      //Select code to use
      int newCodeSet;
      if (forcedCodeSet == -1) {
        newCodeSet = _chooseCode(contents, position, codeSet);
      } else {
        newCodeSet = forcedCodeSet;
      }
      //Get the pattern index
      int patternIndex;
      if (newCodeSet == codeSet) {
        // Encode the current character
        // First handle escapes
        switch (contents.codeUnitAt(position)) {
          case _escapeFnc1:
            patternIndex = _codeFnc1;
            break;
          case _escapeFnc2:
            patternIndex = _codeFnc2;
            break;
          case _escapeFnc3:
            patternIndex = _codeFnc3;
            break;
          case _escapeFnc4:
            if (codeSet == _codeCodeA) {
              patternIndex = _codeFnc4A;
            } else {
              patternIndex = _codeFnc4B;
            }
            break;
          default:
            // Then handle normal characters otherwise
            switch (codeSet) {
              case _codeCodeA:
                patternIndex = contents.codeUnitAt(position) - 32 /*   */;
                if (patternIndex < 0) {
                  // everything below a space character comes behind the underscore in the code patterns table
                  patternIndex += 96 /* ` */;
                }
                break;
              case _codeCodeB:
                patternIndex = contents.codeUnitAt(position) - 32 /*   */;
                break;
              default:
                // CODE_CODE_C
                if (position + 1 == length) {
                  // this is the last character, but the encoding is C, which always encodes two characers
                  throw ArgumentError(
                    'Bad number of characters for digit only encoding.',
                  );
                }
                patternIndex =
                    int.parse(contents.substring(position, position + 2));
                position++; // Also incremented below
                break;
            }
        }
        position++;
      } else {
        // Should we change the current code?
        // Do we have a code set?
        if (codeSet == 0) {
          // No, we don't have a code set
          switch (newCodeSet) {
            case _codeCodeA:
              patternIndex = _codeStartA;
              break;
            case _codeCodeB:
              patternIndex = _codeStartB;
              break;
            default:
              patternIndex = _codeStartC;
              break;
          }
        } else {
          // Yes, we have a code set
          patternIndex = newCodeSet;
        }
        codeSet = newCodeSet;
      }

      // Get the pattern
      patterns.add(Code128Reader.codePatterns[patternIndex]);

      // Compute checksum
      checkSum += patternIndex * checkWeight;
      if (position != 0) {
        checkWeight++;
      }
    }
    return produceResult(patterns, checkSum);
  }

  static List<bool> produceResult(List<List<int>> patterns, int checkSum) {
    // Compute and append checksum
    checkSum %= 103;
    if (checkSum < 0) {
      throw ArgumentError('Unable to compute a valid input checksum');
    }
    patterns.add(Code128Reader.codePatterns[checkSum]);

    // Append stop code
    patterns.add(Code128Reader.codePatterns[_codeStop]);

    // Compute code width
    int codeWidth = 0;
    for (List<int> pattern in patterns) {
      for (int width in pattern) {
        codeWidth += width;
      }
    }

    // Compute result
    final result = List.filled(codeWidth, false);
    int pos = 0;
    for (List<int> pattern in patterns) {
      pos += OneDimensionalCodeWriter.appendPattern(result, pos, pattern, true);
    }

    return result;
  }

  static _CType _findCType(String value, int start) {
    final last = value.length;
    if (start >= last) {
      return _CType.uncodable;
    }
    int c = value.codeUnitAt(start);
    if (c == _escapeFnc1) {
      return _CType.fnc1;
    }
    if (c < 48 /* 0 */ || c > 57 /* 9 */) {
      return _CType.uncodable;
    }
    if (start + 1 >= last) {
      return _CType.oneDigit;
    }
    c = value.codeUnitAt(start + 1);
    if (c < 48 /* 0 */ || c > 57 /* 9 */) {
      return _CType.oneDigit;
    }
    return _CType.twoDigits;
  }

  static int _chooseCode(String value, int start, int oldCode) {
    _CType lookahead = _findCType(value, start);
    if (lookahead == _CType.oneDigit) {
      if (oldCode == _codeCodeA) {
        return _codeCodeA;
      }
      return _codeCodeB;
    }
    if (lookahead == _CType.uncodable) {
      if (start < value.length) {
        final c = value.codeUnitAt(start);
        if (c < 32 /*   */ ||
            (oldCode == _codeCodeA &&
                (c < 96 /* ` */ || (c >= _escapeFnc1 && c <= _escapeFnc4)))) {
          // can continue in code A, encodes ASCII 0 to 95 or FNC1 to FNC4
          return _codeCodeA;
        }
      }
      return _codeCodeB; // no choice
    }
    if (oldCode == _codeCodeA && lookahead == _CType.fnc1) {
      return _codeCodeA;
    }
    if (oldCode == _codeCodeC) {
      // can continue in code C
      return _codeCodeC;
    }
    if (oldCode == _codeCodeB) {
      if (lookahead == _CType.fnc1) {
        return _codeCodeB; // can continue in code B
      }
      // Seen two consecutive digits, see what follows
      lookahead = _findCType(value, start + 2);
      if (lookahead == _CType.uncodable || lookahead == _CType.oneDigit) {
        return _codeCodeB; // not worth switching now
      }
      if (lookahead == _CType.fnc1) {
        // two digits, then FNC_1...
        lookahead = _findCType(value, start + 3);
        if (lookahead == _CType.twoDigits) {
          // then two more digits, switch
          return _codeCodeC;
        } else {
          return _codeCodeB; // otherwise not worth switching
        }
      }
      // At this point, there are at least 4 consecutive digits.
      // Look ahead to choose whether to switch now or on the next round.
      int index = start + 4;
      while ((lookahead = _findCType(value, index)) == _CType.twoDigits) {
        index += 2;
      }
      if (lookahead == _CType.oneDigit) {
        // odd number of digits, switch later
        return _codeCodeB;
      }
      return _codeCodeC; // even number of digits, switch now
    }
    // Here oldCode == 0, which means we are choosing the initial code
    if (lookahead == _CType.fnc1) {
      // ignore FNC_1
      lookahead = _findCType(value, start + 1);
    }
    if (lookahead == _CType.twoDigits) {
      // at least two digits, start in code C
      return _codeCodeC;
    }
    return _codeCodeB;
  }
}
