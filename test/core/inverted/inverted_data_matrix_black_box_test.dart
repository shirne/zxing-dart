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

import 'package:test/scaffolding.dart';
import 'package:zxing_lib/zxing.dart';

import '../common/abstract_black_box.dart';

/// Inverted barcodes
void main() {
  test('InvertedDataMatrixBlackBoxTestCase', () {
    AbstractBlackBoxTestCase('test/resources/blackbox/inverted',
        MultiFormatReader(), BarcodeFormat.DATA_MATRIX)
      ..addHint(DecodeHintType.ALSO_INVERTED)
      ..addTest(1, 1, 0.0)
      ..addTest(1, 1, 90.0)
      ..addTest(1, 1, 180.0)
      ..addTest(1, 1, 270.0)
      ..testBlackBox();
  });
}
