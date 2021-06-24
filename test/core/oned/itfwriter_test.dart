/*
 * Copyright 2017 ZXing authors
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
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../utils.dart';

/// Tests [ITFWriter].
void main() {
  void doTest(String input, String expected) {
    BitMatrix result = ITFWriter().encode(input, BarcodeFormat.ITF, 0, 0);
    expect(expected, matrixToString(result));
  }

  test('testEncode', () {
    doTest(
        "00123456789012",
        "0000010101010111000111000101110100010101110001110111010001010001110100011" +
            "100010101000101011100011101011101000111000101110100010101110001110100000");
  });

  //@Test(expected = IllegalArgumentException.class)
  test('testEncodeIllegalCharacters', () {
    try {
      ITFWriter().encode("00123456789abc", BarcodeFormat.ITF, 0, 0);
      fail('should thrown ArgumentError');
    } catch (_) {
      // passed
    }
  });
}
