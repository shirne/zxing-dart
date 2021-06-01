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

import '../common/bit_array.dart';
import '../common/detector/math_utils.dart';
import '../common/string_builder.dart';

import '../barcode_format.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'one_dreader.dart';

/// <p>Decodes Codabar barcodes.</p>
///
/// @author Bas Vijfwinkel
/// @author David Walker
class CodaBarReader extends OneDReader {
  // These values are critical for determining how permissive the decoding
  // will be. All stripe sizes must be within the window these define, as
  // compared to the average stripe size.
  static const double _MAX_ACCEPTABLE = 2.0;
  static const double _PADDING = 1.5;

  static const String _ALPHABET_STRING = r"0123456789-$:/.+ABCD";
  static final List<int> ALPHABET = _ALPHABET_STRING.codeUnits;

  /// These represent the encodings of characters, as patterns of wide and narrow bars. The 7 least-significant bits of
  /// each int correspond to the pattern of wide and narrow, with 1s representing "wide" and 0s representing narrow.
  static const List<int> CHARACTER_ENCODINGS = [
    0x003, 0x006, 0x009, 0x060, 0x012, 0x042, 0x021, 0x024, 0x030, 0x048, // 0-9
    0x00c, 0x018, 0x045, 0x051, 0x054, 0x015, 0x01A, 0x029, 0x00B,
    0x00E, // -$:/.+ABCD
  ];

  // minimal number of characters that should be present (including start and stop characters)
  // under normal circumstances this should be set to 3, but can be set higher
  // as a last-ditch attempt to reduce false positives.
  static const int _MIN_CHARACTER_LENGTH = 3;

  // official start and end patterns
  static const List<String> _STARTEND_ENCODING = ['A', 'B', 'C', 'D'];
  // some Codabar generator allow the Codabar string to be closed by every
  // character. This will cause lots of false positives!

  // some industries use a checksum standard but this is not part of the original Codabar standard
  // for more information see : http://www.mecsw.com/specs/codabar.html

  // Keep some instance variables to avoid reallocations
  final StringBuilder _decodeRowResult;
  List<int> _counters;
  int _counterLength;

  CodaBarReader()
      : _decodeRowResult = StringBuilder(),
        _counters = List.generate(80, (index) => 0),
        _counterLength = 0;

  @override
  Result decodeRow(
      int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints) {
    //Arrays.fill(counters, 0);
    _setCounters(row);
    int startOffset = _findStartPattern();
    int nextStart = startOffset;

    _decodeRowResult.clear();
    do {
      int charOffset = _toNarrowWidePattern(nextStart);
      if (charOffset == -1) {
        throw NotFoundException.getNotFoundInstance();
      }
      // Hack: We store the position in the alphabet table into a
      // StringBuffer, so that we can access the decoded patterns in
      // validatePattern. We'll translate to the actual characters later.
      _decodeRowResult.writeCharCode(charOffset);
      nextStart += 8;
      // Stop as soon as we see the end character.
      if (_decodeRowResult.length > 1 &&
          _STARTEND_ENCODING
              .contains(String.fromCharCode(ALPHABET[charOffset]))) {
        break;
      }
    } while (nextStart <
        _counterLength); // no fixed end pattern so keep on reading while data is available

    // Look for whitespace after pattern:
    int trailingWhitespace = _counters[nextStart - 1];
    int lastPatternSize = 0;
    for (int i = -8; i < -1; i++) {
      lastPatternSize += _counters[nextStart + i];
    }

    // We need to see whitespace equal to 50% of the last pattern size,
    // otherwise this is probably a false positive. The exception is if we are
    // at the end of the row. (I.e. the barcode barely fits.)
    if (nextStart < _counterLength && trailingWhitespace < lastPatternSize / 2) {
      throw NotFoundException.getNotFoundInstance();
    }

    _validatePattern(startOffset);

    // Translate character table offsets to actual characters.
    for (int i = 0; i < _decodeRowResult.length; i++) {
      _decodeRowResult.setCharAt(i, ALPHABET[_decodeRowResult.codePointAt(i)]);
    }
    // Ensure a valid start and end character
    String startchar = _decodeRowResult.charAt(0);
    if (!_STARTEND_ENCODING.contains(startchar)) {
      throw NotFoundException.getNotFoundInstance();
    }
    String endchar = _decodeRowResult.charAt(_decodeRowResult.length - 1);
    if (!_STARTEND_ENCODING.contains(endchar)) {
      throw NotFoundException.getNotFoundInstance();
    }

    // remove stop/start characters character and check if a long enough string is contained
    if (_decodeRowResult.length <= _MIN_CHARACTER_LENGTH) {
      // Almost surely a false positive ( start + stop + at least 1 character)
      throw NotFoundException.getNotFoundInstance();
    }

    if (hints == null ||
        !hints.containsKey(DecodeHintType.RETURN_CODABAR_START_END)) {
      _decodeRowResult.deleteCharAt(_decodeRowResult.length - 1);
      _decodeRowResult.deleteCharAt(0);
    }

    int runningCount = 0;
    for (int i = 0; i < startOffset; i++) {
      runningCount += _counters[i];
    }
    double left = runningCount.toDouble();
    for (int i = startOffset; i < nextStart - 1; i++) {
      runningCount += _counters[i];
    }
    double right = runningCount.toDouble();

    Result result = Result(
        _decodeRowResult.toString(),
        null,
        [
          ResultPoint(left, rowNumber.toDouble()),
          ResultPoint(right, rowNumber.toDouble())
        ],
        BarcodeFormat.CODABAR);
    result.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER, "]F0");
    return result;
  }

  void _validatePattern(int start) {
    // First, sum up the total size of our four categories of stripe sizes;
    List<int> sizes = [0, 0, 0, 0];
    List<int> counts = [0, 0, 0, 0];
    int end = _decodeRowResult.length - 1;

    // We break out of this loop in the middle, in order to handle
    // inter-character spaces properly.
    int pos = start;
    for (int i = 0; true; i++) {
      int pattern = CHARACTER_ENCODINGS[_decodeRowResult.codePointAt(i)];
      for (int j = 6; j >= 0; j--) {
        // Even j = bars, while odd j = spaces. Categories 2 and 3 are for
        // long stripes, while 0 and 1 are for short stripes.
        int category = (j & 1) + (pattern & 1) * 2;
        sizes[category] += _counters[pos + j];
        counts[category]++;
        pattern >>= 1;
      }
      if (i >= end) {
        break;
      }
      // We ignore the inter-character space - it could be of any size.
      pos += 8;
    }

    // Calculate our allowable size thresholds using fixed-point math.
    List<double> maxes = [0, 0, 0, 0];
    List<double> mins = [0, 0, 0, 0];
    // Define the threshold of acceptability to be the midpoint between the
    // average small stripe and the average large stripe. No stripe lengths
    // should be on the "wrong" side of that line.
    for (int i = 0; i < 2; i++) {
      mins[i] = 0.0; // Accept arbitrarily small "short" stripes.
      mins[i + 2] = (sizes[i] / counts[i] + sizes[i + 2] / counts[i + 2]) / 2.0;
      maxes[i] = mins[i + 2];
      maxes[i + 2] = (sizes[i + 2] * _MAX_ACCEPTABLE + _PADDING) / counts[i + 2];
    }

    // Now verify that all of the stripes are within the thresholds.
    pos = start;
    for (int i = 0; true; i++) {
      int pattern = CHARACTER_ENCODINGS[_decodeRowResult.codePointAt(i)];
      for (int j = 6; j >= 0; j--) {
        // Even j = bars, while odd j = spaces. Categories 2 and 3 are for
        // long stripes, while 0 and 1 are for short stripes.
        int category = (j & 1) + (pattern & 1) * 2;
        int size = _counters[pos + j];
        if (size < mins[category] || size > maxes[category]) {
          throw NotFoundException.getNotFoundInstance();
        }
        pattern >>= 1;
      }
      if (i >= end) {
        break;
      }
      pos += 8;
    }
  }

  /// Records the size of all runs of white and black pixels, starting with white.
  /// This is just like recordPattern, except it records all the counters, and
  /// uses our builtin "counters" member for storage.
  /// @param row row to count from
  void _setCounters(BitArray row) {
    _counterLength = 0;
    // Start from the first white bit.
    int i = row.getNextUnset(0);
    int end = row.getSize();
    if (i >= end) {
      throw NotFoundException.getNotFoundInstance();
    }
    bool isWhite = true;
    int count = 0;
    while (i < end) {
      if (row.get(i) != isWhite) {
        count++;
      } else {
        _counterAppend(count);
        count = 1;
        isWhite = !isWhite;
      }
      i++;
    }
    _counterAppend(count);
  }

  void _counterAppend(int e) {
    _counters[_counterLength] = e;
    _counterLength++;
    if (_counterLength >= _counters.length) {
      List<int> temp = List.generate(_counterLength * 2, (index) => 0);
      List.copyRange(temp, 0, _counters, 0, _counterLength);
      _counters = temp;
    }
  }

  int _findStartPattern() {
    for (int i = 1; i < _counterLength; i += 2) {
      int charOffset = _toNarrowWidePattern(i);
      if (charOffset != -1 &&
          _STARTEND_ENCODING
              .contains(String.fromCharCode(ALPHABET[charOffset]))) {
        // Look for whitespace before start pattern, >= 50% of width of start pattern
        // We make an exception if the whitespace is the first element.
        int patternSize = 0;
        for (int j = i; j < i + 7; j++) {
          patternSize += _counters[j];
        }
        if (i == 1 || _counters[i - 1] >= patternSize / 2) {
          return i;
        }
      }
    }
    throw NotFoundException.getNotFoundInstance();
  }

  static bool arrayContains(List<int>? array, int key) {
    if (array != null) {
      for (int c in array) {
        if (c == key) {
          return true;
        }
      }
    }
    return false;
  }

  // Assumes that counters[position] is a bar.
  int _toNarrowWidePattern(int position) {
    int end = position + 7;
    if (end >= _counterLength) {
      return -1;
    }

    List<int> theCounters = _counters;

    int maxBar = 0;
    int minBar = MathUtils.MAX_VALUE;
    for (int j = position; j < end; j += 2) {
      int currentCounter = theCounters[j];
      if (currentCounter < minBar) {
        minBar = currentCounter;
      }
      if (currentCounter > maxBar) {
        maxBar = currentCounter;
      }
    }
    int thresholdBar = (minBar + maxBar) ~/ 2;

    int maxSpace = 0;
    int minSpace = MathUtils.MAX_VALUE;
    for (int j = position + 1; j < end; j += 2) {
      int currentCounter = theCounters[j];
      if (currentCounter < minSpace) {
        minSpace = currentCounter;
      }
      if (currentCounter > maxSpace) {
        maxSpace = currentCounter;
      }
    }
    int thresholdSpace = (minSpace + maxSpace) ~/ 2;

    int bitmask = 1 << 7;
    int pattern = 0;
    for (int i = 0; i < 7; i++) {
      int threshold = (i & 1) == 0 ? thresholdBar : thresholdSpace;
      bitmask >>= 1;
      if (theCounters[position + i] > threshold) {
        pattern |= bitmask;
      }
    }

    for (int i = 0; i < CHARACTER_ENCODINGS.length; i++) {
      if (CHARACTER_ENCODINGS[i] == pattern) {
        return i;
      }
    }
    return -1;
  }
}
