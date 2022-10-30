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

/// Tests [PlanarYUVLuminanceSource].
void main() {
  const List<int> YUV = [
    0, 1, 1, 2, 3, 5, //
    8, 13, 21, 34, 55, 89,
    0, 255, 255, 254, 253, 251,
    248, 243, 235, 222, 201, 167,
    127, 127, 127, 127, 127, 127,
    127, 127, 127, 127, 127, 127,
  ];
  const int COLS = 6;
  const int ROWS = 4;
  final List<int> Y = List.generate(
    COLS * ROWS,
    (index) => index < YUV.length ? YUV[index] : 0,
  );

  test('testNoCrop', () {
    final source =
        PlanarYUVLuminanceSource(Uint8List.fromList(YUV), COLS, ROWS);
    assertListEquals(Y, 0, source.matrix, 0, Y.length);
    for (int r = 0; r < ROWS; r++) {
      assertListEquals(Y, r * COLS, source.getRow(r, null), 0, COLS);
    }
  });

  test('testCrop', () {
    final source = PlanarYUVLuminanceSource(
      Uint8List.fromList(YUV),
      COLS,
      ROWS,
      left: 1,
      top: 1,
      width: COLS - 2,
      height: ROWS - 2,
    );
    expect(source.isCropSupported, true);
    final cropMatrix = source.matrix;
    for (int r = 0; r < ROWS - 2; r++) {
      assertListEquals(
        Y,
        (r + 1) * COLS + 1,
        cropMatrix,
        r * (COLS - 2),
        COLS - 2,
      );
    }
    for (int r = 0; r < ROWS - 2; r++) {
      assertListEquals(
        Y,
        (r + 1) * COLS + 1,
        source.getRow(r, null),
        0,
        COLS - 2,
      );
    }
  });

  test('testThumbnail', () {
    final source =
        PlanarYUVLuminanceSource(Uint8List.fromList(YUV), COLS, ROWS);
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

void assertListEquals(
  List<int> expected,
  int expectedFrom,
  Uint8List actual,
  int actualFrom,
  int length,
) {
  for (int i = 0; i < length; i++) {
    expect(actual[actualFrom + i], expected[expectedFrom + i]);
  }
}
