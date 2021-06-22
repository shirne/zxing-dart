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


import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/qrcode.dart';


void main(){

  test('testForBits', () {
    expect(Mode.TERMINATOR, Mode.forBits(0x00));
    expect(Mode.NUMERIC, Mode.forBits(0x01));
    expect(Mode.ALPHANUMERIC, Mode.forBits(0x02));
    expect(Mode.BYTE, Mode.forBits(0x04));
    expect(Mode.KANJI, Mode.forBits(0x08));
  });

  //@Test(expected = IllegalArgumentException.class)
  test('testBadMode', () {
    try {
      Mode.forBits(0x10);
      assert(false);
    }catch(_){
      // passed
    }
  });

  test('testCharacterCount', () {
    // Spot check a few values
    expect(10, Mode.NUMERIC.getCharacterCountBits(Version.getVersionForNumber(5)));
    expect(12, Mode.NUMERIC.getCharacterCountBits(Version.getVersionForNumber(26)));
    expect(14, Mode.NUMERIC.getCharacterCountBits(Version.getVersionForNumber(40)));
    expect(9, Mode.ALPHANUMERIC.getCharacterCountBits(Version.getVersionForNumber(6)));
    expect(8, Mode.BYTE.getCharacterCountBits(Version.getVersionForNumber(7)));
    expect(8, Mode.KANJI.getCharacterCountBits(Version.getVersionForNumber(8)));
  });

}
