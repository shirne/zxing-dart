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

/**
 * This class is used to help decode images from files which arrive as RGB data from
 * an ARGB pixel array. It does not support rotation.
 *
 * @author dswitkin@google.com (Daniel Switkin)
 * @author Betaminos
 */
class RGBLuminanceSource extends LuminanceSource {
  final Uint8List luminances;
  final int dataWidth;
  final int dataHeight;
  final int left;
  final int top;

  static Uint8List intList2Int8List(List<int> pixels) {
    int size = pixels.length;
    Uint8List luminances = Uint8List(size);
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

  RGBLuminanceSource(dynamic pixels, this.dataWidth, this.dataHeight,
      [this.left = 0, this.top = 0, int? width, int? height])
      : luminances = (pixels is Uint8List)
            ? pixels
            : intList2Int8List(pixels as List<int>),
        assert(left + (width ?? dataWidth) < dataWidth,
            r'Crop rectangle does not fit within image data.'),
        assert(top + (height ?? dataHeight) < dataHeight,
            r'Crop rectangle does not fit within image data.'),
        super(width ?? dataWidth, height ?? dataHeight);

  @override
  Uint8List getRow(int y, Uint8List row) {
    assert(y >= 0 && y < getHeight(), "Requested row is outside the image: $y");

    int width = getWidth();
    if (row == null || row.length < width) {
      row = Uint8List(width);
    }
    int offset = (y + top) * dataWidth + left;
    List.copyRange(row, 0, luminances, offset, width);
    return row;
  }

  @override
  Uint8List getMatrix() {
    int width = getWidth();
    int height = getHeight();

    // If the caller asks for the entire underlying image, save the copy and give them the
    // original data. The docs specifically warn that result.length must be ignored.
    if (width == dataWidth && height == dataHeight) {
      return luminances;
    }

    int area = width * height;
    Uint8List matrix = Uint8List(area);
    int inputOffset = top * dataWidth + left;

    // If the width matches the full width of the underlying data, perform a single copy.
    if (width == dataWidth) {
      List.copyRange(matrix, 0, luminances, inputOffset, area);
      return matrix;
    }

    // Otherwise copy one cropped row at a time.
    for (int y = 0; y < height; y++) {
      int outputOffset = y * width;
      List.copyRange(matrix, outputOffset, luminances, inputOffset, width);
      inputOffset += dataWidth;
    }
    return matrix;
  }

  @override
  bool isCropSupported() {
    return true;
  }

  @override
  LuminanceSource crop(int left, int top, int width, int height) {
    return RGBLuminanceSource(luminances, dataWidth, dataHeight,
        this.left + left, this.top + top, width, height);
  }
}
