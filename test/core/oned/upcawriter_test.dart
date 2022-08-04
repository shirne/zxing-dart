/*
 * Copyright 2010 ZXing authors
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
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../utils.dart';

void main() {
  test('testEncode', () {
    final testStr = '00001010100011011011101100010001011010111101111010'
        '101011100101110100100111011001101101100101110010100000';
    final result = UPCAWriter()
        .encode('485963095124', BarcodeFormat.UPC_A, testStr.length, 0);
    expect(testStr, matrixToString(result));
  });

  test('testAddChecksumAndEncode', () {
    final testStr = '000010100110010010011011110101000110110001010111101010'
        '10001001001000111010011100101100110110110010100000';
    final result = UPCAWriter()
        .encode('12345678901', BarcodeFormat.UPC_A, testStr.length, 0);
    expect(testStr, matrixToString(result));
  });
}
