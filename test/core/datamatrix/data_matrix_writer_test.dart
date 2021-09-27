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
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/datamatrix.dart';
import 'package:zxing_lib/zxing.dart';

void main() {
  test('testSpecial', () {
    DataMatrixWriter writer = DataMatrixWriter();
    var encode = writer.encode(
        'FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7',
        BarcodeFormat.DATA_MATRIX,
        52,
        52, {
      EncodeHintType.DATA_MATRIX_SHAPE: SymbolShapeHint.FORCE_SQUARE,

      // ignore: deprecated_consistency
      EncodeHintType.MIN_SIZE: Dimension(52, 52)
    });
    expect(encode.get(0, 0), true);
  });

  test('testDataMatrixImageWriter', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.DATA_MATRIX_SHAPE] = SymbolShapeHint.FORCE_SQUARE;

    int bigEnough = 64;
    DataMatrixWriter writer = DataMatrixWriter();
    BitMatrix matrix = writer.encode(
        "Hello Google", BarcodeFormat.DATA_MATRIX, bigEnough, bigEnough, hints);

    //assert(matrix != null);
    assert(bigEnough >= matrix.width);
    assert(bigEnough >= matrix.height);
  });

  test('testDataMatrixWriter', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.DATA_MATRIX_SHAPE] = SymbolShapeHint.FORCE_SQUARE;

    int bigEnough = 14;
    DataMatrixWriter writer = DataMatrixWriter();
    BitMatrix matrix = writer.encode(
        "Hello Me", BarcodeFormat.DATA_MATRIX, bigEnough, bigEnough, hints);
    //assertNotNull(matrix);
    expect(bigEnough, matrix.width);
    expect(bigEnough, matrix.height);
  });

  test('testDataMatrixTooSmall', () {
    // The DataMatrix will not fit in this size, so the matrix should come back bigger
    int tooSmall = 8;
    DataMatrixWriter writer = DataMatrixWriter();
    BitMatrix matrix = writer.encode("http://www.google.com/",
        BarcodeFormat.DATA_MATRIX, tooSmall, tooSmall, null);
    //assertNotNull(matrix);
    assert(tooSmall < matrix.width);
    assert(tooSmall < matrix.height);
  });
}
