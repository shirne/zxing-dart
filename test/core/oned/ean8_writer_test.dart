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
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../utils.dart';


void main(){

  test('testEncode', () {
    String testStr = "0000001010001011010111101111010110111010101001110111001010001001011100101000000";
    BitMatrix result = EAN8Writer().encode("96385074", BarcodeFormat.EAN_8, testStr.length, 0);
    expect(testStr, matrixToString(result));
  });

  test('testAddChecksumAndEncode', () {
    String testStr = "0000001010001011010111101111010110111010101001110111001010001001011100101000000";
    BitMatrix result = EAN8Writer().encode("9638507", BarcodeFormat.EAN_8, testStr.length, 0);
    expect(testStr, matrixToString(result));
  });

  //@Test(expected = IllegalArgumentException.class)
  test('testEncodeIllegalCharacters', () {
    try {
      EAN8Writer().encode("96385abc", BarcodeFormat.EAN_8, 0, 0);
      fail('Should throw ArgumentError');
    } on ArgumentError catch(_){
      // passed
    }
  });
}
