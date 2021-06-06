/*
 * Copyright 2008 ZXing authors
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

import 'dart:math' as Math;

import '../common/bit_array.dart';
import '../common/detector/math_utils.dart';
import '../common/string_builder.dart';

import '../barcode_format.dart';
import '../checksum_exception.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import '../result.dart';
import 'one_dreader.dart';

/// <p>Decodes Code 39 barcodes. Supports "Full ASCII Code 39" if USE_CODE_39_EXTENDED_MODE is set.</p>
///
/// @author Sean Owen
/// @see Code93Reader
class Code39Reader extends OneDReader {
  static const String ALPHABET_STRING =
      r"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%";

  /// These represent the encodings of characters, as patterns of wide and narrow bars.
  /// The 9 least-significant bits of each int correspond to the pattern of wide and narrow,
  /// with 1s representing "wide" and 0s representing narrow.
  static const List<int> CHARACTER_ENCODINGS = [
    0x034, 0x121, 0x061, 0x160, 0x031, 0x130, 0x070, 0x025, 0x124, 0x064, // 0-9
    0x109, 0x049, 0x148, 0x019, 0x118, 0x058, 0x00D, 0x10C, 0x04C, 0x01C, // A-J
    0x103, 0x043, 0x142, 0x013, 0x112, 0x052, 0x007, 0x106, 0x046, 0x016, // K-T
    0x181, 0x0C1, 0x1C0, 0x091, 0x190, 0x0D0, 0x085, 0x184, 0x0C4, 0x0A8, // U-$
    0x0A2, 0x08A, 0x02A // /-%
  ];

  static const int ASTERISK_ENCODING = 0x094;

  final bool _usingCheckDigit;
  final bool _extendedMode;
  final StringBuilder _decodeRowResult;
  final List<int> _counters;

  /// Creates a reader that can be configured to check the last character as a check digit,
  /// or optionally attempt to decode "extended Code 39" sequences that are used to encode
  /// the full ASCII character set.
  ///
  /// @param usingCheckDigit if true, treat the last data character as a check digit, not
  /// data, and verify that the checksum passes.
  /// @param extendedMode if true, will attempt to decode extended Code 39 sequences in the
  /// text.
  Code39Reader([this._usingCheckDigit = false, this._extendedMode = false])
      : _decodeRowResult = StringBuilder(),
        _counters = List.filled(9, 0);

  @override
  Result decodeRow(
      int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints) {
    List<int> theCounters = _counters;
    theCounters.fillRange(0, theCounters.length, 0);

    StringBuilder result = _decodeRowResult;
    result.clear();

    List<int> start = _findAsteriskPattern(row, theCounters);
    // Read off white space
    int nextStart = row.getNextSet(start[1]);
    int end = row.getSize();

    String decodedChar;
    int lastStart;
    do {
      OneDReader.recordPattern(row, nextStart, theCounters);
      int pattern = _toNarrowWidePattern(theCounters);
      if (pattern < 0) {
        throw NotFoundException.getNotFoundInstance();
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
    result.setLength(result.length - 1); // remove asterisk

    // Look for whitespace after pattern:
    int lastPatternSize = 0;
    for (int counter in theCounters) {
      lastPatternSize += counter;
    }
    int whiteSpaceAfterEnd = nextStart - lastStart - lastPatternSize;
    // If 50% of last pattern size, following last pattern, is not whitespace, fail
    // (but if it's whitespace to the very end of the image, that's OK)
    if (nextStart != end && (whiteSpaceAfterEnd * 2) < lastPatternSize) {
      throw NotFoundException.getNotFoundInstance();
    }

    if (_usingCheckDigit) {
      int max = result.length - 1;
      int total = 0;
      for (int i = 0; i < max; i++) {
        total += ALPHABET_STRING.indexOf(_decodeRowResult.charAt(i));
      }
      if (result.codePointAt(max) != ALPHABET_STRING.codeUnitAt(total % 43)) {
        throw ChecksumException.getChecksumInstance();
      }
      result.setLength(max);
    }

    if (result.length == 0) {
      // false positive
      throw NotFoundException.getNotFoundInstance();
    }

    String resultString;
    if (_extendedMode) {
      resultString = _decodeExtended(result.toString());
    } else {
      resultString = result.toString();
    }

    double left = (start[1] + start[0]) / 2.0;
    double right = lastStart + lastPatternSize / 2.0;

    Result resultObject = Result(
        resultString,
        null,
        [
          ResultPoint(left, rowNumber.toDouble()),
          ResultPoint(right, rowNumber.toDouble())
        ],
        BarcodeFormat.CODE_39);
    resultObject.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER, "]A0");
    return resultObject;
  }

  static List<int> _findAsteriskPattern(BitArray row, List<int> counters) {
    int width = row.getSize();
    int rowOffset = row.getNextSet(0);

    int counterPosition = 0;
    int patternStart = rowOffset;
    bool isWhite = false;
    int patternLength = counters.length;

    for (int i = rowOffset; i < width; i++) {
      if (row.get(i) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == patternLength - 1) {
          // Look for whitespace before start pattern, >= 50% of width of start pattern
          if (_toNarrowWidePattern(counters) == ASTERISK_ENCODING &&
              row.isRange(Math.max(0, patternStart - ((i - patternStart) ~/ 2)),
                  patternStart, false)) {
            return [patternStart, i];
          }
          patternStart += counters[0] + counters[1];
          List.copyRange(counters, 0, counters, 2, counterPosition + 1);
          counters[counterPosition - 1] = 0;
          counters[counterPosition] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    throw NotFoundException.getNotFoundInstance();
  }

  // For efficiency, returns -1 on failure. Not throwing here saved as many as 700 exceptions
  // per image when using some of our blackbox images.
  static int _toNarrowWidePattern(List<int> counters) {
    int numCounters = counters.length;
    int maxNarrowCounter = 0;
    int wideCounters;
    do {
      int minCounter = MathUtils.MAX_VALUE;
      for (int counter in counters) {
        if (counter < minCounter && counter > maxNarrowCounter) {
          minCounter = counter;
        }
      }
      maxNarrowCounter = minCounter;
      wideCounters = 0;
      int totalWideCountersWidth = 0;
      int pattern = 0;
      for (int i = 0; i < numCounters; i++) {
        int counter = counters[i];
        if (counter > maxNarrowCounter) {
          pattern |= 1 << (numCounters - 1 - i);
          wideCounters++;
          totalWideCountersWidth += counter;
        }
      }
      if (wideCounters == 3) {
        // Found 3 wide counters, but are they close enough in width?
        // We can perform a cheap, conservative check to see if any individual
        // counter is more than 1.5 times the average:
        for (int i = 0; i < numCounters && wideCounters > 0; i++) {
          int counter = counters[i];
          if (counter > maxNarrowCounter) {
            wideCounters--;
            // totalWideCountersWidth = 3 * average, so this checks if counter >= 3/2 * average
            if ((counter * 2) >= totalWideCountersWidth) {
              return -1;
            }
          }
        }
        return pattern;
      }
    } while (wideCounters > 3);
    return -1;
  }

  static String _patternToChar(int pattern) {
    for (int i = 0; i < CHARACTER_ENCODINGS.length; i++) {
      if (CHARACTER_ENCODINGS[i] == pattern) {
        return ALPHABET_STRING[i];
      }
    }
    if (pattern == ASTERISK_ENCODING) {
      return '*';
    }
    throw NotFoundException.getNotFoundInstance();
  }

  static String _decodeExtended(String encoded) {
    int length = encoded.length;
    StringBuffer decoded = StringBuffer();
    for (int i = 0; i < length; i++) {
      String c = encoded[i];
      if (c == '+' || c == r'$' || c == '%' || c == '/') {
        int next = encoded.codeUnitAt(i + 1);
        String decodedChar = '\x00';
        switch (c) {
          case '+':
            // +A to +Z map to a to z
            if (next >= 65 /* A */ && next <= 90 /* Z */) {
              decodedChar = String.fromCharCode(next + 32);
            } else {
              throw FormatException();
            }
            break;
          case r'$':
            // $A to $Z map to control codes SH to SB
            if (next >= 65 /* A */ && next <= 90 /* Z */) {
              decodedChar = String.fromCharCode(next - 64);
            } else {
              throw FormatException();
            }
            break;
          case '%':
            // %A to %E map to control codes ESC to US
            if (next >= 65 /* A */ && next <= 69 /* E */) {
              decodedChar = String.fromCharCode(next - 38);
            } else if (next >= 70 /* F */ && next <= 74 /* J */) {
              decodedChar = String.fromCharCode(next - 11);
            } else if (next >= 75 /* K */ && next <= 79 /* O */) {
              decodedChar = String.fromCharCode(next + 16);
            } else if (next >= 80 /* P */ && next <= 84 /* T */) {
              decodedChar = String.fromCharCode(next + 43);
            } else if (next == 85 /* U */) {
              decodedChar = String.fromCharCode(0);
            } else if (next == 86 /* V */) {
              decodedChar = '@';
            } else if (next == 87 /* W */) {
              decodedChar = '`';
            } else if (next == 88 /* X */ ||
                next == 89 /* Y */ ||
                next == 90 /* Z */) {
              decodedChar = String.fromCharCode(127);
            } else {
              throw FormatException();
            }
            break;
          case '/':
            // /A to /O map to ! to , and /Z maps to :
            if (next >= 65 /* A */ && next <= 79 /* O */) {
              decodedChar = String.fromCharCode(next - 32);
            } else if (next == 90 /* Z */) {
              decodedChar = ':';
            } else {
              throw FormatException();
            }
            break;
        }
        decoded.write(decodedChar);
        // bump up i again since we read two characters
        i++;
      } else {
        decoded.write(c);
      }
    }
    return decoded.toString();
  }
}
