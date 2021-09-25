/*
 * Copyright 2014 ZXing authors
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
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../utils.dart';

/// Tests [Code128Writer].
void main() {
  const String FNC1 = "11110101110";
  const String FNC2 = "11110101000";
  const String FNC3 = "10111100010";
  const String FNC4A = "11101011110";
  const String FNC4B = "10111101110";
  const String START_CODE_A = "11010000100";
  const String START_CODE_B = "11010010000";
  const String START_CODE_C = "11010011100";
  const String SWITCH_CODE_A = "11101011110";
  const String SWITCH_CODE_B = "10111101110";
  const String QUIET_SPACE = "00000";
  const String STOP = "1100011101011";
  const String LF = "10000110010";

  Writer writer = Code128Writer();
  Code128Reader reader = Code128Reader();

  //@Before
  //void setUp() {
  //  writer = Code128Writer();
  //  reader = Code128Reader();
  //}

  void testEncode(String toEncode, String expected) {
    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(actual, expected, reason: toEncode);

    BitArray row = result.getRow(0, null);
    Result rtResult = reader.decodeRow(0, row, null);
    String actualRoundtripResultText = rtResult.text;
    expect(toEncode, actualRoundtripResultText);
  }

  test('testEncodeWithFunc3', () {
    String toEncode = "\u00f3" "123";
    String expected = QUIET_SPACE +
        START_CODE_B +
        FNC3 +
        "10011100110" + //"1"
        "11001110010" + //"2"
        "11001011100" + //"3"
        "11101000110" + //check digit 51
        STOP +
        QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(actual, expected);
  });

  test('testEncodeWithFunc2', () {
    String toEncode = "\u00f2" "123";
    String expected = QUIET_SPACE +
        START_CODE_B +
        FNC2 +
        "10011100110" + //"1"
        "11001110010" + //"2"
        "11001011100" + //"3"
        "11100010110" + //check digit 56
        STOP +
        QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(actual, expected);
  });

  test('testEncodeWithFunc1', () {
    String toEncode = "\u00f1" "123";
    String expected = QUIET_SPACE +
        START_CODE_C +
        FNC1 +
        "10110011100" + //"12"
        SWITCH_CODE_B +
        "11001011100" + //"3"
        "10101111000" + //check digit 92
        STOP +
        QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(actual, expected);
  });

  test('testRoundtrip', () {
    String toEncode = "\u00f1" "10958" "\u00f1" "17160526";
    String expected = "1095817160526";

    BitMatrix encResult = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);
    BitArray row = encResult.getRow(0, null);
    Result rtResult = reader.decodeRow(0, row, null);
    String actual = rtResult.text;
    expect(actual, expected);
  });

  test('testEncodeWithFunc4', () {
    String toEncode = "\u00f4" "123";
    String expected = QUIET_SPACE +
        START_CODE_B +
        FNC4B +
        "10011100110" + //"1"
        "11001110010" + //"2"
        "11001011100" + //"3"
        "11100011010" + //check digit 59
        STOP +
        QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(actual, expected);
  });

  test('testEncodeWithFncsAndNumberInCodesetA', () {
    String toEncode = "\n" "\u00f1" "\u00f4" "1" "\n";

    String expected = QUIET_SPACE +
        START_CODE_A +
        LF +
        FNC1 +
        FNC4A +
        "10011100110" +
        LF +
        "10101111000" +
        STOP +
        QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);

    expect(actual, expected);
  });

  test('testEncodeSwitchBetweenCodesetsAAndB', () {
    // start with A switch to B and back to A
    testEncode(
        "\x00ABab\u0010",
        QUIET_SPACE +
            START_CODE_A +
            "10100001100" + //"\x00"
            "10100011000" + //"A"
            "10001011000" + //"B"
            SWITCH_CODE_B + //Switch to B
            "10010110000" + // "a"
            "10010000110" + //"b"
            SWITCH_CODE_A + //Switch to A
            "10100111100" + //"\u0010"
            "11001110100" + //check digit
            STOP +
            QUIET_SPACE);

    // start with B switch to A and back to B
    testEncode(
        "ab\x00ab",
        QUIET_SPACE +
            START_CODE_B +
            "10010110000" + // "a"
            "10010000110" + // "b"
            SWITCH_CODE_A + // Switch to A
            "10100001100" + //"\x00             "
            SWITCH_CODE_B + // Switch to B
            "10010110000" + // "a"
            "10010000110" + // "b"
            "11010001110" + // check digit
            STOP +
            QUIET_SPACE);
  });

  test('testEncodeWithForcedCodeSetFailureCodeSetABadCharacter', () {
    String toEncode = "ASDFx0123";

    Map<EncodeHintType, Object> hints = {EncodeHintType.FORCE_CODE_SET: "A"};

    try {
      writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0, hints);
      fail(
          'Lower case characters should not be accepted when the code set is forced to A.');
    } on ArgumentError catch (_) {
      //IllegalArgumentException
    }
  });
  test('testEncodeWithForcedCodeSetFailureCodeSetBBadCharacter', () {
    String toEncode = "ASdf\x000123"; // \0 (ascii value 0)
    // Characters with ASCII value below 32 should not be accepted when the code set is forced to B.

    Map<EncodeHintType, Object> hints = {EncodeHintType.FORCE_CODE_SET: "B"};
    try {
      writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0, hints);
      fail(
          'Characters with ASCII value below 32 should not be accepted when the code set is forced to B.');
    } on ArgumentError catch (_) {
      //IllegalArgumentException
    }
  });

  test('testEncodeWithForcedCodeSetFailureCodeSetCBadCharactersNonNum', () {
    String toEncode = "123a5678";
    // Non-digit characters should not be accepted when the code set is forced to C.

    Map<EncodeHintType, Object> hints = {EncodeHintType.FORCE_CODE_SET: "C"};
    try {
      writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0, hints);
      fail(
          'Non-digit characters should not be accepted when the code set is forced to C.');
    } on ArgumentError catch (_) {
      //IllegalArgumentException
    }
  });

  test('testEncodeWithForcedCodeSetFailureCodeSetCBadCharactersFncCode', () {
    String toEncode = "123\u00f2a678";
    // Function codes other than 1 should not be accepted when the code set is forced to C.

    Map<EncodeHintType, Object> hints = {EncodeHintType.FORCE_CODE_SET: "C"};
    try {
      writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0, hints);
      fail(
          'Function codes other than 1 should not be accepted when the code set is forced to C.');
    } on ArgumentError catch (_) {
      //IllegalArgumentException
    }
  });

  test('testEncodeWithForcedCodeSetFailureCodeSetCWrongAmountOfDigits', () {
    String toEncode = "123456789";
    // An uneven amount of digits should not be accepted when the code set is forced to C.

    Map<EncodeHintType, Object> hints = {EncodeHintType.FORCE_CODE_SET: "C"};
    try {
      writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0, hints);
      fail(
          'An uneven amount of digits should not be accepted when the code set is forced to C.');
    } on ArgumentError catch (_) {
      //IllegalArgumentException
    }
  });

  test('testEncodeWithForcedCodeSetFailureCodeSetCWrongAmountOfDigits', () {
    String toEncode = "AB123";
    // would default to B
    String expected = QUIET_SPACE +
        START_CODE_A +
        "10100011000" + //"A"
        "10001011000" + //"B"
        "10011100110" + //"1"
        "11001110010" + //"2"
        "11001011100" + //"3"
        "11001000100" + //check digit 10
        STOP +
        QUIET_SPACE;

    Map<EncodeHintType, Object> hints = {EncodeHintType.FORCE_CODE_SET: "A"};

    BitMatrix result =
        writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0, hints);

    String actual = matrixToString(result);
    expect(actual, expected);
  });

  test('testEncodeWithForcedCodeSetFailureCodeSetB', () {
    String toEncode = "1234";
    //would default to C
    String expected = QUIET_SPACE +
        START_CODE_B +
        "10011100110" + //"1"
        "11001110010" + //"2"
        "11001011100" + //"3"
        "11001001110" + //"4"
        "11110010010" + //check digit 88
        STOP +
        QUIET_SPACE;

    Map<EncodeHintType, Object> hints = {EncodeHintType.FORCE_CODE_SET: "B"};
    BitMatrix result =
        writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0, hints);

    String actual = matrixToString(result);
    expect(actual, expected);
  });
}
