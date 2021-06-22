/*
 * Copyright 2013 ZXing authors
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
import '../../common/decoder_result.dart';
import '../../common/detector/math_utils.dart';

import '../../checksum_exception.dart';
import '../../formats_exception.dart';
import '../../not_found_exception.dart';
import '../../result_point.dart';
import '../pdf417_common.dart';
import 'barcode_metadata.dart';
import 'barcode_value.dart';
import 'bounding_box.dart';
import 'codeword.dart';
import 'decoded_bit_stream_parser.dart';
import 'detection_result.dart';
import 'detection_result_column.dart';
import 'detection_result_row_indicator_column.dart';
import 'ec/error_correction.dart';
import 'pdf417_codeword_decoder.dart';

/// @author Guenther Grau
class PDF417ScanningDecoder {
  static const int _CODEWORD_SKEW_SIZE = 2;

  static const int _MAX_ERRORS = 3;
  static const int _MAX_EC_CODEWORDS = 512;
  static final ErrorCorrection errorCorrection = ErrorCorrection();

  PDF417ScanningDecoder._();

  // TODO don't pass in minCodewordWidth and maxCodewordWidth, pass in barcode columns for start and stop pattern
  // columns. That way width can be deducted from the pattern column.
  // This approach also allows to detect more details about the barcode, e.g. if a bar type (white or black) is wider
  // than it should be. This can happen if the scanner used a bad blackpoint.
  static DecoderResult decode(
      BitMatrix image,
      ResultPoint? imageTopLeft,
      ResultPoint? imageBottomLeft,
      ResultPoint? imageTopRight,
      ResultPoint? imageBottomRight,
      int minCodewordWidth,
      int maxCodewordWidth) {
    BoundingBox boundingBox = BoundingBox(
        image, imageTopLeft, imageBottomLeft, imageTopRight, imageBottomRight);
    DetectionResultRowIndicatorColumn? leftRowIndicatorColumn;
    DetectionResultRowIndicatorColumn? rightRowIndicatorColumn;
    DetectionResult? detectionResult;
    for (bool firstPass = true;; firstPass = false) {
      if (imageTopLeft != null) {
        leftRowIndicatorColumn = _getRowIndicatorColumn(image, boundingBox,
            imageTopLeft, true, minCodewordWidth, maxCodewordWidth);
      }
      if (imageTopRight != null) {
        rightRowIndicatorColumn = _getRowIndicatorColumn(image, boundingBox,
            imageTopRight, false, minCodewordWidth, maxCodewordWidth);
      }
      detectionResult = _merge(leftRowIndicatorColumn, rightRowIndicatorColumn);
      if (detectionResult == null) {
        throw NotFoundException.instance;
      }
      BoundingBox? resultBox = detectionResult.boundingBox;
      if (firstPass &&
          resultBox != null &&
          (resultBox.minY < boundingBox.minY ||
              resultBox.maxY > boundingBox.maxY)) {
        boundingBox = resultBox;
      } else {
        break;
      }
    }
    detectionResult.boundingBox = boundingBox;
    int maxBarcodeColumn = detectionResult.barcodeColumnCount + 1;
    detectionResult.setDetectionResultColumn(0, leftRowIndicatorColumn);
    detectionResult.setDetectionResultColumn(
        maxBarcodeColumn, rightRowIndicatorColumn);

    bool leftToRight = leftRowIndicatorColumn != null;
    for (int barcodeColumnCount = 1;
        barcodeColumnCount <= maxBarcodeColumn;
        barcodeColumnCount++) {
      int barcodeColumn = leftToRight
          ? barcodeColumnCount
          : maxBarcodeColumn - barcodeColumnCount;
      if (detectionResult.getDetectionResultColumn(barcodeColumn) != null) {
        // This will be the case for the opposite row indicator column, which doesn't need to be decoded again.
        continue;
      }
      late DetectionResultColumn detectionResultColumn;
      if (barcodeColumn == 0 || barcodeColumn == maxBarcodeColumn) {
        detectionResultColumn = DetectionResultRowIndicatorColumn(
            boundingBox, barcodeColumn == 0);
      } else {
        detectionResultColumn = DetectionResultColumn(boundingBox);
      }
      detectionResult.setDetectionResultColumn(
          barcodeColumn, detectionResultColumn);
      int startColumn = -1;
      int previousStartColumn = startColumn;
      // TODO start at a row for which we know the start position, then detect upwards and downwards from there.
      for (int imageRow = boundingBox.minY;
          imageRow <= boundingBox.maxY;
          imageRow++) {
        startColumn = _getStartColumn(
            detectionResult, barcodeColumn, imageRow, leftToRight);
        if (startColumn < 0 || startColumn > boundingBox.maxX) {
          if (previousStartColumn == -1) {
            continue;
          }
          startColumn = previousStartColumn;
        }
        Codeword? codeword = _detectCodeword(
            image,
            boundingBox.minX,
            boundingBox.maxX,
            leftToRight,
            startColumn,
            imageRow,
            minCodewordWidth,
            maxCodewordWidth);
        if (codeword != null) {
          detectionResultColumn.setCodeword(imageRow, codeword);
          previousStartColumn = startColumn;
          minCodewordWidth = Math.min(minCodewordWidth, codeword.width);
          maxCodewordWidth = Math.max(maxCodewordWidth, codeword.width);
        }
      }
    }
    return _createDecoderResult(detectionResult);
  }

  static DetectionResult? _merge(
      DetectionResultRowIndicatorColumn? leftRowIndicatorColumn,
      DetectionResultRowIndicatorColumn? rightRowIndicatorColumn) {
    if (leftRowIndicatorColumn == null && rightRowIndicatorColumn == null) {
      return null;
    }
    BarcodeMetadata? barcodeMetadata =
        _getBarcodeMetadata(leftRowIndicatorColumn, rightRowIndicatorColumn);
    if (barcodeMetadata == null) {
      return null;
    }
    BoundingBox? boundingBox = BoundingBox.merge(
        _adjustBoundingBox(leftRowIndicatorColumn),
        _adjustBoundingBox(rightRowIndicatorColumn));
    return DetectionResult(barcodeMetadata, boundingBox);
  }

  static BoundingBox? _adjustBoundingBox(
      DetectionResultRowIndicatorColumn? rowIndicatorColumn) {
    if (rowIndicatorColumn == null) {
      return null;
    }
    List<int>? rowHeights = rowIndicatorColumn.getRowHeights();
    if (rowHeights == null) {
      return null;
    }
    int maxRowHeight = _getMax(rowHeights);
    int missingStartRows = 0;
    for (int rowHeight in rowHeights) {
      missingStartRows += maxRowHeight - rowHeight;
      if (rowHeight > 0) {
        break;
      }
    }
    List<Codeword?> codewords = rowIndicatorColumn.codewords;
    for (int row = 0; missingStartRows > 0 && codewords[row] == null; row++) {
      missingStartRows--;
    }
    int missingEndRows = 0;
    for (int row = rowHeights.length - 1; row >= 0; row--) {
      missingEndRows += maxRowHeight - rowHeights[row];
      if (rowHeights[row] > 0) {
        break;
      }
    }
    for (int row = codewords.length - 1;
        missingEndRows > 0 && codewords[row] == null;
        row--) {
      missingEndRows--;
    }
    return rowIndicatorColumn.boundingBox.addMissingRows(
        missingStartRows, missingEndRows, rowIndicatorColumn.isLeft);
  }

  static int _getMax(List<int> values) {
    int maxValue = -1;
    for (int value in values) {
      maxValue = Math.max(maxValue, value);
    }
    return maxValue;
  }

  static BarcodeMetadata? _getBarcodeMetadata(
      DetectionResultRowIndicatorColumn? leftRowIndicatorColumn,
      DetectionResultRowIndicatorColumn? rightRowIndicatorColumn) {
    BarcodeMetadata? leftBarcodeMetadata;
    if ((leftBarcodeMetadata = leftRowIndicatorColumn?.getBarcodeMetadata()) ==
            null) {
      return rightRowIndicatorColumn?.getBarcodeMetadata();
    }
    BarcodeMetadata? rightBarcodeMetadata;
    if ((rightBarcodeMetadata = rightRowIndicatorColumn?.getBarcodeMetadata()) ==
            null) {
      return leftBarcodeMetadata;
    }

    if (leftBarcodeMetadata!.columnCount !=
            rightBarcodeMetadata!.columnCount &&
        leftBarcodeMetadata.errorCorrectionLevel !=
            rightBarcodeMetadata.errorCorrectionLevel &&
        leftBarcodeMetadata.rowCount !=
            rightBarcodeMetadata.rowCount) {
      return null;
    }
    return leftBarcodeMetadata;
  }

  static DetectionResultRowIndicatorColumn _getRowIndicatorColumn(
      BitMatrix image,
      BoundingBox boundingBox,
      ResultPoint startPoint,
      bool leftToRight,
      int minCodewordWidth,
      int maxCodewordWidth) {
    DetectionResultRowIndicatorColumn rowIndicatorColumn =
        DetectionResultRowIndicatorColumn(boundingBox, leftToRight);
    for (int i = 0; i < 2; i++) {
      int increment = i == 0 ? 1 : -1;
      int startColumn = startPoint.x.toInt();
      for (int imageRow = startPoint.y.toInt();
          imageRow <= boundingBox.maxY &&
              imageRow >= boundingBox.minY;
          imageRow += increment) {
        Codeword? codeword = _detectCodeword(
            image,
            0,
            image.width,
            leftToRight,
            startColumn,
            imageRow,
            minCodewordWidth,
            maxCodewordWidth);
        if (codeword != null) {
          rowIndicatorColumn.setCodeword(imageRow, codeword);
          if (leftToRight) {
            startColumn = codeword.startX;
          } else {
            startColumn = codeword.endX;
          }
        }
      }
    }
    return rowIndicatorColumn;
  }

  static void _adjustCodewordCount(
      DetectionResult detectionResult, List<List<BarcodeValue>> barcodeMatrix) {
    BarcodeValue barcodeMatrix01 = barcodeMatrix[0][1];
    List<int> numberOfCodewords = barcodeMatrix01.getValue();
    int calculatedNumberOfCodewords = detectionResult.barcodeColumnCount *
            detectionResult.barcodeRowCount -
        _getNumberOfECCodeWords(detectionResult.barcodeECLevel);
    if (numberOfCodewords.length == 0) {
      if (calculatedNumberOfCodewords < 1 ||
          calculatedNumberOfCodewords > PDF417Common.MAX_CODEWORDS_IN_BARCODE) {
        throw NotFoundException.instance;
      }
      barcodeMatrix01.setValue(calculatedNumberOfCodewords);
    } else if (numberOfCodewords[0] != calculatedNumberOfCodewords) {
      if (calculatedNumberOfCodewords >= 1 &&
          calculatedNumberOfCodewords <=
              PDF417Common.MAX_CODEWORDS_IN_BARCODE) {
        // The calculated one is more reliable as it is derived from the row indicator columns
        barcodeMatrix01.setValue(calculatedNumberOfCodewords);
      }
    }
  }

  static DecoderResult _createDecoderResult(DetectionResult detectionResult) {
    List<List<BarcodeValue>> barcodeMatrix =
        _createBarcodeMatrix(detectionResult);
    _adjustCodewordCount(detectionResult, barcodeMatrix);
    List<int> erasures = [];
    List<int> codewords = List.filled(
        detectionResult.barcodeRowCount *
            detectionResult.barcodeColumnCount,
        0);
    List<List<int>> ambiguousIndexValues = [];
    List<int> ambiguousIndexesList = [];
    for (int row = 0; row < detectionResult.barcodeRowCount; row++) {
      for (int column = 0;
          column < detectionResult.barcodeColumnCount;
          column++) {
        List<int> values = barcodeMatrix[row][column + 1].getValue();
        int codewordIndex =
            row * detectionResult.barcodeColumnCount + column;
        if (values.length == 0) {
          erasures.add(codewordIndex);
        } else if (values.length == 1) {
          codewords[codewordIndex] = values[0];
        } else {
          ambiguousIndexesList.add(codewordIndex);
          ambiguousIndexValues.add(values);
        }
      }
    }
    //List<List<int>> ambiguousIndexValues =
    //    List.generate(ambiguousIndexValuesList.length, (index) => []);
    //for (int i = 0; i < ambiguousIndexValues.length; i++) {
    //  ambiguousIndexValues[i] = ambiguousIndexValuesList[i];
    //}
    return _createDecoderResultFromAmbiguousValues(
        detectionResult.barcodeECLevel,
        codewords,
        erasures,
        ambiguousIndexesList,
        ambiguousIndexValues);
  }

  /// This method deals with the fact, that the decoding process doesn't always yield a single most likely value. The
  /// current error correction implementation doesn't deal with erasures very well, so it's better to provide a value
  /// for these ambiguous codewords instead of treating it as an erasure. The problem is that we don't know which of
  /// the ambiguous values to choose. We try decode using the first value, and if that fails, we use another of the
  /// ambiguous values and try to decode again. This usually only happens on very hard to read and decode barcodes,
  /// so decoding the normal barcodes is not affected by this.
  ///
  /// @param erasureArray contains the indexes of erasures
  /// @param ambiguousIndexes array with the indexes that have more than one most likely value
  /// @param ambiguousIndexValues two dimensional array that contains the ambiguous values. The first dimension must
  /// be the same length as the ambiguousIndexes array
  static DecoderResult _createDecoderResultFromAmbiguousValues(
      int ecLevel,
      List<int> codewords,
      List<int> erasureArray,
      List<int> ambiguousIndexes,
      List<List<int>> ambiguousIndexValues) {
    List<int> ambiguousIndexCount = List.filled(ambiguousIndexes.length, 0);

    int tries = 100;
    while (tries-- > 0) {
      for (int i = 0; i < ambiguousIndexCount.length; i++) {
        codewords[ambiguousIndexes[i]] =
            ambiguousIndexValues[i][ambiguousIndexCount[i]];
      }
      try {
        return _decodeCodewords(codewords, ecLevel, erasureArray);
      } on ChecksumException catch (_) {
        //
      }
      if (ambiguousIndexCount.length == 0) {
        throw ChecksumException.getChecksumInstance();
      }
      for (int i = 0; i < ambiguousIndexCount.length; i++) {
        if (ambiguousIndexCount[i] < ambiguousIndexValues[i].length - 1) {
          ambiguousIndexCount[i]++;
          break;
        } else {
          ambiguousIndexCount[i] = 0;
          if (i == ambiguousIndexCount.length - 1) {
            throw ChecksumException.getChecksumInstance();
          }
        }
      }
    }
    throw ChecksumException.getChecksumInstance();
  }

  static List<List<BarcodeValue>> _createBarcodeMatrix(
      DetectionResult detectionResult) {
    List<List<BarcodeValue>> barcodeMatrix = List.generate(
        detectionResult.barcodeRowCount,
        (index) => List.generate(detectionResult.barcodeColumnCount + 2,
            (index) => BarcodeValue()));

    int column = 0;
    for (DetectionResultColumn? detectionResultColumn
        in detectionResult.getDetectionResultColumns()) {
      if (detectionResultColumn != null) {
        for (Codeword? codeword in detectionResultColumn.codewords) {
          if (codeword != null) {
            int rowNumber = codeword.rowNumber;
            if (rowNumber >= 0) {
              if (rowNumber >= barcodeMatrix.length) {
                // We have more rows than the barcode metadata allows for, ignore them.
                continue;
              }
              barcodeMatrix[rowNumber][column].setValue(codeword.value);
            }
          }
        }
      }
      column++;
    }
    return barcodeMatrix;
  }

  static bool _isValidBarcodeColumn(
      DetectionResult detectionResult, int barcodeColumn) {
    return barcodeColumn >= 0 &&
        barcodeColumn <= detectionResult.barcodeColumnCount + 1;
  }

  static int _getStartColumn(DetectionResult detectionResult, int barcodeColumn,
      int imageRow, bool leftToRight) {
    int offset = leftToRight ? 1 : -1;
    Codeword? codeword;
    if (_isValidBarcodeColumn(detectionResult, barcodeColumn - offset)) {
      codeword = detectionResult
          .getDetectionResultColumn(barcodeColumn - offset)!
          .getCodeword(imageRow);
    }
    if (codeword != null) {
      return leftToRight ? codeword.endX : codeword.startX;
    }
    codeword = detectionResult
        .getDetectionResultColumn(barcodeColumn)!
        .getCodewordNearby(imageRow);
    if (codeword != null) {
      return leftToRight ? codeword.startX : codeword.endX;
    }
    if (_isValidBarcodeColumn(detectionResult, barcodeColumn - offset)) {
      codeword = detectionResult
          .getDetectionResultColumn(barcodeColumn - offset)!
          .getCodewordNearby(imageRow);
    }
    if (codeword != null) {
      return leftToRight ? codeword.endX : codeword.startX;
    }
    int skippedColumns = 0;

    while (_isValidBarcodeColumn(detectionResult, barcodeColumn - offset)) {
      barcodeColumn -= offset;
      for (Codeword? previousRowCodeword in detectionResult
          .getDetectionResultColumn(barcodeColumn)!
          .codewords) {
        if (previousRowCodeword != null) {
          return (leftToRight
                  ? previousRowCodeword.endX
                  : previousRowCodeword.startX) +
              offset *
                  skippedColumns *
                  (previousRowCodeword.endX -
                      previousRowCodeword.startX);
        }
      }
      skippedColumns++;
    }
    return leftToRight
        ? detectionResult.boundingBox!.minX
        : detectionResult.boundingBox!.maxX;
  }

  static Codeword? _detectCodeword(
      BitMatrix image,
      int minColumn,
      int maxColumn,
      bool leftToRight,
      int startColumn,
      int imageRow,
      int minCodewordWidth,
      int maxCodewordWidth) {
    startColumn = _adjustCodewordStartColumn(
        image, minColumn, maxColumn, leftToRight, startColumn, imageRow);
    // we usually know fairly exact now how long a codeword is. We should provide minimum and maximum expected length
    // and try to adjust the read pixels, e.g. remove single pixel errors or try to cut off exceeding pixels.
    // min and maxCodewordWidth should not be used as they are calculated for the whole barcode an can be inaccurate
    // for the current position
    List<int>? moduleBitCount = _getModuleBitCount(
        image, minColumn, maxColumn, leftToRight, startColumn, imageRow);
    if (moduleBitCount == null) {
      return null;
    }
    int endColumn;
    int codewordBitCount = MathUtils.sum(moduleBitCount);
    if (leftToRight) {
      endColumn = startColumn + codewordBitCount;
    } else {
      for (int i = 0; i < moduleBitCount.length / 2; i++) {
        int tmpCount = moduleBitCount[i];
        moduleBitCount[i] = moduleBitCount[moduleBitCount.length - 1 - i];
        moduleBitCount[moduleBitCount.length - 1 - i] = tmpCount;
      }
      endColumn = startColumn;
      startColumn = endColumn - codewordBitCount;
    }
    // TODO implement check for width and correction of black and white bars
    // use start (and maybe stop pattern) to determine if black bars are wider than white bars. If so, adjust.
    // should probably done only for codewords with a lot more than 17 bits.
    // The following fixes 10-1.png, which has wide black bars and small white bars
    //    for (int i = 0; i < moduleBitCount.length; i++) {
    //      if (i % 2 == 0) {
    //        moduleBitCount[i]--;
    //      } else {
    //        moduleBitCount[i]++;
    //      }
    //    }

    // We could also use the width of surrounding codewords for more accurate results, but this seems
    // sufficient for now
    if (!_checkCodewordSkew(
        codewordBitCount, minCodewordWidth, maxCodewordWidth)) {
      // We could try to use the startX and endX position of the codeword in the same column in the previous row,
      // create the bit count from it and normalize it to 8. This would help with single pixel errors.
      return null;
    }

    int decodedValue = PDF417CodewordDecoder.getDecodedValue(moduleBitCount);
    int codeword = PDF417Common.getCodeword(decodedValue);
    if (codeword == -1) {
      return null;
    }
    return Codeword(startColumn, endColumn,
        _getCodewordBucketNumber(decodedValue), codeword);
  }

  static List<int>? _getModuleBitCount(BitMatrix image, int minColumn,
      int maxColumn, bool leftToRight, int startColumn, int imageRow) {
    int imageColumn = startColumn;
    List<int> moduleBitCount = List.filled(8, 0);
    int moduleNumber = 0;
    int increment = leftToRight ? 1 : -1;
    bool previousPixelValue = leftToRight;
    while ((leftToRight ? imageColumn < maxColumn : imageColumn >= minColumn) &&
        moduleNumber < moduleBitCount.length) {
      if (image.get(imageColumn, imageRow) == previousPixelValue) {
        moduleBitCount[moduleNumber]++;
        imageColumn += increment;
      } else {
        moduleNumber++;
        previousPixelValue = !previousPixelValue;
      }
    }
    if (moduleNumber == moduleBitCount.length ||
        ((imageColumn == (leftToRight ? maxColumn : minColumn)) &&
            moduleNumber == moduleBitCount.length - 1)) {
      return moduleBitCount;
    }
    return null;
  }

  static int _getNumberOfECCodeWords(int barcodeECLevel) {
    return 2 << barcodeECLevel;
  }

  static int _adjustCodewordStartColumn(BitMatrix image, int minColumn,
      int maxColumn, bool leftToRight, int codewordStartColumn, int imageRow) {
    int correctedStartColumn = codewordStartColumn;
    int increment = leftToRight ? -1 : 1;
    // there should be no black pixels before the start column. If there are, then we need to start earlier.
    for (int i = 0; i < 2; i++) {
      while ((leftToRight
              ? correctedStartColumn >= minColumn
              : correctedStartColumn < maxColumn) &&
          leftToRight == image.get(correctedStartColumn, imageRow)) {
        if ((codewordStartColumn - correctedStartColumn).abs() >
            _CODEWORD_SKEW_SIZE) {
          return codewordStartColumn;
        }
        correctedStartColumn += increment;
      }
      increment = -increment;
      leftToRight = !leftToRight;
    }
    return correctedStartColumn;
  }

  static bool _checkCodewordSkew(
      int codewordSize, int minCodewordWidth, int maxCodewordWidth) {
    return minCodewordWidth - _CODEWORD_SKEW_SIZE <= codewordSize &&
        codewordSize <= maxCodewordWidth + _CODEWORD_SKEW_SIZE;
  }

  static DecoderResult _decodeCodewords(
      List<int> codewords, int ecLevel, List<int> erasures) {
    if (codewords.length == 0) {
      throw FormatsException.instance;
    }

    int numECCodewords = 1 << (ecLevel + 1);
    int correctedErrorsCount =
        _correctErrors(codewords, erasures, numECCodewords);
    _verifyCodewordCount(codewords, numECCodewords);

    // Decode the codewords
    DecoderResult decoderResult =
        DecodedBitStreamParser.decode(codewords, ecLevel.toString());
    decoderResult.errorsCorrected = correctedErrorsCount;
    decoderResult.erasures = erasures.length;
    return decoderResult;
  }

  /// <p>Given data and error-correction codewords received, possibly corrupted by errors, attempts to
  /// correct the errors in-place.</p>
  ///
  /// @param codewords   data and error correction codewords
  /// @param erasures positions of any known erasures
  /// @param numECCodewords number of error correction codewords that are available in codewords
  /// @throws ChecksumException if error correction fails
  static int _correctErrors(
      List<int> codewords, List<int>? erasures, int numECCodewords) {
    if (erasures != null && erasures.length > numECCodewords ~/ 2 + _MAX_ERRORS ||
        numECCodewords < 0 ||
        numECCodewords > _MAX_EC_CODEWORDS) {
      // Too many errors or EC Codewords is corrupted
      throw ChecksumException.getChecksumInstance();
    }
    return errorCorrection.decode(codewords, numECCodewords, erasures);
  }

  /// Verify that all is OK with the codeword array.
  static void _verifyCodewordCount(List<int> codewords, int numECCodewords) {
    if (codewords.length < 4) {
      // Codeword array size should be at least 4 allowing for
      // Count CW, At least one Data CW, Error Correction CW, Error Correction CW
      throw FormatsException.instance;
    }
    // The first codeword, the Symbol Length Descriptor, shall always encode the total number of data
    // codewords in the symbol, including the Symbol Length Descriptor itself, data codewords and pad
    // codewords, but excluding the number of error correction codewords.
    int numberOfCodewords = codewords[0];
    if (numberOfCodewords > codewords.length) {
      throw FormatsException.instance;
    }
    if (numberOfCodewords == 0) {
      // Reset to the length of the array - 8 (Allow for at least level 3 Error Correction (8 Error Codewords)
      if (numECCodewords < codewords.length) {
        codewords[0] = codewords.length - numECCodewords;
      } else {
        throw FormatsException.instance;
      }
    }
  }

  static List<int> _getBitCountForCodeword(int codeword) {
    List<int> result = List.filled(8, 0);
    int previousValue = 0;
    int i = result.length - 1;
    while (true) {
      if ((codeword & 0x1) != previousValue) {
        previousValue = codeword & 0x1;
        i--;
        if (i < 0) {
          break;
        }
      }
      result[i]++;
      codeword >>= 1;
    }
    return result;
  }

  static int _getCodewordBucketNumber(int codeword) {
    return _getCodewordBucketNumberList(_getBitCountForCodeword(codeword));
  }

  static int _getCodewordBucketNumberList(List<int> moduleBitCount) {
    return (moduleBitCount[0] -
            moduleBitCount[2] +
            moduleBitCount[4] -
            moduleBitCount[6] +
            9) %
        9;
  }

  static String barcodeToString(List<List<BarcodeValue>> barcodeMatrix) {
    StringBuffer formatter = StringBuffer();
    for (int row = 0; row < barcodeMatrix.length; row++) {
      formatter.write(
        "Row $row: ",
      );
      for (int column = 0; column < barcodeMatrix[row].length; column++) {
        BarcodeValue barcodeValue = barcodeMatrix[row][column];
        if (barcodeValue.getValue().length == 0) {
          formatter.write("        ");
        } else {
          formatter.write(
              "${barcodeValue.getValue()[0]}(${barcodeValue.getConfidence(barcodeValue.getValue()[0])})");
        }
      }
      formatter.write("\n");
    }
    return formatter.toString();
  }
}
