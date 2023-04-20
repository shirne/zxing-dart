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

import '../pdf417_common.dart';
import 'barcode_metadata.dart';
import 'bounding_box.dart';
import 'codeword.dart';
import 'detection_result_column.dart';
import 'detection_result_row_indicator_column.dart';

/// @author Guenther Grau
class DetectionResult {
  static const int _adjustRowNumberSkip = 2;

  final BarcodeMetadata _barcodeMetadata;
  final List<DetectionResultColumn?> _detectionResultColumns;
  BoundingBox? boundingBox;
  final int _barcodeColumnCount;

  DetectionResult(this._barcodeMetadata, this.boundingBox)
      : _barcodeColumnCount = _barcodeMetadata.columnCount,
        _detectionResultColumns =
            List.filled(_barcodeMetadata.columnCount + 2, null);

  List<DetectionResultColumn?> getDetectionResultColumns() {
    _adjustIndicatorColumnRowNumbers(_detectionResultColumns[0]);
    _adjustIndicatorColumnRowNumbers(
      _detectionResultColumns[_barcodeColumnCount + 1],
    );
    int unadjustedCodewordCount = PDF417Common.maxCodewordsInBarcode;
    int previousUnadjustedCount;
    do {
      previousUnadjustedCount = unadjustedCodewordCount;
      unadjustedCodewordCount = _adjustRowNumbers();
    } while (unadjustedCodewordCount > 0 &&
        unadjustedCodewordCount < previousUnadjustedCount);
    return _detectionResultColumns;
  }

  void _adjustIndicatorColumnRowNumbers(
    DetectionResultColumn? detectionResultColumn,
  ) {
    if (detectionResultColumn != null) {
      (detectionResultColumn as DetectionResultRowIndicatorColumn)
          .adjustCompleteIndicatorColumnRowNumbers(_barcodeMetadata);
    }
  }

  // TODO ensure that no detected codewords with unknown row number are left
  // we should be able to estimate the row height and use it as a hint for the row number
  // we should also fill the rows top to bottom and bottom to top
  /// @return number of codewords which don't have a valid row number. Note that the count is not accurate as codewords
  /// will be counted several times. It just serves as an indicator to see when we can stop adjusting row numbers
  int _adjustRowNumbers() {
    final unadjustedCount = _adjustRowNumbersByRow();
    if (unadjustedCount == 0) {
      return 0;
    }
    for (int barcodeColumn = 1;
        barcodeColumn < _barcodeColumnCount + 1;
        barcodeColumn++) {
      final codewords = _detectionResultColumns[barcodeColumn]!.codewords;
      for (int codewordsRow = 0;
          codewordsRow < codewords.length;
          codewordsRow++) {
        if (codewords[codewordsRow] == null) {
          continue;
        }
        if (!codewords[codewordsRow]!.hasValidRowNumber()) {
          _adjustRowNumbersWords(barcodeColumn, codewordsRow, codewords);
        }
      }
    }
    return unadjustedCount;
  }

  int _adjustRowNumbersByRow() {
    _adjustRowNumbersFromBothRI();
    // TODO we should only do full row adjustments if row numbers of left and right row indicator column match.
    // Maybe it's even better to calculated the height (in codeword rows) and divide it by the number of barcode
    // rows. This, together with the LRI and RRI row numbers should allow us to get a good estimate where a row
    // number starts and ends.
    final unadjustedCount = _adjustRowNumbersFromLRI();
    return unadjustedCount + _adjustRowNumbersFromRRI();
  }

  void _adjustRowNumbersFromBothRI() {
    if (_detectionResultColumns[0] == null ||
        _detectionResultColumns[_barcodeColumnCount + 1] == null) {
      return;
    }
    final lriCodewords = _detectionResultColumns[0]!.codewords;
    final rriCodewords =
        _detectionResultColumns[_barcodeColumnCount + 1]!.codewords;
    for (int codewordsRow = 0;
        codewordsRow < lriCodewords.length;
        codewordsRow++) {
      if (lriCodewords[codewordsRow] != null &&
          rriCodewords[codewordsRow] != null &&
          lriCodewords[codewordsRow]!.rowNumber ==
              rriCodewords[codewordsRow]!.rowNumber) {
        for (int barcodeColumn = 1;
            barcodeColumn <= _barcodeColumnCount;
            barcodeColumn++) {
          final codeword =
              _detectionResultColumns[barcodeColumn]!.codewords[codewordsRow];
          if (codeword == null) {
            continue;
          }
          codeword.rowNumber = lriCodewords[codewordsRow]!.rowNumber;
          if (!codeword.hasValidRowNumber()) {
            _detectionResultColumns[barcodeColumn]!.codewords[codewordsRow] =
                null;
          }
        }
      }
    }
  }

  int _adjustRowNumbersFromRRI() {
    if (_detectionResultColumns[_barcodeColumnCount + 1] == null) {
      return 0;
    }
    int unadjustedCount = 0;
    final codewords =
        _detectionResultColumns[_barcodeColumnCount + 1]!.codewords;
    for (int codewordsRow = 0;
        codewordsRow < codewords.length;
        codewordsRow++) {
      if (codewords[codewordsRow] == null) {
        continue;
      }
      final rowIndicatorRowNumber = codewords[codewordsRow]!.rowNumber;
      int invalidRowCounts = 0;
      for (int barcodeColumn = _barcodeColumnCount + 1;
          barcodeColumn > 0 && invalidRowCounts < _adjustRowNumberSkip;
          barcodeColumn--) {
        final codeword =
            _detectionResultColumns[barcodeColumn]!.codewords[codewordsRow];
        if (codeword != null) {
          invalidRowCounts = _adjustRowNumberIfValid(
            rowIndicatorRowNumber,
            invalidRowCounts,
            codeword,
          );
          if (!codeword.hasValidRowNumber()) {
            unadjustedCount++;
          }
        }
      }
    }
    return unadjustedCount;
  }

  int _adjustRowNumbersFromLRI() {
    if (_detectionResultColumns[0] == null) {
      return 0;
    }
    int unadjustedCount = 0;
    final codewords = _detectionResultColumns[0]!.codewords;
    for (int codewordsRow = 0;
        codewordsRow < codewords.length;
        codewordsRow++) {
      if (codewords[codewordsRow] == null) {
        continue;
      }
      final rowIndicatorRowNumber = codewords[codewordsRow]!.rowNumber;
      int invalidRowCounts = 0;
      for (int barcodeColumn = 1;
          barcodeColumn < _barcodeColumnCount + 1 &&
              invalidRowCounts < _adjustRowNumberSkip;
          barcodeColumn++) {
        final codeword =
            _detectionResultColumns[barcodeColumn]!.codewords[codewordsRow];
        if (codeword != null) {
          invalidRowCounts = _adjustRowNumberIfValid(
            rowIndicatorRowNumber,
            invalidRowCounts,
            codeword,
          );
          if (!codeword.hasValidRowNumber()) {
            unadjustedCount++;
          }
        }
      }
    }
    return unadjustedCount;
  }

  static int _adjustRowNumberIfValid(
    int rowIndicatorRowNumber,
    int invalidRowCounts,
    Codeword? codeword,
  ) {
    if (codeword == null) {
      return invalidRowCounts;
    }
    if (!codeword.hasValidRowNumber()) {
      if (codeword.isValidRowNumber(rowIndicatorRowNumber)) {
        codeword.rowNumber = rowIndicatorRowNumber;
        invalidRowCounts = 0;
      } else {
        ++invalidRowCounts;
      }
    }
    return invalidRowCounts;
  }

  void _adjustRowNumbersWords(
    int barcodeColumn,
    int codewordsRow,
    List<Codeword?> codewords,
  ) {
    final codeword = codewords[codewordsRow];
    final previousColumnCodewords =
        _detectionResultColumns[barcodeColumn - 1]!.codewords;
    List<Codeword?> nextColumnCodewords = previousColumnCodewords;
    if (_detectionResultColumns[barcodeColumn + 1] != null) {
      nextColumnCodewords =
          _detectionResultColumns[barcodeColumn + 1]!.codewords;
    }

    final otherCodewords = List<Codeword?>.filled(14, null);

    otherCodewords[2] = previousColumnCodewords[codewordsRow];
    otherCodewords[3] = nextColumnCodewords[codewordsRow];

    if (codewordsRow > 0) {
      otherCodewords[0] = codewords[codewordsRow - 1];
      otherCodewords[4] = previousColumnCodewords[codewordsRow - 1];
      otherCodewords[5] = nextColumnCodewords[codewordsRow - 1];
    }
    if (codewordsRow > 1) {
      otherCodewords[8] = codewords[codewordsRow - 2];
      otherCodewords[10] = previousColumnCodewords[codewordsRow - 2];
      otherCodewords[11] = nextColumnCodewords[codewordsRow - 2];
    }
    if (codewordsRow < codewords.length - 1) {
      otherCodewords[1] = codewords[codewordsRow + 1];
      otherCodewords[6] = previousColumnCodewords[codewordsRow + 1];
      otherCodewords[7] = nextColumnCodewords[codewordsRow + 1];
    }
    if (codewordsRow < codewords.length - 2) {
      otherCodewords[9] = codewords[codewordsRow + 2];
      otherCodewords[12] = previousColumnCodewords[codewordsRow + 2];
      otherCodewords[13] = nextColumnCodewords[codewordsRow + 2];
    }
    for (Codeword? otherCodeword in otherCodewords) {
      if (_adjustRowNumber(codeword, otherCodeword)) {
        return;
      }
    }
  }

  /// @return true, if row number was adjusted, false otherwise
  static bool _adjustRowNumber(Codeword? codeword, Codeword? otherCodeword) {
    if (otherCodeword == null) {
      return false;
    }
    if (otherCodeword.hasValidRowNumber() &&
        otherCodeword.bucket == codeword!.bucket) {
      codeword.rowNumber = otherCodeword.rowNumber;
      return true;
    }
    return false;
  }

  int get barcodeColumnCount => _barcodeColumnCount;

  int get barcodeRowCount => _barcodeMetadata.rowCount;

  int get barcodeECLevel => _barcodeMetadata.errorCorrectionLevel;

  void setDetectionResultColumn(
    int barcodeColumn,
    DetectionResultColumn? detectionResultColumn,
  ) {
    _detectionResultColumns[barcodeColumn] = detectionResultColumn;
  }

  DetectionResultColumn? getDetectionResultColumn(int barcodeColumn) {
    return _detectionResultColumns[barcodeColumn];
  }

  @override
  String toString() {
    DetectionResultColumn? rowIndicatorColumn = _detectionResultColumns[0];
    rowIndicatorColumn ??= _detectionResultColumns[_barcodeColumnCount + 1];
    final formatter = StringBuffer();
    for (int codewordsRow = 0;
        codewordsRow < rowIndicatorColumn!.codewords.length;
        codewordsRow++) {
      formatter.write('CW ${codewordsRow.toString().padLeft(3)}:');
      for (int barcodeColumn = 0;
          barcodeColumn < _barcodeColumnCount + 2;
          barcodeColumn++) {
        if (_detectionResultColumns[barcodeColumn] == null) {
          formatter.write('    |   ');
          continue;
        }
        final codeword =
            _detectionResultColumns[barcodeColumn]!.codewords[codewordsRow];
        if (codeword == null) {
          formatter.write('    |   ');
          continue;
        }
        formatter.write(
          ' ${codeword.rowNumber.toString().padLeft(3)}|${codeword.value.toString().padLeft(3)}',
        );
      }
      formatter.write('\n');
    }
    return formatter.toString();
  }
}
