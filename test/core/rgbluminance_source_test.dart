/*
 * Copyright 2014 ZXing authors
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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/zxing.dart';

/// Tests [RGBLuminanceSource].
void main() {
  final RGBLuminanceSource source = RGBLuminanceSource(3, 3, [
    0x000000, 0x7F7F7F, 0xFFFFFF, //
    0xFF0000, 0x00FF00, 0x0000FF,
    0x0000FF, 0x00FF00, 0xFF0000
  ]);

  test('testCrop', () {
    expect(source.isCropSupported, true);
    LuminanceSource cropped = source.crop(1, 1, 1, 1);
    expect(cropped.height, 1);
    expect(cropped.width, 1);
    expect(cropped.getRow(0, null), [0x7F]);
  });

  test('testMatrix', () {
    expect(source.matrix,
        [0x00, 0x7F, (0xFF).toSigned(8), 0x3F, 0x7F, 0x3F, 0x3F, 0x7F, 0x3F]);
    LuminanceSource croppedFullWidth = source.crop(0, 1, 3, 2);
    expect(croppedFullWidth.matrix, [0x3F, 0x7F, 0x3F, 0x3F, 0x7F, 0x3F]);
    LuminanceSource croppedCorner = source.crop(1, 1, 2, 2);
    expect(croppedCorner.matrix, [0x7F, 0x3F, 0x7F, 0x3F]);
  });

  test('testGetRow', () {
    expect(source.getRow(2, Int8List(3)), [0x3F, 0x7F, 0x3F]);
  });

  test('testToString', () {
    expect(source.toString(), '#+ \n#+#\n#+#\n');
  });
}
