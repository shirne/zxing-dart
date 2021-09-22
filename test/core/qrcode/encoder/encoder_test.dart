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
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/zxing.dart';

void main() {
  test('testGetAlphanumericCode', () {
    // The first ten code points are numbers.
    for (int i = 0; i < 10; ++i) {
      expect(i, Encoder.getAlphanumericCode(48 /* 0 */ + i));
    }

    // The next 26 code points are capital alphabet letters.
    for (int i = 10; i < 36; ++i) {
      expect(i, Encoder.getAlphanumericCode(65 /* A */ + i - 10));
    }

    // Others are symbol letters
    expect(36, Encoder.getAlphanumericCode(32 /*   */));
    expect(37, Encoder.getAlphanumericCode(36 /* $ */));
    expect(38, Encoder.getAlphanumericCode(37 /* % */));
    expect(39, Encoder.getAlphanumericCode(42 /* * */));
    expect(40, Encoder.getAlphanumericCode(43 /* + */));
    expect(41, Encoder.getAlphanumericCode(45 /* - */));
    expect(42, Encoder.getAlphanumericCode(46 /* . */));
    expect(43, Encoder.getAlphanumericCode(47 /* / */));
    expect(44, Encoder.getAlphanumericCode(58 /* : */));

    // Should return -1 for other letters;
    expect(-1, Encoder.getAlphanumericCode(97 /* a */));
    expect(-1, Encoder.getAlphanumericCode(35 /* # */));
    expect(-1, Encoder.getAlphanumericCode(0));
  });

  test('testChooseMode', () {
    // Numeric mode.
    expect(Mode.NUMERIC, Encoder.chooseMode("0"));
    expect(Mode.NUMERIC, Encoder.chooseMode("0123456789"));
    // Alphanumeric mode.
    expect(Mode.ALPHANUMERIC, Encoder.chooseMode("A"));
    expect(Mode.ALPHANUMERIC,
        Encoder.chooseMode(r"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"));
    // 8-bit byte mode.
    expect(Mode.BYTE, Encoder.chooseMode("a"));
    expect(Mode.BYTE, Encoder.chooseMode("#"));
    expect(Mode.BYTE, Encoder.chooseMode(""));
    // Kanji mode.  We used to use MODE_KANJI for these, but we stopped
    // doing that as we cannot distinguish Shift_JIS from other encodings
    // from data bytes alone.  See also comments in qrcode_encoder.h.

    // AIUE in Hiragana in Shift_JIS
    expect(
        Mode.BYTE,
        Encoder.chooseMode(
            shiftJISString(bytes([0x8, 0xa, 0x8, 0xa, 0x8, 0xa, 0x8, 0xa6]))));

    // Nihon in Kanji in Shift_JIS.
    expect(Mode.BYTE,
        Encoder.chooseMode(shiftJISString(bytes([0x9, 0xf, 0x9, 0x7b]))));

    // Sou-Utsu-Byou in Kanji in Shift_JIS.
    expect(
        Mode.BYTE,
        Encoder.chooseMode(
            shiftJISString(bytes([0xe, 0x4, 0x9, 0x5, 0x9, 0x61]))));
  });

  test('testEncodeDefault', () {
    QRCode qrCode = Encoder.encode("ABCDEF", ErrorCorrectionLevel.H);
    String expected = "<<\n" " mode: ALPHANUMERIC\n" +
        " ecLevel: H\n" +
        " version: 1\n" +
        " maskPattern: 4\n" +
        " matrix:\n" +
        " 1 1 1 1 1 1 1 0 0 1 0 1 0 0 1 1 1 1 1 1 1\n" +
        " 1 0 0 0 0 0 1 0 1 0 1 0 1 0 1 0 0 0 0 0 1\n" +
        " 1 0 1 1 1 0 1 0 0 0 0 0 0 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 0 1 0 0 1 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 0 1 0 1 0 0 1 0 1 1 1 0 1\n" +
        " 1 0 0 0 0 0 1 0 1 0 0 1 1 0 1 0 0 0 0 0 1\n" +
        " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n" +
        " 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0\n" +
        " 0 0 0 0 1 1 1 1 0 1 1 0 1 0 1 1 0 0 0 1 0\n" +
        " 0 0 0 0 1 1 0 1 1 1 0 0 1 1 1 1 0 1 1 0 1\n" +
        " 1 0 0 0 0 1 1 0 0 1 0 1 0 0 0 1 1 1 0 1 1\n" +
        " 1 0 0 1 1 1 0 0 1 1 1 1 0 0 0 0 1 0 0 0 0\n" +
        " 0 1 1 1 1 1 1 0 1 0 1 0 1 1 1 0 0 1 1 0 0\n" +
        " 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1 0 0 0 1 0 1\n" +
        " 1 1 1 1 1 1 1 0 1 1 1 1 0 0 0 0 0 1 1 0 0\n" +
        " 1 0 0 0 0 0 1 0 1 1 0 1 0 0 0 1 0 1 1 1 1\n" +
        " 1 0 1 1 1 0 1 0 1 0 0 1 0 0 0 1 1 0 0 1 1\n" +
        " 1 0 1 1 1 0 1 0 0 0 1 1 0 1 0 0 0 0 1 1 1\n" +
        " 1 0 1 1 1 0 1 0 0 1 0 1 0 0 0 1 1 0 0 0 0\n" +
        " 1 0 0 0 0 0 1 0 0 1 0 0 1 0 0 1 1 0 0 0 1\n" +
        " 1 1 1 1 1 1 1 0 0 0 1 0 0 1 0 0 0 0 1 1 1\n" +
        ">>\n";
    expect(expected, qrCode.toString());
  });

  test('testEncodeWithVersion', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.QR_VERSION] = 7;
    QRCode qrCode = Encoder.encode("ABCDEF", ErrorCorrectionLevel.H, hints);
    assert(qrCode.toString().contains(" version: 7\n"));
  });

  //@Test(expected = WriterException.class)
  test('testEncodeWithVersionTooSmall', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.QR_VERSION] = 3;
    try {
      Encoder.encode("THISMESSAGEISTOOLONGFORAQRCODEVERSION3",
          ErrorCorrectionLevel.H, hints);
      fail('Data too big for requested version');
    } on WriterException catch (_) {
      // passed
    }
  });

  test('testSimpleUTF8ECI', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.CHARACTER_SET] = "UTF8";
    QRCode qrCode = Encoder.encode("hello", ErrorCorrectionLevel.H, hints);
    String expected = "<<\n" " mode: BYTE\n" +
        " ecLevel: H\n" +
        " version: 1\n" +
        " maskPattern: 6\n" +
        " matrix:\n" +
        " 1 1 1 1 1 1 1 0 0 0 1 1 0 0 1 1 1 1 1 1 1\n" +
        " 1 0 0 0 0 0 1 0 0 0 1 1 0 0 1 0 0 0 0 0 1\n" +
        " 1 0 1 1 1 0 1 0 1 0 0 1 1 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 1 0 0 0 1 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 0 1 1 0 0 0 1 0 1 1 1 0 1\n" +
        " 1 0 0 0 0 0 1 0 0 0 0 1 0 0 1 0 0 0 0 0 1\n" +
        " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n" +
        " 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0\n" +
        " 0 0 0 1 1 0 1 1 0 0 0 0 1 0 0 0 0 1 1 0 0\n" +
        " 0 0 0 0 0 0 0 0 1 1 0 1 0 0 1 0 1 1 1 1 1\n" +
        " 1 1 0 0 0 1 1 1 0 0 0 1 1 0 0 1 0 1 0 1 1\n" +
        " 0 0 0 0 1 1 0 0 1 0 0 0 0 0 1 0 1 1 0 0 0\n" +
        " 0 1 1 0 0 1 1 0 0 1 1 1 0 1 1 1 1 1 1 1 1\n" +
        " 0 0 0 0 0 0 0 0 1 1 1 0 1 1 1 1 1 1 1 1 1\n" +
        " 1 1 1 1 1 1 1 0 1 0 1 0 0 0 1 0 0 0 0 0 0\n" +
        " 1 0 0 0 0 0 1 0 0 1 0 0 0 1 0 0 0 1 1 0 0\n" +
        " 1 0 1 1 1 0 1 0 1 0 0 0 1 0 1 0 0 0 1 0 0\n" +
        " 1 0 1 1 1 0 1 0 1 1 1 1 0 1 0 0 1 0 1 1 0\n" +
        " 1 0 1 1 1 0 1 0 0 1 1 1 0 0 1 0 0 1 0 1 1\n" +
        " 1 0 0 0 0 0 1 0 0 0 0 0 0 1 1 0 1 1 0 0 0\n" +
        " 1 1 1 1 1 1 1 0 0 0 0 1 0 1 0 0 1 0 1 0 0\n" +
        ">>\n";
    expect(expected, qrCode.toString());
  });

  test('testEncodeKanjiMode', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.CHARACTER_SET] = "Shift_JIS";
    // Nihon in Kanji
    QRCode qrCode =
        Encoder.encode("\u65e5\u672c", ErrorCorrectionLevel.M, hints);
    String expected = "<<\n" " mode: KANJI\n" +
        " ecLevel: M\n" +
        " version: 1\n" +
        " maskPattern: 0\n" +
        " matrix:\n" +
        " 1 1 1 1 1 1 1 0 0 1 0 1 0 0 1 1 1 1 1 1 1\n" +
        " 1 0 0 0 0 0 1 0 1 1 0 0 0 0 1 0 0 0 0 0 1\n" +
        " 1 0 1 1 1 0 1 0 0 1 1 1 1 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 0 0 0 0 1 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 1 1 1 1 1 0 1 0 1 1 1 0 1\n" +
        " 1 0 0 0 0 0 1 0 0 1 1 1 0 0 1 0 0 0 0 0 1\n" +
        " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n" +
        " 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0\n" +
        " 1 0 1 0 1 0 1 0 0 0 1 0 1 0 0 0 1 0 0 1 0\n" +
        " 1 1 0 1 0 0 0 1 0 1 1 1 0 1 0 1 0 1 0 0 0\n" +
        " 0 1 0 0 0 0 1 1 1 1 1 1 0 1 1 1 0 1 0 1 0\n" +
        " 1 1 1 0 0 1 0 1 0 0 0 1 1 1 0 1 1 0 1 0 0\n" +
        " 0 1 1 0 0 1 1 0 1 1 0 1 0 1 1 1 0 1 0 0 1\n" +
        " 0 0 0 0 0 0 0 0 1 0 1 0 0 0 1 0 0 0 1 0 1\n" +
        " 1 1 1 1 1 1 1 0 0 0 0 0 1 0 0 0 1 0 0 1 1\n" +
        " 1 0 0 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 1 1\n" +
        " 1 0 1 1 1 0 1 0 1 0 0 0 1 0 1 0 1 0 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 0 0 0 1 0 1 0 1 0 1 0 1 0\n" +
        " 1 0 1 1 1 0 1 0 1 0 1 1 0 1 1 1 0 0 1 0 1\n" +
        " 1 0 0 0 0 0 1 0 0 0 0 1 1 1 0 1 1 1 0 1 0\n" +
        " 1 1 1 1 1 1 1 0 1 1 0 1 0 1 1 1 0 0 1 0 0\n" +
        ">>\n";
    expect(expected, qrCode.toString());
  });

  test('testEncodeShiftjisNumeric', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.CHARACTER_SET] = "Shift_JIS";
    QRCode qrCode = Encoder.encode("0123", ErrorCorrectionLevel.M, hints);
    String expected = "<<\n" " mode: NUMERIC\n" +
        " ecLevel: M\n" +
        " version: 1\n" +
        " maskPattern: 2\n" +
        " matrix:\n" +
        " 1 1 1 1 1 1 1 0 0 1 1 0 1 0 1 1 1 1 1 1 1\n" +
        " 1 0 0 0 0 0 1 0 0 1 0 0 1 0 1 0 0 0 0 0 1\n" +
        " 1 0 1 1 1 0 1 0 1 0 0 0 0 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 1 0 1 1 1 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 1 1 0 1 1 0 1 0 1 1 1 0 1\n" +
        " 1 0 0 0 0 0 1 0 1 1 0 0 1 0 1 0 0 0 0 0 1\n" +
        " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n" +
        " 0 0 0 0 0 0 0 0 1 1 1 1 1 0 0 0 0 0 0 0 0\n" +
        " 1 0 1 1 1 1 1 0 0 1 1 0 1 0 1 1 1 1 1 0 0\n" +
        " 1 1 0 0 0 1 0 0 1 0 1 0 1 0 0 1 0 0 1 0 0\n" +
        " 0 1 1 0 1 1 1 1 0 1 1 1 0 1 0 0 1 1 0 1 1\n" +
        " 1 0 1 1 0 1 0 1 0 0 1 0 0 0 0 1 1 0 1 0 0\n" +
        " 0 0 1 0 0 1 1 1 0 0 0 1 0 1 0 0 1 0 1 0 0\n" +
        " 0 0 0 0 0 0 0 0 1 1 0 1 1 1 1 0 0 1 0 0 0\n" +
        " 1 1 1 1 1 1 1 0 0 0 1 0 1 0 1 1 0 0 0 0 0\n" +
        " 1 0 0 0 0 0 1 0 1 1 0 1 1 1 1 0 0 1 0 1 0\n" +
        " 1 0 1 1 1 0 1 0 1 0 1 0 1 0 0 1 0 0 1 0 0\n" +
        " 1 0 1 1 1 0 1 0 1 1 1 0 1 0 0 1 0 0 1 0 0\n" +
        " 1 0 1 1 1 0 1 0 1 1 0 1 0 1 0 0 1 1 1 0 0\n" +
        " 1 0 0 0 0 0 1 0 0 0 1 0 0 0 0 1 1 0 1 1 0\n" +
        " 1 1 1 1 1 1 1 0 1 1 0 1 0 1 0 0 1 1 1 0 0\n" +
        ">>\n";
    expect(expected, qrCode.toString());
  });

  test('testEncodeGS1WithStringTypeHint', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.GS1_FORMAT] = "true";
    QRCode qrCode =
        Encoder.encode("100001%11171218", ErrorCorrectionLevel.H, hints);
    verifyGS1EncodedData(qrCode);
  });

  test('testEncodeGS1WithBooleanTypeHint', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.GS1_FORMAT] = true;
    QRCode qrCode =
        Encoder.encode("100001%11171218", ErrorCorrectionLevel.H, hints);
    verifyGS1EncodedData(qrCode);
  });

  test('testDoesNotEncodeGS1WhenBooleanTypeHintExplicitlyFalse', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.GS1_FORMAT] = false;
    QRCode qrCode = Encoder.encode("ABCDEF", ErrorCorrectionLevel.H, hints);
    verifyNotGS1EncodedData(qrCode);
  });

  test('testDoesNotEncodeGS1WhenStringTypeHintExplicitlyFalse', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.GS1_FORMAT] = "false";
    QRCode qrCode = Encoder.encode("ABCDEF", ErrorCorrectionLevel.H, hints);
    verifyNotGS1EncodedData(qrCode);
  });

  test('testGS1ModeHeaderWithECI', () {
    Map<EncodeHintType, Object> hints = {};
    hints[EncodeHintType.CHARACTER_SET] = "UTF8";
    hints[EncodeHintType.GS1_FORMAT] = true;
    QRCode qrCode = Encoder.encode("hello", ErrorCorrectionLevel.H, hints);
    String expected = "<<\n" " mode: BYTE\n" +
        " ecLevel: H\n" +
        " version: 1\n" +
        " maskPattern: 5\n" +
        " matrix:\n" +
        " 1 1 1 1 1 1 1 0 1 0 1 1 0 0 1 1 1 1 1 1 1\n" +
        " 1 0 0 0 0 0 1 0 0 1 1 0 0 0 1 0 0 0 0 0 1\n" +
        " 1 0 1 1 1 0 1 0 1 1 1 0 0 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 0 1 0 1 0 0 1 0 1 1 1 0 1\n" +
        " 1 0 1 1 1 0 1 0 1 0 1 0 0 0 1 0 1 1 1 0 1\n" +
        " 1 0 0 0 0 0 1 0 0 1 1 1 1 0 1 0 0 0 0 0 1\n" +
        " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n" +
        " 0 0 0 0 0 0 0 0 1 0 1 1 1 0 0 0 0 0 0 0 0\n" +
        " 0 0 0 0 0 1 1 0 0 1 1 0 0 0 1 0 1 0 1 0 1\n" +
        " 0 1 0 1 1 0 0 1 0 1 1 1 1 1 1 0 1 1 1 0 1\n" +
        " 0 1 0 1 1 1 1 0 1 1 0 0 0 1 0 1 0 1 1 0 0\n" +
        " 1 1 1 1 0 1 0 1 0 0 1 0 1 0 0 1 1 1 1 0 0\n" +
        " 1 0 0 1 0 0 1 1 0 1 1 0 1 0 1 0 0 1 0 0 1\n" +
        " 0 0 0 0 0 0 0 0 1 1 1 1 1 0 1 0 1 0 0 1 0\n" +
        " 1 1 1 1 1 1 1 0 0 0 1 1 0 0 1 0 0 0 1 1 0\n" +
        " 1 0 0 0 0 0 1 0 1 1 0 0 0 0 1 0 1 1 1 0 0\n" +
        " 1 0 1 1 1 0 1 0 0 1 0 0 1 0 1 0 1 0 0 0 1\n" +
        " 1 0 1 1 1 0 1 0 0 0 0 0 1 1 1 0 1 1 1 1 0\n" +
        " 1 0 1 1 1 0 1 0 0 0 1 0 0 1 0 0 1 0 1 1 1\n" +
        " 1 0 0 0 0 0 1 0 0 1 0 0 0 1 1 0 0 1 1 1 1\n" +
        " 1 1 1 1 1 1 1 0 0 1 1 1 0 1 1 0 1 0 0 1 0\n" +
        ">>\n";
    expect(expected, qrCode.toString());
  });

  test('testAppendModeInfo', () {
    BitArray bits = BitArray();
    Encoder.appendModeInfo(Mode.NUMERIC, bits);
    expect(" ...X", bits.toString());
  });

  test('testAppendLengthInfo', () {
    BitArray bits = BitArray();
    Encoder.appendLengthInfo(
        1, // 1 letter (1/1).
        Version.getVersionForNumber(1),
        Mode.NUMERIC,
        bits);
    expect(" ........ .X", bits.toString()); // 10 bits.
    bits = BitArray();
    Encoder.appendLengthInfo(
        2, // 2 letters (2/1).
        Version.getVersionForNumber(10),
        Mode.ALPHANUMERIC,
        bits);
    expect(" ........ .X.", bits.toString()); // 11 bits.
    bits = BitArray();
    Encoder.appendLengthInfo(
        255, // 255 letter (255/1).
        Version.getVersionForNumber(27),
        Mode.BYTE,
        bits);
    expect(" ........ XXXXXXXX", bits.toString()); // 16 bits.
    bits = BitArray();
    Encoder.appendLengthInfo(
        512, // 512 letters (1024/2).
        Version.getVersionForNumber(40),
        Mode.KANJI,
        bits);
    expect(" ..X..... ....", bits.toString()); // 12 bits.
  });

  test('testAppendBytes', () {
    // Should use appendNumericBytes.
    // 1 = 01 = 0001 in 4 bits.
    BitArray bits = BitArray();
    Encoder.appendBytes(
        "1", Mode.NUMERIC, bits, Encoder.defaultByteModeEncoding);
    expect(" ...X", bits.toString());
    // Should use appendAlphanumericBytes.
    // A = 10 = 0xa = 001010 in 6 bits
    bits = BitArray();
    Encoder.appendBytes(
        "A", Mode.ALPHANUMERIC, bits, Encoder.defaultByteModeEncoding);
    expect(" ..X.X.", bits.toString());
    // Lower letters such as 'a' cannot be encoded in MODE_ALPHANUMERIC.
    try {
      Encoder.appendBytes(
          "a", Mode.ALPHANUMERIC, bits, Encoder.defaultByteModeEncoding);
    } on WriterException catch (_) {
      //
      // good
    }
    // Should use append8BitBytes.
    // 0x61, 0x62, 0x63
    bits = BitArray();
    Encoder.appendBytes(
        "abc", Mode.BYTE, bits, Encoder.defaultByteModeEncoding);
    expect(" .XX....X .XX...X. .XX...XX", bits.toString());
    // Anything can be encoded in QRCode.MODE_8BIT_BYTE.
    Encoder.appendBytes(
        "\x00", Mode.BYTE, bits, Encoder.defaultByteModeEncoding);
    // Should use appendKanjiBytes.
    // 0x93, 0x5f
    bits = BitArray();
    Encoder.appendBytes(shiftJISString(bytes([0x93, 0x5f])), Mode.KANJI, bits,
        Encoder.defaultByteModeEncoding);
    expect(" .XX.XX.. XXXXX", bits.toString());
  });

  test('testTerminateBits', () {
    BitArray v = BitArray();
    Encoder.terminateBits(0, v);
    expect("", v.toString());
    v = BitArray();
    Encoder.terminateBits(1, v);
    expect(" ........", v.toString());
    v = BitArray();
    v.appendBits(0, 3); // Append 000
    Encoder.terminateBits(1, v);
    expect(" ........", v.toString());
    v = BitArray();
    v.appendBits(0, 5); // Append 00000
    Encoder.terminateBits(1, v);
    expect(" ........", v.toString());
    v = BitArray();
    v.appendBits(0, 8); // Append 00000000
    Encoder.terminateBits(1, v);
    expect(" ........", v.toString());
    v = BitArray();
    Encoder.terminateBits(2, v);
    expect(" ........ XXX.XX..", v.toString());
    v = BitArray();
    v.appendBits(0, 1); // Append 0
    Encoder.terminateBits(3, v);
    expect(" ........ XXX.XX.. ...X...X", v.toString());
  });

  test('testGetNumDataBytesAndNumECBytesForBlockID', () {
    List<int> numDataBytes = [0];
    List<int> numEcBytes = [0];
    // Version 1-H.
    Encoder.getNumDataBytesAndNumECBytesForBlockID(
        26, 9, 1, 0, numDataBytes, numEcBytes);
    expect(9, numDataBytes[0]);
    expect(17, numEcBytes[0]);

    // Version 3-H.  2 blocks.
    Encoder.getNumDataBytesAndNumECBytesForBlockID(
        70, 26, 2, 0, numDataBytes, numEcBytes);
    expect(13, numDataBytes[0]);
    expect(22, numEcBytes[0]);
    Encoder.getNumDataBytesAndNumECBytesForBlockID(
        70, 26, 2, 1, numDataBytes, numEcBytes);
    expect(13, numDataBytes[0]);
    expect(22, numEcBytes[0]);

    // Version 7-H. (4 + 1) blocks.
    Encoder.getNumDataBytesAndNumECBytesForBlockID(
        196, 66, 5, 0, numDataBytes, numEcBytes);
    expect(13, numDataBytes[0]);
    expect(26, numEcBytes[0]);
    Encoder.getNumDataBytesAndNumECBytesForBlockID(
        196, 66, 5, 4, numDataBytes, numEcBytes);
    expect(14, numDataBytes[0]);
    expect(26, numEcBytes[0]);

    // Version 40-H. (20 + 61) blocks.
    Encoder.getNumDataBytesAndNumECBytesForBlockID(
        3706, 1276, 81, 0, numDataBytes, numEcBytes);
    expect(15, numDataBytes[0]);
    expect(30, numEcBytes[0]);
    Encoder.getNumDataBytesAndNumECBytesForBlockID(
        3706, 1276, 81, 20, numDataBytes, numEcBytes);
    expect(16, numDataBytes[0]);
    expect(30, numEcBytes[0]);
    Encoder.getNumDataBytesAndNumECBytesForBlockID(
        3706, 1276, 81, 80, numDataBytes, numEcBytes);
    expect(16, numDataBytes[0]);
    expect(30, numEcBytes[0]);
  });

  test('testInterleaveWithECBytes', () {
    Uint8List dataBytes =
        Uint8List.fromList([32, 65, 205, 69, 41, 220, 46, 128, 236]);
    BitArray inArr = BitArray();
    for (int dataByte in dataBytes) {
      inArr.appendBits(dataByte, 8);
    }
    BitArray out = Encoder.interleaveWithECBytes(inArr, 26, 9, 1);
    Uint8List expected = Uint8List.fromList([
      // Data bytes.
      32, 65, 205, 69, 41, 220, 46, 128, 236,
      // Error correction bytes.
      42, 159, 74, 221, 244, 169, 239, 150, 138, 70,
      237, 85, 224, 96, 74, 219, 61
    ]);
    expect(expected.length, out.sizeInBytes);
    Uint8List outArray = Uint8List(expected.length);
    out.toBytes(0, outArray, 0, expected.length);
    // Can't use Arrays.equals(), because outArray may be longer than out.sizeInBytes()
    for (int x = 0; x < expected.length; x++) {
      expect(expected[x], outArray[x]);
    }
    // Numbers are from http://www.swetake.com/qr/qr8.html
    dataBytes = Uint8List.fromList([
      67, 70, 22, 38, 54, 70, 86, 102, 118, 134, 150, 166, 182, //
      198, 214, 230, 247, 7, 23, 39, 55, 71, 87, 103, 119, 135,
      151, 166, 22, 38, 54, 70, 86, 102, 118, 134, 150, 166,
      182, 198, 214, 230, 247, 7, 23, 39, 55, 71, 87, 103, 119,
      135, 151, 160, 236, 17, 236, 17, 236, 17, 236,
      17
    ]);
    inArr = BitArray();
    for (int dataByte in dataBytes) {
      inArr.appendBits(dataByte, 8);
    }

    out = Encoder.interleaveWithECBytes(inArr, 134, 62, 4);
    expected = bytes([
      // Data bytes.
      67, 230, 54, 55, 70, 247, 70, 71, 22, 7, 86, 87, 38, 23, 102, 103,
      54, 39, 118, 119, 70, 55, 134, 135, 86, 71, 150, 151, 102, 87, 166,
      160, 118, 103, 182, 236, 134, 119, 198, 17, 150,
      135, 214, 236, 166, 151, 230, 17, 182,
      166, 247, 236, 198, 22, 7, 17, 214, 38, 23, 236, 39,
      17,
      // Error correction bytes.
      175, 155, 245, 236, 80, 146, 56, 74, 155, 165,
      133, 142, 64, 183, 132, 13, 178, 54, 132, 108, 45,
      113, 53, 50, 214, 98, 193, 152, 233, 147, 50, 71, 65,
      190, 82, 51, 209, 199, 171, 54, 12, 112, 57, 113, 155, 117,
      211, 164, 117, 30, 158, 225, 31, 190, 242, 38,
      140, 61, 179, 154, 214, 138, 147, 87, 27, 96, 77, 47,
      187, 49, 156, 214
    ]);
    expect(expected.length, out.sizeInBytes);
    outArray = Uint8List(expected.length);
    out.toBytes(0, outArray, 0, expected.length);
    for (int x = 0; x < expected.length; x++) {
      expect(expected[x], outArray[x]);
    }
  });

  test('testAppendNumericBytes', () {
    // 1 = 01 = 0001 in 4 bits.
    BitArray bits = BitArray();
    Encoder.appendNumericBytes("1", bits);
    expect(" ...X", bits.toString());
    // 12 = 0xc = 0001100 in 7 bits.
    bits = BitArray();
    Encoder.appendNumericBytes("12", bits);
    expect(" ...XX..", bits.toString());
    // 123 = 0x7b = 0001111011 in 10 bits.
    bits = BitArray();
    Encoder.appendNumericBytes("123", bits);
    expect(" ...XXXX. XX", bits.toString());
    // 1234 = "123" + "4" = 0001111011 + 0100
    bits = BitArray();
    Encoder.appendNumericBytes("1234", bits);
    expect(" ...XXXX. XX.X..", bits.toString());
    // Empty.
    bits = BitArray();
    Encoder.appendNumericBytes("", bits);
    expect("", bits.toString());
  });

  test('testAppendAlphanumericBytes', () {
    // A = 10 = 0xa = 001010 in 6 bits
    BitArray bits = BitArray();
    Encoder.appendAlphanumericBytes("A", bits);
    expect(" ..X.X.", bits.toString());
    // AB = 10 * 45 + 11 = 461 = 0x1cd = 00111001101 in 11 bits
    bits = BitArray();
    Encoder.appendAlphanumericBytes("AB", bits);
    expect(" ..XXX..X X.X", bits.toString());
    // ABC = "AB" + "C" = 00111001101 + 001100
    bits = BitArray();
    Encoder.appendAlphanumericBytes("ABC", bits);
    expect(" ..XXX..X X.X..XX. .", bits.toString());
    // Empty.
    bits = BitArray();
    Encoder.appendAlphanumericBytes("", bits);
    expect("", bits.toString());
    // Invalid data.
    try {
      Encoder.appendAlphanumericBytes("abc", BitArray());
    } catch (_) {
      // WriterException
      // good
    }
  });

  test('testAppend8BitBytes', () {
    // 0x61, 0x62, 0x63
    BitArray bits = BitArray();
    Encoder.append8BitBytes("abc", bits, Encoder.defaultByteModeEncoding);
    expect(" .XX....X .XX...X. .XX...XX", bits.toString());
    // Empty.
    bits = BitArray();
    Encoder.append8BitBytes("", bits, Encoder.defaultByteModeEncoding);
    expect("", bits.toString());
  });

  // Numbers are from page 21 of JISX0510:2004
  test('testAppendKanjiBytes', () {
    BitArray bits = BitArray();
    Encoder.appendKanjiBytes(shiftJISString(bytes([0x93, 0x5f])), bits);
    expect(" .XX.XX.. XXXXX", bits.toString());
    Encoder.appendKanjiBytes(shiftJISString(bytes([0xe4, 0xaa])), bits);
    expect(" .XX.XX.. XXXXXXX. X.X.X.X. X.", bits.toString());
  });

  // Numbers are from http://www.swetake.com/qr/qr3.html and
  // http://www.swetake.com/qr/qr9.html
  test('testGenerateECBytes', () {
    Uint8List dataBytes = bytes([32, 65, 205, 69, 41, 220, 46, 128, 236]);
    Uint8List ecBytes = Encoder.generateECBytes(dataBytes, 17);
    List<int> expected = [
      42, 159, 74, 221, 244, 169, 239, 150, 138, //
      70, 237, 85, 224, 96, 74, 219, 61
    ];
    expect(expected.length, ecBytes.length);
    for (int x = 0; x < expected.length; x++) {
      expect(expected[x], ecBytes[x] & 0xFF);
    }
    dataBytes = bytes(
        [67, 70, 22, 38, 54, 70, 86, 102, 118, 134, 150, 166, 182, 198, 214]);
    ecBytes = Encoder.generateECBytes(dataBytes, 18);
    expected = [
      175, 80, 155, 64, 178, 45, 214, 233, 65, //
      209, 12, 155, 117, 31, 140, 214, 27, 187
    ];

    expect(expected.length, ecBytes.length);
    for (int x = 0; x < expected.length; x++) {
      expect(expected[x], ecBytes[x] & 0xFF);
    }
    // High-order zero coefficient case.
    dataBytes = bytes([32, 49, 205, 69, 42, 20, 0, 236, 17]);
    ecBytes = Encoder.generateECBytes(dataBytes, 17);
    expected = [
      0, 3, 130, 179, 194, 0, 55, 211, 110, //
      79, 98, 72, 170, 96, 211, 137, 213
    ];
    expect(expected.length, ecBytes.length);
    for (int x = 0; x < expected.length; x++) {
      expect(expected[x], ecBytes[x] & 0xFF);
    }
  });

  test('testBugInBitVectorNumBytes', () {
    // There was a bug in BitVector.sizeInBytes() that caused it to return a
    // smaller-by-one value (ex. 1465 instead of 1466) if the number of bits
    // in the vector is not 8-bit aligned.  In QRCodeEncoder::InitQRCode(),
    // BitVector::sizeInBytes() is used for finding the smallest QR Code
    // version that can fit the given data.  Hence there were corner cases
    // where we chose a wrong QR Code version that cannot fit the given
    // data.  Note that the issue did not occur with MODE_8BIT_BYTE, as the
    // bits in the bit vector are always 8-bit aligned.
    //
    // Before the bug was fixed, the following test didn't pass, because:
    //
    // - MODE_NUMERIC is chosen as all bytes in the data are '0'
    // - The 3518-byte numeric data needs 1466 bytes
    //   - 3518 / 3 * 10 + 7 = 11727 bits = 1465.875 bytes
    //   - 3 numeric bytes are encoded in 10 bits, hence the first
    //     3516 bytes are encoded in 3516 / 3 * 10 = 11720 bits.
    //   - 2 numeric bytes can be encoded in 7 bits, hence the last
    //     2 bytes are encoded in 7 bits.
    // - The version 27 QR Code with the EC level L has 1468 bytes for data.
    //   - 1828 - 360 = 1468
    // - In InitQRCode(), 3 bytes are reserved for a header.  Hence 1465 bytes
    //   (1468 -3) are left for data.
    // - Because of the bug in BitVector::sizeInBytes(), InitQRCode() determines
    //   the given data can fit in 1465 bytes, despite it needs 1466 bytes.
    // - Hence QRCodeEncoder.encode() failed and returned false.
    //   - To be precise, it needs 11727 + 4 (getMode info) + 14 (length info) =
    //     11745 bits = 1468.125 bytes are needed (i.e. cannot fit in 1468
    //     bytes).
    StringBuilder builder = StringBuilder();
    for (int x = 0; x < 3518; x++) {
      builder.write('0');
    }
    Encoder.encode(builder.toString(), ErrorCorrectionLevel.L);
  });
}

Uint8List bytes(List<int> ints) {
  return Uint8List.fromList(ints);
}

void verifyGS1EncodedData(QRCode qrCode) {
  String expected = "<<\n" " mode: ALPHANUMERIC\n" +
      " ecLevel: H\n" +
      " version: 2\n" +
      " maskPattern: 4\n" +
      " matrix:\n" +
      " 1 1 1 1 1 1 1 0 0 1 1 1 1 0 1 0 1 0 1 1 1 1 1 1 1\n" +
      " 1 0 0 0 0 0 1 0 1 1 0 0 0 0 0 1 1 0 1 0 0 0 0 0 1\n" +
      " 1 0 1 1 1 0 1 0 0 0 0 0 1 1 1 0 1 0 1 0 1 1 1 0 1\n" +
      " 1 0 1 1 1 0 1 0 0 1 0 1 0 0 1 1 0 0 1 0 1 1 1 0 1\n" +
      " 1 0 1 1 1 0 1 0 0 0 1 1 1 0 0 0 1 0 1 0 1 1 1 0 1\n" +
      " 1 0 0 0 0 0 1 0 1 1 0 1 1 0 1 1 0 0 1 0 0 0 0 0 1\n" +
      " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n" +
      " 0 0 0 0 0 0 0 0 1 1 0 1 1 0 1 1 0 0 0 0 0 0 0 0 0\n" +
      " 0 0 0 0 1 1 1 1 0 0 1 1 0 0 0 1 1 0 1 1 0 0 0 1 0\n" +
      " 0 1 1 0 1 1 0 0 1 1 1 0 0 0 1 1 1 1 1 1 1 0 0 0 1\n" +
      " 0 0 1 1 1 1 1 0 1 1 1 1 1 0 1 0 0 0 0 0 0 1 1 1 0\n" +
      " 1 0 1 1 1 0 0 1 1 1 0 1 1 1 1 1 0 1 1 0 1 1 1 0 0\n" +
      " 0 1 0 1 0 0 1 1 1 1 1 1 0 0 1 1 0 1 0 0 0 0 0 1 0\n" +
      " 1 0 0 1 1 1 0 0 1 1 0 0 0 1 1 0 1 0 1 0 1 0 0 0 0\n" +
      " 0 0 1 0 0 1 1 1 0 1 1 0 1 1 1 0 1 1 1 0 1 1 1 1 0\n" +
      " 0 0 0 1 1 0 0 1 0 0 1 0 0 1 1 0 0 1 0 0 0 1 1 1 0\n" +
      " 1 1 0 1 0 1 1 0 1 0 1 0 0 0 1 1 1 1 1 1 1 0 0 0 0\n" +
      " 0 0 0 0 0 0 0 0 1 1 0 1 0 0 0 1 1 0 0 0 1 1 0 1 0\n" +
      " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 0 1 0 1 0 0 0 0\n" +
      " 1 0 0 0 0 0 1 0 1 1 0 0 0 1 0 1 1 0 0 0 1 0 1 1 0\n" +
      " 1 0 1 1 1 0 1 0 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 1\n" +
      " 1 0 1 1 1 0 1 0 0 0 0 0 0 1 1 1 0 0 1 1 0 1 0 0 0\n" +
      " 1 0 1 1 1 0 1 0 0 0 1 1 0 1 0 1 1 1 0 1 1 0 0 1 0\n" +
      " 1 0 0 0 0 0 1 0 0 1 1 0 1 1 1 1 1 0 1 0 1 1 0 0 0\n" +
      " 1 1 1 1 1 1 1 0 0 0 1 0 0 0 0 1 1 0 0 1 1 0 0 1 1\n" +
      ">>\n";
  expect(expected, qrCode.toString());
}

void verifyNotGS1EncodedData(QRCode qrCode) {
  String expected = "<<\n" " mode: ALPHANUMERIC\n" +
      " ecLevel: H\n" +
      " version: 1\n" +
      " maskPattern: 4\n" +
      " matrix:\n" +
      " 1 1 1 1 1 1 1 0 0 1 0 1 0 0 1 1 1 1 1 1 1\n" +
      " 1 0 0 0 0 0 1 0 1 0 1 0 1 0 1 0 0 0 0 0 1\n" +
      " 1 0 1 1 1 0 1 0 0 0 0 0 0 0 1 0 1 1 1 0 1\n" +
      " 1 0 1 1 1 0 1 0 0 1 0 0 1 0 1 0 1 1 1 0 1\n" +
      " 1 0 1 1 1 0 1 0 0 1 0 1 0 0 1 0 1 1 1 0 1\n" +
      " 1 0 0 0 0 0 1 0 1 0 0 1 1 0 1 0 0 0 0 0 1\n" +
      " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n" +
      " 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0\n" +
      " 0 0 0 0 1 1 1 1 0 1 1 0 1 0 1 1 0 0 0 1 0\n" +
      " 0 0 0 0 1 1 0 1 1 1 0 0 1 1 1 1 0 1 1 0 1\n" +
      " 1 0 0 0 0 1 1 0 0 1 0 1 0 0 0 1 1 1 0 1 1\n" +
      " 1 0 0 1 1 1 0 0 1 1 1 1 0 0 0 0 1 0 0 0 0\n" +
      " 0 1 1 1 1 1 1 0 1 0 1 0 1 1 1 0 0 1 1 0 0\n" +
      " 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1 0 0 0 1 0 1\n" +
      " 1 1 1 1 1 1 1 0 1 1 1 1 0 0 0 0 0 1 1 0 0\n" +
      " 1 0 0 0 0 0 1 0 1 1 0 1 0 0 0 1 0 1 1 1 1\n" +
      " 1 0 1 1 1 0 1 0 1 0 0 1 0 0 0 1 1 0 0 1 1\n" +
      " 1 0 1 1 1 0 1 0 0 0 1 1 0 1 0 0 0 0 1 1 1\n" +
      " 1 0 1 1 1 0 1 0 0 1 0 1 0 0 0 1 1 0 0 0 0\n" +
      " 1 0 0 0 0 0 1 0 0 1 0 0 1 0 0 1 1 0 0 0 1\n" +
      " 1 1 1 1 1 1 1 0 0 0 1 0 0 1 0 0 0 0 1 1 1\n" +
      ">>\n";
  expect(expected, qrCode.toString());
}

String shiftJISString(Uint8List bytes) {
  return StringUtils.shiftJisCharset!.decode(bytes);
}
