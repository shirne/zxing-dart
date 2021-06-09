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

import '../common/bit_array.dart';
import '../common/string_builder.dart';

import '../barcode_format.dart';
import '../checksum_exception.dart';
import '../decode_hint_type.dart';
import '../formats_exception.dart';
import '../not_found_exception.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import '../result.dart';
import 'one_dreader.dart';

/// <p>Decodes Code 93 barcodes.</p>
///
/// @author Sean Owen
/// @see Code39Reader
class Code93Reader extends OneDReader {
  // Note that 'abcd' are dummy characters in place of control characters.
  static const String ALPHABET_STRING =
      r"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%abcd*";
  static final List<int> _ALPHABET = ALPHABET_STRING.codeUnits;

  /// These represent the encodings of characters, as patterns of wide and narrow bars.
  /// The 9 least-significant bits of each int correspond to the pattern of wide and narrow.
  static const List<int> CHARACTER_ENCODINGS = [
    0x114, 0x148, 0x144, 0x142, 0x128, 0x124, 0x122, 0x150, 0x112, 0x10A, // 0-9
    0x1A8, 0x1A4, 0x1A2, 0x194, 0x192, 0x18A, 0x168, 0x164, 0x162, 0x134, // A-J
    0x11A, 0x158, 0x14C, 0x146, 0x12C, 0x116, 0x1B4, 0x1B2, 0x1AC, 0x1A6, // K-T
    0x196, 0x19A, 0x16C, 0x166, 0x136, 0x13A, // U-Z
    0x12E, 0x1D4, 0x1D2, 0x1CA, 0x16E, 0x176, 0x1AE, // - - %
    0x126, 0x1DA, 0x1D6, 0x132, 0x15E, // Control chars? $-*
  ];
  static final int ASTERISK_ENCODING = CHARACTER_ENCODINGS[47];

  final StringBuilder _decodeRowResult;
  final List<int> _counters;

  Code93Reader()
      : _decodeRowResult = StringBuilder(),
        _counters = List.filled(6, 0);

  @override
  Result decodeRow(
      int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints) {
    List<int> start = _findAsteriskPattern(row);
    // Read off white space
    int nextStart = row.getNextSet(start[1]);
    int end = row.size;

    List<int> theCounters = _counters;
    // Arrays.fill(theCounters, 0);
    StringBuilder result = _decodeRowResult;
    result.clear();

    String decodedChar;
    int lastStart;
    do {
      OneDReader.recordPattern(row, nextStart, theCounters);
      int pattern = _toPattern(theCounters);
      if (pattern < 0) {
        throw NotFoundException.instance;
      }
      decodedChar = _patternToChar(pattern);
      result.write(decodedChar);
      lastStart = nextStart;
      for (int counter in theCounters) {
        nextStart += counter;
      }
      // Read off white space
      nextStart = row.getNextSet(nextStart);
    } while (decodedChar != '*');
    result.deleteCharAt(result.length - 1); // remove asterisk

    int lastPatternSize = 0;
    for (int counter in theCounters) {
      lastPatternSize += counter;
    }

    // Should be at least one more black module
    if (nextStart == end || !row.get(nextStart)) {
      throw NotFoundException.instance;
    }

    if (result.length < 2) {
      // false positive -- need at least 2 checksum digits
      throw NotFoundException.instance;
    }

    _checkChecksums(result.toString());
    // Remove checksum digits
    result.setLength(result.length - 2);

    String resultString = _decodeExtended(result.toString());

    double left = (start[1] + start[0]) / 2.0;
    double right = lastStart + lastPatternSize / 2.0;

    Result resultObject = Result(
        resultString,
        null,
        [
          ResultPoint(left, rowNumber.toDouble()),
          ResultPoint(right, rowNumber.toDouble())
        ],
        BarcodeFormat.CODE_93);
    resultObject.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER, "]G0");
    return resultObject;
  }

  List<int> _findAsteriskPattern(BitArray row) {
    int width = row.size;
    int rowOffset = row.getNextSet(0);

    // Arrays.fill(counters, 0);
    List<int> theCounters = _counters;
    int patternStart = rowOffset;
    bool isWhite = false;
    int patternLength = theCounters.length;

    int counterPosition = 0;
    for (int i = rowOffset; i < width; i++) {
      if (row.get(i) != isWhite) {
        theCounters[counterPosition]++;
      } else {
        if (counterPosition == patternLength - 1) {
          if (_toPattern(theCounters) == ASTERISK_ENCODING) {
            return [patternStart, i];
          }
          patternStart += theCounters[0] + theCounters[1];
          List.copyRange(theCounters, 0, theCounters, 2, counterPosition + 1);
          theCounters[counterPosition - 1] = 0;
          theCounters[counterPosition] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        theCounters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    throw NotFoundException.instance;
  }

  static int _toPattern(List<int> counters) {
    int sum = 0;
    for (int counter in counters) {
      sum += counter;
    }
    int pattern = 0;
    int max = counters.length;
    for (int i = 0; i < max; i++) {
      int scaled = (counters[i] * 9.0 / sum).round();
      if (scaled < 1 || scaled > 4) {
        return -1;
      }
      if ((i & 0x01) == 0) {
        for (int j = 0; j < scaled; j++) {
          pattern = (pattern << 1) | 0x01;
        }
      } else {
        pattern <<= scaled;
      }
    }
    return pattern;
  }

  static String _patternToChar(int pattern) {
    for (int i = 0; i < CHARACTER_ENCODINGS.length; i++) {
      if (CHARACTER_ENCODINGS[i] == pattern) {
        return String.fromCharCode(_ALPHABET[i]);
      }
    }
    throw NotFoundException.instance;
  }

  static String _decodeExtended(String encoded) {
    int length = encoded.length;
    StringBuffer decoded = StringBuffer();
    for (int i = 0; i < length; i++) {
      int c = encoded.codeUnitAt(i);
      if (c >= 97 /* a */ && c <= 100 /* d */) {
        if (i >= length - 1) {
          throw FormatsException.instance;
        }
        int next = encoded.codeUnitAt(i + 1);
        int decodedChar = 0;
        switch (c) {
          case 100: // 'd'
            // +A to +Z map to a to z
            if (next >= 65 /* A */ && next <= 90 /* Z */) {
              decodedChar = next + 32;
            } else {
              throw FormatsException.instance;
            }
            break;
          case 97: //'a'
            // $A to $Z map to control codes SH to SB
            if (next >= 65 /* A */ && next <= 90 /* Z */) {
              decodedChar = next - 64;
            } else {
              throw FormatsException.instance;
            }
            break;
          case 98: // 'b'
            if (next >= 65 /* A */ && next <= 69 /* E */) {
              // %A to %E map to control codes ESC to USep
              decodedChar = next - 38;
            } else if (next >= 70 /* F */ && next <= 74 /* J */) {
              // %F to %J map to ; < = > ?
              decodedChar = next - 11;
            } else if (next >= 75 /* K */ && next <= 79 /* O */) {
              // %K to %O map to [ \ ] ^ _
              decodedChar = next + 16;
            } else if (next >= 80 /* P */ && next <= 84 /* T */) {
              // %P to %T map to { | } ~ DEL
              decodedChar = next + 43;
            } else if (next == 85 /* U */) {
              // %U map to NUL
              decodedChar = 0;
            } else if (next == 86 /* V */) {
              // %V map to @
              decodedChar = 64;
            } else if (next == 87 /* W */) {
              // %W map to `
              decodedChar = 96;
            } else if (next >= 88 /* X */ && next <= 90 /* Z */) {
              // %X to %Z all map to DEL (127)
              decodedChar = 127;
            } else {
              throw FormatsException.instance;
            }
            break;
          case 99: // 'c'
            // /A to /O map to ! to , and /Z maps to :
            if (next >= 65 /* A */ && next <= 79 /* O */) {
              decodedChar = next - 32;
            } else if (next == 90 /* Z */) {
              decodedChar = 58;
            } else {
              throw FormatsException.instance;
            }
            break;
        }
        decoded.writeCharCode(decodedChar);
        // bump up i again since we read two characters
        i++;
      } else {
        decoded.writeCharCode(c);
      }
    }
    return decoded.toString();
  }

  static void _checkChecksums(String result) {
    int length = result.length;
    _checkOneChecksum(result, length - 2, 20);
    _checkOneChecksum(result, length - 1, 15);
  }

  static void _checkOneChecksum(
      String result, int checkPosition, int weightMax) {
    int weight = 1;
    int total = 0;
    for (int i = checkPosition - 1; i >= 0; i--) {
      total += weight * ALPHABET_STRING.indexOf(result[i]);
      if (++weight > weightMax) {
        weight = 1;
      }
    }
    if (result.codeUnitAt(checkPosition) != _ALPHABET[total % 47]) {
      throw ChecksumException.getChecksumInstance();
    }
  }
}
