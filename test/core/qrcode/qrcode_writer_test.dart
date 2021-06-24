/*
 * Copyright 2008 ZXing authors
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

import 'dart:io';

import 'package:image/image.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/zxing.dart';

void main() {
  final String baseImagePath =
      "${Directory.current.absolute.path}/test/resources/golden/qrcode/";

  Future<Image> loadImage(String fileName) async {
    File file = File("$baseImagePath$fileName");

    var exists = await file.exists();
    expect(!exists,
        "Please download and install test images($fileName), and run from the 'core' directory");

    return decodeImage(file.readAsBytesSync())!;
  }

  // In case the golden images are not monochromatic, convert the RGB values to greyscale.
  BitMatrix createMatrixFromImage(Image image) {
    int width = image.width;
    int height = image.height;
    List<int> pixels = List.generate(width * height,
        (index) => image.getPixel(index % width, index ~/ width));
    //image.getRGB(0, 0, width, height, pixels, 0, width);

    BitMatrix matrix = BitMatrix(width, height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int pixel = pixels[y * width + x];
        int luminance = getLuminance(pixel);
        if (luminance <= 0x7F) {
          matrix.set(x, y);
        }
      }
    }
    return matrix;
  }

  test('testQRCodeWriter', () {
    // The QR should be multiplied up to fit, with extra padding if necessary
    int bigEnough = 256;
    Writer writer = QRCodeWriter();
    BitMatrix matrix = writer.encode("http://www.google.com/",
        BarcodeFormat.QR_CODE, bigEnough, bigEnough, null);
    //assertNotNull(matrix);
    expect(bigEnough, matrix.width);
    expect(bigEnough, matrix.height);

    // The QR will not fit in this size, so the matrix should come back bigger
    int tooSmall = 20;
    matrix = writer.encode("http://www.google.com/", BarcodeFormat.QR_CODE,
        tooSmall, tooSmall, null);
    //assertNotNull(matrix);
    expect(tooSmall < matrix.width, true);
    expect(tooSmall < matrix.height, true);

    // We should also be able to handle non-square requests by padding them
    int strangeWidth = 500;
    int strangeHeight = 100;
    matrix = writer.encode("http://www.google.com/", BarcodeFormat.QR_CODE,
        strangeWidth, strangeHeight, null);
    //assertNotNull(matrix);
    expect(strangeWidth, matrix.width);
    expect(strangeHeight, matrix.height);
  });

  void compareToGoldenFile(String contents, ErrorCorrectionLevel ecLevel,
      int resolution, String fileName) async {
    Image image = await loadImage(fileName);
    //assertNotNull(image);
    BitMatrix goldenResult = createMatrixFromImage(image);
    //assertNotNull(goldenResult);

    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.ERROR_CORRECTION] = ecLevel;
    Writer writer = QRCodeWriter();
    BitMatrix generatedResult = writer.encode(
        contents, BarcodeFormat.QR_CODE, resolution, resolution, hints);

    expect(resolution, generatedResult.width);
    expect(resolution, generatedResult.height);
    expect(goldenResult, generatedResult);
  }

  // Golden images are generated with "qrcode_sample.cc". The images are checked with both eye balls
  // and cell phones. We expect pixel-perfect results, because the error correction level is known,
  // and the pixel dimensions matches exactly.
  test('testRegressionTest', () {
    compareToGoldenFile("http://www.google.com/", ErrorCorrectionLevel.M, 99,
        "renderer-test-01.png");
  });
}
