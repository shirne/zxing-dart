/*
 * Copyright 2016 ZXing authors
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
import 'package:zxing/oned.dart';
import 'package:zxing/zxing.dart';

import '../utils.dart';

/**
 * Tests {@link UPCEWriter}.
 */
void main(){

  void doTest(String content, String encoding) {
    BitMatrix result = new UPCEWriter().encode(content, BarcodeFormat.UPC_E, encoding.length, 0);
    expect(encoding, matrixToString(result));
  }

  test('testEncode', () {
    doTest("05096893",
           "0000000000010101110010100111000101101011110110111001011101010100000000000");
  });

  test('testEncodeSystem1', () {
    doTest("12345670",
           "0000000000010100100110111101010001101110010000101001000101010100000000000");
  });

  test('testAddChecksumAndEncode', () {
    doTest("0509689",
           "0000000000010101110010100111000101101011110110111001011101010100000000000");
  });

  //@Test(expected = IllegalArgumentException.class)
  test('testEncodeIllegalCharacters', () {
    try {
      new UPCEWriter().encode("05096abc", BarcodeFormat.UPC_E, 0, 0);
      assert(false);
    }catch(_){
      // passed
    }
  });
}
