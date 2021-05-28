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

/**
 * @author Guenther Grau
 */
class BarcodeMetadata {
  final int columnCount;
  final int errorCorrectionLevel;
  final int rowCountUpperPart;
  final int rowCountLowerPart;
  final int rowCount;

  BarcodeMetadata(this.columnCount, this.rowCountUpperPart,
      this.rowCountLowerPart, this.errorCorrectionLevel)
      : this.rowCount = rowCountUpperPart + rowCountLowerPart;

  int getColumnCount() {
    return columnCount;
  }

  int getErrorCorrectionLevel() {
    return errorCorrectionLevel;
  }

  int getRowCount() {
    return rowCount;
  }

  int getRowCountUpperPart() {
    return rowCountUpperPart;
  }

  int getRowCountLowerPart() {
    return rowCountLowerPart;
  }
}
