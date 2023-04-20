/*
 * Copyright 2007 ZXing authors
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
  const int maskedTestFormatInfo = 0x2BED;
  const int unmaskedTestFormatInfo = maskedTestFormatInfo ^ 0x5412;

  test('testBitsDiffering', () {
    expect(0, FormatInformation.numBitsDiffering(1, 1));
    expect(1, FormatInformation.numBitsDiffering(0, 2));
    expect(2, FormatInformation.numBitsDiffering(1, 2));
    expect(32, FormatInformation.numBitsDiffering(-1, 0));
  });

  test('testDecode', () {
    // Normal case
    final expected = FormatInformation.decodeFormatInformation(
      maskedTestFormatInfo,
      maskedTestFormatInfo,
    );
    assert(expected != null);
    expect(0x07, expected!.dataMask);
    expect(ErrorCorrectionLevel.Q, expected.errorCorrectionLevel);
    // where the code forgot the mask!
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        unmaskedTestFormatInfo,
        maskedTestFormatInfo,
      ),
    );
  });

  test('testDecodeWithBitDifference', () {
    final expected = FormatInformation.decodeFormatInformation(
      maskedTestFormatInfo,
      maskedTestFormatInfo,
    );
    // 1,2,3,4 bits difference
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        maskedTestFormatInfo ^ 0x01,
        maskedTestFormatInfo ^ 0x01,
      ),
    );
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        maskedTestFormatInfo ^ 0x03,
        maskedTestFormatInfo ^ 0x03,
      ),
    );
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        maskedTestFormatInfo ^ 0x07,
        maskedTestFormatInfo ^ 0x07,
      ),
    );
    assert(
      FormatInformation.decodeFormatInformation(
            maskedTestFormatInfo ^ 0x0F,
            maskedTestFormatInfo ^ 0x0F,
          ) ==
          null,
    );
  });

  test('testDecodeWithMisread', () {
    final expected = FormatInformation.decodeFormatInformation(
      maskedTestFormatInfo,
      maskedTestFormatInfo,
    );
    expect(
      expected,
      FormatInformation.decodeFormatInformation(
        maskedTestFormatInfo ^ 0x03,
        maskedTestFormatInfo ^ 0x0F,
      ),
    );
  });
}
