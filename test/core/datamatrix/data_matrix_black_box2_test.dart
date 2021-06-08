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
import 'package:zxing_lib/zxing.dart';

import '../common/abstract_black_box.dart';

/// @author dswitkin@google.com (Daniel Switkin)
void main(){

  test('DataMatrixBlackBox2TestCase', () {
    AbstractBlackBoxTestCase("test/resources/blackbox/datamatrix-2", new MultiFormatReader(), BarcodeFormat.DATA_MATRIX)
    ..addTest(13, 13, 0.0, 0, 1, )
    ..addTest(15, 15, 90.0, 0, 1, )
    ..addTest(17, 16, 180.0, 0, 1)
    ..addTest(15, 15, 270.0, 0, 1)
        ..testBlackBox();
  });

}
