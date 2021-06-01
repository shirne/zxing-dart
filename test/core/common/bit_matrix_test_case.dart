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

import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/common.dart';
import 'package:zxing/zxing.dart';

import '../planar_yuvluminance_source_test_case.dart';


/// @author Sean Owen
/// @author dswitkin@google.com (Daniel Switkin)
void main() {

  final List<int> BIT_MATRIX_POINTS = [ 1, 2, 2, 0, 3, 1 ];

  BitMatrix getExpected(int width, int height) {
    BitMatrix result = new BitMatrix(width, height);
    for (int i = 0; i < BIT_MATRIX_POINTS.length; i += 2) {
      result.set(width - 1 - BIT_MATRIX_POINTS[i], height - 1 - BIT_MATRIX_POINTS[i + 1]);
    }
    return result;
  }

  BitMatrix getInput(int width, int height) {
    BitMatrix result = new BitMatrix(width, height);
    for (int i = 0; i < BIT_MATRIX_POINTS.length; i += 2) {
      result.set(BIT_MATRIX_POINTS[i], BIT_MATRIX_POINTS[i + 1]);
    }
    return result;
  }
  


  void testXOR(BitMatrix dataMatrix, BitMatrix flipMatrix, BitMatrix expectedMatrix) {
    BitMatrix matrix = dataMatrix.clone();
    matrix.xor(flipMatrix);
    assert(expectedMatrix == matrix);
  }

  void testRotate180(int width, int height) {
    BitMatrix input = getInput(width, height);
    input.rotate180();
    BitMatrix expected = getExpected(width, height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        expect(expected.get(x, y), input.get(x, y), reason:"($x,$y)");
      }
    }
  }

  

  test('testGetSet',() {
    BitMatrix matrix = new BitMatrix(33);
    expect(33, matrix.getHeight());
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

  test('testSetRegion',() {
    BitMatrix matrix = new BitMatrix(5);
    matrix.setRegion(1, 1, 3, 3);
    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 5; x++) {
        expect(y >= 1 && y <= 3 && x >= 1 && x <= 3, matrix.get(x, y));
      }
    }
  });

  test('testEnclosing', (){
    BitMatrix matrix = new BitMatrix(5);
    assert(matrix.getEnclosingRectangle() == null);
    matrix.setRegion(1, 1, 1, 1);
    expect([ 1, 1, 1, 1 ], matrix.getEnclosingRectangle());
    matrix.setRegion(1, 1, 3, 2);
    expect([ 1, 1, 3, 2 ], matrix.getEnclosingRectangle());
    matrix.setRegion(0, 0, 5, 5);
    expect([ 0, 0, 5, 5 ], matrix.getEnclosingRectangle());
  });

  test('testOnBit', () {
    BitMatrix matrix = new BitMatrix(5);
    assert(matrix.getTopLeftOnBit() == null);
    assert(matrix.getBottomRightOnBit() == null);
    matrix.setRegion(1, 1, 1, 1);
    expect([ 1, 1 ], matrix.getTopLeftOnBit());
    expect([ 1, 1 ], matrix.getBottomRightOnBit());
    matrix.setRegion(1, 1, 3, 2);
    expect([ 1, 1 ], matrix.getTopLeftOnBit());
    expect([ 3, 2 ], matrix.getBottomRightOnBit());
    matrix.setRegion(0, 0, 5, 5);
    expect([ 0, 0 ], matrix.getTopLeftOnBit());
    expect([ 4, 4 ], matrix.getBottomRightOnBit());
  });

  test('testRectangularMatrix',() {
    BitMatrix matrix = new BitMatrix(75, 20);
    expect(75, matrix.getWidth());
    expect(20, matrix.getHeight());
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

  test('testRectangularSetRegion',() {
    BitMatrix matrix = new BitMatrix(320, 240);
    expect(320, matrix.getWidth());
    expect(240, matrix.getHeight());
    matrix.setRegion(105, 22, 80, 12);

    // Only bits in the region should be on
    for (int y = 0; y < 240; y++) {
      for (int x = 0; x < 320; x++) {
        expect(y >= 22 && y < 34 && x >= 105 && x < 185, matrix.get(x, y));
      }
    }
  });

  test('testGetRow',() {
    BitMatrix matrix = new BitMatrix(102, 5);
    for (int x = 0; x < 102; x++) {
      if ((x & 0x03) == 0) {
        matrix.set(x, 2);
      }
    }

    // Should allocate
    BitArray array = matrix.getRow(2, null);
    expect(102, array.getSize());

    // Should reallocate
    BitArray array2 = new BitArray(60);
    array2 = matrix.getRow(2, array2);
    expect(102, array2.getSize());

    // Should use provided object, with original BitArray size
    BitArray array3 = new BitArray(200);
    array3 = matrix.getRow(2, array3);
    expect(200, array3.getSize());

    for (int x = 0; x < 102; x++) {
      bool on = (x & 0x03) == 0;
      expect(on, array[x]);
      expect(on, array2[x]);
      expect(on, array3[x]);
    }
  });

  test('testRotate90Simple',() {
    BitMatrix matrix = new BitMatrix(3, 3);
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

  test('testRotate180Simple',() {
    BitMatrix matrix = new BitMatrix(3, 3);
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

  test('testRotate180',() {
    testRotate180(7, 4);
    testRotate180(7, 5);
    testRotate180(8, 4);
    testRotate180(8, 5);
  });

  test('testParse',() {
    BitMatrix emptyMatrix = new BitMatrix(3, 3);
    BitMatrix fullMatrix = new BitMatrix(3, 3);
    fullMatrix.setRegion(0, 0, 3, 3);
    BitMatrix centerMatrix = new BitMatrix(3, 3);
    centerMatrix.setRegion(1, 1, 1, 1);
    BitMatrix emptyMatrix24 = new BitMatrix(2, 4);

    assert(emptyMatrix == BitMatrix.parse("   \n   \n   \n", "x", " "));
    assert(emptyMatrix == BitMatrix.parse("   \n   \r\r\n   \n\r", "x", " "));
    assert(emptyMatrix == BitMatrix.parse("   \n   \n   ", "x", " "));

    assert(fullMatrix == BitMatrix.parse("xxx\nxxx\nxxx\n", "x", " "));

    assert(centerMatrix == BitMatrix.parse("   \n x \n   \n", "x", " "));
    assert(centerMatrix == BitMatrix.parse("      \n  x   \n      \n", "x ", "  "));
    try {
      assert(centerMatrix == BitMatrix.parse("   \n xy\n   \n", "x", " "));
      assert(false);
    } catch ( _) { // IllegalArgumentException
      // good
    }

    assert(emptyMatrix24 == BitMatrix.parse("  \n  \n  \n  \n", "x", " "));

    assert(centerMatrix == BitMatrix.parse(centerMatrix.toString("x", "."), "x", "."));
  });

  test('testParseBoolean',() {
    BitMatrix emptyMatrix = new BitMatrix(3, 3);
    BitMatrix fullMatrix = new BitMatrix(3, 3);
    fullMatrix.setRegion(0, 0, 3, 3);
    BitMatrix centerMatrix = new BitMatrix(3, 3);
    centerMatrix.setRegion(1, 1, 1, 1);
    BitMatrix emptyMatrix24 = new BitMatrix(2, 4);

    List<List<bool>> matrix = List.generate(3, (index) => List.filled(3, false));
    assert(emptyMatrix == BitMatrix.parse(matrix));
    matrix[1][1] = true;
    assert(centerMatrix == BitMatrix.parse(matrix));
    for (List<bool> arr in matrix) {
      arr.fillRange(0, arr.length, true);
      // Arrays.fill(arr, true);
    }
    assert(fullMatrix == BitMatrix.parse(matrix));
  });

  test('testUnset',() {
    BitMatrix emptyMatrix = new BitMatrix(3, 3);
    BitMatrix matrix = emptyMatrix.clone();
    matrix.set(1, 1);
    assert(emptyMatrix != matrix);
    matrix.unset(1, 1);
    assert(emptyMatrix == matrix);
    matrix.unset(1, 1);
    assert(emptyMatrix == matrix);
  });

  test('testXOR',() {
    BitMatrix emptyMatrix = new BitMatrix(3, 3);
    BitMatrix fullMatrix = new BitMatrix(3, 3);
    fullMatrix.setRegion(0, 0, 3, 3);
    BitMatrix centerMatrix = new BitMatrix(3, 3);
    centerMatrix.setRegion(1, 1, 1, 1);
    BitMatrix invertedCenterMatrix = fullMatrix.clone();
    invertedCenterMatrix.unset(1, 1);
    BitMatrix badMatrix = new BitMatrix(4, 4);

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

    try {
      emptyMatrix.clone().xor(badMatrix);
      assert(false);
    } catch ( _) { //IllegalArgumentException
      // good
    }

    try {
      badMatrix.clone().xor(emptyMatrix);
      assert(false);
    } catch ( _) {// IllegalArgumentException
      // good
    }
  });



}
