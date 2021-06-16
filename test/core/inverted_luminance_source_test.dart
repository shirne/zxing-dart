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

import 'dart:ui';

import 'package:buffer_image/buffer_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxing_lib/zxing.dart';

import 'buffered_image_luminance_source.dart';



/// Tests [InvertedLuminanceSource].
void main() {

  test('testInverted', () async {

    BufferImage image = BufferImage( 2, 1);
    //BufferedImage image = new BufferedImage(2, 1, BufferedImage.TYPE_INT_RGB);
    //image.setRGB(0, 0, 0xFFFFFF);
    image.setColor(0, 0, Color.fromARGB(255, 255, 255, 255));

    LuminanceSource source = new BufferedImageLuminanceSource(image);

    expect(source.getRow(0, null), [0xFF.toSigned(8), 0]);
    LuminanceSource inverted = new InvertedLuminanceSource(source);
    expect(inverted.getRow(0, null), [0, 0xFF.toSigned(8)]);
  });

}
