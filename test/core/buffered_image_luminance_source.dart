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
import 'dart:math' as Math;
import 'dart:ui';

import 'package:buffer_image/buffer_image.dart';
import 'package:zxing_lib/zxing.dart';


/// This LuminanceSource implementation is meant for J2SE clients and our blackbox unit tests.
///
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Sean Owen
/// @author code@elektrowolle.de (Wolfgang Jung)
class BufferedImageLuminanceSource extends LuminanceSource {

  static final double MINUS_45_IN_RADIANS = -0.7853981633974483; // Math.toRadians(-45.0)

  late BufferImage image;
  final int left;
  final int top;

  BufferedImageLuminanceSource(this.image, [this.left = 0, this.top = 0, int? width, int? height])
      :super(width ?? image.width, height ?? image.height) {

    if(width == null) width = image.width;
    if(height == null) height = image.height;


    int sourceWidth = image.width;
    int sourceHeight = image.height;
    if (left + width > sourceWidth || top + height > sourceHeight) {
      throw Exception("Crop rectangle does not fit within image data.");
    }

      //WritableRaster raster = this.image.getRaster();
      //List<int> buffer = List.filled(width, 0);
      for (int y = top; y < top + height; y++) {
        //image.getRGB(left, y, width, 1, buffer, 0, sourceWidth);
        for (int x = 0; x < width; x++) {
          Color color = image.getColor(x + left, y);
          //int pixel = buffer[x];

          // The color of fully-transparent pixels is irrelevant. They are often, technically, fully-transparent
          // black (0 alpha, and then 0 RGB). They are often used, of course as the "white" area in a
          // barcode image. Force any such pixel to be white:
          if (color.alpha == 0) {
            // white, so we know its luminance is 255
            //buffer[x] = 0xFF;
            image.setColor(x + left, y, color.withAlpha(255));
          } else {
            // .299R + 0.587G + 0.114B (YUV/YIQ for PAL and NTSC),
            // (306*R) >> 10 is approximately equal to R*0.299, and so on.
            // 0x200 >> 10 is 0.5, it implements rounding.

            int newAlpha = (306 * ((color.value >> 16) & 0xFF) +
                601 * ((color.value >> 8) & 0xFF) +
                117 * (color.value & 0xFF) +
                0x200) >> 10;
            image.setColor(x + left, y, color.withAlpha(newAlpha));
          }
        }
        //raster.setPixels(left, y, width, 1, buffer);
      }


  }

  @override
  Int8List getRow(int y, Int8List? row) {
    if (y < 0 || y >= height) {
      throw Exception("Requested row is outside the image: $y");
    }
    if (row == null || row.length < width) {
      row = Int8List(width);
    }
    // The underlying raster of image consists of bytes with the luminance values
    //image.getDataElements(left, top + y, width, 1, row);
    for(int x = left; x < left + width; x++){
        Color pColor = image.getColor(x, top + y);
        int max = Math.max(pColor.red, Math.max(pColor.green, pColor.blue));
        int min = Math.min(pColor.red, Math.min(pColor.green, pColor.blue));
        row[x - left] = (max + min) ~/ 2;
    }
    return row;
  }

  @override
  Int8List get matrix {
    int area = width * height;
    Int8List matrix = Int8List(area);
    // The underlying raster of image consists of area bytes with the luminance values
    //image.getDataElements(left, top, width, height, matrix);
    for(int x = left; x < left + width; x++){
      for(int y = top; y < top + height; y++){
        Color pColor = image.getColor(x, y);
        int max = Math.max(pColor.red, Math.max(pColor.green, pColor.blue));
        int min = Math.min(pColor.red, Math.min(pColor.green, pColor.blue));
        matrix[(y-top)*width + x - left] = (max + min) ~/ 2;
      }
    }
    return matrix;
  }

  @override
  bool get isCropSupported => true;

  @override
  LuminanceSource crop(int left, int top, int width, int height) {
    return new BufferedImageLuminanceSource(image, this.left + left, this.top + top, width, height);
  }

  /// This is always true, since the image is a gray-scale image.
  ///
  /// @return true
  @override
  bool get isRotateSupported => true;

  @override
  LuminanceSource rotateCounterClockwise() {
    int sourceWidth = image.width;
    int sourceHeight = image.height;

    // Rotate 90 degrees counterclockwise.
    //AffineTransform transform = new AffineTransform(0.0, -1.0, 1.0, 0.0, 0.0, sourceWidth);

    // Note width/height are flipped since we are rotating 90 degrees.
    BufferImage rotatedImage = image.rotate(Math.pi/2);

    // Draw the original image into rotated, via transformation
    //Graphics2D g = rotatedImage.createGraphics();
    //g.drawImage(image, transform, null);
    //g.dispose();

    // Maintain the cropped region, but rotate it too.
    return new BufferedImageLuminanceSource(rotatedImage, top, sourceWidth - (left + width), height, width);
  }

  @override
  LuminanceSource rotateCounterClockwise45() {

    int oldCenterX = left + width ~/ 2;
    int oldCenterY = top + height ~/ 2;

    // Rotate 45 degrees counterclockwise.
    //AffineTransform transform = AffineTransform.getRotateInstance(MINUS_45_IN_RADIANS, oldCenterX, oldCenterY);

    int sourceDimension = Math.max(image.width, image.height);
    //BufferedImage rotatedImage = new BufferedImage(sourceDimension, sourceDimension, BufferedImage.TYPE_BYTE_GRAY);
    BufferImage rotatedImage = image.rotate(Math.pi / 4);

    // Draw the original image into rotated, via transformation
    //Graphics2D g = rotatedImage.createGraphics();
    //g.drawImage(image, transform, null);
    //g.dispose();

    int halfDimension = Math.max(width, height) ~/ 2;
    int newLeft = Math.max(0, oldCenterX - halfDimension);
    int newTop = Math.max(0, oldCenterY - halfDimension);
    int newRight = Math.min(sourceDimension - 1, oldCenterX + halfDimension);
    int newBottom = Math.min(sourceDimension - 1, oldCenterY + halfDimension);

    return new BufferedImageLuminanceSource(rotatedImage, newLeft, newTop, newRight - newLeft, newBottom - newTop);
  }

}
