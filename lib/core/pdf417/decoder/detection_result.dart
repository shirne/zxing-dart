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

/**
 * @author Guenther Grau
 */
class DetectionResult {
  static final int ADJUST_ROW_NUMBER_SKIP = 2;

  final BarcodeMetadata barcodeMetadata;
  final List<DetectionResultColumn?> detectionResultColumns;
  BoundingBox boundingBox;
  final int barcodeColumnCount;

  DetectionResult(this.barcodeMetadata, this.boundingBox)
      : this.barcodeColumnCount = barcodeMetadata.getColumnCount(),
        detectionResultColumns =
            List.filled(barcodeMetadata.getColumnCount() + 2, null);

  List<DetectionResultColumn?> getDetectionResultColumns() {
    adjustIndicatorColumnRowNumbers(detectionResultColumns[0]);
    adjustIndicatorColumnRowNumbers(
        detectionResultColumns[barcodeColumnCount + 1]);
    int unadjustedCodewordCount = PDF417Common.MAX_CODEWORDS_IN_BARCODE;
    int previousUnadjustedCount;
    do {
      previousUnadjustedCount = unadjustedCodewordCount;
      unadjustedCodewordCount = adjustRowNumbers();
    } while (unadjustedCodewordCount > 0 &&
        unadjustedCodewordCount < previousUnadjustedCount);
    return detectionResultColumns;
  }

  void adjustIndicatorColumnRowNumbers(
      DetectionResultColumn? detectionResultColumn) {
    if (detectionResultColumn != null) {
      (detectionResultColumn as DetectionResultRowIndicatorColumn)
          .adjustCompleteIndicatorColumnRowNumbers(barcodeMetadata);
    }
  }

  // TODO ensure that no detected codewords with unknown row number are left
  // we should be able to estimate the row height and use it as a hint for the row number
  // we should also fill the rows top to bottom and bottom to top
  /**
   * @return number of codewords which don't have a valid row number. Note that the count is not accurate as codewords
   * will be counted several times. It just serves as an indicator to see when we can stop adjusting row numbers
   */
  int adjustRowNumbers() {
    int unadjustedCount = adjustRowNumbersByRow();
    if (unadjustedCount == 0) {
      return 0;
    }
    for (int barcodeColumn = 1;
        barcodeColumn < barcodeColumnCount + 1;
        barcodeColumn++) {
      List<Codeword?> codewords =
          detectionResultColumns[barcodeColumn]!.getCodewords();
      for (int codewordsRow = 0;
          codewordsRow < codewords.length;
          codewordsRow++) {
        if (codewords[codewordsRow] == null) {
          continue;
        }
        if (!codewords[codewordsRow]!.hasValidRowNumber()) {
          adjustRowNumbersWords(barcodeColumn, codewordsRow, codewords);
        }
      }
    }
    return unadjustedCount;
  }

  int adjustRowNumbersByRow() {
    adjustRowNumbersFromBothRI();
    // TODO we should only do full row adjustments if row numbers of left and right row indicator column match.
    // Maybe it's even better to calculated the height (in codeword rows) and divide it by the number of barcode
    // rows. This, together with the LRI and RRI row numbers should allow us to get a good estimate where a row
    // number starts and ends.
    int unadjustedCount = adjustRowNumbersFromLRI();
    return unadjustedCount + adjustRowNumbersFromRRI();
  }

  void adjustRowNumbersFromBothRI() {
    if (detectionResultColumns[0] == null ||
        detectionResultColumns[barcodeColumnCount + 1] == null) {
      return;
    }
    List<Codeword?> LRIcodewords = detectionResultColumns[0]!.getCodewords();
    List<Codeword?> RRIcodewords =
        detectionResultColumns[barcodeColumnCount + 1]!.getCodewords();
    for (int codewordsRow = 0;
        codewordsRow < LRIcodewords.length;
        codewordsRow++) {
      if (LRIcodewords[codewordsRow] != null &&
          RRIcodewords[codewordsRow] != null &&
          LRIcodewords[codewordsRow]!.getRowNumber() ==
              RRIcodewords[codewordsRow]!.getRowNumber()) {
        for (int barcodeColumn = 1;
            barcodeColumn <= barcodeColumnCount;
            barcodeColumn++) {
          Codeword? codeword = detectionResultColumns[barcodeColumn]!
              .getCodewords()[codewordsRow];
          if (codeword == null) {
            continue;
          }
          codeword.setRowNumber(LRIcodewords[codewordsRow]!.getRowNumber());
          if (!codeword.hasValidRowNumber()) {
            detectionResultColumns[barcodeColumn]!
                .getCodewords()[codewordsRow] = null;
          }
        }
      }
    }
  }

  int adjustRowNumbersFromRRI() {
    if (detectionResultColumns[barcodeColumnCount + 1] == null) {
      return 0;
    }
    int unadjustedCount = 0;
    List<Codeword?> codewords =
        detectionResultColumns[barcodeColumnCount + 1]!.getCodewords();
    for (int codewordsRow = 0;
        codewordsRow < codewords.length;
        codewordsRow++) {
      if (codewords[codewordsRow] == null) {
        continue;
      }
      int rowIndicatorRowNumber = codewords[codewordsRow]!.getRowNumber();
      int invalidRowCounts = 0;
      for (int barcodeColumn = barcodeColumnCount + 1;
          barcodeColumn > 0 && invalidRowCounts < ADJUST_ROW_NUMBER_SKIP;
          barcodeColumn--) {
        Codeword? codeword =
            detectionResultColumns[barcodeColumn]!.getCodewords()[codewordsRow];
        if (codeword != null) {
          invalidRowCounts = adjustRowNumberIfValid(
              rowIndicatorRowNumber, invalidRowCounts, codeword);
          if (!codeword.hasValidRowNumber()) {
            unadjustedCount++;
          }
        }
      }
    }
    return unadjustedCount;
  }

  int adjustRowNumbersFromLRI() {
    if (detectionResultColumns[0] == null) {
      return 0;
    }
    int unadjustedCount = 0;
    List<Codeword?> codewords = detectionResultColumns[0]!.getCodewords();
    for (int codewordsRow = 0;
        codewordsRow < codewords.length;
        codewordsRow++) {
      if (codewords[codewordsRow] == null) {
        continue;
      }
      int rowIndicatorRowNumber = codewords[codewordsRow]!.getRowNumber();
      int invalidRowCounts = 0;
      for (int barcodeColumn = 1;
          barcodeColumn < barcodeColumnCount + 1 &&
              invalidRowCounts < ADJUST_ROW_NUMBER_SKIP;
          barcodeColumn++) {
        Codeword? codeword =
            detectionResultColumns[barcodeColumn]!.getCodewords()[codewordsRow];
        if (codeword != null) {
          invalidRowCounts = adjustRowNumberIfValid(
              rowIndicatorRowNumber, invalidRowCounts, codeword);
          if (!codeword.hasValidRowNumber()) {
            unadjustedCount++;
          }
        }
      }
    }
    return unadjustedCount;
  }

  static int adjustRowNumberIfValid(
      int rowIndicatorRowNumber, int invalidRowCounts, Codeword codeword) {
    if (codeword == null) {
      return invalidRowCounts;
    }
    if (!codeword.hasValidRowNumber()) {
      if (codeword.isValidRowNumber(rowIndicatorRowNumber)) {
        codeword.setRowNumber(rowIndicatorRowNumber);
        invalidRowCounts = 0;
      } else {
        ++invalidRowCounts;
      }
    }
    return invalidRowCounts;
  }

  void adjustRowNumbersWords(
      int barcodeColumn, int codewordsRow, List<Codeword?> codewords) {
    Codeword? codeword = codewords[codewordsRow];
    List<Codeword?> previousColumnCodewords =
        detectionResultColumns[barcodeColumn - 1]!.getCodewords();
    List<Codeword?> nextColumnCodewords = previousColumnCodewords;
    if (detectionResultColumns[barcodeColumn + 1] != null) {
      nextColumnCodewords =
          detectionResultColumns[barcodeColumn + 1]!.getCodewords();
    }

    List<Codeword?> otherCodewords = List.filled(14, null);

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
      if (adjustRowNumber(codeword, otherCodeword)) {
        return;
      }
    }
  }

  /**
   * @return true, if row number was adjusted, false otherwise
   */
  static bool adjustRowNumber(Codeword? codeword, Codeword? otherCodeword) {
    if (otherCodeword == null) {
      return false;
    }
    if (otherCodeword.hasValidRowNumber() &&
        otherCodeword.getBucket() == codeword!.getBucket()) {
      codeword.setRowNumber(otherCodeword.getRowNumber());
      return true;
    }
    return false;
  }

  int getBarcodeColumnCount() {
    return barcodeColumnCount;
  }

  int getBarcodeRowCount() {
    return barcodeMetadata.getRowCount();
  }

  int getBarcodeECLevel() {
    return barcodeMetadata.getErrorCorrectionLevel();
  }

  void setBoundingBox(BoundingBox boundingBox) {
    this.boundingBox = boundingBox;
  }

  BoundingBox getBoundingBox() {
    return boundingBox;
  }

  void setDetectionResultColumn(
      int barcodeColumn, DetectionResultColumn detectionResultColumn) {
    detectionResultColumns[barcodeColumn] = detectionResultColumn;
  }

  DetectionResultColumn? getDetectionResultColumn(int barcodeColumn) {
    return detectionResultColumns[barcodeColumn];
  }

  @override
  String toString() {
    DetectionResultColumn? rowIndicatorColumn = detectionResultColumns[0];
    if (rowIndicatorColumn == null) {
      rowIndicatorColumn = detectionResultColumns[barcodeColumnCount + 1];
    }
    try {
      StringBuffer formatter = StringBuffer();
      for (int codewordsRow = 0;
          codewordsRow < rowIndicatorColumn!.getCodewords().length;
          codewordsRow++) {
        formatter.write("CW $codewordsRow:");
        for (int barcodeColumn = 0;
            barcodeColumn < barcodeColumnCount + 2;
            barcodeColumn++) {
          if (detectionResultColumns[barcodeColumn] == null) {
            formatter.write("    |   ");
            continue;
          }
          Codeword? codeword = detectionResultColumns[barcodeColumn]!
              .getCodewords()[codewordsRow];
          if (codeword == null) {
            formatter.write("    |   ");
            continue;
          }
          formatter.write(" ${codeword.getRowNumber()}|${codeword.getValue()}");
        }
        formatter.write("\n");
      }
      return formatter.toString();
    } catch (e) {}

    return '';
  }
}
