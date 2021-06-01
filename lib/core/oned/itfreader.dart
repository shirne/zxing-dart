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

import '../barcode_format.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../result.dart';
import '../result_point.dart';
import 'one_dreader.dart';

/// <p>Implements decoding of the ITF format, or Interleaved Two of Five.</p>
///
/// <p>This Reader will scan ITF barcodes of certain lengths only.
/// At the moment it reads length 6, 8, 10, 12, 14, 16, 18, 20, 24, and 44 as these have appeared "in the wild". Not all
/// lengths are scanned, especially shorter ones, to avoid false positives. This in turn is due to a lack of
/// required checksum function.</p>
///
/// <p>The checksum is optional and is not applied by this Reader. The consumer of the decoded
/// value will have to apply a checksum if required.</p>
///
/// <p><a href="http://en.wikipedia.org/wiki/Interleaved_2_of_5">http://en.wikipedia.org/wiki/Interleaved_2_of_5</a>
/// is a great reference for Interleaved 2 of 5 information.</p>
///
/// @author kevin.osullivan@sita.aero, SITA Lab.
class ITFReader extends OneDReader {

  static const double _MAX_AVG_VARIANCE = 0.38;
  static const double _MAX_INDIVIDUAL_VARIANCE = 0.5;

  static const int _W = 3; // Pixel width of a 3x wide line
  static const int _w = 2; // Pixel width of a 2x wide line
  static const int _N = 1; // Pixed width of a narrow line

  /// Valid ITF lengths. Anything longer than the largest value is also allowed.
  static const List<int> _DEFAULT_ALLOWED_LENGTHS = [6, 8, 10, 12, 14];

  // Stores the actual narrow line width of the image being decoded.
  int _narrowLineWidth = -1;

  /// Start/end guard pattern.
  ///
  /// Note: The end pattern is reversed because the row is reversed before
  /// searching for the END_PATTERN
  static const List<int> _START_PATTERN = [_N, _N, _N, _N];
  static const List<List<int>> _END_PATTERN_REVERSED = [
      [_N, _N, _w], // 2x
      [_N, _N, _W]  // 3x
  ];

  // See ITFWriter.PATTERNS

  /// Patterns of Wide / Narrow lines to indicate each digit
  static const List<List<int>> _PATTERNS = [
      [_N, _N, _w, _w, _N], // 0
      [_w, _N, _N, _N, _w], // 1
      [_N, _w, _N, _N, _w], // 2
      [_w, _w, _N, _N, _N], // 3
      [_N, _N, _w, _N, _w], // 4
      [_w, _N, _w, _N, _N], // 5
      [_N, _w, _w, _N, _N], // 6
      [_N, _N, _N, _w, _w], // 7
      [_w, _N, _N, _w, _N], // 8
      [_N, _w, _N, _w, _N], // 9
      [_N, _N, _W, _W, _N], // 0
      [_W, _N, _N, _N, _W], // 1
      [_N, _W, _N, _N, _W], // 2
      [_W, _W, _N, _N, _N], // 3
      [_N, _N, _W, _N, _W], // 4
      [_W, _N, _W, _N, _N], // 5
      [_N, _W, _W, _N, _N], // 6
      [_N, _N, _N, _W, _W], // 7
      [_W, _N, _N, _W, _N], // 8
      [_N, _W, _N, _W, _N]  // 9
  ];

  @override
  Result decodeRow(int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints)
     {

    // Find out where the Middle section (payload) starts & ends
    List<int> startRange = _decodeStart(row);
    List<int> endRange = _decodeEnd(row);

    StringBuffer result = StringBuffer();
    _decodeMiddle(row, startRange[1], endRange[0], result);
    String resultString = result.toString();

    List<int>? allowedLengths ;
    if (hints != null) {
      allowedLengths = hints[DecodeHintType.ALLOWED_LENGTHS] as List<int>;

    }
    if (allowedLengths == null) {
      allowedLengths = _DEFAULT_ALLOWED_LENGTHS;
    }

    // To avoid false positives with 2D barcodes (and other patterns), make
    // an assumption that the decoded string must be a 'standard' length if it's short
    int length = resultString.length;
    bool lengthOK = false;
    int maxAllowedLength = 0;
    for (int allowedLength in allowedLengths) {
      if (length == allowedLength) {
        lengthOK = true;
        break;
      }
      if (allowedLength > maxAllowedLength) {
        maxAllowedLength = allowedLength;
      }
    }
    if (!lengthOK && length > maxAllowedLength) {
      lengthOK = true;
    }
    if (!lengthOK) {
      throw FormatException();
    }

    return Result(
        resultString,
        null, // no natural byte representation for these barcodes
        [ResultPoint(startRange[1].toDouble(), rowNumber.toDouble()),
                           ResultPoint(endRange[0].toDouble(), rowNumber.toDouble())],
        BarcodeFormat.ITF);
  }

  /// @param row          row of black/white values to search
  /// @param payloadStart offset of start pattern
  /// @param resultString {@link StringBuffer} to append decoded chars to
  /// @throws NotFoundException if decoding could not complete successfully
  static void _decodeMiddle(BitArray row,
                                   int payloadStart,
                                   int payloadEnd,
                                   StringBuffer resultString){

    // Digits are interleaved in pairs - 5 black lines for one digit, and the
    // 5
    // interleaved white lines for the second digit.
    // Therefore, need to scan 10 lines and then
    // split these into two arrays
    List<int> counterDigitPair = List.filled(10, 0);
    List<int> counterBlack = List.filled(5, 0);
    List<int> counterWhite = List.filled(5, 0);

    while (payloadStart < payloadEnd) {

      // Get 10 runs of black/white.
      OneDReader.recordPattern(row, payloadStart, counterDigitPair);
      // Split them into each array
      for (int k = 0; k < 5; k++) {
        int twoK = 2 * k;
        counterBlack[k] = counterDigitPair[twoK];
        counterWhite[k] = counterDigitPair[twoK + 1];
      }

      int bestMatch = _decodeDigit(counterBlack);
      resultString.writeCharCode('0'.codeUnitAt(0) + bestMatch);
      bestMatch = _decodeDigit(counterWhite);
      resultString.write('0'.codeUnitAt(0) + bestMatch);

      for (int counterDigit in counterDigitPair) {
        payloadStart += counterDigit;
      }
    }
  }

  /// Identify where the start of the middle / payload section starts.
  ///
  /// @param row row of black/white values to search
  /// @return Array, containing index of start of 'start block' and end of
  ///         'start block'
  List<int> _decodeStart(BitArray row){
    int endStart = _skipWhiteSpace(row);
    List<int> startPattern = _findGuardPattern(row, endStart, _START_PATTERN);

    // Determine the width of a narrow line in pixels. We can do this by
    // getting the width of the start pattern and dividing by 4 because its
    // made up of 4 narrow lines.
    this._narrowLineWidth = (startPattern[1] - startPattern[0]) ~/ 4;

    _validateQuietZone(row, startPattern[0]);

    return startPattern;
  }

  /// The start & end patterns must be pre/post fixed by a quiet zone. This
  /// zone must be at least 10 times the width of a narrow line.  Scan back until
  /// we either get to the start of the barcode or match the necessary number of
  /// quiet zone pixels.
  ///
  /// Note: Its assumed the row is reversed when using this method to find
  /// quiet zone after the end pattern.
  ///
  /// ref: http://www.barcode-1.net/i25code.html
  ///
  /// @param row bit array representing the scanned barcode.
  /// @param startPattern index into row of the start or end pattern.
  /// @throws NotFoundException if the quiet zone cannot be found
  void _validateQuietZone(BitArray row, int startPattern){

    int quietCount = this._narrowLineWidth * 10;  // expect to find this many pixels of quiet zone

    // if there are not so many pixel at all let's try as many as possible
    quietCount = Math.min(quietCount, startPattern);

    for (int i = startPattern - 1; quietCount > 0 && i >= 0; i--) {
      if (row.get(i)) {
        break;
      }
      quietCount--;
    }
    if (quietCount != 0) {
      // Unable to find the necessary number of quiet zone pixels.
      throw NotFoundException.getNotFoundInstance();
    }
  }

  /// Skip all whitespace until we get to the first black line.
  ///
  /// @param row row of black/white values to search
  /// @return index of the first black line.
  /// @throws NotFoundException
  static int _skipWhiteSpace(BitArray row){
    int width = row.getSize();
    int endStart = row.getNextSet(0);
    if (endStart == width) {
      throw NotFoundException.getNotFoundInstance();
    }

    return endStart;
  }

  /// Identify where the end of the middle / payload section ends.
  ///
  /// @param row row of black/white values to search
  /// @return Array, containing index of start of 'end block' and end of 'end
  ///         block'
  List<int> _decodeEnd(BitArray row){

    // For convenience, reverse the row and then
    // search from 'the start' for the end block
    row.reverse();
    try {
      int endStart = _skipWhiteSpace(row);
      List<int> endPattern;
      try {
        endPattern = _findGuardPattern(row, endStart, _END_PATTERN_REVERSED[0]);
      } catch ( nfe) { // NotFoundException
        endPattern = _findGuardPattern(row, endStart, _END_PATTERN_REVERSED[1]);
      }

      // The start & end patterns must be pre/post fixed by a quiet zone. This
      // zone must be at least 10 times the width of a narrow line.
      // ref: http://www.barcode-1.net/i25code.html
      _validateQuietZone(row, endPattern[0]);

      // Now recalculate the indices of where the 'endblock' starts & stops to
      // accommodate
      // the reversed nature of the search
      int temp = endPattern[0];
      endPattern[0] = row.getSize() - endPattern[1];
      endPattern[1] = row.getSize() - temp;

      return endPattern;
    } finally {
      // Put the row back the right way.
      row.reverse();
    }
  }

  /// @param row       row of black/white values to search
  /// @param rowOffset position to start search
  /// @param pattern   pattern of counts of number of black and white pixels that are
  ///                  being searched for as a pattern
  /// @return start/end horizontal offset of guard pattern, as an array of two
  ///         ints
  /// @throws NotFoundException if pattern is not found
  static List<int> _findGuardPattern(BitArray row,
                                        int rowOffset,
                                        List<int> pattern){
    int patternLength = pattern.length;
    List<int> counters = List.filled(patternLength, 0);
    int width = row.getSize();
    bool isWhite = false;

    int counterPosition = 0;
    int patternStart = rowOffset;
    for (int x = rowOffset; x < width; x++) {
      if (row.get(x) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == patternLength - 1) {
          if (OneDReader.patternMatchVariance(counters, pattern, _MAX_INDIVIDUAL_VARIANCE) < _MAX_AVG_VARIANCE) {
            return [patternStart, x];
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

  /// Attempts to decode a sequence of ITF black/white lines into single
  /// digit.
  ///
  /// @param counters the counts of runs of observed black/white/black/... values
  /// @return The decoded digit
  /// @throws NotFoundException if digit cannot be decoded
  static int _decodeDigit(List<int> counters){
    double bestVariance = _MAX_AVG_VARIANCE; // worst variance we'll accept
    int bestMatch = -1;
    int max = _PATTERNS.length;
    for (int i = 0; i < max; i++) {
      List<int> pattern = _PATTERNS[i];
      double variance = OneDReader.patternMatchVariance(counters, pattern, _MAX_INDIVIDUAL_VARIANCE);
      if (variance < bestVariance) {
        bestVariance = variance;
        bestMatch = i;
      } else if (variance == bestVariance) {
        // if we find a second 'best match' with the same variance, we can not reliably report to have a suitable match
        bestMatch = -1;
      }
    }
    if (bestMatch >= 0) {
      return bestMatch % 10;
    } else {
      throw NotFoundException.getNotFoundInstance();
    }
  }

}
