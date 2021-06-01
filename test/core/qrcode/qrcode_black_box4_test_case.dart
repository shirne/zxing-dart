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







import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/zxing.dart';

import '../common/abstract_black_box.dart';
import '../common/abstract_black_box_test_case.dart';

/**
 * Tests of various QR Codes from t-shirts, which are notoriously not flat.
 *
 * @author dswitkin@google.com (Daniel Switkin)
 */
void main(){

  AbstractBlackBoxTestCase testCase = AbstractBlackBoxTestCase("src/test/resources/blackbox/qrcode-4", new MultiFormatReader(), BarcodeFormat.QR_CODE);
  test('QRCodeBlackBox4TestCase', () {
    testCase.addTest(36, 36, 0.0);
    testCase.addTest(35, 35, 90.0);
    testCase.addTest(35, 35, 180.0);
    testCase.addTest(35, 35, 270.0);
  });

}
