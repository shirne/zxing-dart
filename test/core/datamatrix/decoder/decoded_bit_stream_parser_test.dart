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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/datamatrix.dart';

void main() {
  test('testAsciiStandardDecode', () {
    // ASCII characters 0-127 are encoded as the value + 1
    Uint8List bytes = Uint8List.fromList([
      (97 /* a */ + 1),
      (98 /* b */ + 1),
      (99 /* c */ + 1),
      (65 /* A */ + 1),
      (66 /* B */ + 1),
      (67 /* C */ + 1)
    ]);
    String decodedString = DecodedBitStreamParser.decode(bytes).text;
    expect("abcABC", decodedString);
  });

  test('testAsciiDoubleDigitDecode', () {
    // ASCII double digit (00 - 99) Numeric Value + 130
    Uint8List bytes = Uint8List.fromList([
      130,
      (1 + 130),
      (98 + 130),
      (99 + 130),
    ]);
    String decodedString = DecodedBitStreamParser.decode(bytes).text;
    expect("00019899", decodedString);
  });

  // TODO(bbrown): Add test cases for each encoding type
  // TODO(bbrown): Add test cases for switching encoding types
}
