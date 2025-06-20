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

/// This object extends LuminanceSource around an array of YUV data returned from the camera driver,
/// with the option to crop to a rectangle within the full data. This can be used to exclude
/// superfluous pixels around the perimeter and speed up decoding.
///
/// It works for any pixel format where the Y channel is planar and appears first, including
/// YCbCr_420_SP and YCbCr_422_SP.
///
/// @author dswitkin@google.com (Daniel Switkin)
class PlanarYUVLuminanceSource extends LuminanceSource {
  static const int _thumbnailScaleFactor = 2;

  final Uint8List _yuvData;
  final int _dataWidth;
  final int _dataHeight;
  final int _left;
  final int _top;

  PlanarYUVLuminanceSource(
    this._yuvData,
    this._dataWidth,
    this._dataHeight, {
    int left = 0,
    int top = 0,
    int? width,
    int? height,
    bool isReverseHorizontal = false,
  })  : _left = left,
        _top = top,
        super(width ?? (_dataWidth - left), height ?? (_dataHeight - top)) {
    width ??= _dataWidth - _left;
    height ??= _dataHeight - _top;
    if (_left + width > _dataWidth || _top + height > _dataHeight) {
      throw ArgumentError('Crop rectangle does not fit within image data.');
    }

    if (isReverseHorizontal) {
      _reverseHorizontal(width, height);
    }
  }

  @override
  Uint8List getRow(int y, Uint8List? row) {
    if (y < 0 || y >= height) {
      throw ArgumentError('Requested row is outside the image: $y');
    }

    if (row == null || row.length < width) {
      row = Uint8List(width);
    }
    final offset = (y + _top) * _dataWidth + _left;
    List.copyRange(row, 0, _yuvData, offset, offset + width);
    return row;
  }

  @override
  Uint8List get matrix {
    // If the caller asks for the entire underlying image, save the copy and give them the
    // original data. The docs specifically warn that result.length must be ignored.
    if (width == _dataWidth && height == _dataHeight) {
      return _yuvData;
    }

    final area = width * height;
    final matrix = Uint8List(area);
    int inputOffset = _top * _dataWidth + _left;

    // If the width matches the full width of the underlying data, perform a single copy.
    if (width == _dataWidth) {
      List.copyRange(matrix, 0, _yuvData, inputOffset, inputOffset + area);
      return matrix;
    }

    // Otherwise copy one cropped row at a time.
    for (int y = 0; y < height; y++) {
      final outputOffset = y * width;
      List.copyRange(
        matrix,
        outputOffset,
        _yuvData,
        inputOffset,
        inputOffset + width,
      );
      inputOffset += _dataWidth;
    }
    return matrix;
  }

  @override
  bool get isCropSupported => true;

  @override
  LuminanceSource crop(int left, int top, int width, int height) {
    return PlanarYUVLuminanceSource(
      _yuvData,
      _dataWidth,
      _dataHeight,
      left: _left + left,
      top: _top + top,
      width: width,
      height: height,
    );
  }

  @override
  LuminanceSource rotateCounterClockwise() {
    final newData = Uint8List(_yuvData.length);
    for (int i = 0; i < _dataWidth; i++) {
      List.copyRange(
        newData,
        i * _dataHeight,
        List.generate(_dataHeight, (j) => _yuvData[j * _dataWidth + i]),
      );
    }

    return PlanarYUVLuminanceSource(
      newData,
      _dataHeight,
      _dataWidth,
    );
  }

  List<int> renderThumbnail() {
    final tWidth = width ~/ _thumbnailScaleFactor;
    final tHeight = height ~/ _thumbnailScaleFactor;
    final pixels = List.filled(tWidth * tHeight, 0);
    final yuv = _yuvData;
    int inputOffset = _top * _dataWidth + _left;

    for (int y = 0; y < tHeight; y++) {
      final outputOffset = y * tWidth;
      for (int x = 0; x < tWidth; x++) {
        final grey = yuv[inputOffset + x * _thumbnailScaleFactor];
        pixels[outputOffset + x] = 0xFF000000 | (grey * 0x00010101);
      }
      inputOffset += _dataWidth * _thumbnailScaleFactor;
    }
    return pixels;
  }

  /// @return width of image from [renderThumbnail]
  int get thumbnailWidth => width ~/ _thumbnailScaleFactor;

  /// @return height of image from [renderThumbnail]
  int get getThumbnailHeight => height ~/ _thumbnailScaleFactor;

  void _reverseHorizontal(int width, int height) {
    final yuvData = _yuvData;
    for (int y = 0, rowStart = _top * _dataWidth + _left;
        y < height;
        y++, rowStart += _dataWidth) {
      final middle = rowStart + width ~/ 2;
      for (int x1 = rowStart, x2 = rowStart + width - 1;
          x1 < middle;
          x1++, x2--) {
        final temp = yuvData[x1];
        yuvData[x1] = yuvData[x2];
        yuvData[x2] = temp;
      }
    }
  }
}
