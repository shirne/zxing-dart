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

import 'dart:math' as math;

import '../pdf417_common.dart';
import 'barcode_metadata.dart';
import 'barcode_value.dart';
import 'bounding_box.dart';
import 'codeword.dart';
import 'detection_result_column.dart';

/// @author Guenther Grau
class DetectionResultRowIndicatorColumn extends DetectionResultColumn {
  final bool isLeft;

  DetectionResultRowIndicatorColumn(BoundingBox boundingBox, this.isLeft)
      : super(boundingBox);

  void _setRowNumbers() {
    for (Codeword? codeword in codewords) {
      if (codeword != null) {
        codeword.setRowNumberAsRowIndicatorColumn();
      }
    }
  }

  // TODO implement properly
  // TODO maybe we should add missing codewords to store the correct row number to make
  // finding row numbers for other columns easier
  // use row height count to make detection of invalid row numbers more reliable
  void adjustCompleteIndicatorColumnRowNumbers(
    BarcodeMetadata barcodeMetadata,
  ) {
    _setRowNumbers();
    _removeIncorrectCodewords(codewords, barcodeMetadata);
    final top = isLeft ? boundingBox.topLeft : boundingBox.topRight;
    final bottom = isLeft ? boundingBox.bottomLeft : boundingBox.bottomRight;
    final firstRow = imageRowToCodewordIndex(top.y.toInt());
    final lastRow = imageRowToCodewordIndex(bottom.y.toInt());
    // We need to be careful using the average row height. Barcode could be skewed so that we have smaller and
    // taller rows
    //double averageRowHeight = (lastRow - firstRow) / (double) barcodeMetadata.getRowCount();
    int barcodeRow = -1;
    int maxRowHeight = 1;
    int currentRowHeight = 0;
    for (int codewordsRow = firstRow; codewordsRow < lastRow; codewordsRow++) {
      if (codewords[codewordsRow] == null) {
        continue;
      }
      final codeword = codewords[codewordsRow]!;

      final rowDifference = codeword.rowNumber - barcodeRow;

      // TODO improve handling with case where first row indicator doesn't start with 0

      if (rowDifference == 0) {
        currentRowHeight++;
      } else if (rowDifference == 1) {
        maxRowHeight = math.max(maxRowHeight, currentRowHeight);
        currentRowHeight = 1;
        barcodeRow = codeword.rowNumber;
      } else if (rowDifference < 0 ||
          codeword.rowNumber >= barcodeMetadata.rowCount ||
          rowDifference > codewordsRow) {
        codewords[codewordsRow] = null;
      } else {
        int checkedRows;
        if (maxRowHeight > 2) {
          checkedRows = (maxRowHeight - 2) * rowDifference;
        } else {
          checkedRows = rowDifference;
        }
        bool closePreviousCodewordFound = checkedRows >= codewordsRow;
        for (int i = 1; i <= checkedRows && !closePreviousCodewordFound; i++) {
          // there must be (height * rowDifference) number of codewords missing. For now we assume height = 1.
          // This should hopefully get rid of most problems already.
          closePreviousCodewordFound = codewords[codewordsRow - i] != null;
        }
        if (closePreviousCodewordFound) {
          codewords[codewordsRow] = null;
        } else {
          barcodeRow = codeword.rowNumber;
          currentRowHeight = 1;
        }
      }
    }
    //return (int) (averageRowHeight + 0.5);
  }

  List<int>? getRowHeights() {
    final barcodeMetadata = getBarcodeMetadata();
    if (barcodeMetadata == null) {
      return null;
    }
    _adjustIncompleteIndicatorColumnRowNumbers(barcodeMetadata);
    final result = List.filled(barcodeMetadata.rowCount, 0);
    for (Codeword? codeword in codewords) {
      if (codeword != null) {
        final rowNumber = codeword.rowNumber;
        if (rowNumber >= result.length) {
          // We have more rows than the barcode metadata allows for, ignore them.
          continue;
        }
        result[rowNumber]++;
      } // else throw exception?
    }
    return result;
  }

  // TODO maybe we should add missing codewords to store the correct row number to make
  // finding row numbers for other columns easier
  // use row height count to make detection of invalid row numbers more reliable
  void _adjustIncompleteIndicatorColumnRowNumbers(
    BarcodeMetadata barcodeMetadata,
  ) {
    final top = isLeft ? boundingBox.topLeft : boundingBox.topRight;
    final bottom = isLeft ? boundingBox.bottomLeft : boundingBox.bottomRight;
    final firstRow = imageRowToCodewordIndex(top.y.toInt());
    final lastRow = imageRowToCodewordIndex(bottom.y.toInt());

    int barcodeRow = -1;
    int maxRowHeight = 1;
    int currentRowHeight = 0;
    for (int codewordsRow = firstRow; codewordsRow < lastRow; codewordsRow++) {
      if (codewords[codewordsRow] == null) {
        continue;
      }
      final codeword = codewords[codewordsRow]!;

      codeword.setRowNumberAsRowIndicatorColumn();

      final rowDifference = codeword.rowNumber - barcodeRow;

      // TODO improve handling with case where first row indicator doesn't start with 0

      if (rowDifference == 0) {
        currentRowHeight++;
      } else if (rowDifference == 1) {
        maxRowHeight = math.max(maxRowHeight, currentRowHeight);
        currentRowHeight = 1;
        barcodeRow = codeword.rowNumber;
      } else if (codeword.rowNumber >= barcodeMetadata.rowCount) {
        codewords[codewordsRow] = null;
      } else {
        barcodeRow = codeword.rowNumber;
        currentRowHeight = 1;
      }
    }
    //return (int) (averageRowHeight + 0.5);
  }

  BarcodeMetadata? getBarcodeMetadata() {
    final codewords = this.codewords;
    final barcodeColumnCount = BarcodeValue();
    final barcodeRowCountUpperPart = BarcodeValue();
    final barcodeRowCountLowerPart = BarcodeValue();
    final barcodeECLevel = BarcodeValue();
    for (Codeword? codeword in codewords) {
      if (codeword == null) {
        continue;
      }
      codeword.setRowNumberAsRowIndicatorColumn();
      final rowIndicatorValue = codeword.value % 30;
      int codewordRowNumber = codeword.rowNumber;
      if (!isLeft) {
        codewordRowNumber += 2;
      }
      switch (codewordRowNumber % 3) {
        case 0:
          barcodeRowCountUpperPart.setValue(rowIndicatorValue * 3 + 1);
          break;
        case 1:
          barcodeECLevel.setValue(rowIndicatorValue ~/ 3);
          barcodeRowCountLowerPart.setValue(rowIndicatorValue % 3);
          break;
        case 2:
          barcodeColumnCount.setValue(rowIndicatorValue + 1);
          break;
      }
    }
    // Maybe we should check if we have ambiguous values?
    if ((barcodeColumnCount.getValue().isEmpty) ||
        (barcodeRowCountUpperPart.getValue().isEmpty) ||
        (barcodeRowCountLowerPart.getValue().isEmpty) ||
        (barcodeECLevel.getValue().isEmpty) ||
        barcodeColumnCount.getValue()[0] < 1 ||
        barcodeRowCountUpperPart.getValue()[0] +
                barcodeRowCountLowerPart.getValue()[0] <
            PDF417Common.minRowsInBarcode ||
        barcodeRowCountUpperPart.getValue()[0] +
                barcodeRowCountLowerPart.getValue()[0] >
            PDF417Common.maxRowsInBarcode) {
      return null;
    }
    final barcodeMetadata = BarcodeMetadata(
      barcodeColumnCount.getValue()[0],
      barcodeRowCountUpperPart.getValue()[0],
      barcodeRowCountLowerPart.getValue()[0],
      barcodeECLevel.getValue()[0],
    );
    _removeIncorrectCodewords(codewords, barcodeMetadata);
    return barcodeMetadata;
  }

  /// todo test error
  void _removeIncorrectCodewords(
    List<Codeword?> codewords,
    BarcodeMetadata barcodeMetadata,
  ) {
    // Remove codewords which do not match the metadata
    // TODO Maybe we should keep the incorrect codewords for the start and end positions?
    for (int codewordRow = 0; codewordRow < codewords.length; codewordRow++) {
      final codeword = codewords[codewordRow];
      if (codewords[codewordRow] == null) {
        continue;
      }
      final rowIndicatorValue = codeword!.value % 30;
      int codewordRowNumber = codeword.rowNumber;
      if (codewordRowNumber > barcodeMetadata.rowCount) {
        codewords[codewordRow] = null;
        continue;
      }
      if (!isLeft) {
        codewordRowNumber += 2;
      }
      switch (codewordRowNumber % 3) {
        case 0:
          if (rowIndicatorValue * 3 + 1 != barcodeMetadata.rowCountUpperPart) {
            codewords[codewordRow] = null;
          }
          break;
        case 1:
          if (rowIndicatorValue ~/ 3 != barcodeMetadata.errorCorrectionLevel ||
              rowIndicatorValue % 3 != barcodeMetadata.rowCountLowerPart) {
            codewords[codewordRow] = null;
          }
          break;
        case 2:
          if (rowIndicatorValue + 1 != barcodeMetadata.columnCount) {
            codewords[codewordRow] = null;
          }
          break;
      }
    }
  }

  @override
  String toString() => 'IsLeft: $isLeft\n${super.toString()}';
}
