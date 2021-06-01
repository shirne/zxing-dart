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

import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/datamatrix.dart';




/**
 * @author bbrown@google.com (Brian Brown)
 */
void main(){

  test('testAsciiStandardDecode', (){
    // ASCII characters 0-127 are encoded as the value + 1
    Uint8List bytes = Uint8List.fromList([('a'.codeUnitAt(0) + 1), ('b'.codeUnitAt(0) + 1), ('c'.codeUnitAt(0) + 1),
                    ('A'.codeUnitAt(0) + 1), ('B'.codeUnitAt(0) + 1), ('C'.codeUnitAt(0) + 1)]);
    String decodedString = DecodedBitStreamParser.decode(bytes).getText();
    expect("abcABC", decodedString);
  });

  test('testAsciiDoubleDigitDecode', (){
    // ASCII double digit (00 - 99) Numeric Value + 130
    Uint8List bytes = Uint8List.fromList([ 130 , (1 + 130),
                    (98 + 130), (99 + 130)]);
    String decodedString = DecodedBitStreamParser.decode(bytes).getText();
    expect("00019899", decodedString);
  });
  
  // TODO(bbrown): Add test cases for each encoding type
  // TODO(bbrown): Add test cases for switching encoding types
}