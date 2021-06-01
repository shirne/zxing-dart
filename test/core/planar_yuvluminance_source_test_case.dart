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

import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/zxing.dart';

/// Tests {@link PlanarYUVLuminanceSource}.
void main() {
  const List<int> YUV = [
    0, 1, 1, 2, 3, 5, //
    8, 13, 21, 34, 55, 89,
    0, -1, -1, -2, -3, -5,
    -8, -13, -21, -34, -55, -89,
    127, 127, 127, 127, 127, 127,
    127, 127, 127, 127, 127, 127,
  ];
  const int COLS = 6;
  const int ROWS = 4;
  final List<int> Y = List.generate(
      COLS * ROWS, (index) => index < YUV.length ? YUV[index] : 0);

  test('testNoCrop', () {
    PlanarYUVLuminanceSource source = new PlanarYUVLuminanceSource(
        Uint8List.fromList(YUV), COLS, ROWS, 0, 0, COLS, ROWS, false);
    assertListEquals(Y, 0, source.getMatrix(), 0, Y.length);
    for (int r = 0; r < ROWS; r++) {
      assertListEquals(Y, r * COLS, source.getRow(r, null), 0, COLS);
    }
  });

  test('testCrop', () {
    PlanarYUVLuminanceSource source = new PlanarYUVLuminanceSource(
        Uint8List.fromList(YUV), COLS, ROWS, 1, 1, COLS - 2, ROWS - 2, false);
    expect(source.isCropSupported(), true);
    Uint8List cropMatrix = source.getMatrix();
    for (int r = 0; r < ROWS - 2; r++) {
      assertListEquals(Y, (r + 1) * COLS + 1, cropMatrix, r * (COLS - 2), COLS - 2);
    }
    for (int r = 0; r < ROWS - 2; r++) {
      assertListEquals(Y, (r + 1) * COLS + 1, source.getRow(r, null), 0, COLS - 2);
    }
  });

  test('testThumbnail', () {
    PlanarYUVLuminanceSource source = new PlanarYUVLuminanceSource(
        Uint8List.fromList(YUV), COLS, ROWS, 0, 0, COLS, ROWS, false);
    expect(source.renderThumbnail(), [
      0xFF000000,
      0xFF010101,
      0xFF030303,
      0xFF000000,
      0xFFFFFFFF,
      0xFFFDFDFD
    ]);
  });


}

void assertListEquals(List<int> expected, int expectedFrom,
    Uint8List actual, int actualFrom, int length) {
  for (int i = 0; i < length; i++) {
    expect(actual[actualFrom + i], expected[expectedFrom + i]);
  }
}