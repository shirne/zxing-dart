/*
 * Copyright 2006 Jeremias Maerki.
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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/datamatrix.dart';

import '../../utils.dart';

/// Tests for [HighLevelEncoder] and [MinimalEncoder]
void main() {
  final List<SymbolInfo> testSymbols = [
    SymbolInfo(false, 3, 5, 8, 8, 1),
    SymbolInfo(false, 5, 7, 10, 10, 1),
    /*rect*/ SymbolInfo(true, 5, 7, 16, 6, 1),
    SymbolInfo(false, 8, 10, 12, 12, 1),
    /*rect*/ SymbolInfo(true, 10, 11, 14, 6, 2),
    SymbolInfo(false, 13, 0, 0, 0, 1),
    SymbolInfo(false, 77, 0, 0, 0, 1),
    //The last entries are fake entries to test special conditions with C40 encoding
  ];

  void useTestSymbols() {
    SymbolInfo.overrideSymbolSet(testSymbols);
  }

  void resetSymbols() {
    SymbolInfo.overrideSymbolSet(SymbolInfo.prodSymbols);
  }

  String createBinaryMessage(int len) {
    final sb = StringBuffer();
    sb.write('\u00ABäöüéàá-');
    for (int i = 0; i < len - 9; i++) {
      sb.write('\u00B7');
    }
    sb.write('\u00BB');
    return sb.toString();
  }

  void assertStartsWith(String expected, String actual) {
    if (!actual.startsWith(expected)) {
      expect(expected, actual.substring(0, expected.length));
    }
  }

  void assertEndsWith(String expected, String actual) {
    if (!actual.endsWith(expected)) {
      expect(expected, actual.substring(actual.length - expected.length));
    }
  }

  String encodeHighLevel(
    String msg, [
    bool compareSizeToMinimalEncoder = true,
  ]) {
    final encoded = HighLevelEncoder.encodeHighLevel(msg);
    final encoded2 = MinimalEncoder.encodeHighLevel(msg);
    if (compareSizeToMinimalEncoder) {
      expect(encoded.length, greaterThanOrEqualTo(encoded2.length));
    }
    return visualize(encoded);
  }

  void encodeHighLevelSize(String msg, List<int> sizes) {
    sizes[0] = HighLevelEncoder.encodeHighLevel(msg).length;
    sizes[1] = MinimalEncoder.encodeHighLevel(msg).length;
  }

  test('testASCIIEncodation', () {
    String visualized = encodeHighLevel('123456');
    expect('142 164 186', visualized);

    visualized = encodeHighLevel('123456£');
    expect('142 164 186 235 36', visualized);

    visualized = encodeHighLevel('30Q324343430794<OQQ');
    expect('160 82 162 173 173 173 137 224 61 80 82 82', visualized);
  });

  test('testC40EncodationBasic1', () {
    final visualized = encodeHighLevel('AIMAIMAIM');

    expect('230 91 11 91 11 91 11 254', visualized);
    //230 shifts to C40 encodation, 254 unlatches, "else" case
  });

  test('testC40EncodationBasic2', () {
    String visualized = encodeHighLevel('AIMAIAB');
    expect('230 91 11 90 255 254 67 129', visualized);
    //"B" is normally encoded as "15" (one C40 value)
    //"else" case: "B" is encoded as ASCII

    visualized = encodeHighLevel('AIMAIAb');
    expect('66 74 78 66 74 66 99 129', visualized); //Encoded as ASCII
    //Alternative solution:
    //expect("230 91 11 90 255 254 99 129", visualized);
    //"b" is normally encoded as "Shift 3, 2" (two C40 values)
    //"else" case: "b" is encoded as ASCII

    visualized = encodeHighLevel('AIMAIMAIMË');
    expect('230 91 11 91 11 91 11 254 235 76', visualized);
    //Alternative solution:
    //expect("230 91 11 91 11 91 11 11 9 254", visualized);
    //Expl: 230 = shift to C40, "91 11" = "AIM",
    //"11 9" = "�" = "Shift 2, UpperShift, <char>
    //"else" case

    visualized = encodeHighLevel('AIMAIMAIMë');
    expect(
      '230 91 11 91 11 91 11 254 235 108',
      visualized,
    ); //Activate when additional rectangulars are available
    //Expl: 230 = shift to C40, "91 11" = "AIM",
    //"�" in C40 encodes to: 1 30 2 11 which doesn't fit into a triplet
    //"10 243" =
    //254 = unlatch, 235 = Upper Shift, 108 = � = 0xEB/235 - 128 + 1
    //"else" case
  });

  test('testC40EncodationSpecExample', () {
    //Example in Figure 1 in the spec
    final visualized = encodeHighLevel('A1B2C3D4E5F6G7H8I9J0K1L2');
    expect(
      '230 88 88 40 8 107 147 59 67 126 206 78 126 144 121 35 47 254',
      visualized,
    );
  });

  test('testC40EncodationSpecialCases1', () {
    //Special tests avoiding ultra-long test strings because these tests are only used
    //with the 16x48 symbol (47 data codewords)
    useTestSymbols();

    String visualized = encodeHighLevel('AIMAIMAIMAIMAIMAIM', false);
    expect('230 91 11 91 11 91 11 91 11 91 11 91 11', visualized);
    //case "a": Unlatch is not required

    visualized = encodeHighLevel('AIMAIMAIMAIMAIMAI', false);
    expect('230 91 11 91 11 91 11 91 11 91 11 90 241', visualized);
    //case "b": Add trailing shift 0 and Unlatch is not required

    visualized = encodeHighLevel('AIMAIMAIMAIMAIMA');
    expect('230 91 11 91 11 91 11 91 11 91 11 254 66', visualized);
    //case "c": Unlatch and write last character in ASCII

    resetSymbols();

    visualized = encodeHighLevel('AIMAIMAIMAIMAIMAI');
    expect('230 91 11 91 11 91 11 91 11 91 11 254 66 74 129 237', visualized);

    visualized = encodeHighLevel('AIMAIMAIMA');
    expect('230 91 11 91 11 91 11 66', visualized);
    //case "d": Skip Unlatch and write last character in ASCII
  });

  test('testC40EncodationSpecialCases2', () {
    final visualized = encodeHighLevel('AIMAIMAIMAIMAIMAIMAI');
    expect(visualized, '230 91 11 91 11 91 11 91 11 91 11 91 11 254 66 74');
    //available > 2, rest = 2 --> unlatch and encode as ASCII
  });

  test('testTextEncodation', () {
    String visualized = encodeHighLevel('aimaimaim');
    expect('239 91 11 91 11 91 11 254', visualized);
    //239 shifts to Text encodation, 254 unlatches

    visualized = encodeHighLevel("aimaimaim'");
    expect('239 91 11 91 11 91 11 254 40 129', visualized);
    //expect("239 91 11 91 11 91 11 7 49 254", visualized);
    //This is an alternative, but doesn't strictly follow the rules in the spec.

    visualized = encodeHighLevel('aimaimaIm');
    expect('239 91 11 91 11 87 218 110', visualized);

    visualized = encodeHighLevel('aimaimaimB');
    expect('239 91 11 91 11 91 11 254 67 129', visualized);

    visualized = encodeHighLevel('aimaimaim{txt}\u0004');
    expect(
      //TODO java result:"239 91 11 91 11 91 11 254 124 117 121 117 126 5 129 237",
      '239 91 11 91 11 91 11 16 218 236 107 181 69 254 129 237',
      visualized,
    );
  });

  test('testX12Encodation', () {
    //238 shifts to X12 encodation, 254 unlatches

    String visualized = encodeHighLevel('ABC>ABC123>AB');
    expect('238 89 233 14 192 100 207 44 31 67', visualized);

    visualized = encodeHighLevel('ABC>ABC123>ABC');
    expect('238 89 233 14 192 100 207 44 31 254 67 68', visualized);

    visualized = encodeHighLevel('ABC>ABC123>ABCD');
    expect('238 89 233 14 192 100 207 44 31 96 82 254', visualized);

    visualized = encodeHighLevel('ABC>ABC123>ABCDE');
    expect('238 89 233 14 192 100 207 44 31 96 82 70', visualized);

    visualized = encodeHighLevel('ABC>ABC123>ABCDEF');
    expect(
      '238 89 233 14 192 100 207 44 31 96 82 254 70 71 129 237',
      visualized,
    );
  });

  test('testEDIFACTEncodation', () {
    //240 shifts to EDIFACT encodation

    String visualized = encodeHighLevel('.A.C1.3.DATA.123DATA.123DATA');
    expect(
      '240 184 27 131 198 236 238 16 21 1 187 28 179 16 21 1 187 28 179 16 21 1',
      visualized,
    );

    visualized = encodeHighLevel('.A.C1.3.X.X2..');
    expect('240 184 27 131 198 236 238 98 230 50 47 47', visualized);

    visualized = encodeHighLevel('.A.C1.3.X.X2.');
    expect('240 184 27 131 198 236 238 98 230 50 47 129', visualized);

    visualized = encodeHighLevel('.A.C1.3.X.X2');
    expect('240 184 27 131 198 236 238 98 230 50', visualized);

    visualized = encodeHighLevel('.A.C1.3.X.X');
    expect('240 184 27 131 198 236 238 98 230 31', visualized);

    visualized = encodeHighLevel('.A.C1.3.X.');
    expect('240 184 27 131 198 236 238 98 231 192', visualized);

    visualized = encodeHighLevel('.A.C1.3.X');
    expect('240 184 27 131 198 236 238 89', visualized);

    //Checking temporary unlatch from EDIFACT
    visualized =
        encodeHighLevel('.XXX.XXX.XXX.XXX.XXX.XXX.üXX.XXX.XXX.XXX.XXX.XXX.XXX');
    expect(
      '240 185 134 24 185 134 24 185 134 24 185 134 24 185 134 24 185 134 24'
      ' 124 47 235 125 240' //<-- this is the temporary unlatch

      ' 97 139 152 97 139 152 97 139 152 97 139 152 97 139 152 97 139 152 89 89',
      visualized,
    );
  });

  test('testBase256Encodation', () {
    //231 shifts to Base256 encodation

    String visualized = encodeHighLevel('\u00ABäöüé\u00BB');
    expect('231 44 108 59 226 126 1 104', visualized);
    visualized = encodeHighLevel('\u00ABäöüéà\u00BB');
    expect('231 51 108 59 226 126 1 141 254 129', visualized);
    visualized = encodeHighLevel('\u00ABäöüéàá\u00BB');
    expect('231 44 108 59 226 126 1 141 36 147', visualized);

    //ASCII only (for reference)
    visualized = encodeHighLevel(' 23£');
    expect('33 153 235 36 129', visualized);

    //Mixed Base256 + ASCII
    visualized = encodeHighLevel('\u00ABäöüé\u00BB 234');
    expect('231 50 108 59 226 126 1 104 33 153 53 129', visualized);

    visualized = encodeHighLevel('\u00ABäöüé\u00BB 23£ 1234567890123456789');
    expect(
      '231 54 108 59 226 126 1 104 99 10 161 167 33 142 164 186 208'
      ' 220 142 164 186 208 58 129 59 209 104 254 150 45',
      visualized,
    );

    visualized = encodeHighLevel(createBinaryMessage(20));
    expect(
      '231 44 108 59 226 126 1 141 36 5 37 187 80 230 123 17 166 60 210 103 253 150',
      visualized,
    );

    //padding necessary at the end
    visualized = encodeHighLevel(createBinaryMessage(19));
    expect(
      '231 63 108 59 226 126 1 141 36 5 37 187 80 230 123 17 166 60 210 103 1 129',
      visualized,
    );

    visualized = encodeHighLevel(createBinaryMessage(276));
    assertStartsWith('231 38 219 2 208 120 20 150 35', visualized);
    assertEndsWith('146 40 194 129', visualized);

    visualized = encodeHighLevel(createBinaryMessage(277));
    assertStartsWith('231 38 220 2 208 120 20 150 35', visualized);
    assertEndsWith('146 40 190 87', visualized);
  });

  test('testUnlatchingFromC40', () {
    final visualized = encodeHighLevel('AIMAIMAIMAIMaimaimaim');
    expect(
      '230 91 11 91 11 91 11 254 66 74 78 239 91 11 91 11 91 11',
      visualized,
    );
  });

  test('testUnlatchingFromText', () {
    final visualized = encodeHighLevel('aimaimaimaim12345678');
    expect(
      '239 91 11 91 11 91 11 91 11 254 142 164 186 208 129 237',
      visualized,
    );
  });

  test('testHelloWorld', () {
    final visualized = encodeHighLevel('Hello World!');
    expect('73 239 116 130 175 123 148 64 158 233 254 34', visualized);
  });

  test('testBug1664266', () {
    //There was an exception and the encoder did not handle the unlatching from
    //EDIFACT encoding correctly

    String visualized = encodeHighLevel('CREX-TAN:h');
    expect('68 83 70 89 46 85 66 79 59 105', visualized);

    visualized = encodeHighLevel('CREX-TAN:hh');
    expect('68 83 70 89 46 85 66 79 59 105 105 129', visualized);

    visualized = encodeHighLevel('CREX-TAN:hhh');
    expect('68 83 70 89 46 85 66 79 59 105 105 105', visualized);
  });

  test('testX12Unlatch', () {
    final visualized = encodeHighLevel('*DTCP01');
    expect('43 69 85 68 81 131 129 56', visualized);
  });

  test('testX12Unlatch2', () {
    final visualized = encodeHighLevel('*DTCP0');
    expect('238 9 10 104 141', visualized);
  });

  test('testBug3048549', () {
    //There was an IllegalArgumentException for an illegal character here because
    //of an encoding problem of the character 0x0060 in Java source code.

    final visualized = encodeHighLevel('fiykmj*Rh2`,e6');
    expect(
      //TODO java result:"103 106 122 108 110 107 43 83 105 51 97 45 102 55 129 237",
      '239 122 87 154 40 7 171 115 207 12 130 71 155 254 129 237',
      visualized,
    );
  });

  test('testMacroCharacters', () {
    final visualized =
        encodeHighLevel('[)>\u001E05\u001D5555\u001C6666\u001E\u0004');
    //expect("92 42 63 31 135 30 185 185 29 196 196 31 5 129 87 237", visualized);
    expect('236 185 185 29 196 196 129 56', visualized);
  });

  test('testEncodingWithStartAsX12AndLatchToEDIFACTInTheMiddle', () {
    final visualized = encodeHighLevel('*MEMANT-1F-MESTECH');

    expect('240 168 209 77 4 229 45 196 107 77 21 53 5 12 135 192', visualized);
  });

  test('testX12AndEDIFACTSpecErrors', () {
    //X12 encoding error with spec conform float point comparisons in lookAheadTest()
    String visualized =
        encodeHighLevel('AAAAAAAAAAA**\u00FCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
    expect(
      '230 89 191 89 191 89 191 89 178 56 114 10 243 177 63 89 191 89 191 89 191 89 191 89 191 89 191 89 '
      '191 89 191 89 191 254 66 129',
      visualized,
    );
    //X12 encoding error with integer comparisons in lookAheadTest()
    visualized =
        encodeHighLevel('AAAAAAAAAAAA0+****AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
    expect(
      '238 89 191 89 191 89 191 89 191 254 240 194 186 170 170 160 65 4 16 65 4 16 65 4 16 65 4 16 65 4 '
      '16 65 4 16 65 4 16 65 124 129 167 62 212 107',
      visualized,
    );
    //EDIFACT encoding error with spec conform float point comparisons in lookAheadTest()
    visualized =
        encodeHighLevel('AAAAAAAAAAA++++\u00FCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
    expect(
      '230 89 191 89 191 89 191 254 66 66 44 44 44 44 235 125 230 89 191 89 191 89 191 89 191 89 191 89 '
      '191 89 191 89 191 89 191 89 191 254 129 17 167 62 212 107',
      visualized,
    );
    //EDIFACT encoding error with integer comparisons in lookAheadTest()
    visualized =
        encodeHighLevel('++++++++++AAa0 0++++++++++++++++++++++++++++++');
    expect(
      '240 174 186 235 174 186 235 174 176 65 124 98 240 194 12 43 174 186 235 174 186 235 174 186 235 '
      '174 186 235 174 186 235 174 186 235 174 186 235 173 240 129 167 62 212 107',
      visualized,
    );
    visualized =
        encodeHighLevel('AAAAAAAAAAAA*+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
    expect(
      '230 89 191 89 191 89 191 89 191 7 170 64 191 89 191 89 191 89 191 89 191 89 191 89 191 89 191 89 '
      '191 89 191 66',
      visualized,
    );
    visualized =
        encodeHighLevel('AAAAAAAAAAA*0a0 *AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
    expect(
      '230 89 191 89 191 89 191 89 178 56 227 6 228 7 183 89 191 89 191 89 191 89 191 89 191 89 191 89 '
      '191 89 191 89 191 254 66 66',
      visualized,
    );
  });

  test('testSizes', () {
    final sizes = List.filled(2, 0);
    encodeHighLevelSize('A', sizes);
    expect(3, sizes[0]);
    expect(3, sizes[1]);

    encodeHighLevelSize('AB', sizes);
    expect(3, sizes[0]);
    expect(3, sizes[1]);

    encodeHighLevelSize('ABC', sizes);
    expect(3, sizes[0]);
    expect(3, sizes[1]);

    encodeHighLevelSize('ABCD', sizes);
    expect(5, sizes[0]);
    expect(5, sizes[1]);

    encodeHighLevelSize('ABCDE', sizes);
    expect(5, sizes[0]);
    expect(5, sizes[1]);

    encodeHighLevelSize('ABCDEF', sizes);
    expect(5, sizes[0]);
    expect(5, sizes[1]);

    encodeHighLevelSize('ABCDEFG', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize('ABCDEFGH', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize('ABCDEFGHI', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize('ABCDEFGHIJ', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize('a', sizes);
    expect(3, sizes[0]);
    expect(3, sizes[1]);

    encodeHighLevelSize('ab', sizes);
    expect(3, sizes[0]);
    expect(3, sizes[1]);

    encodeHighLevelSize('abc', sizes);
    expect(3, sizes[0]);
    expect(3, sizes[1]);

    encodeHighLevelSize('abcd', sizes);
    expect(5, sizes[0]);
    expect(5, sizes[1]);

    encodeHighLevelSize('abcdef', sizes);
    expect(5, sizes[0]);
    expect(5, sizes[1]);

    encodeHighLevelSize('abcdefg', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize('abcdefgh', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize('+', sizes);
    expect(3, sizes[0]);
    expect(3, sizes[1]);

    encodeHighLevelSize('++', sizes);
    expect(3, sizes[0]);
    expect(3, sizes[1]);

    encodeHighLevelSize('+++', sizes);
    expect(3, sizes[0]);
    expect(3, sizes[1]);

    encodeHighLevelSize('++++', sizes);
    expect(5, sizes[0]);
    expect(5, sizes[1]);

    encodeHighLevelSize('+++++', sizes);
    expect(5, sizes[0]);
    expect(5, sizes[1]);

    encodeHighLevelSize('++++++', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize('+++++++', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize('++++++++', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize('+++++++++', sizes);
    expect(8, sizes[0]);
    expect(8, sizes[1]);

    encodeHighLevelSize(
      '\u00F0\u00F0'
      'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEF',
      sizes,
    );
    expect(114, sizes[0]);
    expect(62, sizes[1]);
  });

  test('testECIs', () {
    String visualized = visualize(
      MinimalEncoder.encodeHighLevel(
        'that particularly stands out to me is \u0625\u0650'
        '\u062C\u064E\u0651\u0627\u0635 (\u02BE\u0101\u1E63) "pear", suggested to have originated from Hebrew '
        '\u05D0\u05B7\u05D2\u05B8\u05BC\u05E1 (ag\u00E1s)',
      ),
    );
    // TODO 2. 116 33 241 9 231 186 14 206 64 248 44 252 159 33 41 241 27 231 83
    expect(
      visualized,
      '239 209 151 206 214 92 122 140 35 158 144 162 52 205 55 171 137 23 67 206 218 175 147 113 15 254'
      ' 116 33 241 25 231 186 14 212 64 253 151 252 159 33 41 241 27 231 83 171 53 209 35 25 134 6 42 33 35 239 184'
      ' 31 193 234 7 252 205 101 127 241 209 34 24 5 22 23 221 148 179 239 128 140 92 187 106 204 198 59 19 25 114'
      ' 248 118 36 254 231 106 196 19 239 101 27 107 69 189 112 236 156 252 16 174 125 24 10 125 116 42 129',
    );

    visualized = visualize(
      MinimalEncoder.encodeHighLevel(
        'that particularly stands out to me is \u0625\u0650'
        '\u062C\u064E\u0651\u0627\u0635 (\u02BE\u0101\u1E63) "pear", suggested to have originated from Hebrew '
        '\u05D0\u05B7\u05D2\u05B8\u05BC\u05E1 (ag\u00E1s)',
        utf8,
        -1,
        SymbolShapeHint.forceNone,
      ),
    );
    expect(
      visualized,
      '241 27 239 209 151 206 214 92 122 140 35 158 144 162 52 205 55 171 137 23 67 206 218 175 147 113'
      ' 15 254 116 33 231 202 33 131 77 154 119 225 163 238 206 28 249 93 36 150 151 53 108 246 145 228 217 71'
      ' 199 42 33 35 239 184 31 193 234 7 252 205 101 127 241 209 34 24 5 22 23 221 148 179 239 128 140 92 187 106'
      ' 204 198 59 19 25 114 248 118 36 254 231 43 133 212 175 38 220 44 6 125 49 172 93 189 209 111 61 217 203 62'
      ' 116 42 129 1 151 46 196 91 241 137 32 182 77 227 122 18 168 63 213 108 4 154 49 199 94 244 140 35 185 80',
    );
  });

  test('testPadding', () {
    final sizes = List.filled(2, 0);
    encodeHighLevelSize(
      'IS010000000000000000000000S1118058599124123S21.2.250.1.213.1.4.8 S3FIRST NAMETEST S5MS618-06'
      '-1985S713201S4LASTNAMETEST',
      sizes,
    );
    expect(86, sizes[0]);
    expect(86, sizes[1]);
  });
}
