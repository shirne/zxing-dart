/*
 * Copyright 2012 ZXing authors
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
import 'dart:math';
import 'dart:typed_data';

import 'package:charset/charset.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';

import '../utils.dart';

/// Tests [StringUtils].
void main() {
  void doTest(List<int> bytes, Encoding charset, String encoding) {
    final guessedCharset =
        StringUtils.guessCharset(Uint8List.fromList(bytes), null)!;
    final guessedEncoding =
        StringUtils.guessEncoding(Uint8List.fromList(bytes), null);
    expect(charset, guessedCharset);
    expect(encoding, guessedEncoding);
  }

  final args = <String>[];
  if (args.isNotEmpty) {
    final text = args[0];
    final charset = Encoding.getByName(args[1])!;
    final declaration = StringBuilder();
    declaration.write('Uint8List.fromList([ ');
    for (int b in charset.encode(text)) {
      declaration.write('0x');
      final value = b & 0xFF;
      if (value < 0x10) {
        declaration.write('0');
      }
      declaration.write(value.toRadixString(16));
      declaration.write(', ');
    }
    declaration.write('])');
    print(declaration);
  }

  test('testRandom', () {
    final r = Random(1234);
    final bytes = Uint8List(1000);
    r.nextBytes(bytes);

    expect(StringUtils.guessCharset(bytes, null), utf8);
  });

  test('testShortShiftJIS1', () {
    // 金魚
    doTest([
      0x8b, 0xe0, 0x8b, 0x9b, //
    ], StringUtils.shiftJisCharset, 'SJIS');
  });

  test('testShortISO885911', () {
    // båd
    doTest([
      0x62, 0xe5, 0x64, //
    ], latin1, 'ISO8859_1');
  });

  test('testShortUTF81', () {
    // Español
    doTest([0x45, 0x73, 0x70, 0x61, 0xc3, 0xb1, 0x6f, 0x6c], utf8, 'UTF8');
  });

  test('testMixedShiftJIS1', () {
    // Hello 金!
    doTest([
      0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x8b, 0xe0, 0x21, //
    ], StringUtils.shiftJisCharset, 'SJIS');
  });

  test('testUTF16BE', () {
    // 调压柜
    doTest([
      0xFE, 0xFF, 0x8c, 0x03, 0x53, 0x8b, 0x67, 0xdc, //
    ], utf16, utf16.name);
  });

  test('testUTF16LE', () {
    // 调压柜
    doTest([
      0xFF, 0xFE, 0x03, 0x8c, 0x8b, 0x53, 0xdc, 0x67, //
    ], utf16, utf16.name);
  });
}
