/*
 * Copyright 2020 ZXing authors
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

import 'package:image/image.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/zxing.dart';

import 'buffered_image_luminance_source.dart';

/// Tests [InvertedLuminanceSource].
void main() {
  test('testInverted', () async {
    Image image = Image(2, 1);
    image.fill(getColor(0, 0, 0, 255));
    //BufferedImage image = BufferedImage(2, 1, BufferedImage.TYPE_INT_RGB);
    //image.setRGB(0, 0, 0xFFFFFF);
    image.setPixel(0, 0, 0xffffffff);

    LuminanceSource source = BufferedImageLuminanceSource(image);

    expect(source.getRow(0, null), [0xFF.toSigned(8), 0]);
    LuminanceSource inverted = InvertedLuminanceSource(source);
    expect(inverted.getRow(0, null), [0, 0xFF.toSigned(8)]);
  });
}
