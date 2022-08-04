/*
 * Copyright (C) 2010 ZXing authors
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

/* 
 * These authors would like to acknowledge the Spanish Ministry of Industry,
 * Tourism and Trade, for the support in the project TSI020301-2008-2
 * "PIRAmIDE: Personalizable Interactions with Resources on AmI-enabled
 * Mobile Dynamic Environments", led by Treelogic
 * ( http://www.treelogic.com/ ):
 *
 *   http://www.piramidepse.com/
 */

import 'package:test/scaffolding.dart';

import 'abstract_decoder.dart';

void main() {
  final String header = '.....';

  test('testAnyAIDecoder1', () {
    String data = header +
        AbstractDecoderTest.numeric10 +
        AbstractDecoderTest.numeric12 +
        AbstractDecoderTest.numeric2alpha +
        AbstractDecoderTest.alphaA +
        AbstractDecoderTest.alpha2numeric +
        AbstractDecoderTest.numeric12;
    String expected = '(10)12A12';

    assertCorrectBinaryString(data, expected);
  });

  test('testAnyAIDecoder2', () {
    String data = header +
        AbstractDecoderTest.numeric10 +
        AbstractDecoderTest.numeric12 +
        AbstractDecoderTest.numeric2alpha +
        AbstractDecoderTest.alphaA +
        AbstractDecoderTest.alpha2isoiec646 +
        AbstractDecoderTest.i646B;
    String expected = '(10)12AB';

    assertCorrectBinaryString(data, expected);
  });

  test('testAnyAIDecoder3', () {
    String data = header +
        AbstractDecoderTest.numeric10 +
        AbstractDecoderTest.numeric2alpha +
        AbstractDecoderTest.alpha2isoiec646 +
        AbstractDecoderTest.i646B +
        AbstractDecoderTest.i646C +
        AbstractDecoderTest.isoiec6462alpha +
        AbstractDecoderTest.alphaA +
        AbstractDecoderTest.alpha2numeric +
        AbstractDecoderTest.numeric10;
    String expected = '(10)BCA10';

    assertCorrectBinaryString(data, expected);
  });

  test('testAnyAIDecodernumericFNC1secondDigit', () {
    String data = header +
        AbstractDecoderTest.numeric10 +
        AbstractDecoderTest.numeric1FNC1;
    String expected = '(10)1';

    assertCorrectBinaryString(data, expected);
  });

  test('testAnyAIDecoderalphaFNC1', () {
    String data = header +
        AbstractDecoderTest.numeric10 +
        AbstractDecoderTest.numeric2alpha +
        AbstractDecoderTest.alphaA +
        AbstractDecoderTest.alphaFNC1;
    String expected = '(10)A';

    assertCorrectBinaryString(data, expected);
  });

  test('testAnyAIDecoder646FNC1', () {
    String data = header +
        AbstractDecoderTest.numeric10 +
        AbstractDecoderTest.numeric2alpha +
        AbstractDecoderTest.alphaA +
        AbstractDecoderTest.isoiec6462alpha +
        AbstractDecoderTest.i646B +
        AbstractDecoderTest.i646FNC1;
    String expected = '(10)AB';

    assertCorrectBinaryString(data, expected);
  });
}
