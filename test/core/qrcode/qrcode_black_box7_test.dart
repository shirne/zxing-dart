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

import 'package:image/image.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/grayscale.dart';
import 'package:zxing_lib/zxing.dart';

import '../common/abstract_black_box.dart';

/// These tests are supplied by Tim Gernat and test finder pattern detection at small size and under
/// rotation, which was a weak spot.
void main() {
  Image dispatcher(Image image, String path) {
    path = path.replaceAll('\\', '/');
    final filename = path.substring(path.lastIndexOf('/') + 1);
    Uint8List data;
    final origData = image.getBytes(format: Format.luminance);
    switch (filename) {
      case 'over_dark.png':
        data = OverDarkScale().dispatch(origData, image.width, image.height);
        break;
      case 'over_light.png':
        data = OverBrightScale().dispatch(origData, image.width, image.height);
        break;
      case 'reverse.png':
        data = RevGrayscale().dispatch(origData, image.width, image.height);
        break;
      case 'test_inter.png':
        data =
            InterruptGrayscale().dispatch(origData, image.width, image.height);
        break;
      case 'test_gray.png':
        data = LightGrayscale().dispatch(origData, image.width, image.height);
        break;
      default:
        data = origData;
    }
    final result = Image.fromBytes(image.width, image.height, data,
        format: Format.luminance);
    // File(path.replaceAll('.png', '-p.png')).writeAsBytes(encodePng(result));
    return result;
  }

  test('QRCodeBlackBox7TestCase', () {
    AbstractBlackBoxTestCase(
      'test/resources/blackbox/qrcode-7',
      MultiFormatReader(),
      BarcodeFormat.QR_CODE,
      dispatcher,
    )
      ..addTest(2, 2, 0.0)
      ..addTest(2, 2, 90.0)
      ..addTest(2, 2, 180.0)
      ..addTest(2, 2, 270.0)
      ..testBlackBox();
  });
}
