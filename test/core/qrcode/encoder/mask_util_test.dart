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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/qrcode.dart';

void main() {
  test('testApplyMaskPenaltyRule1', () {
    ByteMatrix matrix = ByteMatrix(4, 1);
    matrix.set(0, 0, 0);
    matrix.set(1, 0, 0);
    matrix.set(2, 0, 0);
    matrix.set(3, 0, 0);
    expect(0, MaskUtil.applyMaskPenaltyRule1(matrix));
    // Horizontal.
    matrix = ByteMatrix(6, 1);
    matrix.set(0, 0, 0);
    matrix.set(1, 0, 0);
    matrix.set(2, 0, 0);
    matrix.set(3, 0, 0);
    matrix.set(4, 0, 0);
    matrix.set(5, 0, 1);
    expect(3, MaskUtil.applyMaskPenaltyRule1(matrix));
    matrix.set(5, 0, 0);
    expect(4, MaskUtil.applyMaskPenaltyRule1(matrix));
    // Vertical.
    matrix = ByteMatrix(1, 6);
    matrix.set(0, 0, 0);
    matrix.set(0, 1, 0);
    matrix.set(0, 2, 0);
    matrix.set(0, 3, 0);
    matrix.set(0, 4, 0);
    matrix.set(0, 5, 1);
    expect(3, MaskUtil.applyMaskPenaltyRule1(matrix));
    matrix.set(0, 5, 0);
    expect(4, MaskUtil.applyMaskPenaltyRule1(matrix));
  });

  test('testApplyMaskPenaltyRule2', () {
    ByteMatrix matrix = ByteMatrix(1, 1);
    matrix.set(0, 0, 0);
    expect(0, MaskUtil.applyMaskPenaltyRule2(matrix));
    matrix = ByteMatrix(2, 2);
    matrix.set(0, 0, 0);
    matrix.set(1, 0, 0);
    matrix.set(0, 1, 0);
    matrix.set(1, 1, 1);
    expect(0, MaskUtil.applyMaskPenaltyRule2(matrix));
    matrix = ByteMatrix(2, 2);
    matrix.set(0, 0, 0);
    matrix.set(1, 0, 0);
    matrix.set(0, 1, 0);
    matrix.set(1, 1, 0);
    expect(3, MaskUtil.applyMaskPenaltyRule2(matrix));
    matrix = ByteMatrix(3, 3);
    matrix.set(0, 0, 0);
    matrix.set(1, 0, 0);
    matrix.set(2, 0, 0);
    matrix.set(0, 1, 0);
    matrix.set(1, 1, 0);
    matrix.set(2, 1, 0);
    matrix.set(0, 2, 0);
    matrix.set(1, 2, 0);
    matrix.set(2, 2, 0);
    // Four instances of 2x2 blocks.
    expect(3 * 4, MaskUtil.applyMaskPenaltyRule2(matrix));
  });

  test('testApplyMaskPenaltyRule3', () {
    // Horizontal 00001011101.
    ByteMatrix matrix = ByteMatrix(11, 1);
    matrix.set(0, 0, 0);
    matrix.set(1, 0, 0);
    matrix.set(2, 0, 0);
    matrix.set(3, 0, 0);
    matrix.set(4, 0, 1);
    matrix.set(5, 0, 0);
    matrix.set(6, 0, 1);
    matrix.set(7, 0, 1);
    matrix.set(8, 0, 1);
    matrix.set(9, 0, 0);
    matrix.set(10, 0, 1);
    expect(40, MaskUtil.applyMaskPenaltyRule3(matrix));
    // Horizontal 10111010000.
    matrix = ByteMatrix(11, 1);
    matrix.set(0, 0, 1);
    matrix.set(1, 0, 0);
    matrix.set(2, 0, 1);
    matrix.set(3, 0, 1);
    matrix.set(4, 0, 1);
    matrix.set(5, 0, 0);
    matrix.set(6, 0, 1);
    matrix.set(7, 0, 0);
    matrix.set(8, 0, 0);
    matrix.set(9, 0, 0);
    matrix.set(10, 0, 0);
    expect(40, MaskUtil.applyMaskPenaltyRule3(matrix));
    // Horizontal 1011101.
    matrix = ByteMatrix(7, 1);
    matrix.set(0, 0, 1);
    matrix.set(1, 0, 0);
    matrix.set(2, 0, 1);
    matrix.set(3, 0, 1);
    matrix.set(4, 0, 1);
    matrix.set(5, 0, 0);
    matrix.set(6, 0, 1);
    expect(0, MaskUtil.applyMaskPenaltyRule3(matrix));
    // Vertical 00001011101.
    matrix = ByteMatrix(1, 11);
    matrix.set(0, 0, 0);
    matrix.set(0, 1, 0);
    matrix.set(0, 2, 0);
    matrix.set(0, 3, 0);
    matrix.set(0, 4, 1);
    matrix.set(0, 5, 0);
    matrix.set(0, 6, 1);
    matrix.set(0, 7, 1);
    matrix.set(0, 8, 1);
    matrix.set(0, 9, 0);
    matrix.set(0, 10, 1);
    expect(40, MaskUtil.applyMaskPenaltyRule3(matrix));
    // Vertical 10111010000.
    matrix = ByteMatrix(1, 11);
    matrix.set(0, 0, 1);
    matrix.set(0, 1, 0);
    matrix.set(0, 2, 1);
    matrix.set(0, 3, 1);
    matrix.set(0, 4, 1);
    matrix.set(0, 5, 0);
    matrix.set(0, 6, 1);
    matrix.set(0, 7, 0);
    matrix.set(0, 8, 0);
    matrix.set(0, 9, 0);
    matrix.set(0, 10, 0);
    expect(40, MaskUtil.applyMaskPenaltyRule3(matrix));
    // Vertical 1011101.
    matrix = ByteMatrix(1, 7);
    matrix.set(0, 0, 1);
    matrix.set(0, 1, 0);
    matrix.set(0, 2, 1);
    matrix.set(0, 3, 1);
    matrix.set(0, 4, 1);
    matrix.set(0, 5, 0);
    matrix.set(0, 6, 1);
    expect(0, MaskUtil.applyMaskPenaltyRule3(matrix));
  });

  test('testApplyMaskPenaltyRule4', () {
    // Dark cell ratio = 0%
    ByteMatrix matrix = ByteMatrix(1, 1);
    matrix.set(0, 0, 0);
    expect(100, MaskUtil.applyMaskPenaltyRule4(matrix));
    // Dark cell ratio = 5%
    matrix = ByteMatrix(2, 1);
    matrix.set(0, 0, 0);
    matrix.set(0, 0, 1);
    expect(0, MaskUtil.applyMaskPenaltyRule4(matrix));
    // Dark cell ratio = 66.67%
    matrix = ByteMatrix(6, 1);
    matrix.set(0, 0, 0);
    matrix.set(1, 0, 1);
    matrix.set(2, 0, 1);
    matrix.set(3, 0, 1);
    matrix.set(4, 0, 1);
    matrix.set(5, 0, 0);
    expect(30, MaskUtil.applyMaskPenaltyRule4(matrix));
  });

  // See mask patterns on the page 43 of JISX0510:2004.
  test('testGetDataMaskBit', () {
    final mask0 = [
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
    ];
    assert(testGetDataMaskBitInternal(0, mask0));
    final mask1 = [
      [1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0],
    ];
    assert(testGetDataMaskBitInternal(1, mask1));
    final mask2 = [
      [1, 0, 0, 1, 0, 0],
      [1, 0, 0, 1, 0, 0],
      [1, 0, 0, 1, 0, 0],
      [1, 0, 0, 1, 0, 0],
      [1, 0, 0, 1, 0, 0],
      [1, 0, 0, 1, 0, 0],
    ];
    assert(testGetDataMaskBitInternal(2, mask2));
    final mask3 = [
      [1, 0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0, 1],
      [0, 1, 0, 0, 1, 0],
      [1, 0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0, 1],
      [0, 1, 0, 0, 1, 0],
    ];
    assert(testGetDataMaskBitInternal(3, mask3));
    final mask4 = [
      [1, 1, 1, 0, 0, 0],
      [1, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 1],
      [0, 0, 0, 1, 1, 1],
      [1, 1, 1, 0, 0, 0],
      [1, 1, 1, 0, 0, 0],
    ];
    assert(testGetDataMaskBitInternal(4, mask4));
    final mask5 = [
      [1, 1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0, 0],
      [1, 0, 0, 1, 0, 0],
      [1, 0, 1, 0, 1, 0],
      [1, 0, 0, 1, 0, 0],
      [1, 0, 0, 0, 0, 0],
    ];
    assert(testGetDataMaskBitInternal(5, mask5));
    final mask6 = [
      [1, 1, 1, 1, 1, 1],
      [1, 1, 1, 0, 0, 0],
      [1, 1, 0, 1, 1, 0],
      [1, 0, 1, 0, 1, 0],
      [1, 0, 1, 1, 0, 1],
      [1, 0, 0, 0, 1, 1],
    ];
    assert(testGetDataMaskBitInternal(6, mask6));
    final mask7 = [
      [1, 0, 1, 0, 1, 0],
      [0, 0, 0, 1, 1, 1],
      [1, 0, 0, 0, 1, 1],
      [0, 1, 0, 1, 0, 1],
      [1, 1, 1, 0, 0, 0],
      [0, 1, 1, 1, 0, 0],
    ];
    assert(testGetDataMaskBitInternal(7, mask7));
  });
}

bool testGetDataMaskBitInternal(int maskPattern, List<List<int>> expected) {
  for (int x = 0; x < 6; ++x) {
    for (int y = 0; y < 6; ++y) {
      if ((expected[y][x] == 1) != MaskUtil.getDataMaskBit(maskPattern, x, y)) {
        return false;
      }
    }
  }
  return true;
}
