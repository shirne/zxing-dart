/*
 * Copyright 2011 ZXing authors
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

import 'dart:typed_data';

import 'barcode_row.dart';

/**
 * Holds all of the information for a barcode in a format where it can be easily accessible
 *
 * @author Jacob Haynes
 */
class BarcodeMatrix {
  final List<BarcodeRow> _matrix;
  int _currentRow = -1;
  final int _height;
  final int _width;

  /**
   * @param height the height of the matrix (Rows)
   * @param width  the width of the matrix (Cols)
   */
  BarcodeMatrix(this._height, int width)
      : this._width = width * 17,
        this._matrix =
            List.generate(_height, (index) => BarcodeRow((width + 4) * 17 + 1));

  void set(int x, int y, int value) {
    _matrix[y].set(x, value);
  }

  void startRow() {
    ++_currentRow;
  }

  BarcodeRow getCurrentRow() {
    return _matrix[_currentRow];
  }

  List<Uint8List> getMatrix() {
    return getScaledMatrix(1, 1);
  }

  List<Uint8List> getScaledMatrix(int xScale, int yScale) {
    List<Uint8List> matrixOut =
        List.generate(_height * yScale, (index) => Uint8List(_width * xScale));
    int yMax = _height * yScale;
    for (int i = 0; i < yMax; i++) {
      matrixOut[yMax - i - 1] = _matrix[i ~/ yScale].getScaledRow(xScale);
    }
    return matrixOut;
  }
}
