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

import '../../common/bit_source_builder.dart';

/// Tests [DecodedBitStreamParser].
///
void main() {
  test('testSimpleByteMode', () {
    BitSourceBuilder builder = BitSourceBuilder();
    builder.write(0x04, 4); // Byte mode
    builder.write(0x03, 8); // 3 bytes
    builder.write(0xF1, 8);
    builder.write(0xF2, 8);
    builder.write(0xF3, 8);
    String result = DecodedBitStreamParser.decode(
            builder.toByteArray(), Version.getVersionForNumber(1), null, null)
        .text;
    expect(result, "\u00f1\u00f2\u00f3");
  });

  test('testSimpleSJIS', () {
    BitSourceBuilder builder = BitSourceBuilder();
    builder.write(0x04, 4); // Byte mode
    builder.write(0x04, 8); // 4 bytes
    builder.write(0xA1, 8);
    builder.write(0xA2, 8);
    builder.write(0xA3, 8);
    builder.write(0xD0, 8);
    String result = DecodedBitStreamParser.decode(
            builder.toByteArray(), Version.getVersionForNumber(1), null, null)
        .text;
    expect("\uff61\uff62\uff63\uff90", result);
  });

  test('testECI', () {
    BitSourceBuilder builder = BitSourceBuilder();
    builder.write(0x07, 4); // ECI mode
    builder.write(0x02, 8); // ECI 2 = CP437 encoding
    builder.write(0x04, 4); // Byte mode
    builder.write(0x03, 8); // 3 bytes
    builder.write(0xA1, 8);
    builder.write(0xA2, 8);
    builder.write(0xA3, 8);
    String result = DecodedBitStreamParser.decode(
            builder.toByteArray(), Version.getVersionForNumber(1), null, null)
        .text;
    expect(result, "\u00ed\u00f3\u00fa");
  });

  test('testHanzi', () {
    BitSourceBuilder builder = BitSourceBuilder();
    builder.write(0x0D, 4); // Hanzi mode
    builder.write(0x01, 4); // Subset 1 = GB2312 encoding
    builder.write(0x01, 8); // 1 characters
    builder.write(0x03C1, 13);
    String result = DecodedBitStreamParser.decode(
            builder.toByteArray(), Version.getVersionForNumber(1), null, null)
        .text;
    expect("\u963f", result);
  });

  test('testHanziLevel1', () {
    BitSourceBuilder builder = BitSourceBuilder();
    builder.write(0x0D, 4); // Hanzi mode
    builder.write(0x01, 4); // Subset 1 = GB2312 encoding
    builder.write(0x01, 8); // 1 characters
    // A5A2 (U+30A2) => A5A2 - A1A1 = 401, 4*60 + 01 = 0181
    builder.write(0x0181, 13);
    String result = DecodedBitStreamParser.decode(
            builder.toByteArray(), Version.getVersionForNumber(1), null, null)
        .text;
    expect("\u30a2", result);
  });

  // TODO definitely need more tests here
}
