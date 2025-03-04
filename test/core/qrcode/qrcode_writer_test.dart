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
  final baseImagePath =
      '${Directory.current.absolute.path}/test/resources/golden/qrcode/';

  Future<Image> loadImage(String fileName) async {
    final file = File('$baseImagePath$fileName');

    final exists = await file.exists();
    expect(
      exists,
      true,
      reason:
          "Please download and install test images($fileName), and run from the 'core' directory",
    );

    return decodeImage(file.readAsBytesSync())!;
  }

  // In case the golden images are not monochromatic, convert the RGB values to greyscale.
  BitMatrix createMatrixFromImage(Image image) {
    final width = image.width;
    final height = image.height;

    // final pixels = List.generate(
    //   width * height,
    //   (index) => image.getPixel(index % width, index ~/ width),
    // );
    //image.getRGB(0, 0, width, height, pixels, 0, width);

    final matrix = BitMatrix(width, height);
    final lumianceLevel = 0x7f / 0xff;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);

        // Format.uint1 is monochromatic
        final luminance =
            pixel.format == Format.uint1 ? pixel.r : getLuminance(pixel);
        if (luminance <= lumianceLevel) {
          matrix.set(x, y);
        }
      }
    }
    return matrix;
  }

  test('testQRCodeWriter', () {
    // The QR should be multiplied up to fit, with extra padding if necessary
    final bigEnough = 256;
    final writer = QRCodeWriter();
    BitMatrix matrix = writer.encode(
      'http://www.google.com/',
      BarcodeFormat.qrCode,
      bigEnough,
      bigEnough,
      null,
    );
    //assertNotNull(matrix);
    expect(bigEnough, matrix.width);
    expect(bigEnough, matrix.height);

    // The QR will not fit in this size, so the matrix should come back bigger
    final tooSmall = 20;
    matrix = writer.encode(
      'http://www.google.com/',
      BarcodeFormat.qrCode,
      tooSmall,
      tooSmall,
      null,
    );
    //assertNotNull(matrix);
    expect(tooSmall < matrix.width, true);
    expect(tooSmall < matrix.height, true);

    // We should also be able to handle non-square requests by padding them
    final strangeWidth = 500;
    final strangeHeight = 100;
    matrix = writer.encode(
      'http://www.google.com/',
      BarcodeFormat.qrCode,
      strangeWidth,
      strangeHeight,
      null,
    );
    //assertNotNull(matrix);
    expect(strangeWidth, matrix.width);
    expect(strangeHeight, matrix.height);
  });

  Future<void> compareToGoldenFile(
    String contents,
    ErrorCorrectionLevel ecLevel,
    int resolution,
    String fileName,
  ) async {
    final image = await loadImage(fileName);
    //assertNotNull(image);
    final goldenResult = createMatrixFromImage(image);
    //assertNotNull(goldenResult);

    final writer = QRCodeWriter();
    final generatedResult = writer.encode(
      contents,
      BarcodeFormat.qrCode,
      resolution,
      resolution,
      EncodeHint(errorCorrectionLevel: ecLevel),
    );

    expect(resolution, generatedResult.width);
    expect(resolution, generatedResult.height);
    expect(goldenResult, generatedResult);
  }

  // Golden images are generated with "qrcode_sample.cc". The images are checked with both eye balls
  // and cell phones. We expect pixel-perfect results, because the error correction level is known,
  // and the pixel dimensions matches exactly.
  test('testRegressionTest', () async {
    await compareToGoldenFile(
      'http://www.google.com/',
      ErrorCorrectionLevel.M,
      99,
      'renderer-test-01.png',
    );
  });

  test('renderResultScalesNothing', () {
    final int expectedSize = 33; // Original Size (25) + quietZone
    BitMatrix result;
    ByteMatrix matrix;
    QRCode code;

    matrix = ByteMatrix(25, 25); // QR Version 2! It's all white
    // but it doesn't matter here

    code = QRCode();
    code.matrix = matrix;

    // Test:
    result = QRCodeWriter.renderResult(code, -1, -1, 4);

    // assert(result!=null);
    expect(result.height, expectedSize);
    expect(result.width, expectedSize);
  });

  test('renderResultScalesWhenRequired', () {
    final int expectedSize = 66;
    BitMatrix result;
    ByteMatrix matrix;
    QRCode code;

    matrix = ByteMatrix(25, 25); // QR Version 2! It's all white
    // but it doesn't matter here

    code = QRCode();
    code.matrix = matrix;

    // Test:
    result = QRCodeWriter.renderResult(code, 66, 66, 4);

    // assertNotNull(result);
    expect(result.height, expectedSize);
    expect(result.width, expectedSize);
  });

  // @Test(expected = NullPointerException.class)
  // test('renderResultThrowsExIfCcodeIsNull', () {
  //   QRCodeWriter.renderResult(null, 0, 0, 0);
  // });

  //@Test(expected = IllegalStateException.class)
  test('renderResultThrowsExIfCodeIsIncomplete', () {
    expect(
      () => QRCodeWriter.renderResult(QRCode(), 0, 0, 0),
      throwsA(TypeMatcher<StateError>()),
    );
  });
}
