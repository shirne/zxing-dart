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

import 'dart:typed_data';

import 'luminance_source.dart';

/**
 * A wrapper implementation of {@link LuminanceSource} which inverts the luminances it returns -- black becomes
 * white and vice versa, and each value becomes (255-value).
 *
 * @author Sean Owen
 */
class InvertedLuminanceSource extends LuminanceSource {
  final LuminanceSource _delegate;

  InvertedLuminanceSource(this._delegate)
      : super(_delegate.getWidth(), _delegate.getHeight());

  @override
  Uint8List getRow(int y, Uint8List? row) {
    row = _delegate.getRow(y, row);
    int width = getWidth();
    for (int i = 0; i < width; i++) {
      row[i] = (255 - (row[i] & 0xFF));
    }
    return row;
  }

  @override
  Uint8List getMatrix() {
    Uint8List matrix = _delegate.getMatrix();
    int length = getWidth() * getHeight();
    Uint8List invertedMatrix = Uint8List(length);
    for (int i = 0; i < length; i++) {
      invertedMatrix[i] = (255 - (matrix[i] & 0xFF));
    }
    return invertedMatrix;
  }

  @override
  bool isCropSupported() {
    return _delegate.isCropSupported();
  }

  @override
  LuminanceSource crop(int left, int top, int width, int height) {
    return InvertedLuminanceSource(_delegate.crop(left, top, width, height));
  }

  @override
  bool isRotateSupported() {
    return _delegate.isRotateSupported();
  }

  /**
   * @return original delegate {@link LuminanceSource} since invert undoes itself
   */
  @override
  LuminanceSource invert() {
    return _delegate;
  }

  @override
  LuminanceSource rotateCounterClockwise() {
    return InvertedLuminanceSource(_delegate.rotateCounterClockwise());
  }

  @override
  LuminanceSource rotateCounterClockwise45() {
    return InvertedLuminanceSource(_delegate.rotateCounterClockwise45());
  }
}
