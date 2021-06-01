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

/**
 * @author dswitkin@google.com (Daniel Switkin)
 */
void main(){

  test('UPCABlackBox3ReflectiveTestCase', () {
    AbstractBlackBoxTestCase("src/test/resources/blackbox/upca-3", new MultiFormatReader(), BarcodeFormat.UPC_A)
    ..addTest(7, 9, 0.0, 0, 2)
    ..addTest(8, 9, 180.0, 0, 2)
    ..testBlackBox();
  });

}
