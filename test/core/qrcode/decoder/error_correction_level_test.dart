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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/qrcode.dart';

void main() {
  test('testForBits', () {
    expect(ErrorCorrectionLevel.M, ErrorCorrectionLevel.values[0]);
    expect(ErrorCorrectionLevel.L, ErrorCorrectionLevel.values[1]);
    expect(ErrorCorrectionLevel.H, ErrorCorrectionLevel.values[2]);
    expect(ErrorCorrectionLevel.Q, ErrorCorrectionLevel.values[3]);
  });

  //@Test(expected = IllegalArgumentException.class)
  test('testBadECLevel', () {
    try {
      ErrorCorrectionLevel.values[4];
    } catch (_) {
      // passed
    }
  });
}
