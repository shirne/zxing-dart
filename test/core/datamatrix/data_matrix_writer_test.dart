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
import 'package:zxing_lib/datamatrix.dart';
import 'package:zxing_lib/zxing.dart';

void main() {
  test('testSpecial', () {
    final writer = DataMatrixWriter();
    final encode = writer.encode(
        'FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7FR03AV011E7F1E7',
        BarcodeFormat.dataMatrix,
        52,
        52, {
      EncodeHintType.dataMatrixShape: SymbolShapeHint.forceSquare,

      // ignore: deprecated_member_use_from_same_package
      EncodeHintType.minSize: Dimension(52, 52),
    });
    expect(encode.get(0, 0), true);
  });

  test('testDataMatrixImageWriter', () {
    final hints = <EncodeHintType, Object>{};
    hints[EncodeHintType.dataMatrixShape] = SymbolShapeHint.forceSquare;

    final bigEnough = 64;
    final writer = DataMatrixWriter();
    final matrix = writer.encode(
      'Hello Google',
      BarcodeFormat.dataMatrix,
      bigEnough,
      bigEnough,
      hints,
    );

    //assert(matrix != null);
    assert(bigEnough >= matrix.width);
    assert(bigEnough >= matrix.height);
  });

  test('testDataMatrixWriter', () {
    final hints = <EncodeHintType, Object>{};
    hints[EncodeHintType.dataMatrixShape] = SymbolShapeHint.forceSquare;

    const bigEnough = 14;
    final writer = DataMatrixWriter();
    final matrix = writer.encode(
      'Hello Me',
      BarcodeFormat.dataMatrix,
      bigEnough,
      bigEnough,
      hints,
    );
    //assertNotNull(matrix);
    expect(bigEnough, matrix.width);
    expect(bigEnough, matrix.height);
  });

  test('testDataMatrixTooSmall', () {
    // The DataMatrix will not fit in this size, so the matrix should come back bigger
    const tooSmall = 8;
    final writer = DataMatrixWriter();
    final matrix = writer.encode(
      'http://www.google.com/',
      BarcodeFormat.dataMatrix,
      tooSmall,
      tooSmall,
      null,
    );
    //assertNotNull(matrix);
    assert(tooSmall < matrix.width);
    assert(tooSmall < matrix.height);
  });
}
