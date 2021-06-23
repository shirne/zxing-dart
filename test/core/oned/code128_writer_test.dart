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
void main(){

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
  //  writer = new Code128Writer();
  //  reader = new Code128Reader();
  //}


  void testEncode(String toEncode, String expected){
    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(expected, actual, reason:toEncode);

    BitArray row = result.getRow(0, null);
    Result rtResult = reader.decodeRow(0, row, null);
    String actualRoundtripResultText = rtResult.text;
    expect(toEncode, actualRoundtripResultText);
  }

  test('testEncodeWithFunc3', (){
    String toEncode = "\u00f3" + "123";
    //                                                       "1"            "2"             "3"          check digit 51
    String expected = QUIET_SPACE + START_CODE_B + FNC3 + "10011100110" + "11001110010" + "11001011100" + "11101000110" + STOP + QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(expected, actual);
  });

  test('testEncodeWithFunc2', (){
    String toEncode = "\u00f2" + "123";
    //                                                       "1"            "2"             "3"          check digit 56
    String expected = QUIET_SPACE + START_CODE_B + FNC2 + "10011100110" + "11001110010" + "11001011100" + "11100010110" + STOP + QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(expected, actual);
  });

  test('testEncodeWithFunc1', (){
    String toEncode = "\u00f1" + "123";
    //                                                       "12"                           "3"          check digit 92
    String expected = QUIET_SPACE + START_CODE_C + FNC1 + "10110011100" + SWITCH_CODE_B + "11001011100" + "10101111000" + STOP + QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(expected, actual);
  });

  test('testRoundtrip', (){
    String toEncode = "\u00f1" + "10958" + "\u00f1" + "17160526";
    String expected = "1095817160526";

    BitMatrix encResult = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);
    BitArray row = encResult.getRow(0, null);
    Result rtResult = reader.decodeRow(0, row, null);
    String actual = rtResult.text;
    expect(expected, actual);
  });

  test('testEncodeWithFunc4', (){
    String toEncode = "\u00f4" + "123";
    //                                                       "1"            "2"             "3"          check digit 59
    String expected = QUIET_SPACE + START_CODE_B + FNC4B + "10011100110" + "11001110010" + "11001011100" + "11100011010" + STOP + QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);
    expect(expected, actual);
  });

  test('testEncodeWithFncsAndNumberInCodesetA', (){
    String toEncode = "\n" + "\u00f1" + "\u00f4" + "1" + "\n";

    String expected = QUIET_SPACE + START_CODE_A + LF + FNC1 + FNC4A + "10011100110" + LF + "10101111000" + STOP + QUIET_SPACE;

    BitMatrix result = writer.encode(toEncode, BarcodeFormat.CODE_128, 0, 0);

    String actual = matrixToString(result);

    expect(expected, actual);
  });

  test('testEncodeSwitchBetweenCodesetsAAndB', (){
    // start with A switch to B and back to A
    //                                                      "\x00"            "A"             "B"             Switch to B     "a"             "b"             Switch to A     "\u0010"        check digit
    testEncode("\x00ABab\u0010", QUIET_SPACE + START_CODE_A + "10100001100" + "10100011000" + "10001011000" + SWITCH_CODE_B + "10010110000" + "10010000110" + SWITCH_CODE_A + "10100111100" + "11001110100" + STOP + QUIET_SPACE);

    // start with B switch to A and back to B
    //                                                "a"             "b"             Switch to A     "\x00             "Switch to B"   "a"             "b"             check digit
    testEncode("ab\x00ab", QUIET_SPACE + START_CODE_B + "10010110000" + "10010000110" + SWITCH_CODE_A + "10100001100" + SWITCH_CODE_B + "10010110000" + "10010000110" + "11010001110" + STOP + QUIET_SPACE);
  });

}
