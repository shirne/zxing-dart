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

/// @author Guenther Grau
class BarcodeMetadata {
  final int _columnCount;
  final int _errorCorrectionLevel;
  final int _rowCountUpperPart;
  final int _rowCountLowerPart;
  final int _rowCount;

  BarcodeMetadata(
    this._columnCount,
    this._rowCountUpperPart,
    this._rowCountLowerPart,
    this._errorCorrectionLevel,
  ) : _rowCount = _rowCountUpperPart + _rowCountLowerPart;

  int get columnCount => _columnCount;

  int get errorCorrectionLevel => _errorCorrectionLevel;

  int get rowCount => _rowCount;

  int get rowCountUpperPart => _rowCountUpperPart;

  int get rowCountLowerPart => _rowCountLowerPart;
}
