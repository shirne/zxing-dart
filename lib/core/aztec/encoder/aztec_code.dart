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

import '../../common/bit_matrix.dart';

/// Aztec 2D code representation
///
/// @author Rustam Abdullaev
class AztecCode {
  bool _compact = false;
  int _size = 0;
  int _layers = 0;
  int _codeWords = 0;
  BitMatrix? _matrix;

  /// @return {@code true} if compact instead of full mode
  bool isCompact() {
    return _compact;
  }

  void setCompact(bool compact) {
    this._compact = compact;
  }

  /// @return size in pixels (width and height)
  int getSize() {
    return _size;
  }

  void setSize(int size) {
    this._size = size;
  }

  /// @return number of levels
  int getLayers() {
    return _layers;
  }

  void setLayers(int layers) {
    this._layers = layers;
  }

  /// @return number of data codewords
  int getCodeWords() {
    return _codeWords;
  }

  void setCodeWords(int codeWords) {
    this._codeWords = codeWords;
  }

  /// @return the symbol image
  BitMatrix? getMatrix() {
    return _matrix;
  }

  void setMatrix(BitMatrix matrix) {
    this._matrix = matrix;
  }
}
