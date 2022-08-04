/*
 * Copyright 2009 ZXing authors
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
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/pdf417.dart';
import 'package:zxing_lib/zxing.dart';

import '../../utils.dart';

/// Tests [DecodedBitStreamParser].
void main() {
  void performDecodeTest(List<int> codewords, String expectedResult) {
    DecoderResult result = DecodedBitStreamParser.decode(codewords, '0');
    expect(result.text, expectedResult);
  }

  int encodeDecode(String input,
      [Encoding? charset, bool autoECI = false, bool decode = true]) {
    String s = PDF417HighLevelEncoder.encodeHighLevel(
        input, Compaction.AUTO, charset, autoECI);
    if (decode) {
      List<int> codewords = List.filled(s.length + 1, 0);
      codewords[0] = codewords.length;
      for (int i = 1; i < codewords.length; i++) {
        codewords[i] = s.codeUnitAt(i - 1);
      }
      performDecodeTest(codewords, input);
    }
    return s.length + 1;
  }

  void encodeDecodeLen(String input, int expectedLength) {
    expect(expectedLength, encodeDecode(input));
  }

  int getEndIndex(int length, List<int> chars) {
    double decimalLength = math.log(chars.length) / math.ln10;
    return (math.pow(10, decimalLength * length)).ceil();
  }

  String generatePermutation(int index, int length, List<int> chars) {
    int N = chars.length;
    String baseNNumber = index.toRadixString(N);
    while (baseNNumber.length < length) {
      baseNNumber = '0$baseNNumber';
    }
    String prefix = '';
    for (int i = 0; i < baseNNumber.length; i++) {
      prefix += String.fromCharCode(
          chars[baseNNumber.codeUnitAt(i) - '0'.codeUnitAt(0)]);
    }
    return prefix;
  }

  void performPermutationTest(List<int> chars, int length, int expectedTotal) {
    int endIndex = getEndIndex(length, chars);
    int total = 0;
    for (int i = 0; i < endIndex; i++) {
      total += encodeDecode(generatePermutation(i, length, chars));
    }
    expect(expectedTotal, total);
  }

  void performEncodeTest(int c, List<int> expectedLengths) {
    for (int i = 0; i < expectedLengths.length; i++) {
      StringBuffer sb = StringBuffer();
      for (int j = 0; j <= i; j++) {
        sb.writeCharCode(c);
      }
      encodeDecodeLen(sb.toString(), expectedLengths[i]);
    }
  }

  String generateText(
      math.Random random, int maxWidth, List<int> chars, List<double> weights) {
    StringBuffer result = StringBuffer();
    final int maxWordWidth = 7;
    double total = 0;
    for (int i = 0; i < weights.length; i++) {
      total += weights[i];
    }
    for (int i = 0; i < weights.length; i++) {
      weights[i] /= total;
    }
    int cnt = 0;
    do {
      double maxValue = 0;
      int maxIndex = 0;
      for (int j = 0; j < weights.length; j++) {
        double value = random.nextDouble() * weights[j];
        if (value > maxValue) {
          maxValue = value;
          maxIndex = j;
        }
      }
      final double wordLength = maxWordWidth * random.nextDouble();
      if (wordLength > 0 && result.length > 0) {
        result.write(' ');
      }
      for (int j = 0; j < wordLength; j++) {
        int c = chars[maxIndex];
        if (j == 0 &&
            c >= 'a'.codeUnitAt(0) &&
            c <= 'z'.codeUnitAt(0) &&
            random.nextBool()) {
          c = (c - 'a'.codeUnitAt(0) + 'A'.codeUnitAt(0));
        }
        result.writeCharCode(c);
      }
      if (cnt % 2 != 0 && random.nextBool()) {
        result.write('.');
      }
      cnt++;
    } while (result.length < maxWidth - maxWordWidth);
    return result.toString();
  }

  void performECITest(List<int> chars, List<double> weights,
      int expectedMinLength, int expectedUTFLength) {
    math.Random random = math.Random(0);
    int minLength = 0;
    int utfLength = 0;
    for (int i = 0; i < 1000; i++) {
      String s = generateText(random, 100, chars, weights);
      minLength += encodeDecode(s, null, true, true);

      utfLength += encodeDecode(s, utf8, false, true);
    }
    expect(expectedMinLength, minLength);
    expect(expectedUTFLength, utfLength);
  }

  /// Tests the first sample given in ISO/IEC 15438:2015(E) - Annex H.4
  test('testStandardSample1', () {
    PDF417ResultMetadata resultMetadata = PDF417ResultMetadata();
    List<int> sampleCodes = [
      20, 928, 111, 100, 17, 53, 923, 1, 111, 104, 923, 3, 64, 416, 34,
      923, 4, 258, 446, 67,
      // we should never reach these
      1000, 1000, 1000
    ];

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);

    expect(resultMetadata.segmentIndex, 0);
    expect(resultMetadata.fileId, '017053');
    assert(!resultMetadata.isLastSegment);
    expect(resultMetadata.segmentCount, 4);
    expect(resultMetadata.sender, 'CEN BE');
    expect(resultMetadata.addressee, 'ISO CH');

    // ignore: deprecated_consistency, deprecated_member_use_from_same_package
    List<int> optionalData = resultMetadata.optionalData!;
    expect(optionalData[0], 1,
        reason:
            'first element of optional array should be the first field identifier');
    expect(optionalData[optionalData.length - 1], 67,
        reason:
            'last element of optional array should be the last codeword of the last field');
  });

  /// Tests the second given in ISO/IEC 15438:2015(E) - Annex H.4
  test('testStandardSample2', () {
    PDF417ResultMetadata resultMetadata = PDF417ResultMetadata();
    List<int> sampleCodes = [
      11, 928, 111, 103, 17, 53, 923, 1, 111, 104, 922,
      // we should never reach these
      1000, 1000, 1000
    ];

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);

    expect(3, resultMetadata.segmentIndex);
    expect('017053', resultMetadata.fileId);
    assert(resultMetadata.isLastSegment);
    expect(4, resultMetadata.segmentCount);
    assert(resultMetadata.addressee == null);
    assert(resultMetadata.sender == null);

    // ignore: deprecated_consistency, deprecated_member_use_from_same_package
    List<int> optionalData = resultMetadata.optionalData!;
    expect(1, optionalData[0],
        reason:
            'first element of optional array should be the first field identifier');
    expect(104, optionalData[optionalData.length - 1],
        reason:
            'last element of optional array should be the last codeword of the last field');
  });

  /// Tests the example given in ISO/IEC 15438:2015(E) - Annex H.6
  test('testStandardSample3', () {
    PDF417ResultMetadata resultMetadata = PDF417ResultMetadata();

    // Final dummy ECC codeword required to avoid ArrayIndexOutOfBounds
    List<int> sampleCodes = [7, 928, 111, 100, 100, 200, 300, 0];

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);

    expect(0, resultMetadata.segmentIndex);
    expect('100200300', resultMetadata.fileId);
    assert(!resultMetadata.isLastSegment);
    expect(-1, resultMetadata.segmentCount);
    assert(resultMetadata.addressee == null);
    assert(resultMetadata.sender == null);

    // ignore: deprecated_consistency, deprecated_member_use_from_same_package
    assert(resultMetadata.optionalData == null);

    // Check that symbol containing no data except Macro is accepted (see note in Annex H.2)
    DecoderResult decoderResult =
        DecodedBitStreamParser.decode(sampleCodes, '0');
    expect('', decoderResult.text);
    assert(decoderResult.other != null);
  });

  test('testSampleWithFilename', () {
    List<int> sampleCodes = [
      23, 477, 928, 111, 100, 0, 252, 21, 86, 923, 0, 815, 251, 133, 12, //
      148, 537, 593, 599, 923, 1, 111, 102, 98, 311, 355, 522, 920, 779,
      40, 628, 33, 749, 267, 506, 213, 928, 465, 248, 493, 72, 780, 699,
      780, 493, 755, 84, 198, 628, 368, 156, 198, 809, 19, 113
    ];
    PDF417ResultMetadata resultMetadata = PDF417ResultMetadata();

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 3, resultMetadata);

    expect(0, resultMetadata.segmentIndex);
    expect('000252021086', resultMetadata.fileId);
    assert(!resultMetadata.isLastSegment);
    expect(2, resultMetadata.segmentCount);
    assert(resultMetadata.addressee == null);
    assert(resultMetadata.sender == null);
    expect('filename.txt', resultMetadata.fileName);
  });

  test('testSampleWithNumericValues', () {
    List<int> sampleCodes = [
      25, 477, 928, 111, 100, 0, 252, 21, 86, 923, 2, 2, 0, 1, 0, 0, 0, //
      923, 5, 130, 923, 6, 1, 500, 13, 0
    ];
    PDF417ResultMetadata resultMetadata = PDF417ResultMetadata();

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 3, resultMetadata);

    expect(0, resultMetadata.segmentIndex);
    expect('000252021086', resultMetadata.fileId);
    assert(!resultMetadata.isLastSegment);

    expect(180980729000000, resultMetadata.timestamp);
    expect(30, resultMetadata.fileSize);
    expect(260013, resultMetadata.checksum);
  });

  test('testSampleWithMacroTerminatorOnly', () {
    List<int> sampleCodes = [7, 477, 928, 222, 198, 0, 922];
    PDF417ResultMetadata resultMetadata = PDF417ResultMetadata();

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 3, resultMetadata);

    expect(99998, resultMetadata.segmentIndex);
    expect('000', resultMetadata.fileId);
    assert(resultMetadata.isLastSegment);
    expect(-1, resultMetadata.segmentCount);

    // ignore: deprecated_consistency, deprecated_member_use_from_same_package
    assert(resultMetadata.optionalData == null);
  });

  test('testSampleWithBadSequenceIndexMacro', () {
    List<int> sampleCodes = [3, 928, 222, 0];
    PDF417ResultMetadata resultMetadata = PDF417ResultMetadata();

    try {
      DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);
    } on FormatsException catch (_) {
      // continue
    }
  });

  test('testSampleWithNoFileIdMacro', () {
    List<int> sampleCodes = [4, 928, 222, 198, 0];
    PDF417ResultMetadata resultMetadata = PDF417ResultMetadata();

    try {
      DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);
    } on FormatsException catch (_) {
      // continue
    }
  });

  test('testSampleWithNoDataNoMacro', () {
    List<int> sampleCodes = [3, 899, 899, 0];

    try {
      DecodedBitStreamParser.decode(sampleCodes, '0');
    } on FormatsException catch (_) {
      // continue
    }
  });

  test('testUppercase', () {
    //encodeDecode("", 0);
    performEncodeTest('A'.codeUnitAt(0), [3, 4, 5, 6, 4, 4, 5, 5]);
  });

  test('testNumeric', () {
    performEncodeTest('1'.codeUnitAt(0),
        [2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10]);
  });

  test('testByte', () {
    performEncodeTest('\u00c4'.codeUnitAt(0), [3, 4, 5, 6, 7, 7, 8]);
  });

  test('testUppercaseLowercaseMix1', () {
    encodeDecodeLen('aA', 4);
    encodeDecodeLen('aAa', 5);
    encodeDecodeLen('Aa', 4);
    encodeDecodeLen('Aaa', 5);
    encodeDecodeLen('AaA', 5);
    encodeDecodeLen('AaaA', 6);
    encodeDecodeLen('Aaaa', 6);
    encodeDecodeLen('AaAaA', 5);
    encodeDecodeLen('AaaAaaA', 6);
    encodeDecodeLen('AaaAAaaA', 7);
  });

  test('testPunctuation', () {
    performEncodeTest(';'.codeUnitAt(0), [3, 4, 5, 6, 6, 7, 8]);
    encodeDecodeLen(';;;;;;;;;;;;;;;;', 17);
  });

  test('testUppercaseLowercaseMix2', () {
    // orig: 8972
    performPermutationTest(
        ['A', 'a'].map((e) => e.codeUnitAt(0)).toList(), 10, 8960);
  });

  test('testUppercaseNumericMix', () {
    performPermutationTest(
        ['A', '1'].map((e) => e.codeUnitAt(0)).toList(), 14, 192510);
  });

  test('testUppercaseMixedMix', () {
    performPermutationTest(
        ['A', '1', ' ', ';'].map((e) => e.codeUnitAt(0)).toList(), 7, 106060);
  });

  test('testUppercasePunctuationMix', () {
    // orig: 8967
    performPermutationTest(
        ['A', ';'].map((e) => e.codeUnitAt(0)).toList(), 10, 8960);
  });

  test('testUppercaseByteMix', () {
    // orig: 11222
    performPermutationTest(
        ['A', '\u00c4'].map((e) => e.codeUnitAt(0)).toList(), 10, 11210);
  });

  test('testLowercaseByteMix', () {
    // orig: 11233
    performPermutationTest(
        ['a', '\u00c4'].map((e) => e.codeUnitAt(0)).toList(), 10, 11221);
  });

  test('testUppercaseLowercaseNumericMix', () {
    performPermutationTest('Aa1'.codeUnits, 7, 15491);
  });

  test('testUppercaseLowercasePunctuationMix', () {
    performPermutationTest(
        ['A', 'a', ';'].map((e) => e.codeUnitAt(0)).toList(), 7, 15491);
  });

  test('testUppercaseLowercaseByteMix', () {
    performPermutationTest(
        ['A', 'a', '\u00c4'].map((e) => e.codeUnitAt(0)).toList(), 7, 17288);
  });

  test('testLowercasePunctuationByteMix', () {
    performPermutationTest(
        ['a', ';', '\u00c4'].map((e) => e.codeUnitAt(0)).toList(), 7, 17427);
  });

  test('testUppercaseLowercaseNumericPunctuationMix', () {
    performPermutationTest(
        ['A', 'a', '1', ';'].map((e) => e.codeUnitAt(0)).toList(), 7, 120479);
  });

  test('testBinaryData', () {
    Uint8List bytes = Uint8List(500);
    math.Random random = math.Random(0);
    int total = 0;
    for (int i = 0; i < 10000; i++) {
      random.nextBytes(bytes);
      total += encodeDecode(latin1.decode(bytes, allowInvalid: false));
    }
    // orig: 4190044
    expect(4190042, total);
  });

  test('testECIEnglishHiragana', () {
    //multi ECI UTF-8, UTF-16 and ISO-8859-1
    // orig: 105825 110914
    performECITest(['a', '1', '\u3040'].map((e) => e.codeUnitAt(0)).toList(),
        [20.0, 1.0, 10.0], 110854, 110754);
  });

  test('testECIEnglishKatakana', () {
    //multi ECI UTF-8, UTF-16 and ISO-8859-1
    // orig: 109177 110914
    performECITest(['a', '1', '\u30a0'].map((e) => e.codeUnitAt(0)).toList(),
        [20.0, 1.0, 10.0], 110854, 110754);
  });

  test('testECIEnglishHalfWidthKatakana', () {
    //single ECI orig: 80617 110914
    performECITest(['a', '1', '\uff80'].map((e) => e.codeUnitAt(0)).toList(),
        [20.0, 1.0, 10.0], 80562, 110754);
  });

  test('testECIEnglishChinese', () {
    //single ECI orig: 95797 110914
    performECITest(['a', '1', '\u4e00'].map((e) => e.codeUnitAt(0)).toList(),
        [20.0, 1.0, 10.0], 95707, 110754);
  });

  test('testECIGermanCyrillic', () {
    //single ECI since the German Umlaut is in ISO-8859-1
    // orig: 80755 96007
    performECITest(
        ['a', '1', '\u00c4', '\u042f'].map((e) => e.codeUnitAt(0)).toList(),
        [20.0, 1.0, 1.0, 10.0],
        80549,
        95729);
  });

  test('testECIEnglishCzechCyrillic1', () {
    //multi ECI between ISO-8859-2 and ISO-8859-5
    // orig: 102824 124525
    performECITest(
        ['a', '1', '\u010c', '\u042f'].map((e) => e.codeUnitAt(0)).toList(),
        [10.0, 1.0, 10.0, 10.0],
        102903,
        124195);
  });

  test('testECIEnglishCzechCyrillic2', () {
    //multi ECI between ISO-8859-2 and ISO-8859-5
    // orig: 81321 88236
    performECITest(
        ['a', '1', '\u010c', '\u042f'].map((e) => e.codeUnitAt(0)).toList(),
        [40.0, 1.0, 10.0, 10.0],
        81652,
        88507);
  });

  test('testECIEnglishArabicCyrillic', () {
    //multi ECI between UTF-8 (ISO-8859-6 is excluded in CharacterSetECI) and ISO-8859-5
    // orig: 118510 124525
    performECITest(
        ['a', '1', '\u0620', '\u042f'].map((e) => e.codeUnitAt(0)).toList(),
        [10.0, 1.0, 10.0, 10.0],
        118419,
        124195);
  });

  test('testBinaryMultiECI', () {
    //Test the cases described in 5.5.5.3 "ECI and Byte Compaction mode using latch 924 and 901"
    performDecodeTest([5, 927, 4, 913, 200], '\u010c');
    performDecodeTest([9, 927, 4, 913, 200, 927, 7, 913, 207], '\u010c\u042f');
    performDecodeTest([9, 927, 4, 901, 200, 927, 7, 901, 207], '\u010c\u042f');
    performDecodeTest([8, 927, 4, 901, 200, 927, 7, 207], '\u010c\u042f');
    performDecodeTest(
        [14, 927, 4, 901, 200, 927, 7, 207, 927, 4, 200, 927, 7, 207],
        '\u010c\u042f\u010c\u042f');
    performDecodeTest(
      [
        16, 927, 4, 924, 336, 432, 197, 51, 300, 927, 7, 348, 231, 311, 858,
        567 //
      ],
      '\u010c\u010c\u010c\u010c\u010c\u010c\u042f\u042f\u042f\u042f\u042f\u042f',
    );
  });
}
