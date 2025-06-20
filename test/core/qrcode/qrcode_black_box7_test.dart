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
import '../common/logger.dart' show Logger;

/// These tests are supplied by Tim Gernat and test finder pattern detection at small size and under
/// rotation, which was a weak spot.
void main() {
  final Logger logger = Logger.getLogger(AbstractBlackBoxTestCase);
  Image dispatcher(Image image, String path) {
    path = path.replaceAll('\\', '/');
    final filename = path.substring(path.lastIndexOf('/') + 1);
    Uint8List data;
    final origData = Uint8List.fromList(
      image.map<int>((e) => (e.luminanceNormalized * 255).round()).toList(),
    );
    int width = image.width;
    int height = image.height;
    Dispatch? dispatcher;
    switch (filename) {
      case 'over_dark.png':
        dispatcher = OverDarkScale();
        break;
      case 'over_light.png':
        dispatcher = OverBrightScale();
        break;
      case 'reverse.png':
        dispatcher = RevGrayscale();
        break;
      case 'test_inter.png':
        dispatcher = InterruptGrayscale();
        break;
      case 'test_gray.png':
        dispatcher = LightGrayscale();
        break;
      case 'test1.png':
        dispatcher = CropBackground(purity: 0.95, tolerance: 0.1);
        break;
      case 'test3.png':
        dispatcher = CropBackground(cropIn: 2);
        break;
      case 'test4.png':
        dispatcher = CropBackground(tolerance: 0.2, cropIn: 6);
        break;
      default:
    }
    if (dispatcher != null) {
      data = dispatcher.dispatch(origData, width, height);
      final rect = dispatcher.cropRect;
      if (rect != null) {
        logger.info('cropped $filename:$rect ${rect.width}  ${rect.height}');
        width = rect.width;
        height = rect.height;
      }
    } else {
      data = origData;
    }

    final result = Image.fromBytes(
      width: width,
      height: height,
      bytes: data.buffer,
      format: Format.uint8,
      order: ChannelOrder.red,
    );
    return result;
  }

  test('QRCodeBlackBox7TestCase', () {
    AbstractBlackBoxTestCase(
      'test/resources/blackbox/qrcode-7',
      MultiFormatReader(),
      BarcodeFormat.qrCode,
      imageProcess: dispatcher,
    )
      ..addTest(2, 2, 0.0)
      ..addTest(2, 2, 90.0)
      ..addTest(2, 2, 180.0)
      ..addTest(2, 2, 270.0)
      ..testBlackBox();
  });
}
