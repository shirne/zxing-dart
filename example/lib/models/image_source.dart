

import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as Math;

import 'package:buffer_image/buffer_image.dart';
import 'package:zxing_lib/zxing.dart';

class ImageLuminanceSource extends LuminanceSource {

  static final double minus45InRadians = -0.7853981633974483; // Math.toRadians(-45.0)

  AbstractImage image;
  final int left;
  final int top;

  ImageLuminanceSource(this.image, [this.left = 0, this.top = 0, int? width, int? height])
      :super(width ?? image.width, height ?? image.height) {

    if(width == null) width = image.width;
    if(height == null) height = image.height;

    int sourceWidth = image.width;
    int sourceHeight = image.height;
    if (left + width > sourceWidth || top + height > sourceHeight) {
      throw Exception("Crop rectangle does not fit within image data.");
    }

    for (int y = top; y < top + height; y++) {
      for (int x = 0; x < width; x++) {
        Color color = image.getColor(x + left, y);

        // The color of fully-transparent pixels is irrelevant. They are often, technically, fully-transparent
        // black (0 alpha, and then 0 RGB). They are often used, of course as the "white" area in a
        // barcode image. Force any such pixel to be white:
        if (color.alpha == 0) {
          // white, so we know its luminance is 255
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
    }
  }

  scaleDown(int scale){
    var newImage = BufferImage((image.width / scale).ceil(),(image.height / scale).ceil());
    List<Color?> colors = List.filled(scale * scale, null);
    for(int y=0; y < newImage.width; y++){
      for(int x=0; x < newImage.width; x++){
        int count = 0;
        colors.fillRange(0, colors.length, null);
        for(int sy=0; sy < scale; sy++){
          if(y * scale + sy >= image.height)break;
          for(int sx=0; sx < scale; sx++){
            if(x * scale + sx >= image.width)break;
            count ++;
            colors[sy*scale + sx] = image.getColor(x * scale + sx, y * scale + sy);
          }
        }
        if(count  < 1) break;

        int alpha = 0;
        int red = 0;
        int green = 0;
        int blue = 0;
        for(Color? color in colors){
          if(color != null){
            count ++;
            alpha += color.alpha;
            red += color.red;
            green += color.green;
            blue += color.blue;
          }
        }
        newImage.setColor(x, y, Color.fromARGB(alpha ~/ count, red ~/ count , green ~/ count, blue ~/ count));
      }
    }

    return ImageLuminanceSource(newImage);
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
    return ImageLuminanceSource(image.copy(), this.left + left, this.top + top, width, height);
  }

  /// This is always true, since the image is a gray-scale image.
  @override
  bool get isRotateSupported => true;

  @override
  LuminanceSource rotateCounterClockwise() {
    int sourceWidth = image.width;
    int sourceHeight = image.height;

    // Rotate 90 degrees counterclockwise.
    // Note width/height are flipped since we are rotating 90 degrees.
    image.rotate(Math.pi/2);


    // Maintain the cropped region, but rotate it too.
    return ImageLuminanceSource(image.copy(), top, sourceWidth - (left + width), height, width);
  }

  @override
  LuminanceSource rotateCounterClockwise45() {

    int oldCenterX = left + width ~/ 2;
    int oldCenterY = top + height ~/ 2;

    // Rotate 45 degrees counterclockwise.
    int sourceDimension = Math.max(image.width, image.height);
    image.rotate(Math.pi / 4);


    int halfDimension = Math.max(width, height) ~/ 2;
    int newLeft = Math.max(0, oldCenterX - halfDimension);
    int newTop = Math.max(0, oldCenterY - halfDimension);
    int newRight = Math.min(sourceDimension - 1, oldCenterX + halfDimension);
    int newBottom = Math.min(sourceDimension - 1, oldCenterY + halfDimension);

    return ImageLuminanceSource(image.copy(), newLeft, newTop, newRight - newLeft, newBottom - newTop);
  }

}