/*
 * Copyright 2011 ZXing authors
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
 * @author dsbnatut@gmail.com (Kazuki Nishiura)
 * @author Sean Owen
 */
void main(){


  BitMatrix encode(String input) {
    return new CodaBarWriter().encode(input, BarcodeFormat.CODABAR, 0, 0);
  }
  void doTest(String input, String expected) {
    BitMatrix result = encode(input);
    expect(expected, matrixToString(result));
  }
  test('testEncode', () {
    doTest("B515-3/B",
           "00000" +
           "1001001011" + "0110101001" + "0101011001" + "0110101001" + "0101001101" +
           "0110010101" + "01101101011" + "01001001011" +
           "00000");
  });

  test('testEncode2', () {
    doTest("T123T",
           "00000" +
           "1011001001" + "0101011001" + "0101001011" + "0110010101" + "01011001001" +
           "00000");
  });

  test('testAltStartEnd', () {
    expect(encode(r"T123456789-$T"), encode(r"A123456789-$A"));
  });

}
