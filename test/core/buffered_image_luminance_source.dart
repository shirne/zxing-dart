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

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:zxing_lib/zxing.dart';

/// This LuminanceSource implementation is meant for J2SE clients and our blackbox unit tests.
///
class BufferedImageLuminanceSource extends LuminanceSource {
  static const double minus45InRadians =
      -0.7853981633974483; // Math.toRadians(-45.0)

  late Uint8List buffer;
  Image image;
  final int left;
  final int top;

  BufferedImageLuminanceSource(
    this.image, [
    this.left = 0,
    this.top = 0,
    int? width,
    int? height,
  ]) : super(width ?? image.width, height ?? image.height) {
    width ??= image.width - left;
    height ??= image.height - top;

    final int sourceWidth = image.width;
    final int sourceHeight = image.height;
    if (left + width > sourceWidth || top + height > sourceHeight) {
      throw ArgumentError('Crop rectangle does not fit within image data.');
    }

    buffer = Uint8List(width * height);
    for (int y = top; y < top + height; y++) {
      for (int x = 0; x < width; x++) {
        final int color = image.getPixel(x + left, y);
        final int alpha = getAlpha(color);

        // The color of fully-transparent pixels is irrelevant. They are often, technically, fully-transparent
        // black (0 alpha, and then 0 RGB). They are often used, of course as the "white" area in a
        // barcode image. Force any such pixel to be white:
        if (alpha == 0) {
          // white, so we know its luminance is 255
          buffer[(y - top) * width + x] = 0xff;
        } else {
          // .299R + 0.587G + 0.114B (YUV/YIQ for PAL and NTSC),
          // (306*R) >> 10 is approximately equal to R*0.299, and so on.
          // 0x200 >> 10 is 0.5, it implements rounding.
          buffer[(y - top) * width + x] = (306 * getRed(color) +
                  601 * getGreen(color) +
                  117 * getBlue(color) +
                  0x200) >>
              10;
        }
      }
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

    // The underlying raster of image consists of bytes with the luminance values
    //image.getDataElements(left, top + y, width, 1, row);
    List.copyRange(row, 0, buffer, y * width, (y + 1) * width);
    return row;
  }

  @override
  Uint8List get matrix {
    // The underlying raster of image consists of area bytes with the luminance values
    //image.getDataElements(left, top, width, height, matrix);
    final Uint8List matrix = Uint8List.fromList(buffer);

    return matrix;
  }

  @override
  bool get isCropSupported => true;

  @override
  LuminanceSource crop(int left, int top, int width, int height) {
    return BufferedImageLuminanceSource(
      image.clone(),
      this.left + left,
      this.top + top,
      width,
      height,
    );
  }

  /// This is always true, since the image is a gray-scale image.
  ///
  /// @return true
  @override
  bool get isRotateSupported => true;

  @override
  LuminanceSource rotateCounterClockwise() {
    final int sourceWidth = image.width;
    //int sourceHeight = image.height;

    // Rotate 90 degrees counterclockwise.
    // Note width/height are flipped since we are rotating 90 degrees.
    final newImage = copyRotate(image, 90);

    // Maintain the cropped region, but rotate it too.
    return BufferedImageLuminanceSource(
      newImage,
      top,
      sourceWidth - (left + width),
      height,
      width,
    );
  }

  @override
  LuminanceSource rotateCounterClockwise45() {
    final int oldCenterX = left + width ~/ 2;
    final int oldCenterY = top + height ~/ 2;

    // Rotate 45 degrees counterclockwise.
    //AffineTransform transform = AffineTransform.getRotateInstance(MINUS_45_IN_RADIANS, oldCenterX, oldCenterY);

    final int sourceDimension = math.max(image.width, image.height);
    //BufferedImage rotatedImage = BufferedImage(sourceDimension, sourceDimension, BufferedImage.TYPE_BYTE_GRAY);
    final newImage = copyRotate(image, 45);

    final int halfDimension = math.max(width, height) ~/ 2;
    final int newLeft = math.max(0, oldCenterX - halfDimension);
    final int newTop = math.max(0, oldCenterY - halfDimension);
    final int newRight =
        math.min(sourceDimension - 1, oldCenterX + halfDimension);
    final int newBottom =
        math.min(sourceDimension - 1, oldCenterY + halfDimension);

    return BufferedImageLuminanceSource(
      newImage,
      newLeft,
      newTop,
      newRight - newLeft,
      newBottom - newTop,
    );
  }
}
