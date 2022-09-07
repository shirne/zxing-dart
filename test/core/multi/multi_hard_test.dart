/*
 * Copyright 2016 ZXing authors
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
import 'package:zxing_lib/multi.dart';
import 'package:zxing_lib/zxing.dart';

import '../buffered_image_luminance_source.dart';
import '../common/abstract_black_box.dart';

/// This is a high difficulty test.
/// I'm looking for a way to do it
///
/// todo Not passed yet
void main() {
  test('testMulti', () async {
    // Very basic test for now
    final testBase = AbstractBlackBoxTestCase.buildTestBase(
        'test/resources/blackbox/multi-2');

    final testImage = File('${testBase.path}/multi.jpg');
    final image = decodeImage(testImage.readAsBytesSync())!;
    final scaleImage = copyResize(image,
        width: image.width ~/ 2,
        height: image.height ~/ 2,
        interpolation: Interpolation.average);
    final source = BufferedImageLuminanceSource(scaleImage);
    final bitmap = BinaryBitmap(HybridBinarizer(source));

    final reader = GenericMultipleBarcodeReader(MultiFormatReader());
    final results = reader.decodeMultiple(bitmap);
    //assertNotNull(results);
    expect(results.length, 2);

    expect('031415926531', results[0].text);
    expect(BarcodeFormat.UPC_A, results[0].barcodeFormat);

    expect('www.airtable.com/jobs', results[1].text);
    expect(BarcodeFormat.QR_CODE, results[1].barcodeFormat);
  });

  testQR(String name, {int down = 0, String text = 'www.airtable.com/jobs'}) {
    final testBase = AbstractBlackBoxTestCase.buildTestBase(
        'test/resources/blackbox/multi-2');
    final startTimer = DateTime.now().millisecondsSinceEpoch;

    final testImage = File('${testBase.path}/$name');
    Image image = decodeImage(testImage.readAsBytesSync())!;
    if (down > 0) {
      //image.scaleDown(down.toDouble());
      image = copyResize(image,
          width: (image.width / down).ceil(),
          height: (image.height / down).ceil(),
          interpolation: Interpolation.average);
    }
    final pixels = <int>[];
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final color = image.getPixel(x, y);
        pixels.add(((color & 0xff) << 16) +
            ((color >> 8) & 0xff) +
            ((color >> 16) & 0xff));
      }
    }

    final source = RGBLuminanceSource(image.width, image.height, pixels);

    //MultipleBarcodeReader reader = GenericMultipleBarcodeReader(MultiFormatReader());
    final reader = MultiFormatReader();
    final hints = <DecodeHintType, Object>{
      DecodeHintType.TRY_HARDER: true,
      DecodeHintType.ALSO_INVERTED: true
    };

    Result? result;

    try {
      result = reader.decode(BinaryBitmap(HybridBinarizer(source)), hints);
    } on NotFoundException catch (_) {
      try {
        result = reader.decode(
          BinaryBitmap(GlobalHistogramBinarizer(source)),
          hints,
        );
      } on NotFoundException catch (_) {}
    }
    print('${DateTime.now().millisecondsSinceEpoch - startTimer} ms');
    if (result == null) {
      print('decode failed: $name');
    } else {
      expect(text, result.text);
      expect(BarcodeFormat.QR_CODE, result.barcodeFormat);
      print('decoded:$name');
    }
  }

  test('testHardQR', () {
    testQR('inverted.png');
    testQR('inverse.jpg', down: 3);
    testQR('qr-clip3.png', down: 3);
    testQR('qr-clip2.png', down: 3);
    testQR('qr-clip1.png', down: 3);
    testQR('qr2.jpg', down: 2);
    testQR('qr1.jpg', down: 2);
  });
}
