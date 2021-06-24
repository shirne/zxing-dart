/*
 * Copyright 2009 ZXing authors
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

import '../../common/bit_matrix.dart';

import '../../binary_bitmap.dart';
import '../../decode_hint_type.dart';
import '../../result_point.dart';
import 'pdf417_detector_result.dart';

/// Encapsulates logic that can detect a PDF417 Code in an image, even if the
/// PDF417 Code is rotated or skewed, or partially obscured.
///
/// @author SITA Lab (kevin.osullivan@sita.aero)
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Guenther Grau
class Detector {
  static const List<int> _INDEXES_START_PATTERN = [0, 4, 1, 5];
  static const List<int> _INDEXES_STOP_PATTERN = [6, 2, 7, 3];
  static const double _MAX_AVG_VARIANCE = 0.42;
  static const double _MAX_INDIVIDUAL_VARIANCE = 0.8;

  // B S B S B S B S Bar/Space pattern
  // 11111111 0 1 0 1 0 1 000
  static const List<int> _START_PATTERN = [8, 1, 1, 1, 1, 1, 1, 3];
  // 1111111 0 1 000 1 0 1 00 1
  static const List<int> _STOP_PATTERN = [7, 1, 1, 3, 1, 1, 1, 2, 1];
  static const int _MAX_PIXEL_DRIFT = 3;
  static const int _MAX_PATTERN_DRIFT = 5;
  // if we set the value too low, then we don't detect the correct height of the bar if the start patterns are damaged.
  // if we set the value too high, then we might detect the start pattern from a neighbor barcode.
  static const int _SKIPPED_ROW_COUNT_MAX = 25;
  // A PDF471 barcode should have at least 3 rows, with each row being >= 3 times the module width. Therefore it should be at least
  // 9 pixels tall. To be conservative, we use about half the size to ensure we don't miss it.
  static const int _ROW_STEP = 5;
  static const int _BARCODE_MIN_HEIGHT = 10;

  Detector._();

  /// <p>Detects a PDF417 Code in an image. Checks 0, 90, 180, and 270 degree rotations.</p>
  ///
  /// @param image barcode image to decode
  /// @param hints optional hints to detector
  /// @param multiple if true, then the image is searched for multiple codes. If false, then at most one code will
  /// be found and returned
  /// @return [PDF417DetectorResult] encapsulating results of detecting a PDF417 code
  /// @throws NotFoundException if no PDF417 Code can be found
  static PDF417DetectorResult detect(
      BinaryBitmap image, Map<DecodeHintType, Object>? hints, bool multiple) {
    // TODO detection improvement, tryHarder could try several different luminance thresholds/blackpoints or even
    // different binarizers
    //bool tryHarder = hints != null && hints.containsKey(DecodeHintType.TRY_HARDER);

    BitMatrix bitMatrix = image.blackMatrix;

    List<List<ResultPoint?>> barcodeCoordinates = _detect(multiple, bitMatrix);
    // Try 180, 270, 90 degree rotations, in that order
    for (int rotate = 0; barcodeCoordinates.isEmpty && rotate < 3; rotate++) {
      bitMatrix = bitMatrix.clone();
      if (rotate != 1) {
        bitMatrix.rotate180();
      } else {
        bitMatrix.rotate90();
      }
      barcodeCoordinates = _detect(multiple, bitMatrix);
    }
    return PDF417DetectorResult(bitMatrix, barcodeCoordinates);
  }

  /// Detects PDF417 codes in an image. Only checks 0 degree rotation
  /// @param multiple if true, then the image is searched for multiple codes. If false, then at most one code will
  /// be found and returned
  /// @param bitMatrix bit matrix to detect barcodes in
  /// @return List of ResultPoint arrays containing the coordinates of found barcodes
  static List<List<ResultPoint?>> _detect(bool multiple, BitMatrix bitMatrix) {
    List<List<ResultPoint?>> barcodeCoordinates = [];
    int row = 0;
    int column = 0;
    bool foundBarcodeInRow = false;
    while (row < bitMatrix.height) {
      List<ResultPoint?> vertices = _findVertices(bitMatrix, row, column);

      if (vertices[0] == null && vertices[3] == null) {
        if (!foundBarcodeInRow) {
          // we didn't find any barcode so that's the end of searching
          break;
        }
        // we didn't find a barcode starting at the given column and row. Try again from the first column and slightly
        // below the lowest barcode we found so far.
        foundBarcodeInRow = false;
        column = 0;
        for (List<ResultPoint?> barcodeCoordinate in barcodeCoordinates) {
          if (barcodeCoordinate[1] != null) {
            row = Math.max(row, barcodeCoordinate[1]!.y).toInt();
          }
          if (barcodeCoordinate[3] != null) {
            row = Math.max(row, barcodeCoordinate[3]!.y.toInt());
          }
        }
        row += _ROW_STEP;
        continue;
      }
      foundBarcodeInRow = true;
      barcodeCoordinates.add(vertices);
      if (!multiple) {
        break;
      }
      // if we didn't find a right row indicator column, then continue the search for the next barcode after the
      // start pattern of the barcode just found.
      if (vertices[2] != null) {
        column = vertices[2]!.x.toInt();
        row = vertices[2]!.y.toInt();
      } else {
        column = vertices[4]!.x.toInt();
        row = vertices[4]!.y.toInt();
      }
    }
    return barcodeCoordinates;
  }

  /// Locate the vertices and the codewords area of a black blob using the Start
  /// and Stop patterns as locators.
  ///
  /// @param matrix the scanned barcode image.
  /// @return an array containing the vertices:
  ///           vertices[0] x, y top left barcode
  ///           vertices[1] x, y bottom left barcode
  ///           vertices[2] x, y top right barcode
  ///           vertices[3] x, y bottom right barcode
  ///           vertices[4] x, y top left codeword area
  ///           vertices[5] x, y bottom left codeword area
  ///           vertices[6] x, y top right codeword area
  ///           vertices[7] x, y bottom right codeword area
  static List<ResultPoint?> _findVertices(
      BitMatrix matrix, int startRow, int startColumn) {
    int height = matrix.height;
    int width = matrix.width;

    List<ResultPoint?> result = List.filled(8, null);
    _copyToResult(
        result,
        _findRowsWithPattern(
            matrix, height, width, startRow, startColumn, _START_PATTERN),
        _INDEXES_START_PATTERN);

    if (result[4] != null) {
      startColumn = result[4]!.x.toInt();
      startRow = result[4]!.y.toInt();
    }

    _copyToResult(
        result,
        _findRowsWithPattern(
            matrix, height, width, startRow, startColumn, _STOP_PATTERN),
        _INDEXES_STOP_PATTERN);

    return result;
  }

  static void _copyToResult(List<ResultPoint?> result,
      List<ResultPoint?> tmpResult, List<int> destinationIndexes) {
    for (int i = 0; i < destinationIndexes.length; i++) {
      result[destinationIndexes[i]] = tmpResult[i];
    }
  }

  static List<ResultPoint?> _findRowsWithPattern(BitMatrix matrix, int height,
      int width, int startRow, int startColumn, List<int> pattern) {
    List<ResultPoint?> result = List.filled(4, null);
    bool found = false;
    List<int> counters = List.filled(pattern.length, 0);
    for (; startRow < height; startRow += _ROW_STEP) {
      List<int>? loc = _findGuardPattern(
          matrix, startColumn, startRow, width, pattern, counters);
      if (loc != null) {
        while (startRow > 0) {
          List<int>? previousRowLoc = _findGuardPattern(
              matrix, startColumn, --startRow, width, pattern, counters);
          if (previousRowLoc != null) {
            loc = previousRowLoc;
          } else {
            startRow++;
            break;
          }
        }
        result[0] = ResultPoint(loc![0].toDouble(), startRow.toDouble());
        result[1] = ResultPoint(loc[1].toDouble(), startRow.toDouble());
        found = true;
        break;
      }
    }
    int stopRow = startRow + 1;
    // Last row of the current symbol that contains pattern
    if (found) {
      int skippedRowCount = 0;
      List<int> previousRowLoc = [result[0]!.x.toInt(), result[1]!.x.toInt()];
      for (; stopRow < height; stopRow++) {
        List<int>? loc = _findGuardPattern(
            matrix, previousRowLoc[0], stopRow, width, pattern, counters);
        // a found pattern is only considered to belong to the same barcode if the start and end positions
        // don't differ too much. Pattern drift should be not bigger than two for consecutive rows. With
        // a higher number of skipped rows drift could be larger. To keep it simple for now, we allow a slightly
        // larger drift and don't check for skipped rows.
        if (loc != null &&
            (previousRowLoc[0] - loc[0]).abs() < _MAX_PATTERN_DRIFT &&
            (previousRowLoc[1] - loc[1]).abs() < _MAX_PATTERN_DRIFT) {
          previousRowLoc = loc;
          skippedRowCount = 0;
        } else {
          if (skippedRowCount > _SKIPPED_ROW_COUNT_MAX) {
            break;
          } else {
            skippedRowCount++;
          }
        }
      }
      stopRow -= skippedRowCount + 1;
      result[2] = ResultPoint(previousRowLoc[0].toDouble(), stopRow.toDouble());
      result[3] = ResultPoint(previousRowLoc[1].toDouble(), stopRow.toDouble());
    }
    if (stopRow - startRow < _BARCODE_MIN_HEIGHT) {
      result.fillRange(0, result.length, null);
    }
    return result;
  }

  /// @param matrix row of black/white values to search
  /// @param column x position to start search
  /// @param row y position to start search
  /// @param width the number of pixels to search on this row
  /// @param pattern pattern of counts of number of black and white pixels that are
  ///                 being searched for as a pattern
  /// @param counters array of counters, as long as pattern, to re-use
  /// @return start/end horizontal offset of guard pattern, as an array of two ints.
  static List<int>? _findGuardPattern(BitMatrix matrix, int column, int row,
      int width, List<int> pattern, List<int> counters) {
    counters.fillRange(0, counters.length, 0);
    int patternStart = column;
    int pixelDrift = 0;

    // if there are black pixels left of the current pixel shift to the left, but only for MAX_PIXEL_DRIFT pixels
    while (matrix.get(patternStart, row) &&
        patternStart > 0 &&
        pixelDrift++ < _MAX_PIXEL_DRIFT) {
      patternStart--;
    }
    int x = patternStart;
    int counterPosition = 0;
    int patternLength = pattern.length;
    for (bool isWhite = false; x < width; x++) {
      bool pixel = matrix.get(x, row);
      if (pixel != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == patternLength - 1) {
          if (_patternMatchVariance(counters, pattern) < _MAX_AVG_VARIANCE) {
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
    if (counterPosition == patternLength - 1 &&
        _patternMatchVariance(counters, pattern) < _MAX_AVG_VARIANCE) {
      return [patternStart, x - 1];
    }
    return null;
  }

  /// Determines how closely a set of observed counts of runs of black/white
  /// values matches a given target pattern. This is reported as the ratio of
  /// the total variance from the expected pattern proportions across all
  /// pattern elements, to the length of the pattern.
  ///
  /// @param counters observed counters
  /// @param pattern expected pattern
  /// @return ratio of total variance between counters and pattern compared to total pattern size
  static double _patternMatchVariance(List<int> counters, List<int> pattern) {
    int numCounters = counters.length;
    int total = 0;
    int patternLength = 0;
    for (int i = 0; i < numCounters; i++) {
      total += counters[i];
      patternLength += pattern[i];
    }
    if (total < patternLength) {
      // If we don't even have one pixel per unit of bar width, assume this
      // is too small to reliably match, so fail:
      return double.maxFinite;
    }
    // We're going to fake floating-point math in integers. We just need to use more bits.
    // Scale up patternLength so that intermediate values below like scaledCounter will have
    // more "significant digits".
    double unitBarWidth = total / patternLength;
    double maxIndividualVariance = _MAX_INDIVIDUAL_VARIANCE * unitBarWidth;

    double totalVariance = 0.0;
    for (int x = 0; x < numCounters; x++) {
      int counter = counters[x];
      double scaledPattern = pattern[x] * unitBarWidth;
      double variance = counter > scaledPattern
          ? counter - scaledPattern
          : scaledPattern - counter;
      if (variance > maxIndividualVariance) {
        return double.maxFinite;
        //POSITIVE_INFINITY;
      }
      totalVariance += variance;
    }
    return totalVariance / total;
  }
}
