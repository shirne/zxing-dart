/*
 * Copyright (C) 2014 ZXing authors
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

import 'dart:convert';

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/pdf417.dart';

/// Tests [PDF417HighLevelEncoder].
void main() {
  test('testEncodeAuto', () {
    String encoded = PDF417HighLevelEncoder.encodeHighLevel(
        "ABCD", Compaction.AUTO, utf8, false);
    expect("\u039f\u001A\u0385ABCD", encoded);
  });

  test('testEncodeAutoWithSpecialChars', () {
    // Just check if this does not throw an exception
    PDF417HighLevelEncoder.encodeHighLevel(
        r"1%§s ?aG$", Compaction.AUTO, utf8, false);
  });

  test('testEncodeIso88591WithSpecialChars', () {
    // Just check if this does not throw an exception
    PDF417HighLevelEncoder.encodeHighLevel(
        "asdfg§asd", Compaction.AUTO, latin1, false);
  });

  test('testEncodeText', () {
    String encoded = PDF417HighLevelEncoder.encodeHighLevel(
        "ABCD", Compaction.TEXT, utf8, false);
    expect("Ο\u001A\u0001?", encoded);
  });

  test('testEncodeNumeric', () {
    String encoded = PDF417HighLevelEncoder.encodeHighLevel(
        "1234", Compaction.NUMERIC, utf8, false);
    expect("\u039f\u001A\u0386\f\u01b2", encoded);
  });

  test('testEncodeByte', () {
    String encoded = PDF417HighLevelEncoder.encodeHighLevel(
        "abcd", Compaction.BYTE, utf8, false);
    expect("\u039f\u001A\u0385abcd", encoded);
  });
}
