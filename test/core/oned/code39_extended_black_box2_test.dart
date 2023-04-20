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
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../common/abstract_black_box.dart';

void main() {
  test('Code39ExtendedBlackBox2TestCase', () {
    AbstractBlackBoxTestCase(
      'test/resources/blackbox/code39-2',
      Code39Reader(false, true),
      BarcodeFormat.code39,
    )
      ..addTest(2, 2, 0.0)
      ..addTest(2, 2, 180.0)
      ..testBlackBox();
  });
}
