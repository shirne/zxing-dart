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

import 'dart:typed_data';

import 'luminance_source.dart';

/// This class is used to help decode images from files which arrive as RGB data from
/// an ARGB pixel array. It does not support rotation.
///
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Betaminos
class RGBLuminanceSource extends LuminanceSource {
  final Int8List _luminances;
  final int _dataWidth;
  final int _dataHeight;
  final int _left;
  final int _top;

  static Int8List intList2Int8List(List<int> pixels) {
    int size = pixels.length;
    Int8List luminances = Int8List(size);
    for (int offset = 0; offset < size; offset++) {
      int pixel = pixels[offset];
      int r = (pixel >> 16) & 0xff; // red
      int g2 = (pixel >> 7) & 0x1fe; // 2 * green
      int b = pixel & 0xff; // blue
      // Calculate green-favouring average cheaply
      luminances[offset] = ((r + g2 + b) ~/ 4);
    }
    return luminances;
  }

  RGBLuminanceSource(int width, int height, List<int> pixels):
        this._dataWidth = width,
  this._dataHeight = height,
  _left = 0,
  _top = 0,
        _luminances = intList2Int8List(pixels),
        super(width, height);

  RGBLuminanceSource._(this._luminances, this._dataWidth, this._dataHeight,
      [this._left = 0, this._top = 0, int? width, int? height])
      :
        assert(_left + (width ?? _dataWidth) <= _dataWidth,
            r'Crop rectangle does not fit within image data.'),
        assert(_top + (height ?? _dataHeight) <= _dataHeight,
            r'Crop rectangle does not fit within image data.'),
        super(width ?? _dataWidth, height ?? _dataHeight);

  @override
  Int8List getRow(int y, Int8List? row) {
    assert(y >= 0 && y < getHeight(), "Requested row is outside the image: $y");

    int width = getWidth();
    if (row == null || row.length < width) {
      row = Int8List(width);
    }
    int offset = (y + _top) * _dataWidth + _left;
    List.copyRange(row, 0, _luminances, offset, offset + width);
    return row;
  }

  @override
  Int8List getMatrix() {
    int width = getWidth();
    int height = getHeight();

    // If the caller asks for the entire underlying image, save the copy and give them the
    // original data. The docs specifically warn that result.length must be ignored.
    if (width == _dataWidth && height == _dataHeight) {
      return _luminances;
    }

    int area = width * height;
    Int8List matrix = Int8List(area);
    int inputOffset = _top * _dataWidth + _left;

    // If the width matches the full width of the underlying data, perform a single copy.
    if (width == _dataWidth) {
      List.copyRange(matrix, 0, _luminances, inputOffset, inputOffset + area);
      return matrix;
    }

    // Otherwise copy one cropped row at a time.
    for (int y = 0; y < height; y++) {
      int outputOffset = y * width;
      List.copyRange(matrix, outputOffset, _luminances, inputOffset, inputOffset + width);
      inputOffset += _dataWidth;
    }
    return matrix;
  }

  @override
  bool isCropSupported() {
    return true;
  }

  @override
  LuminanceSource crop(int left, int top, int width, int height) {
    return RGBLuminanceSource._(_luminances, _dataWidth, _dataHeight,
        this._left + left, this._top + top, width, height);
  }
}
