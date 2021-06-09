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

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zxing_lib/aztec.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

import '../../utils.dart';





/// Tests {@link Decoder}.
void main(){

  final List<ResultPoint> NO_POINTS = [];

  final RegExp DOTX = RegExp("[^.X]");
  final RegExp SPACES = RegExp("\\s+");

  String stripSpace(String s) {
    return s.replaceAll(SPACES, '');
  }

  BitArray toBitArray(String bits) {
    BitArray inBit = new BitArray();
    List<String> str = bits.replaceAll(DOTX, "").split('');
    for (String aStr in str) {
      inBit.appendBit(aStr == 'X');
    }
    return inBit;
  }

  List<bool> toBooleanArray(BitArray bitArray) {
    List<bool> result = List.filled(bitArray.size, false);
    for (int i = 0; i < result.length; i++) {
      result[i] = bitArray[i];
    }
    return result;
  }

  void testHighLevelDecodeString(String expectedString, String b){
    BitArray bits = toBitArray(stripSpace(b));
    expect(expectedString, Decoder.highLevelDecode(toBooleanArray(bits)), reason: "highLevelDecode() failed for input bits: $b");
  }

  test('testHighLevelDecode', (){
      // no ECI codes
      testHighLevelDecodeString("A. b.",
          // 'A'  P/S   '. ' L/L    b    D/L    '.'
          "...X. ..... ...XX XXX.. ...XX XXXX. XX.X");

      // initial ECI code 26 (switch to UTF-8)
      testHighLevelDecodeString("Ça",
          // P/S FLG(n) 2  '2'  '6'  B/S   2     0xc3     0x87     L/L   'a'
          "..... ..... .X. .X.. X... XXXXX ...X. XX....XX X....XXX XXX.. ...X.");

      // initial character without ECI (must be interpreted as ISO_8859_1)
      // followed by ECI code 26 (= UTF-8) and UTF-8 text
      testHighLevelDecodeString("±Ça",
         // B/S 1     0xb1     P/S   FLG(n) 2  '2'  '6'  B/S   2     0xc3     0x87     L/L   'a'
         "XXXXX ....X X.XX...X ..... ..... .X. .X.. X... XXXXX ...X. XX....XX X....XXX XXX.. ...X.");
  });

  test('testAztecResult', (){
    BitMatrix matrix = BitMatrix.parse(
        "X X X X X     X X X       X X X     X X X     \n" +
        "X X X     X X X     X X X X     X X X     X X \n" +
        "  X   X X       X   X   X X X X     X     X X \n" +
        "  X   X X     X X     X     X   X       X   X \n" +
        "  X X   X X         X               X X     X \n" +
        "  X X   X X X X X X X X X X X X X X X     X   \n" +
        "  X X X X X                       X   X X X   \n" +
        "  X   X   X   X X X X X X X X X   X X X   X X \n" +
        "  X   X X X   X               X   X X       X \n" +
        "  X X   X X   X   X X X X X   X   X X X X   X \n" +
        "  X X   X X   X   X       X   X   X   X X X   \n" +
        "  X   X   X   X   X   X   X   X   X   X   X   \n" +
        "  X X X   X   X   X       X   X   X X   X X   \n" +
        "  X X X X X   X   X X X X X   X   X X X   X X \n" +
        "X X   X X X   X               X   X   X X   X \n" +
        "  X       X   X X X X X X X X X   X   X     X \n" +
        "  X X   X X                       X X   X X   \n" +
        "  X X X   X X X X X X X X X X X X X X   X X   \n" +
        "X     X     X     X X   X X               X X \n" +
        "X   X X X X X   X X X X X     X   X   X     X \n" +
        "X X X   X X X X           X X X       X     X \n" +
        "X X     X X X     X X X X     X X X     X X   \n" +
        "    X X X     X X X       X X X     X X X X   \n",
        "X ", "  ");
    AztecDetectorResult r = new AztecDetectorResult(matrix, NO_POINTS, false, 30, 2);
    DecoderResult result = new Decoder().decode(r);
    expect(result.text, "88888TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT");
    assertArrayEquals(
        Uint8List.fromList([-11, 85, 85, 117, 107, 90, -42, -75, -83, 107,
            90, -42, -75, -83, 107, 90, -42, -75, -83, 107,
            90, -42, -80]),
        result.rawBytes);
    expect(result.numBits, 180);
  });

  test('testAztecResultECI', (){
    BitMatrix matrix = BitMatrix.parse(
        "      X     X X X   X           X     \n" +
        "    X X   X X   X X X X X X X   X     \n" +
        "    X X                         X   X \n" +
        "  X X X X X X X X X X X X X X X X X   \n" +
        "      X                       X       \n" +
        "      X   X X X X X X X X X   X   X   \n" +
        "  X X X   X               X   X X X   \n" +
        "  X   X   X   X X X X X   X   X X X   \n" +
        "      X   X   X       X   X   X X X   \n" +
        "  X   X   X   X   X   X   X   X   X   \n" +
        "X   X X   X   X       X   X   X     X \n" +
        "  X X X   X   X X X X X   X   X X     \n" +
        "      X   X               X   X X   X \n" +
        "      X   X X X X X X X X X   X   X X \n" +
        "  X   X                       X       \n" +
        "X X   X X X X X X X X X X X X X X X   \n" +
        "X X     X   X         X X X       X X \n" +
        "  X   X   X   X X X X X     X X   X   \n" +
        "X     X       X X   X X X       X     \n",
        "X ", "  ");
    AztecDetectorResult r = new AztecDetectorResult(matrix, NO_POINTS, false, 15, 1);
    DecoderResult result = new Decoder().decode(r);
    expect(result.text, "Français");
  });

  //@Test(expected = FormatException.class)
  test('testDecodeTooManyErrors', (){
    BitMatrix matrix = BitMatrix.parse(""
        + "X X . X . . . X X . . . X . . X X X . X . X X X X X . \n"
        + "X X . . X X . . . . . X X . . . X X . . . X . X . . X \n"
        + "X . . . X X . . X X X . X X . X X X X . X X . . X . . \n"
        + ". . . . X . X X . . X X . X X . X . X X X X . X . . X \n"
        + "X X X . . X X X X X . . . . . X X . . . X . X . X . X \n"
        + "X X . . . . . . . . X . . . X . X X X . X . . X . . . \n"
        + "X X . . X . . . . . X X . . . . . X . . . . X . . X X \n"
        + ". . . X . X . X . . . . . X X X X X X . . . . . . X X \n"
        + "X . . . X . X X X X X X . . X X X . X . X X X X X X . \n"
        + "X . . X X X . X X X X X X X X X X X X X . . . X . X X \n"
        + ". . . . X X . . . X . . . . . . . X X . . . X X . X . \n"
        + ". . . X X X . . X X . X X X X X . X . . X . . . . . . \n"
        + "X . . . . X . X . X . X . . . X . X . X X . X X . X X \n"
        + "X . X . . X . X . X . X . X . X . X . . . . . X . X X \n"
        + "X . X X X . . X . X . X . . . X . X . X X X . . . X X \n"
        + "X X X X X X X X . X . X X X X X . X . X . X . X X X . \n"
        + ". . . . . . . X . X . . . . . . . X X X X . . . X X X \n"
        + "X X . . X . . X . X X X X X X X X X X X X X . . X . X \n"
        + "X X X . X X X X . . X X X X . . X . . . . X . . X X X \n"
        + ". . . . X . X X X . . . . X X X X . . X X X X . . . . \n"
        + ". . X . . X . X . . . X . X X . X X . X . . . X . X . \n"
        + "X X . . X . . X X X X X X X . . X . X X X X X X X . . \n"
        + "X . X X . . X X . . . . . X . . . . . . X X . X X X . \n"
        + "X . . X X . . X X . X . X . . . . X . X . . X . . X . \n"
        + "X . X . X . . X . X X X X X X X X . X X X X . . X X . \n"
        + "X X X X . . . X . . X X X . X X . . X . . . . X X X . \n"
        + "X X . X . X . . . X . X . . . . X X . X . . X X . . . \n",
        "X ", ". ");
    AztecDetectorResult r = new AztecDetectorResult(matrix, NO_POINTS, true, 16, 4);
    try {
      new Decoder().decode(r);
      fail('here should be FormatException');
    }catch(_){
      // passed
    }
  });

  //@Test(expected = FormatException.class)
  test('testDecodeTooManyErrors2', (){
    BitMatrix matrix = BitMatrix.parse(""
        + ". X X . . X . X X . . . X . . X X X . . . X X . X X . \n"
        + "X X . X X . . X . . . X X . . . X X . X X X . X . X X \n"
        + ". . . . X . . . X X X . X X . X X X X . X X . . X . . \n"
        + "X . X X . . X . . . X X . X X . X . X X . . . . . X . \n"
        + "X X . X . . X . X X . . . . . X X . . . . . X . . . X \n"
        + "X . . X . . . . . . X . . . X . X X X X X X X . . . X \n"
        + "X . . X X . . X . . X X . . . . . X . . . . . X X X . \n"
        + ". . X X X X . X . . . . . X X X X X X . . . . . . X X \n"
        + "X . . . X . X X X X X X . . X X X . X . X X X X X X . \n"
        + "X . . X X X . X X X X X X X X X X X X X . . . X . X X \n"
        + ". . . . X X . . . X . . . . . . . X X . . . X X . X . \n"
        + ". . . X X X . . X X . X X X X X . X . . X . . . . . . \n"
        + "X . . . . X . X . X . X . . . X . X . X X . X X . X X \n"
        + "X . X . . X . X . X . X . X . X . X . . . . . X . X X \n"
        + "X . X X X . . X . X . X . . . X . X . X X X . . . X X \n"
        + "X X X X X X X X . X . X X X X X . X . X . X . X X X . \n"
        + ". . . . . . . X . X . . . . . . . X X X X . . . X X X \n"
        + "X X . . X . . X . X X X X X X X X X X X X X . . X . X \n"
        + "X X X . X X X X . . X X X X . . X . . . . X . . X X X \n"
        + ". . X X X X X . X . . . . X X X X . . X X X . X . X . \n"
        + ". . X X . X . X . . . X . X X . X X . . . . X X . . . \n"
        + "X . . . X . X . X X X X X X . . X . X X X X X . X . . \n"
        + ". X . . . X X X . . . . . X . . . . . X X X X X . X . \n"
        + "X . . X . X X X X . X . X . . . . X . X X . X . . X . \n"
        + "X . . . X X . X . X X X X X X X X . X X X X . . X X . \n"
        + ". X X X X . . X . . X X X . X X . . X . . . . X X X . \n"
        + "X X . . . X X . . X . X . . . . X X . X . . X . X . X \n",
        "X ", ". ");
    AztecDetectorResult r = new AztecDetectorResult(matrix, NO_POINTS, true, 16, 4);
    try {
      new Decoder().decode(r);
      fail('here should be FormatException');
    }catch(_){
      // passed
    }
  });

  test('testRawBytes', () {
    List<bool> bool0 = [];
    List<bool> bool1 = [true] ;
    List<bool> bool7 = [true, false, true, false, true, false, true ];
    List<bool> bool8 = [true, false, true, false, true, false, true, false ];
    List<bool> bool9 = [true, false, true, false, true, false, true, false,
                        true ];
    List<bool> bool16 = [false, true, true, false, false, false, true, true,
                         true, true, false, false, false, false, false, true ];
    Uint8List byte0 = Uint8List.fromList([]);
    Uint8List byte1 = Uint8List.fromList([ -128 ]);
    Uint8List byte7 = Uint8List.fromList([ -86 ]);
    Uint8List byte8 = Uint8List.fromList([ -86 ]);
    Uint8List byte9 = Uint8List.fromList([ -86, -128 ]);
    Uint8List byte16 = Uint8List.fromList([ 99, -63 ]);

    assertArrayEquals(byte0, Decoder.convertBoolArrayToByteArray(bool0));
    assertArrayEquals(byte1, Decoder.convertBoolArrayToByteArray(bool1));
    assertArrayEquals(byte7, Decoder.convertBoolArrayToByteArray(bool7));
    assertArrayEquals(byte8, Decoder.convertBoolArrayToByteArray(bool8));
    assertArrayEquals(byte9, Decoder.convertBoolArrayToByteArray(bool9));
    assertArrayEquals(byte16, Decoder.convertBoolArrayToByteArray(bool16));
  });
}
