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
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../buffered_image_luminance_source.dart';
import '../common/abstract_black_box.dart';
import '../common/abstract_negative_black_box.dart';

/// This test ensures that partial barcodes do not decode.
///
void main() {
  // todo 11.png may pass because of https://github.com/zxing/zxing/issues/1400
  test('PartialBlackBoxTestCase', () {
    AbstractNegativeBlackBoxTestCase("test/resources/blackbox/partial")
      ..addNegativeTest(2, 0.0)
      ..addNegativeTest(2, 90.0)
      ..addNegativeTest(2, 180.0)
      ..addNegativeTest(2, 270.0)
      ..testBlackBox();
  });

  grayImage(String srcName) async {
    Directory base = AbstractBlackBoxTestCase.buildTestBase(
        "test/resources/blackbox/partial");
    File testImage = File(base.path + "/$srcName.png");
    Image image = decodeImage(testImage.readAsBytesSync())!;

    LuminanceSource source = BufferedImageLuminanceSource(image);
    BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));

    Image newImage = Image(bitmap.width, bitmap.height);
    newImage.fill(getColor(255, 255, 255));
    var black = getColor(0, 0, 0);
    for (int i = 0; i < image.height; i++) {
      try {
        var row = bitmap.getBlackRow(i, null);
        for (int j = 0; j < row.size; j++) {
          if (row.get(j)) {
            newImage.setPixel(j, i, black);
          }
        }
      } on NotFoundException catch (_) {}
    }

    var iosink = File(base.path + "/$srcName-gray.png").openWrite();
    iosink.add(encodePng(newImage));
    await iosink.flush();
    iosink.close();
  }

  // for UPCEANReader.decodeDigit bug (https://github.com/zxing/zxing/issues/1400)
  test('p11Test', () {
    Result? result;
    var row = BitArray.test(
        Uint32List.fromList([
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          -33570816,
          118,
          0,
          0,
          946064924,
          -2026257522,
          955253639,
          124828,
          0,
          0,
          0,
          0
        ]),
        640);
    try {
      result =
          UPCEReader().decodeRow(128, row, {DecodeHintType.TRY_HARDER: true});
      print(result);
    } on ChecksumException catch (_) {
      //pass
    }
  });
}
