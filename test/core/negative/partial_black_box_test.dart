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

import 'dart:typed_data';

import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../common/abstract_negative_black_box.dart';

/// This test ensures that partial barcodes do not decode.
///
void main() {
  // todo 11.png may pass because of https://github.com/zxing/zxing/issues/1400
  test('PartialBlackBoxTestCase', () {
    AbstractNegativeBlackBoxTestCase('test/resources/blackbox/partial')
      ..addNegativeTest(2, 0.0)
      ..addNegativeTest(2, 90.0)
      ..addNegativeTest(2, 180.0)
      ..addNegativeTest(2, 270.0)
      ..testBlackBox();
  });

  // for UPCEANReader.decodeDigit bug (https://github.com/zxing/zxing/issues/1400)
  test('p11Test', () {
    Result? result;
    final row = BitArray.test(
        Uint32List.fromList([
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          -33570816,
          118,
          0,
          0,
          946064924,
          -2026257522,
          955253639,
          124828,
          0,
          0,
          0,
          0
        ]),
        640);
    try {
      result =
          UPCEReader().decodeRow(128, row, {DecodeHintType.TRY_HARDER: true});
      print(result);
    } on ChecksumException catch (_) {
      //pass
    }
  });
}
