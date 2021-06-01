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









import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/common.dart';
import 'package:zxing/oned.dart';
import 'package:zxing/zxing.dart';

import '../utils.dart';

/// @author Ari Pollak
void main(){

  test('testEncode', () {
    String testStr = "00001010001011010011101100110010011011110100111010101011001101101100100001010111001001110100010010100000";
    BitMatrix result = new EAN13Writer().encode("5901234123457", BarcodeFormat.EAN_13, testStr.length, 0);
    expect(testStr, matrixToString(result));
  });

  test('testAddChecksumAndEncode', () {
    String testStr = "00001010001011010011101100110010011011110100111010101011001101101100100001010111001001110100010010100000";
    BitMatrix result = new EAN13Writer().encode("590123412345", BarcodeFormat.EAN_13, testStr.length, 0);
    expect(testStr, matrixToString(result));
  });

  //@Test(expected = IllegalArgumentException.class)
  test('testEncodeIllegalCharacters', () {
    try {
      new EAN13Writer().encode("5901234123abc", BarcodeFormat.EAN_13, 0, 0);
      assert(false);
    }catch(_){
      // passed
    }
  });
}
