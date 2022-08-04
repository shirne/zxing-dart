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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/aztec.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

import '../../utils.dart';

/// Tests [Decoder].
void main() {
  final List<ResultPoint> noPoints = [];

  final RegExp dotX = RegExp('[^.X]');
  final RegExp spaces = RegExp('\\s+');

  String stripSpace(String s) {
    return s.replaceAll(spaces, '');
  }

  BitArray toBitArray(String bits) {
    final inBit = BitArray();
    final str = bits.replaceAll(dotX, '').split('');
    for (String aStr in str) {
      inBit.appendBit(aStr == 'X');
    }
    return inBit;
  }

  List<bool> toBooleanArray(BitArray bitArray) {
    final List<bool> result = List.filled(bitArray.size, false);
    for (int i = 0; i < result.length; i++) {
      result[i] = bitArray[i];
    }
    return result;
  }

  void testHighLevelDecodeString(String expectedString, String b) {
    final BitArray bits = toBitArray(stripSpace(b));
    expect(expectedString, Decoder.highLevelDecode(toBooleanArray(bits)),
        reason: 'highLevelDecode() failed for input bits: $b');
  }

  test('testHighLevelDecode', () {
    // no ECI codes
    testHighLevelDecodeString(
        'A. b.',
        // 'A'  P/S   '. ' L/L    b    D/L    '.'
        '...X. ..... ...XX XXX.. ...XX XXXX. XX.X');

    // initial ECI code 26 (switch to UTF-8)
    testHighLevelDecodeString(
        'Ça',
        // P/S FLG(n) 2  '2'  '6'  B/S   2     0xc3     0x87     L/L   'a'
        '..... ..... .X. .X.. X... XXXXX ...X. XX....XX X....XXX XXX.. ...X.');

    // initial character without ECI (must be interpreted as ISO_8859_1)
    // followed by ECI code 26 (= UTF-8) and UTF-8 text
    testHighLevelDecodeString(
        '±Ça',
        // B/S 1     0xb1     P/S   FLG(n) 2  '2'  '6'  B/S   2     0xc3     0x87     L/L   'a'
        'XXXXX ....X X.XX...X ..... ..... .X. .X.. X... XXXXX ...X. XX....XX X....XXX XXX.. ...X.');

    // GS1 data
    testHighLevelDecodeString(
        '101233742',
        // P/S FLG(n) 0  D/L   1    0    1    2    3    P/S  FLG(n) 0  3    7    4    2
        '..... ..... ... XXXX. ..XX ..X. ..XX .X.. .X.X .... ..... ... .X.X X..X .XX. .X..');
  });

  test('testAztecResult', () {
    final BitMatrix matrix = BitMatrix.parse(
        'X X X X X     X X X       X X X     X X X     \n'
            'X X X     X X X     X X X X     X X X     X X \n'
            '  X   X X       X   X   X X X X     X     X X \n'
            '  X   X X     X X     X     X   X       X   X \n'
            '  X X   X X         X               X X     X \n'
            '  X X   X X X X X X X X X X X X X X X     X   \n'
            '  X X X X X                       X   X X X   \n'
            '  X   X   X   X X X X X X X X X   X X X   X X \n'
            '  X   X X X   X               X   X X       X \n'
            '  X X   X X   X   X X X X X   X   X X X X   X \n'
            '  X X   X X   X   X       X   X   X   X X X   \n'
            '  X   X   X   X   X   X   X   X   X   X   X   \n'
            '  X X X   X   X   X       X   X   X X   X X   \n'
            '  X X X X X   X   X X X X X   X   X X X   X X \n'
            'X X   X X X   X               X   X   X X   X \n'
            '  X       X   X X X X X X X X X   X   X     X \n'
            '  X X   X X                       X X   X X   \n'
            '  X X X   X X X X X X X X X X X X X X   X X   \n'
            'X     X     X     X X   X X               X X \n'
            'X   X X X X X   X X X X X     X   X   X     X \n'
            'X X X   X X X X           X X X       X     X \n'
            'X X     X X X     X X X X     X X X     X X   \n'
            '    X X X     X X X       X X X     X X X X   \n',
        'X ',
        '  ');
    final AztecDetectorResult r =
        AztecDetectorResult(matrix, noPoints, false, 30, 2);
    final DecoderResult result = Decoder().decode(r);
    expect(result.text, '88888TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT');
    assertArrayEquals(
        Uint8List.fromList([
          -11, 85, 85, 117, 107, 90, -42, -75, -83, 107, //
          90, -42, -75, -83, 107, 90, -42, -75, -83, 107,
          90, -42, -80
        ]),
        result.rawBytes);
    expect(result.numBits, 180);
  });

  test('testAztecResultECI', () {
    final BitMatrix matrix = BitMatrix.parse(
        '      X     X X X   X           X     \n'
            '    X X   X X   X X X X X X X   X     \n'
            '    X X                         X   X \n'
            '  X X X X X X X X X X X X X X X X X   \n'
            '      X                       X       \n'
            '      X   X X X X X X X X X   X   X   \n'
            '  X X X   X               X   X X X   \n'
            '  X   X   X   X X X X X   X   X X X   \n'
            '      X   X   X       X   X   X X X   \n'
            '  X   X   X   X   X   X   X   X   X   \n'
            'X   X X   X   X       X   X   X     X \n'
            '  X X X   X   X X X X X   X   X X     \n'
            '      X   X               X   X X   X \n'
            '      X   X X X X X X X X X   X   X X \n'
            '  X   X                       X       \n'
            'X X   X X X X X X X X X X X X X X X   \n'
            'X X     X   X         X X X       X X \n'
            '  X   X   X   X X X X X     X X   X   \n'
            'X     X       X X   X X X       X     \n',
        'X ',
        '  ');
    final AztecDetectorResult r =
        AztecDetectorResult(matrix, noPoints, false, 15, 1);
    final DecoderResult result = Decoder().decode(r);
    expect(result.text, 'Français');
  });

  //@Test(expected = FormatException.class)
  test('testDecodeTooManyErrors', () {
    final BitMatrix matrix = BitMatrix.parse(
        ''
            'X X . X . . . X X . . . X . . X X X . X . X X X X X . \n'
            'X X . . X X . . . . . X X . . . X X . . . X . X . . X \n'
            'X . . . X X . . X X X . X X . X X X X . X X . . X . . \n'
            '. . . . X . X X . . X X . X X . X . X X X X . X . . X \n'
            'X X X . . X X X X X . . . . . X X . . . X . X . X . X \n'
            'X X . . . . . . . . X . . . X . X X X . X . . X . . . \n'
            'X X . . X . . . . . X X . . . . . X . . . . X . . X X \n'
            '. . . X . X . X . . . . . X X X X X X . . . . . . X X \n'
            'X . . . X . X X X X X X . . X X X . X . X X X X X X . \n'
            'X . . X X X . X X X X X X X X X X X X X . . . X . X X \n'
            '. . . . X X . . . X . . . . . . . X X . . . X X . X . \n'
            '. . . X X X . . X X . X X X X X . X . . X . . . . . . \n'
            'X . . . . X . X . X . X . . . X . X . X X . X X . X X \n'
            'X . X . . X . X . X . X . X . X . X . . . . . X . X X \n'
            'X . X X X . . X . X . X . . . X . X . X X X . . . X X \n'
            'X X X X X X X X . X . X X X X X . X . X . X . X X X . \n'
            '. . . . . . . X . X . . . . . . . X X X X . . . X X X \n'
            'X X . . X . . X . X X X X X X X X X X X X X . . X . X \n'
            'X X X . X X X X . . X X X X . . X . . . . X . . X X X \n'
            '. . . . X . X X X . . . . X X X X . . X X X X . . . . \n'
            '. . X . . X . X . . . X . X X . X X . X . . . X . X . \n'
            'X X . . X . . X X X X X X X . . X . X X X X X X X . . \n'
            'X . X X . . X X . . . . . X . . . . . . X X . X X X . \n'
            'X . . X X . . X X . X . X . . . . X . X . . X . . X . \n'
            'X . X . X . . X . X X X X X X X X . X X X X . . X X . \n'
            'X X X X . . . X . . X X X . X X . . X . . . . X X X . \n'
            'X X . X . X . . . X . X . . . . X X . X . . X X . . . \n',
        'X ',
        '. ');
    final AztecDetectorResult r =
        AztecDetectorResult(matrix, noPoints, true, 16, 4);
    try {
      Decoder().decode(r);
      fail('here should be FormatException');
    } catch (_) {
      // passed
    }
  });

  //@Test(expected = FormatException.class)
  test('testDecodeTooManyErrors2', () {
    final BitMatrix matrix = BitMatrix.parse(
        ''
            '. X X . . X . X X . . . X . . X X X . . . X X . X X . \n'
            'X X . X X . . X . . . X X . . . X X . X X X . X . X X \n'
            '. . . . X . . . X X X . X X . X X X X . X X . . X . . \n'
            'X . X X . . X . . . X X . X X . X . X X . . . . . X . \n'
            'X X . X . . X . X X . . . . . X X . . . . . X . . . X \n'
            'X . . X . . . . . . X . . . X . X X X X X X X . . . X \n'
            'X . . X X . . X . . X X . . . . . X . . . . . X X X . \n'
            '. . X X X X . X . . . . . X X X X X X . . . . . . X X \n'
            'X . . . X . X X X X X X . . X X X . X . X X X X X X . \n'
            'X . . X X X . X X X X X X X X X X X X X . . . X . X X \n'
            '. . . . X X . . . X . . . . . . . X X . . . X X . X . \n'
            '. . . X X X . . X X . X X X X X . X . . X . . . . . . \n'
            'X . . . . X . X . X . X . . . X . X . X X . X X . X X \n'
            'X . X . . X . X . X . X . X . X . X . . . . . X . X X \n'
            'X . X X X . . X . X . X . . . X . X . X X X . . . X X \n'
            'X X X X X X X X . X . X X X X X . X . X . X . X X X . \n'
            '. . . . . . . X . X . . . . . . . X X X X . . . X X X \n'
            'X X . . X . . X . X X X X X X X X X X X X X . . X . X \n'
            'X X X . X X X X . . X X X X . . X . . . . X . . X X X \n'
            '. . X X X X X . X . . . . X X X X . . X X X . X . X . \n'
            '. . X X . X . X . . . X . X X . X X . . . . X X . . . \n'
            'X . . . X . X . X X X X X X . . X . X X X X X . X . . \n'
            '. X . . . X X X . . . . . X . . . . . X X X X X . X . \n'
            'X . . X . X X X X . X . X . . . . X . X X . X . . X . \n'
            'X . . . X X . X . X X X X X X X X . X X X X . . X X . \n'
            '. X X X X . . X . . X X X . X X . . X . . . . X X X . \n'
            'X X . . . X X . . X . X . . . . X X . X . . X . X . X \n',
        'X ',
        '. ');
    final AztecDetectorResult r =
        AztecDetectorResult(matrix, noPoints, true, 16, 4);
    try {
      Decoder().decode(r);
      fail('here should be FormatException');
    } catch (_) {
      // passed
    }
  });

  test('testRawBytes', () {
    final List<bool> bool0 = [];
    final List<bool> bool1 = [true];
    final List<bool> bool7 = [true, false, true, false, true, false, true];
    final List<bool> bool8 = [
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false
    ];
    final List<bool> bool9 = [
      true, false, true, false, true, false, true, false, true //
    ];
    final List<bool> bool16 = [
      false, true, true, false, false, false, true, true, true, //
      true, false, false, false, false, false, true
    ];
    final Uint8List byte0 = Uint8List.fromList([]);
    final Uint8List byte1 = Uint8List.fromList([-128]);
    final Uint8List byte7 = Uint8List.fromList([-86]);
    final Uint8List byte8 = Uint8List.fromList([-86]);
    final Uint8List byte9 = Uint8List.fromList([-86, -128]);
    final Uint8List byte16 = Uint8List.fromList([99, -63]);

    assertArrayEquals(byte0, Decoder.convertBoolArrayToByteArray(bool0));
    assertArrayEquals(byte1, Decoder.convertBoolArrayToByteArray(bool1));
    assertArrayEquals(byte7, Decoder.convertBoolArrayToByteArray(bool7));
    assertArrayEquals(byte8, Decoder.convertBoolArrayToByteArray(bool8));
    assertArrayEquals(byte9, Decoder.convertBoolArrayToByteArray(bool9));
    assertArrayEquals(byte16, Decoder.convertBoolArrayToByteArray(bool16));
  });
}
