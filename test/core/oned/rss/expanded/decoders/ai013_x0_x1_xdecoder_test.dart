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





import 'package:flutter_test/flutter_test.dart';

import 'abstract_decoder_test.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
void main(){

  final String header310x11 = "..XXX...";
  final String header320x11 = "..XXX..X";
  final String header310x13 = "..XXX.X.";
  final String header320x13 = "..XXX.XX";
  final String header310x15 = "..XXXX..";
  final String header320x15 = "..XXXX.X";
  final String header310x17 = "..XXXXX.";
  final String header320x17 = "..XXXXXX";

  test('test01310X1XendDate', (){
    String data = header310x11 + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed20bitWeight1750 + AbstractDecoderTest.compressedDateEnd;
    String expected = "(01)90012345678908(3100)001750";

    assertCorrectBinaryString(data, expected);
  });

  test('test01310X111', (){
    String data = header310x11 + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed20bitWeight1750 + AbstractDecoderTest.compressedDateMarch12th2010;
    String expected = "(01)90012345678908(3100)001750(11)100312";

    assertCorrectBinaryString(data, expected);
  });

  test('test01320X111', (){
    String data = header320x11 + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed20bitWeight1750 + AbstractDecoderTest.compressedDateMarch12th2010;
    String expected = "(01)90012345678908(3200)001750(11)100312";

    assertCorrectBinaryString(data, expected);
  });

  test('test01310X131', (){
    String data = header310x13 + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed20bitWeight1750 + AbstractDecoderTest.compressedDateMarch12th2010;
    String expected = "(01)90012345678908(3100)001750(13)100312";

    assertCorrectBinaryString(data, expected);
  });

  test('test01320X131', (){
    String data = header320x13 + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed20bitWeight1750 + AbstractDecoderTest.compressedDateMarch12th2010;
    String expected = "(01)90012345678908(3200)001750(13)100312";

    assertCorrectBinaryString(data, expected);
  });

  test('test01310X151', (){
    String data = header310x15 + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed20bitWeight1750 + AbstractDecoderTest.compressedDateMarch12th2010;
    String expected = "(01)90012345678908(3100)001750(15)100312";

    assertCorrectBinaryString(data, expected);
  });

  test('test01320X151', (){
    String data = header320x15 + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed20bitWeight1750 + AbstractDecoderTest.compressedDateMarch12th2010;
    String expected = "(01)90012345678908(3200)001750(15)100312";

    assertCorrectBinaryString(data, expected);
  });

  test('test01310X171', (){
    String data = header310x17 + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed20bitWeight1750 + AbstractDecoderTest.compressedDateMarch12th2010;
    String expected = "(01)90012345678908(3100)001750(17)100312";

    assertCorrectBinaryString(data, expected);
  });

  test('test01320X171', (){
    String data = header320x17 + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed20bitWeight1750 + AbstractDecoderTest.compressedDateMarch12th2010;
    String expected = "(01)90012345678908(3200)001750(17)100312";

    assertCorrectBinaryString(data, expected);
  });

}
