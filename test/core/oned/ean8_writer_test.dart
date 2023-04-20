/*
 * Copyright 2009 ZXing authors
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
    final testStr =
        '0000001010001011010111101111010110111010101001110111001010001001011100101000000';
    final result =
        EAN8Writer().encode('96385074', BarcodeFormat.ean8, testStr.length, 0);
    expect(testStr, matrixToString(result));
  });

  test('testAddChecksumAndEncode', () {
    final testStr =
        '0000001010001011010111101111010110111010101001110111001010001001011100101000000';
    final result =
        EAN8Writer().encode('9638507', BarcodeFormat.ean8, testStr.length, 0);
    expect(testStr, matrixToString(result));
  });

  test('testEncodeIllegalCharacters', () {
    expect(
      () => EAN8Writer().encode('96385abc', BarcodeFormat.ean8, 0, 0),
      throwsArgumentError,
      reason: 'Should throw ArgumentError',
    );
  });
}
