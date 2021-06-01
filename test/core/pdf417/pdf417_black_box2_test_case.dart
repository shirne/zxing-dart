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
import 'package:zxing/zxing.dart';

import '../common/abstract_black_box.dart';


/**
 * This test contains 480x240 images captured from an Android device at preview resolution.
 *
 * @author dswitkin@google.com (Daniel Switkin)
 */
void main(){

  test('PDF417BlackBox2TestCase', () {
    AbstractBlackBoxTestCase testCase =
    AbstractBlackBoxTestCase("src/test/resources/blackbox/pdf417-2", new MultiFormatReader(), BarcodeFormat.PDF_417);
    testCase.addTest(25, 25, 0.0, 0, 0);
    testCase.addTest(25, 25, 180.0, 0, 0);
  });

}
