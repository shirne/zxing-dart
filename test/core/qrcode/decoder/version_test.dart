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


import 'package:flutter_test/flutter_test.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/zxing.dart';


void main(){

  //@Test(expected = IllegalArgumentException.class)
  test('testBadVersion', () {
    try {
      Version.getVersionForNumber(0);
      fail('expected');
    }catch(_){
      //passed
    }
  });

  test('testVersionForNumber', () {
    for (int i = 1; i <= 40; i++) {
      checkVersion(Version.getVersionForNumber(i), i, 4 * i + 17);
    }
  });



  test('testGetProvisionalVersionForDimension', (){
    for (int i = 1; i <= 40; i++) {
      expect(i, Version.getProvisionalVersionForDimension(4 * i + 17).versionNumber);
    }
  });

  test('testDecodeVersionInformation', () {
    // Spot check
    doTestVersion(7, 0x07C94);
    doTestVersion(12, 0x0C762);
    doTestVersion(17, 0x1145D);
    doTestVersion(22, 0x168C9);
    doTestVersion(27, 0x1B08E);
    doTestVersion(32, 0x209D5);
  });
  


}

void checkVersion(Version version, int number, int dimension) {
  assert(version != null);
  expect(number, version.versionNumber);
  assert(version.alignmentPatternCenters != null);
  if (number > 1) {
    assert(version.alignmentPatternCenters.length > 0);
  }
  expect(dimension, version.dimensionForVersion);
  assert(version.getECBlocksForLevel(ErrorCorrectionLevel.H) != null);
  assert(version.getECBlocksForLevel(ErrorCorrectionLevel.L) != null);
  assert(version.getECBlocksForLevel(ErrorCorrectionLevel.M) != null);
  assert(version.getECBlocksForLevel(ErrorCorrectionLevel.Q) != null);
  assert(version.buildFunctionPattern() != null);
}

void doTestVersion(int expectedVersion, int mask) {
  Version? version = Version.decodeVersionInformation(mask);
  assert(version != null);
  expect(expectedVersion, version!.versionNumber);
}