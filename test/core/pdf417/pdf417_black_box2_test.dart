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

import 'dart:io';

import 'package:image/image.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/pdf417.dart';
import 'package:zxing_lib/zxing.dart';

import '../buffered_image_luminance_source.dart';
import '../common/abstract_black_box.dart';

/// This test contains 480x240 images captured from an Android device at preview resolution.
///

void main() {
  // todo the result is different with zxing java
  test('test22png', () {
    Directory root = AbstractBlackBoxTestCase.buildTestBase(
        "test/resources/blackbox/pdf417-2");
    File testImage = File('${root.path}/22.png');
    Image image = decodeImage(testImage.readAsBytesSync())!;
    LuminanceSource source = BufferedImageLuminanceSource(image);
    BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));
    try {
      var result = PDF417Reader().decode(bitmap, {
        DecodeHintType.PURE_BARCODE: true,
        DecodeHintType.TRY_HARDER: true,
      });
      print(result.text);
    } on ReaderException catch (_) {}
  });

  test('PDF417BlackBox2TestCase', () {
    AbstractBlackBoxTestCase("test/resources/blackbox/pdf417-2",
        MultiFormatReader(), BarcodeFormat.PDF_417)
      ..addTest(24, 24, 0.0, 0, 0)
      ..addTest(24, 24, 180.0, 0, 0)
      ..testBlackBox();
  });
}
