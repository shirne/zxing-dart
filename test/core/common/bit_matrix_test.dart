/*
 * Copyright 2007 ZXing authors
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
import 'package:zxing_lib/common.dart';

void main() {
  const List<int> bitMatrixPoints = [1, 2, 2, 0, 3, 1];

  BitMatrix getExpected(int width, int height) {
    final result = BitMatrix(width, height);
    for (int i = 0; i < bitMatrixPoints.length; i += 2) {
      result.set(
        width - 1 - bitMatrixPoints[i],
        height - 1 - bitMatrixPoints[i + 1],
      );
    }
    return result;
  }

  BitMatrix getInput(int width, int height) {
    final result = BitMatrix(width, height);
    for (int i = 0; i < bitMatrixPoints.length; i += 2) {
      result.set(bitMatrixPoints[i], bitMatrixPoints[i + 1]);
    }
    return result;
  }

  void testXOR(
    BitMatrix dataMatrix,
    BitMatrix flipMatrix,
    BitMatrix expectedMatrix,
  ) {
    final matrix = dataMatrix.clone();
    matrix.xor(flipMatrix);
    assert(expectedMatrix == matrix);
  }

  void testRotate180(int width, int height) {
    final input = getInput(width, height);
    input.rotate180();
    final expected = getExpected(width, height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        expect(expected.get(x, y), input.get(x, y), reason: '($x,$y)');
      }
    }
  }

  test('testGetSet', () {
    final matrix = BitMatrix(33);
    expect(33, matrix.height);
    for (int y = 0; y < 33; y++) {
      for (int x = 0; x < 33; x++) {
        if (y * x % 3 == 0) {
          matrix.set(x, y);
        }
      }
    }
    for (int y = 0; y < 33; y++) {
      for (int x = 0; x < 33; x++) {
        expect(y * x % 3 == 0, matrix.get(x, y));
      }
    }
  });

  test('testSetRegion', () {
    final matrix = BitMatrix(5);
    matrix.setRegion(1, 1, 3, 3);
    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 5; x++) {
        expect(y >= 1 && y <= 3 && x >= 1 && x <= 3, matrix.get(x, y));
      }
    }
  });

  test('testEnclosing', () {
    final matrix = BitMatrix(5);
    assert(matrix.getEnclosingRectangle() == null);
    matrix.setRegion(1, 1, 1, 1);
    print(matrix.data.toList().map((a) => a.toRadixString(2)));
    expect([1, 1, 1, 1], matrix.getEnclosingRectangle());
    matrix.setRegion(1, 1, 3, 2);
    expect([1, 1, 3, 2], matrix.getEnclosingRectangle());
    matrix.setRegion(0, 0, 5, 5);
    expect([0, 0, 5, 5], matrix.getEnclosingRectangle());
  });

  test('testOnBit', () {
    final matrix = BitMatrix(5);
    assert(matrix.getTopLeftOnBit() == null);
    assert(matrix.getBottomRightOnBit() == null);
    matrix.setRegion(1, 1, 1, 1);
    expect([1, 1], matrix.getTopLeftOnBit());
    expect([1, 1], matrix.getBottomRightOnBit());
    matrix.setRegion(1, 1, 3, 2);
    expect([1, 1], matrix.getTopLeftOnBit());
    expect([3, 2], matrix.getBottomRightOnBit());
    matrix.setRegion(0, 0, 5, 5);
    expect([0, 0], matrix.getTopLeftOnBit());
    expect([4, 4], matrix.getBottomRightOnBit());
  });

  test('testRectangularMatrix', () {
    final matrix = BitMatrix(75, 20);
    expect(75, matrix.width);
    expect(20, matrix.height);
    matrix.set(10, 0);
    matrix.set(11, 1);
    matrix.set(50, 2);
    matrix.set(51, 3);
    matrix.flip(74, 4);
    matrix.flip(0, 5);

    // Should all be on
    assert(matrix.get(10, 0));
    assert(matrix.get(11, 1));
    assert(matrix.get(50, 2));
    assert(matrix.get(51, 3));
    assert(matrix.get(74, 4));
    assert(matrix.get(0, 5));

    // Flip a couple back off
    matrix.flip(50, 2);
    matrix.flip(51, 3);
    assert(!matrix.get(50, 2));
    assert(!matrix.get(51, 3));
  });

  test('testRectangularSetRegion', () {
    final matrix = BitMatrix(320, 240);
    expect(320, matrix.width);
    expect(240, matrix.height);
    matrix.setRegion(105, 22, 80, 12);

    // Only bits in the region should be on
    for (int y = 0; y < 240; y++) {
      for (int x = 0; x < 320; x++) {
        expect(y >= 22 && y < 34 && x >= 105 && x < 185, matrix.get(x, y));
      }
    }
  });

  test('testGetRow', () {
    final matrix = BitMatrix(102, 5);
    for (int x = 0; x < 102; x++) {
      if ((x & 0x03) == 0) {
        matrix.set(x, 2);
      }
    }

    // Should allocate
    final array = matrix.getRow(2, null);
    expect(102, array.size);

    // Should reallocate
    BitArray array2 = BitArray(60);
    array2 = matrix.getRow(2, array2);
    expect(102, array2.size);

    // Should use provided object, with original BitArray size
    BitArray array3 = BitArray(200);
    array3 = matrix.getRow(2, array3);
    expect(200, array3.size);

    for (int x = 0; x < 102; x++) {
      final isOn = (x & 0x03) == 0;
      expect(isOn, array[x]);
      expect(isOn, array2[x]);
      expect(isOn, array3[x]);
    }
  });

  test('testRotate90Simple', () {
    final matrix = BitMatrix(3, 3);
    matrix.set(0, 0);
    matrix.set(0, 1);
    matrix.set(1, 2);
    matrix.set(2, 1);

    matrix.rotate90();

    assert(matrix.get(0, 2));
    assert(matrix.get(1, 2));
    assert(matrix.get(2, 1));
    assert(matrix.get(1, 0));
  });

  test('testRotate180Simple', () {
    final matrix = BitMatrix(3, 3);
    matrix.set(0, 0);
    matrix.set(0, 1);
    matrix.set(1, 2);
    matrix.set(2, 1);

    matrix.rotate180();

    assert(matrix.get(2, 2));
    assert(matrix.get(2, 1));
    assert(matrix.get(1, 0));
    assert(matrix.get(0, 1));
  });

  test('testRotate180', () {
    testRotate180(7, 4);
    testRotate180(7, 5);
    testRotate180(8, 4);
    testRotate180(8, 5);
  });

  test('testParse', () {
    final emptyMatrix = BitMatrix(3, 3);
    final fullMatrix = BitMatrix(3, 3);
    fullMatrix.setRegion(0, 0, 3, 3);
    final centerMatrix = BitMatrix(3, 3);
    centerMatrix.setRegion(1, 1, 1, 1);
    final emptyMatrix24 = BitMatrix(2, 4);

    expect(BitMatrix.parse('   \n   \n   \n', 'x', ' '), emptyMatrix);
    expect(BitMatrix.parse('   \n   \r\r\n   \n\r', 'x', ' '), emptyMatrix);
    expect(BitMatrix.parse('   \n   \n   ', 'x', ' '), emptyMatrix);

    expect(BitMatrix.parse('xxx\nxxx\nxxx\n', 'x', ' '), fullMatrix);

    expect(BitMatrix.parse('   \n x \n   \n', 'x', ' '), centerMatrix);
    expect(
      BitMatrix.parse('      \n  x   \n      \n', 'x ', '  '),
      centerMatrix,
    );
    expect(
      () => BitMatrix.parse('   \n xy\n   \n', 'x', ' '),
      throwsArgumentError,
    );

    expect(BitMatrix.parse('  \n  \n  \n  \n', 'x', ' '), emptyMatrix24);

    expect(
      BitMatrix.parse(centerMatrix.toString('x', '.'), 'x', '.'),
      centerMatrix,
    );
  });

  test('testParseBoolean', () {
    final emptyMatrix = BitMatrix(3, 3);
    final fullMatrix = BitMatrix(3, 3);
    fullMatrix.setRegion(0, 0, 3, 3);
    final centerMatrix = BitMatrix(3, 3);
    centerMatrix.setRegion(1, 1, 1, 1);

    final matrix = List.generate(3, (index) => List.filled(3, false));
    assert(emptyMatrix == BitMatrix.parse(matrix));
    matrix[1][1] = true;
    assert(centerMatrix == BitMatrix.parse(matrix));
    for (List<bool> arr in matrix) {
      arr.fillRange(0, arr.length, true);
      // Arrays.fill(arr, true);
    }
    assert(fullMatrix == BitMatrix.parse(matrix));
  });

  test('testUnset', () {
    final emptyMatrix = BitMatrix(3, 3);
    final matrix = emptyMatrix.clone();
    matrix.set(1, 1);
    assert(emptyMatrix != matrix);
    matrix.unset(1, 1);
    assert(emptyMatrix == matrix);
    matrix.unset(1, 1);
    assert(emptyMatrix == matrix);
  });

  test('testXOR', () {
    final emptyMatrix = BitMatrix(3, 3);
    final fullMatrix = BitMatrix(3, 3);
    fullMatrix.setRegion(0, 0, 3, 3);
    final centerMatrix = BitMatrix(3, 3);
    centerMatrix.setRegion(1, 1, 1, 1);
    final invertedCenterMatrix = fullMatrix.clone();
    invertedCenterMatrix.unset(1, 1);
    final badMatrix = BitMatrix(4, 4);

    testXOR(emptyMatrix, emptyMatrix, emptyMatrix);
    testXOR(emptyMatrix, centerMatrix, centerMatrix);
    testXOR(emptyMatrix, fullMatrix, fullMatrix);

    testXOR(centerMatrix, emptyMatrix, centerMatrix);
    testXOR(centerMatrix, centerMatrix, emptyMatrix);
    testXOR(centerMatrix, fullMatrix, invertedCenterMatrix);

    testXOR(invertedCenterMatrix, emptyMatrix, invertedCenterMatrix);
    testXOR(invertedCenterMatrix, centerMatrix, fullMatrix);
    testXOR(invertedCenterMatrix, fullMatrix, centerMatrix);

    testXOR(fullMatrix, emptyMatrix, fullMatrix);
    testXOR(fullMatrix, centerMatrix, invertedCenterMatrix);
    testXOR(fullMatrix, fullMatrix, emptyMatrix);

    expect(() => emptyMatrix.clone().xor(badMatrix), throwsArgumentError);
    expect(() => badMatrix.clone().xor(emptyMatrix), throwsArgumentError);
  });
}
