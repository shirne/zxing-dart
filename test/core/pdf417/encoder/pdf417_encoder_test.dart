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

import 'package:charset/charset.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart' show BitMatrix;
import 'package:zxing_lib/pdf417.dart';
import 'package:zxing_lib/src/multi_format_writer.dart' show MultiFormatWriter;
import 'package:zxing_lib/src/pdf417/encoder/dimensions.dart';
import 'package:zxing_lib/src/writer_exception.dart';
import 'package:zxing_lib/zxing.dart' show BarcodeFormat, EncodeHint;

/// Tests [PDF417HighLevelEncoder].
void main() {
  const pdf417Pfx = '\u039f\u001A\u0385';

  String checkEncodeAutoWithSpecialChars(String input, Compaction compaction) {
    return PDF417HighLevelEncoder.encodeHighLevel(
      input,
      compaction,
      utf8,
      false,
    );
  }

  test('testEncodeAuto', () {
    final input = 'ABCD';
    expect(
      '${pdf417Pfx}ABCD',
      checkEncodeAutoWithSpecialChars(input, Compaction.auto),
    );
  });

  test('testEncodeAutoWithSpecialChars', () {
    // Just check if this does not throw an exception
    checkEncodeAutoWithSpecialChars('1%§s ?aG\$', Compaction.auto);
    checkEncodeAutoWithSpecialChars('日本語', Compaction.auto);
    checkEncodeAutoWithSpecialChars('₸ 5555', Compaction.auto);
    checkEncodeAutoWithSpecialChars('€ 123,45', Compaction.auto);
    checkEncodeAutoWithSpecialChars('€ 123,45', Compaction.byte);
    checkEncodeAutoWithSpecialChars('123,45', Compaction.text);

    // Greek alphabet
    final cp437 = Charset.getByName('IBM437');
    assert(cp437 != null);
    final cp437Array = [224, 225, 226, 227, 228]; //αßΓπΣ
    final greek = cp437?.decode(cp437Array) ?? '';
    expect('αßΓπΣ', greek);
    checkEncodeAutoWithSpecialChars(greek, Compaction.auto);
    checkEncodeAutoWithSpecialChars(greek, Compaction.byte);
    PDF417HighLevelEncoder.encodeHighLevel(greek, Compaction.auto, cp437, true);
    PDF417HighLevelEncoder.encodeHighLevel(
      greek,
      Compaction.auto,
      cp437,
      false,
    );

    try {
      // detect when a TEXT Compaction is applied to a non text input
      checkEncodeAutoWithSpecialChars('€ 123,45', Compaction.text);
    } on WriterException catch (e) {
      assert(e.message != null);
      assert(e.message.contains('8364'));
      assert(e.message.contains('Compaction.TEXT'));
      assert(e.message.contains('Compaction.AUTO'));
    }

    try {
      // detect when a TEXT Compaction is applied to a non text input
      final String input = 'Hello! ${String.fromCharCode(128)}';
      checkEncodeAutoWithSpecialChars(input, Compaction.text);
    } on WriterException catch (e) {
      assert(e.message != null);
      assert(e.message.contains('128'));
      assert(e.message.contains('Compaction.TEXT'));
      assert(e.message.contains('Compaction.AUTO'));
    }

    try {
      // detect when a TEXT Compaction is applied to a non text input
      // https://github.com/zxing/zxing/issues/1761
      final String content = '€ 123,45';
      final hints = EncodeHint(
        errorCorrection: 4,
        pdf417Dimensions: Dimensions(7, 7, 1, 300),
        margin: 0,
        characterSet: 'ISO-8859-15',
        pdf417Compaction: Compaction.text,
      );

      (MultiFormatWriter())
          .encode(content, BarcodeFormat.pdf417, 200, 100, hints);
    } on WriterException catch (e) {
      assert(e.message != null);
      assert(e.message.contains('8364'));
      assert(e.message.contains('Compaction.TEXT'));
      assert(e.message.contains('Compaction.AUTO'));
    }
  });

  test('testCheckCharset', () {
    final String input = 'Hello!';
    final String errorMessage =
        DateTime.now().microsecondsSinceEpoch.toRadixString(16);

    // no exception
    PDF417HighLevelEncoder.checkCharset(input, 255, errorMessage);
    PDF417HighLevelEncoder.checkCharset(input, 1255, errorMessage);
    PDF417HighLevelEncoder.checkCharset(input, 111, errorMessage);

    try {
      // should throw an exception for character 'o' because it exceeds upper limit 110
      PDF417HighLevelEncoder.checkCharset(input, 110, errorMessage);
    } on WriterException catch (e) {
      assert(e.message != null);
      assert(e.message.contains('111'));
      assert(e.message.contains(errorMessage));
    }
  });

  test('testEncodeIso88591WithSpecialChars', () {
    // Just check if this does not throw an exception
    PDF417HighLevelEncoder.encodeHighLevel(
      'asdfg§asd',
      Compaction.auto,
      latin1,
      false,
    );
  });

  test('testEncodeText', () {
    final encoded = PDF417HighLevelEncoder.encodeHighLevel(
      'ABCD',
      Compaction.text,
      utf8,
      false,
    );
    expect('Ο\u001A\u0001?', encoded);
  });

  test('testEncodeNumeric', () {
    final encoded = PDF417HighLevelEncoder.encodeHighLevel(
      '1234',
      Compaction.numeric,
      utf8,
      false,
    );
    expect('\u039f\u001A\u0386\f\u01b2', encoded);
  });

  test('testEncodeByte', () {
    final encoded = PDF417HighLevelEncoder.encodeHighLevel(
      'abcd',
      Compaction.byte,
      utf8,
      false,
    );
    expect('\u039f\u001A\u0385abcd', encoded);
  });

  test('testEncodeEmptyString', () {
    try {
      PDF417HighLevelEncoder.encodeHighLevel('', Compaction.auto, null, false);
    } on WriterException catch (_) {}
  });

  /// WriterException
  BitMatrix? generatePDF417BitMatrix(
    String barcodeText,
    int width,
    int? heightRequested,
    Dimensions dimensions,
  ) {
    try {
      final barcodeWriter = PDF417Writer();
      final int height = heightRequested ?? width ~/ 4;
      final hints = EncodeHint(margin: 0, pdf417Dimensions: dimensions);
      return barcodeWriter.encode(
        barcodeText,
        BarcodeFormat.pdf417,
        width,
        height,
        hints,
      );
    } on WriterException catch (_) {
      return null;
    }
  }

  /// Exception
  void testDimensions(String input, Dimensions dimensions) {
    final int sourceCodeWords = 20;
    final int errorCorrectionCodeWords = 8;

    final calculated = PDF417.determineDimensions(
      dimensions.minCols,
      dimensions.maxCols,
      dimensions.minRows,
      dimensions.maxRows,
      sourceCodeWords,
      errorCorrectionCodeWords,
    );

    assert(calculated != null);
    expect(2, calculated?.length);
    assert(dimensions.minCols <= calculated![0]);
    assert(dimensions.maxCols >= calculated![0]);
    assert(dimensions.minRows <= calculated![1]);
    assert(dimensions.maxRows >= calculated![1]);
    assert(generatePDF417BitMatrix(input, 371, null, dimensions) != null);
  }

  test('testDimensions', () {
    // test https://github.com/zxing/zxing/issues/1831
    final input = '0000000001000000022200000003330444400888888881010101010';
    testDimensions(input, Dimensions(1, 30, 7, 10));
    testDimensions(input, Dimensions(1, 40, 1, 7));
    testDimensions(input, Dimensions(10, 30, 1, 5));
    testDimensions(input, Dimensions(1, 3, 1, 15));
    testDimensions(input, Dimensions(5, 30, 7, 7));
    testDimensions(input, Dimensions(12, 12, 1, 17));
    testDimensions(input, Dimensions(1, 30, 7, 7));
  });
}
