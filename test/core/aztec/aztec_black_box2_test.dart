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
import 'package:zxing/aztec.dart';
import 'package:zxing/zxing.dart';

import '../common/abstract_black_box.dart';

/// A test of Aztec barcodes under real world lighting conditions, taken with a mobile phone.
///
/// @author dswitkin@google.com (Daniel Switkin)
void main(){

  test('AztecBlackBox2TestCase', () {
    AbstractBlackBoxTestCase("test/resources/blackbox/aztec-2", new AztecReader(), BarcodeFormat.AZTEC)
    ..addTest(5, 5, 0.0)
    ..addTest(4, 4, 90.0)
    ..addTest(6, 6, 180.0)
    ..addTest(3, 3, 270.0)
        ..testBlackBox();
  });

}