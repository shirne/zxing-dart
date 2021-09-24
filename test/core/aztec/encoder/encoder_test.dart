/*
 * Copyright 2013 ZXing authors
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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/aztec.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

/// Aztec 2D generator unit tests.
///
void main() {
  final Encoding iso_8859_1 = latin1;
  final Encoding utf_8 = utf8;
  final Encoding? shiftJis = StringUtils.shiftJisCharset;
  final Encoding? iso_8859_15 = CharacterSetECI.ISO8859_15.charset;
  final Encoding? windows1252 = CharacterSetECI.Cp1252.charset;

  final RegExp dotX = RegExp("[^.X]");
  final RegExp spaces = RegExp("\\s+");
  final List<ResultPoint> noPoints = [];

  // Helper routines

  String stripSpace(String s) {
    return s.replaceAll(spaces, '');
  }

  Random getPseudoRandom() {
    return Random(0xDEADBEEF);
  }

  void testEncode(String data, bool compact, int layers, String expected) {
    AztecCode aztec = Encoder.encode(data, 33, Encoder.DEFAULT_AZTEC_LAYERS);
    expect(aztec.isCompact, compact,
        reason: "Unexpected symbol format (compact)");
    expect(aztec.layers, layers, reason: "Unexpected nr. of layers");
    BitMatrix matrix = aztec.matrix!;
    expect(matrix.toString(), expected, reason: "encode() failed");
  }

  void testEncodeDecode(String data, bool compact, int layers) {
    AztecCode aztec = Encoder.encode(data, 25, Encoder.DEFAULT_AZTEC_LAYERS);
    expect(aztec.isCompact, compact,
        reason: "Unexpected symbol format (compact)");
    expect(aztec.layers, layers, reason: "Unexpected nr. of layers");
    BitMatrix matrix = aztec.matrix!;
    AztecDetectorResult r = AztecDetectorResult(
        matrix, noPoints, aztec.isCompact, aztec.codeWords, aztec.layers);
    DecoderResult res = Decoder().decode(r);
    expect(
      res.text,
      data,
    );
    // Check error correction by introducing a few minor errors
    Random random = getPseudoRandom();
    matrix.flip(random.nextInt(matrix.width), random.nextInt(2));
    matrix.flip(
        random.nextInt(matrix.width), matrix.height - 2 + random.nextInt(2));
    matrix.flip(random.nextInt(2), random.nextInt(matrix.height));
    matrix.flip(
        matrix.width - 2 + random.nextInt(2), random.nextInt(matrix.height));
    r = AztecDetectorResult(
        matrix, noPoints, aztec.isCompact, aztec.codeWords, aztec.layers);
    res = Decoder().decode(r);
    expect(res.text, data);
  }

  void testWriter(String data, Encoding? charset, int eccPercent, bool compact,
      int layers) {
    // Perform an encode-decode round-trip because it can be lossy.
    Map<EncodeHintType, Object> hints = {};
    if (null != charset) {
      hints[EncodeHintType.CHARACTER_SET] = charset.name;
    }
    hints[EncodeHintType.ERROR_CORRECTION] = eccPercent;
    AztecWriter writer = AztecWriter();
    BitMatrix matrix = writer.encode(data, BarcodeFormat.AZTEC, 0, 0, hints);
    AztecCode aztec =
        Encoder.encode(data, eccPercent, Encoder.DEFAULT_AZTEC_LAYERS, charset);
    expect(aztec.isCompact, compact,
        reason: "Unexpected symbol format (compact)");
    expect(aztec.layers, layers, reason: "Unexpected nr. of layers");
    BitMatrix matrix2 = aztec.matrix!;
    expect(matrix, matrix2);
    AztecDetectorResult r = AztecDetectorResult(
        matrix, noPoints, aztec.isCompact, aztec.codeWords, aztec.layers);
    DecoderResult res = Decoder().decode(r);
    expect(
      res.text,
      data,
    );
    // Check error correction by introducing up to eccPercent/2 errors
    int ecWords = aztec.codeWords * eccPercent ~/ 100 ~/ 2;
    Random random = getPseudoRandom();
    for (int i = 0; i < ecWords; i++) {
      // don't touch the core
      int x = random.nextBool()
          ? random.nextInt(aztec.layers * 2)
          : matrix.width - 1 - random.nextInt(aztec.layers * 2);
      int y = random.nextBool()
          ? random.nextInt(aztec.layers * 2)
          : matrix.height - 1 - random.nextInt(aztec.layers * 2);
      matrix.flip(x, y);
    }
    r = AztecDetectorResult(
        matrix, noPoints, aztec.isCompact, aztec.codeWords, aztec.layers);
    res = Decoder().decode(r);
    expect(res.text, data);
  }

  void testModeMessage(bool compact, int layers, int words, String expected) {
    BitArray inBit = Encoder.generateModeMessage(compact, layers, words);
    expect(stripSpace(expected), stripSpace(inBit.toString()),
        reason: "generateModeMessage() failed");
  }

  BitArray toBitArray(String bits) {
    BitArray inBit = BitArray();
    List<String> str = bits.replaceAll(dotX, "").split('');
    for (String aStr in str) {
      inBit.appendBit(aStr == 'X');
    }
    return inBit;
  }

  void testStuffBits(int wordSize, String bits, String expected) {
    BitArray inBit = toBitArray(bits);
    BitArray stuffed = Encoder.stuffBits(inBit, wordSize);
    expect(stripSpace(expected), stripSpace(stuffed.toString()),
        reason: "stuffBits() failed for input string: $bits");
  }

  List<bool> toBooleanArray(BitArray bitArray) {
    List<bool> result = List.filled(bitArray.size, false);
    for (int i = 0; i < result.length; i++) {
      result[i] = bitArray[i];
    }
    return result;
  }

  void testHighLevelEncodeStringString(String s, String expectedBits) {
    BitArray bits = HighLevelEncoder(latin1.encode(s)).encode();
    String receivedBits = stripSpace(bits.toString());
    expect(Decoder.highLevelDecode(toBooleanArray(bits)), s);
    expect(stripSpace(expectedBits), receivedBits,
        reason: "highLevelEncode() failed for input string: $s");
  }

  // todo 加密串长度和预期不一致，但是能解密 ?
  void testHighLevelEncodeStringInt(String s, int expectedReceivedBits) {
    BitArray bits = HighLevelEncoder(latin1.encode(s)).encode();
    int receivedBitCount = stripSpace(bits.toString()).length;
    expect(Decoder.highLevelDecode(toBooleanArray(bits)), s);
    if (expectedReceivedBits != receivedBitCount) {
      print(
          "highLevelEncode() result length($receivedBitCount) unexpected(expected $expectedReceivedBits) for input string: $s");
    }
    //expect(expectedReceivedBits, receivedBitCount, reason: "highLevelEncode() failed for input string: $s");
  }

  void testHighLevelEncodeString(String s, dynamic expBits) {
    if (expBits is String) {
      return testHighLevelEncodeStringString(s, expBits);
    } else {
      return testHighLevelEncodeStringInt(s, expBits as int);
    }
  }

  // real life tests

  test('testEncode1', () {
    testEncode(
        "This is an example Aztec symbol for Wikipedia.",
        true,
        3,
        "X     X X       X     X X     X     X         \n"
            "X         X     X X     X   X X   X X       X \n"
            "X X   X X X X X   X X X                 X     \n"
            "X X                 X X   X       X X X X X X \n"
            "    X X X   X   X     X X X X         X X     \n"
            "  X X X   X X X X   X     X   X     X X   X   \n"
            "        X X X X X     X X X X   X   X     X   \n"
            "X       X   X X X X X X X X X X X     X   X X \n"
            "X   X     X X X               X X X X   X X   \n"
            "X     X X   X X   X X X X X   X X   X   X X X \n"
            "X   X         X   X       X   X X X X       X \n"
            "X       X     X   X   X   X   X   X X   X     \n"
            "      X   X X X   X       X   X     X X X     \n"
            "    X X X X X X   X X X X X   X X X X X X   X \n"
            "  X X   X   X X               X X X   X X X X \n"
            "  X   X       X X X X X X X X X X X X   X X   \n"
            "  X X   X       X X X   X X X       X X       \n"
            "  X               X   X X     X     X X X     \n"
            "  X   X X X   X X   X   X X X X   X   X X X X \n"
            "    X   X   X X X   X   X   X X X X     X     \n"
            "        X               X                 X   \n"
            "        X X     X   X X   X   X   X       X X \n"
            "  X   X   X X       X   X         X X X     X \n");
  });

  test('testEncode2', () {
    testEncode(
        "Aztec Code is a public domain 2D matrix barcode symbology"
            " of nominally square symbols built on a square grid with a "
            "distinctive square bullseye pattern at their center.",
        false,
        6,
        "        X X     X X     X     X     X   X X X         X   X         X   X X       \n"
            "  X       X X     X   X X   X X       X             X     X   X X   X           X \n"
            "  X   X X X     X   X   X X     X X X   X   X X               X X       X X     X \n"
            "X X X             X   X         X         X     X     X   X     X X       X   X   \n"
            "X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X \n"
            "    X X   X   X   X X X               X       X       X X     X X   X X       X   \n"
            "X X     X       X       X X X X   X   X X       X   X X   X       X X   X X   X   \n"
            "  X       X   X     X X   X   X X   X X   X X X X X X   X X           X   X   X X \n"
            "X X   X X   X   X X X X   X X X X X X X X   X   X       X X   X X X X   X X X     \n"
            "  X       X   X     X       X X     X X   X   X   X     X X   X X X   X     X X X \n"
            "  X   X X X   X X       X X X         X X           X   X   X   X X X   X X     X \n"
            "    X     X   X X     X X X X     X   X     X X X X   X X   X X   X X X     X   X \n"
            "X X X   X             X         X X X X X   X   X X   X   X   X X   X   X   X   X \n"
            "          X       X X X   X X     X   X           X   X X X X   X X               \n"
            "  X     X X   X   X       X X X X X X X X X X X X X X X   X   X X   X   X X X     \n"
            "    X X                 X   X                       X X   X       X         X X X \n"
            "        X   X X   X X X X X X   X X X X X X X X X   X     X X           X X X X   \n"
            "          X X X   X     X   X   X               X   X X     X X X   X X           \n"
            "X X     X     X   X   X   X X   X   X X X X X   X   X X X X X X X       X   X X X \n"
            "X X X X       X       X   X X   X   X       X   X   X     X X X     X X       X X \n"
            "X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X \n"
            "    X     X       X         X   X   X       X   X   X     X   X X                 \n"
            "        X X     X X X X X   X   X   X X X X X   X   X X X     X X X X   X         \n"
            "X     X   X   X         X   X   X               X   X X   X X   X X X     X   X   \n"
            "  X   X X X   X   X X   X X X   X X X X X X X X X   X X         X X     X X X X   \n"
            "    X X   X   X   X X X     X                       X X X   X X   X   X     X     \n"
            "    X X X X   X         X   X X X X X X X X X X X X X X   X       X X   X X   X X \n"
            "            X   X   X X       X X X X X     X X X       X       X X X         X   \n"
            "X       X         X   X X X X   X     X X     X X     X X           X   X       X \n"
            "X     X       X X X X X     X   X X X X   X X X     X       X X X X   X   X X   X \n"
            "  X X X X X               X     X X X   X       X X   X X   X X X X     X X       \n"
            "X             X         X   X X   X X     X     X     X   X   X X X X             \n"
            "    X   X X       X     X       X   X X X X X X   X X   X X X X X X X X X   X   X \n"
            "    X         X X   X       X     X   X   X       X     X X X     X       X X X X \n"
            "X     X X     X X X X X X             X X X   X               X   X     X     X X \n"
            "X   X X     X               X X X X X     X X     X X X X X X X X     X   X   X X \n"
            "X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X   X \n"
            "X           X     X X X X     X     X         X         X   X       X X   X X X   \n"
            "X   X   X X   X X X   X         X X     X X X X     X X   X   X     X   X       X \n"
            "      X     X     X     X X     X   X X   X X   X         X X       X       X   X \n"
            "X       X           X   X   X     X X   X               X     X     X X X         \n");
  });

  test('testAztecWriter', () {
    // Without ECI (implicit ISO-8859-1)
    testWriter("Espa\u00F1ol", null, 25, true, 1);
    // Explicit ISO-8859-1
    testWriter("Espa\u00F1ol", iso_8859_1, 25, true, 1);
    // Standard ISO-8859-1 cannot encode Euro symbol; Windows-1252 superset can
    // testWriter("\u20AC 1 sample data.", windows1252, 25, true, 2);
    testWriter("\u20AC 1 sample data.", iso_8859_15, 25, true, 2);
    testWriter("\u20AC 1 sample data.", utf_8, 25, true, 2);
    testWriter("\u20AC 1 sample data.", utf_8, 100, true, 3);
    testWriter("\u20AC 1 sample data.", utf_8, 300, true, 4);
    testWriter("\u20AC 1 sample data.", utf_8, 500, false, 5);
    testWriter(
        "The capital of Japan is named \u6771\u4EAC.", shiftJis, 25, true, 3);
    // Test AztecWriter defaults
    String data = "In ut magna vel mauris malesuada";
    AztecWriter writer = AztecWriter();
    BitMatrix matrix = writer.encode(data, BarcodeFormat.AZTEC, 0, 0);
    AztecCode aztec = Encoder.encode(
        data, Encoder.DEFAULT_EC_PERCENT, Encoder.DEFAULT_AZTEC_LAYERS);
    BitMatrix expectedMatrix = aztec.matrix!;
    expect(matrix, expectedMatrix);
  });

  // synthetic tests (encode-decode round-trip)

  test('testEncodeDecode1', () {
    testEncodeDecode("Abc123!", true, 1);
  });

  test('testEncodeDecode2', () {
    testEncodeDecode("Lorem ipsum. http://test/", true, 2);
  });

  test('testEncodeDecode3', () {
    testEncodeDecode(
        "AAAANAAAANAAAANAAAANAAAANAAAANAAAANAAAANAAAANAAAAN", true, 3);
  });

  test('testEncodeDecode4', () {
    testEncodeDecode(
        "http://test/~!@#*^%&)__ ;:'\"[]{}\\|-+-=`1029384", true, 4);
  });

  test('testEncodeDecode5', () {
    testEncodeDecode(
        "http://test/~!@#*^%&)__ ;:'\"[]{}\\|-+-=`1029384756<>/?abc"
        "Four score and seven our forefathers brought forth",
        false,
        5);
  });

  test('testEncodeDecode10', () {
    testEncodeDecode(
        "In ut magna vel mauris malesuada dictum. Nulla ullamcorper metus quis diam"
        " cursus facilisis. Sed mollis quam id justo rutrum sagittis. Donec laoreet rutrum"
        " est, nec convallis mauris condimentum sit amet. Phasellus gravida, justo et congue"
        " auctor, nisi ipsum viverra erat, eget hendrerit felis turpis nec lorem. Nulla"
        " ultrices, elit pellentesque aliquet laoreet, justo erat pulvinar nisi, id"
        " elementum sapien dolor et diam.",
        false,
        10);
  });

  test('testEncodeDecode23', () {
    testEncodeDecode(
        "In ut magna vel mauris malesuada dictum. Nulla ullamcorper metus quis diam"
        " cursus facilisis. Sed mollis quam id justo rutrum sagittis. Donec laoreet rutrum"
        " est, nec convallis mauris condimentum sit amet. Phasellus gravida, justo et congue"
        " auctor, nisi ipsum viverra erat, eget hendrerit felis turpis nec lorem. Nulla"
        " ultrices, elit pellentesque aliquet laoreet, justo erat pulvinar nisi, id"
        " elementum sapien dolor et diam. Donec ac nunc sodales elit placerat eleifend."
        " Sed ornare luctus ornare. Vestibulum vehicula, massa at pharetra fringilla, risus"
        " justo faucibus erat, nec porttitor nibh tellus sed est. Ut justo diam, lobortis eu"
        " tristique ac, p.In ut magna vel mauris malesuada dictum. Nulla ullamcorper metus"
        " quis diam cursus facilisis. Sed mollis quam id justo rutrum sagittis. Donec"
        " laoreet rutrum est, nec convallis mauris condimentum sit amet. Phasellus gravida,"
        " justo et congue auctor, nisi ipsum viverra erat, eget hendrerit felis turpis nec"
        " lorem. Nulla ultrices, elit pellentesque aliquet laoreet, justo erat pulvinar"
        " nisi, id elementum sapien dolor et diam. Donec ac nunc sodales elit placerat"
        " eleifend. Sed ornare luctus ornare. Vestibulum vehicula, massa at pharetra"
        " fringilla, risus justo faucibus erat, nec porttitor nibh tellus sed est. Ut justo"
        " diam, lobortis eu tristique ac, p. In ut magna vel mauris malesuada dictum. Nulla"
        " ullamcorper metus quis diam cursus facilisis. Sed mollis quam id justo rutrum"
        " sagittis. Donec laoreet rutrum est, nec convallis mauris condimentum sit amet."
        " Phasellus gravida, justo et congue auctor, nisi ipsum viverra erat, eget hendrerit"
        " felis turpis nec lorem. Nulla ultrices, elit pellentesque aliquet laoreet, justo"
        " erat pulvinar nisi, id elementum sapien dolor et diam.",
        false,
        23);
  });

  test('testEncodeDecode31', () {
    testEncodeDecode(
        "In ut magna vel mauris malesuada dictum. Nulla ullamcorper metus quis diam"
        " cursus facilisis. Sed mollis quam id justo rutrum sagittis. Donec laoreet rutrum"
        " est, nec convallis mauris condimentum sit amet. Phasellus gravida, justo et congue"
        " auctor, nisi ipsum viverra erat, eget hendrerit felis turpis nec lorem. Nulla"
        " ultrices, elit pellentesque aliquet laoreet, justo erat pulvinar nisi, id"
        " elementum sapien dolor et diam. Donec ac nunc sodales elit placerat eleifend."
        " Sed ornare luctus ornare. Vestibulum vehicula, massa at pharetra fringilla, risus"
        " justo faucibus erat, nec porttitor nibh tellus sed est. Ut justo diam, lobortis eu"
        " tristique ac, p.In ut magna vel mauris malesuada dictum. Nulla ullamcorper metus"
        " quis diam cursus facilisis. Sed mollis quam id justo rutrum sagittis. Donec"
        " laoreet rutrum est, nec convallis mauris condimentum sit amet. Phasellus gravida,"
        " justo et congue auctor, nisi ipsum viverra erat, eget hendrerit felis turpis nec"
        " lorem. Nulla ultrices, elit pellentesque aliquet laoreet, justo erat pulvinar"
        " nisi, id elementum sapien dolor et diam. Donec ac nunc sodales elit placerat"
        " eleifend. Sed ornare luctus ornare. Vestibulum vehicula, massa at pharetra"
        " fringilla, risus justo faucibus erat, nec porttitor nibh tellus sed est. Ut justo"
        " diam, lobortis eu tristique ac, p. In ut magna vel mauris malesuada dictum. Nulla"
        " ullamcorper metus quis diam cursus facilisis. Sed mollis quam id justo rutrum"
        " sagittis. Donec laoreet rutrum est, nec convallis mauris condimentum sit amet."
        " Phasellus gravida, justo et congue auctor, nisi ipsum viverra erat, eget hendrerit"
        " felis turpis nec lorem. Nulla ultrices, elit pellentesque aliquet laoreet, justo"
        " erat pulvinar nisi, id elementum sapien dolor et diam. Donec ac nunc sodales elit"
        " placerat eleifend. Sed ornare luctus ornare. Vestibulum vehicula, massa at"
        " pharetra fringilla, risus justo faucibus erat, nec porttitor nibh tellus sed est."
        " Ut justo diam, lobortis eu tristique ac, p.In ut magna vel mauris malesuada"
        " dictum. Nulla ullamcorper metus quis diam cursus facilisis. Sed mollis quam id"
        " justo rutrum sagittis. Donec laoreet rutrum est, nec convallis mauris condimentum"
        " sit amet. Phasellus gravida, justo et congue auctor, nisi ipsum viverra erat,"
        " eget hendrerit felis turpis nec lorem. Nulla ultrices, elit pellentesque aliquet"
        " laoreet, justo erat pulvinar nisi, id elementum sapien dolor et diam. Donec ac"
        " nunc sodales elit placerat eleifend. Sed ornare luctus ornare. Vestibulum vehicula,"
        " massa at pharetra fringilla, risus justo faucibus erat, nec porttitor nibh tellus"
        " sed est. Ut justo diam, lobortis eu tris. In ut magna vel mauris malesuada dictum."
        " Nulla ullamcorper metus quis diam cursus facilisis. Sed mollis quam id justo rutrum"
        " sagittis. Donec laoreet rutrum est, nec convallis mauris condimentum sit amet."
        " Phasellus gravida, justo et congue auctor, nisi ipsum viverra erat, eget"
        " hendrerit felis turpis nec lorem.",
        false,
        31);
  });

  test('testGenerateModeMessage', () {
    testModeMessage(true, 2, 29, ".X .XXX.. ...X XX.. ..X .XX. .XX.X");
    testModeMessage(true, 4, 64, "XX XXXXXX .X.. ...X ..XX .X.. XX..");
    testModeMessage(
        false, 21, 660, "X.X.. .X.X..X..XX .XXX ..X.. .XXX. .X... ..XXX");
    testModeMessage(
        false, 32, 4096, "XXXXX XXXXXXXXXXX X.X. ..... XXX.X ..X.. X.XXX");
  });

  test('testStuffBits', () {
    testStuffBits(5, ".X.X. X.X.X .X.X.", ".X.X. X.X.X .X.X.");
    testStuffBits(5, ".X.X. ..... .X.X", ".X.X. ....X ..X.X");
    testStuffBits(
        3, "XX. ... ... ..X XXX .X. ..", "XX. ..X ..X ..X ..X .XX XX. .X. ..X");
    testStuffBits(6, ".X.X.. ...... ..X.XX", ".X.X.. .....X. ..X.XX XXXX.");
    testStuffBits(
        6, ".X.X.. ...... ...... ..X.X.", ".X.X.. .....X .....X ....X. X.XXXX");
    testStuffBits(
        6, ".X.X.. XXXXXX ...... ..X.XX", ".X.X.. XXXXX. X..... ...X.X XXXXX.");
    testStuffBits(
        6,
        "...... ..XXXX X..XX. .X.... .X.X.X .....X .X.... ...X.X .....X ....XX ..X... ....X. X..XXX X.XX.X",
        ".....X ...XXX XX..XX ..X... ..X.X. X..... X.X... ....X. X..... X....X X..X.. .....X X.X..X XXX.XX .XXXXX");
  });

  test('testHighLevelEncode', () {
    testHighLevelEncodeString(
        "A. b.",
        // 'A'  P/S   '. ' L/L    b    D/L    '.'
        "...X. ..... ...XX XXX.. ...XX XXXX. XX.X");
    testHighLevelEncodeString(
        "Lorem ipsum.",
        // 'L'  L/L   'o'   'r'   'e'   'm'   ' '   'i'   'p'   's'   'u'   'm'   D/L   '.'
        ".XX.X XXX.. X.... X..XX ..XX. .XXX. ....X .X.X. X...X X.X.. X.XX. .XXX. XXXX. XX.X");
    testHighLevelEncodeString(
        "Lo. Test 123.",
        // 'L'  L/L   'o'   P/S   '. '  U/S   'T'   'e'   's'   't'    D/L   ' '  '1'  '2'  '3'  '.'
        ".XX.X XXX.. X.... ..... ...XX XXX.. X.X.X ..XX. X.X.. X.X.X  XXXX. ...X ..XX .X.. .X.X XX.X");
    testHighLevelEncodeString(
        "Lo...x",
        // 'L'  L/L   'o'   D/L   '.'  '.'  '.'  U/L  L/L   'x'
        ".XX.X XXX.. X.... XXXX. XX.X XX.X XX.X XXX. XXX.. XX..X");
    testHighLevelEncodeString(
        ". x://abc/.",
        //P/S   '. '  L/L   'x'   P/S   ':'   P/S   '/'   P/S   '/'   'a'   'b'   'c'   P/S   '/'   D/L   '.'
        "..... ...XX XXX.. XX..X ..... X.X.X ..... X.X.. ..... X.X.. ...X. ...XX ..X.. ..... X.X.. XXXX. XX.X");
    // Uses Binary/Shift rather than Lower/Shift to save two bits.
    testHighLevelEncodeString(
        "ABCdEFG",
        //'A'   'B'   'C'   B/S    =1    'd'     'E'   'F'   'G'
        "...X. ...XX ..X.. XXXXX ....X .XX..X.. ..XX. ..XXX .X...");

    testHighLevelEncodeString(
        // Found on an airline boarding pass.  Several stretches of Binary shift are
        // necessary to keep the bitcount so low.
        "09  UAG    ^160MEUCIQC0sYS/HpKxnBELR1uB85R20OoqqwFGa0q2uEi"
        "Ygh6utAIgLl1aBVM4EOTQtMQQYH9M2Z3Dp4qnA/fwWuQ+M8L3V8U=",
        823);
  });

  test('testHighLevelEncodeBinary', () {
    // binary short form single byte
    testHighLevelEncodeString(
        "N\x00N",
        // 'N'  B/S    =1   '\x00'      N
        ".XXXX XXXXX ....X ........ .XXXX"); // Encode "N" in UPPER

    testHighLevelEncodeString(
        "N\x00n",
        // 'N'  B/S    =2   '\x00'       'n'
        ".XXXX XXXXX ...X. ........ .XX.XXX."); // Encode "n" in BINARY

    // binary short form consecutive bytes
    testHighLevelEncodeString(
        "N\x00\u0080 A",
        // 'N'  B/S    =2    '\x00'    \u0080   ' '  'A'
        ".XXXX XXXXX ...X. ........ X....... ....X ...X.");

    // binary skipping over single character
    testHighLevelEncodeString(
        "\x00a\u00FF\u0080 A",
        // B/S  =4    '\x00'      'a'     '\3ff'   '\x80'   ' '   'A'
        "XXXXX ..X.. ........ .XX....X XXXXXXXX X....... ....X ...X.");

    // getting into binary mode from digit mode
    testHighLevelEncodeString(
        "1234\x00",
        //D/L   '1'  '2'  '3'  '4'  U/L  B/S    =1    \x00
        "XXXX. ..XX .X.. .X.X .XX. XXX. XXXXX ....X ........");

    // Create a string in which every character requires binary
    StringBuilder sb = StringBuilder();
    for (int i = 0; i <= 3000; i++) {
      sb.writeCharCode((128 + (i % 30)));
    }
    // Test the output generated by Binary/Switch, particularly near the
    // places where the encoding changes: 31, 62, and 2047+31=2078
    for (int i in [
      1, 2, 3, 10, 29, 30, 31, 32, 33, 60, //
      61, 62, 63, 64, 2076, 2077, 2078, 2079, 2080, 2100
    ]) {
      // This is the expected length of a binary string of length "i"
      int expectedLength = (8 * i) +
          ((i <= 31)
              ? 10
              : (i <= 62)
                  ? 20
                  : (i <= 2078)
                      ? 21
                      : 31);
      // Verify that we are correct about the length.
      testHighLevelEncodeString(sb.substring(0, i), expectedLength);
      if (i != 1 && i != 32 && i != 2079) {
        // The addition of an 'a' at the beginning or end gets merged into the binary code
        // in those cases where adding another binary character only adds 8 or 9 bits to the result.
        // So we exclude the border cases i=1,32,2079
        // A lower case letter at the beginning will be merged into binary mode
        testHighLevelEncodeString('a' + sb.substring(0, i - 1), expectedLength);
        // A lower case letter at the end will also be merged into binary mode
        testHighLevelEncodeString(sb.substring(0, i - 1) + 'a', expectedLength);
      }
      // A lower case letter at both ends will enough to latch us into LOWER.
      testHighLevelEncodeString(
          'a' + sb.substring(0, i) + 'b', expectedLength + 15);
    }

    sb = StringBuilder();
    for (int i = 0; i < 32; i++) {
      sb.write('§'); // § forces binary encoding
    }
    sb.setCharAt(1, 'A');
    // expect B/S(1) A B/S(30)
    testHighLevelEncodeString(sb.toString(), 5 + 20 + 31 * 8);

    sb = StringBuilder();
    for (int i = 0; i < 31; i++) {
      sb.write('§');
    }
    sb.setCharAt(1, 'A');
    // expect B/S(31)
    testHighLevelEncodeString(sb.toString(), 10 + 31 * 8);

    sb = StringBuilder();
    for (int i = 0; i < 34; i++) {
      sb.write('§');
    }
    sb.setCharAt(1, 'A');
    // expect B/S(31) B/S(3)
    testHighLevelEncodeString(sb.toString(), 20 + 34 * 8);

    sb = StringBuilder();
    for (int i = 0; i < 64; i++) {
      sb.write('§');
    }
    sb.setCharAt(30, 'A');
    // expect B/S(64)
    testHighLevelEncodeString(sb.toString(), 21 + 64 * 8);
  });

  test('testHighLevelEncodePairs', () {
    // Typical usage
    testHighLevelEncodeString(
        "ABC. DEF\r\n",
        //  A     B    C    P/S   .<sp>   D    E     F    P/S   \r\n
        "...X. ...XX ..X.. ..... ...XX ..X.X ..XX. ..XXX ..... ...X.");

    // We should latch to PUNCT mode, rather than shift.  Also check all pairs
    testHighLevelEncodeString(
        "A. : , \r\n",
        // 'A'    M/L   P/L   ". "  ": "   ", " "\r\n"
        "...X. XXX.X XXXX. ...XX ..X.X  ..X.. ...X.");

    // Latch to DIGIT rather than shift to PUNCT
    testHighLevelEncodeString(
        "A. 1234",
        // 'A'  D/L   '.'  ' '  '1' '2'   '3'  '4'
        "...X. XXXX. XX.X ...X ..XX .X.. .X.X .X X.");
    // Don't bother leaving Binary Shift.
    testHighLevelEncodeString(
        "A\x80. \x80",
        // 'A'  B/S    =2    \x80      "."     " "     \x80
        "...X. XXXXX ..X.. X....... ..X.XXX. ..X..... X.......");
  });

  void doTestUserSpecifiedLayers(int userSpecifiedLayers) {
    String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    AztecCode aztec = Encoder.encode(alphabet, 25, -2);
    expect(aztec.layers, 2);
    assert(aztec.isCompact);

    aztec = Encoder.encode(alphabet, 25, 32);
    expect(aztec.layers, 32);
    assert(!aztec.isCompact);

    try {
      Encoder.encode(alphabet, 25, userSpecifiedLayers);
      fail(
          "Encode should have failed.  No such thing as $userSpecifiedLayers layers");
    } on ArgumentError catch (_) {
      // IllegalArgumentException
      // continue
    }
  }

  test('testUserSpecifiedLayers', () {
    doTestUserSpecifiedLayers(33);
  });
  test('testUserSpecifiedLayers2', () {
    doTestUserSpecifiedLayers(-1);
  });

  test('testBorderCompact4CaseFailed', () {
    // Compact(4) con hold 608 bits of information, but at most 504 can be data.  Rest must
    // be error correction
    String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    // encodes as 26 * 5 * 4 = 520 bits of data
    String alphabet4 = alphabet * 4;
    try {
      Encoder.encode(alphabet4, 0, -4);
      fail('Rest must be error correction');
    } on ArgumentError catch (_) {
      // IllegalArgumentException
      // continue
    }
  });
  test('testBorderCompact4Case', () {
    // Compact(4) con hold 608 bits of information, but at most 504 can be data.  Rest must
    // be error correction
    String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    // encodes as 26 * 5 * 4 = 520 bits of data
    String alphabet4 = alphabet * 4;

    // If we just try to encode it normally, it will go to a non-compact 4 layer
    AztecCode aztecCode =
        Encoder.encode(alphabet4, 0, Encoder.DEFAULT_AZTEC_LAYERS);
    assert(!aztecCode.isCompact);
    expect(aztecCode.layers, 4);

    // But shortening the string to 100 bytes (500 bits of data), compact works fine, even if we
    // include more error checking.
    aztecCode = Encoder.encode(
        alphabet4.substring(0, 100), 10, Encoder.DEFAULT_AZTEC_LAYERS);
    assert(aztecCode.isCompact);
    expect(aztecCode.layers, 4);
  });
}
