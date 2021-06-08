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
import 'package:zxing_lib/zxing.dart';

import 'abstract_decoder.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
void main(){

  final String header = "..X..";

  test('test0131031', (){
    String data = header + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed15bitWeight1750;
    String expected = "(01)90012345678908(3103)001750";
    assertCorrectBinaryString(data, expected);
  });

  test('test0131032', (){
    String data = header + AbstractDecoderTest.compressedGtin900000000000008 + AbstractDecoderTest.compressed15bitWeight0;
    String expected = "(01)90000000000003(3103)000000";
    assertCorrectBinaryString(data, expected);
  });

  //@Test(expected = NotFoundException.class)
  test('test013103invalid', (){
    String data = header + AbstractDecoderTest.compressedGtin900123456798908 + AbstractDecoderTest.compressed15bitWeight1750 + "..";
    try {
      assertCorrectBinaryString(data, "");
      fail('accepted NotFoundException');
    } on NotFoundException catch(_){
      // passed
    }
  });
}
