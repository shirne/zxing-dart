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

import 'dart:io';

import 'package:image/image.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../../../buffered_image_luminance_source.dart';
import '../../../common/abstract_black_box.dart';

void main() {
  Image readImage(String fileName) {
    File path = File(
        '${AbstractBlackBoxTestCase.buildTestBase("test/resources/blackbox/rssexpanded-1/").path}/$fileName');
    return decodeImage(path.readAsBytesSync())!;
  }

  test('testFindFinderPatterns', () async {
    Image image = readImage('2.png');
    BinaryBitmap binaryMap = BinaryBitmap(
        GlobalHistogramBinarizer(BufferedImageLuminanceSource(image)));
    int rowNumber = binaryMap.height ~/ 2;
    BitArray row = binaryMap.getBlackRow(rowNumber, null);
    List<ExpandedPair> previousPairs = [];

    RSSExpandedReader rssExpandedReader = RSSExpandedReader();
    ExpandedPair pair1 =
        rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair1);
    FinderPattern finderPattern = pair1.finderPattern!;
    //assertNotNull(finderPattern);
    expect(0, finderPattern.value);

    ExpandedPair pair2 =
        rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair2);
    finderPattern = pair2.finderPattern!;
    //assertNotNull(finderPattern);
    expect(1, finderPattern.value);

    ExpandedPair pair3 =
        rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair3);
    finderPattern = pair3.finderPattern!;
    //assertNotNull(finderPattern);
    expect(1, finderPattern.value);

    try {
      rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber);
      //   the previous was the last pair
      fail('NotFoundException expected');
    } on NotFoundException catch (_) {
      // ok
    }
  });

  test('testRetrieveNextPairPatterns', () async {
    Image image = readImage('3.png');
    BinaryBitmap binaryMap = BinaryBitmap(
        GlobalHistogramBinarizer(BufferedImageLuminanceSource(image)));
    int rowNumber = binaryMap.height ~/ 2;
    BitArray row = binaryMap.getBlackRow(rowNumber, null);
    List<ExpandedPair> previousPairs = [];

    RSSExpandedReader rssExpandedReader = RSSExpandedReader();
    ExpandedPair pair1 =
        rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair1);
    FinderPattern finderPattern = pair1.finderPattern!;
    //assertNotNull(finderPattern);
    expect(0, finderPattern.value);

    ExpandedPair pair2 =
        rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair2);
    finderPattern = pair2.finderPattern!;
    //assertNotNull(finderPattern);
    expect(0, finderPattern.value);
  });

  test('testDecodeCheckCharacter', () async {
    Image image = readImage('3.png');
    BinaryBitmap binaryMap = BinaryBitmap(
        GlobalHistogramBinarizer(BufferedImageLuminanceSource(image)));
    BitArray row = binaryMap.getBlackRow(binaryMap.height ~/ 2, null);

    //image pixels where the A1 pattern starts (at 124) and ends (at 214)
    List<int> startEnd = [145, 243];
    int value = 0; // A
    FinderPattern finderPatternA1 = FinderPattern(
        value, startEnd, startEnd[0], startEnd[1], image.height ~/ 2);
    //{1, 8, 4, 1, 1};
    RSSExpandedReader rssExpandedReader = RSSExpandedReader();
    DataCharacter dataCharacter =
        rssExpandedReader.decodeDataCharacter(row, finderPatternA1, true, true);

    expect(98, dataCharacter.value);
  });

  test('testDecodeDataCharacter', () async {
    Image image = readImage('3.png');
    BinaryBitmap binaryMap = BinaryBitmap(
        GlobalHistogramBinarizer(BufferedImageLuminanceSource(image)));
    BitArray row = binaryMap.getBlackRow(binaryMap.height ~/ 2, null);

    //image pixels where the A1 pattern starts (at 124) and ends (at 214)
    List<int> startEnd = [145, 243];
    int value = 0; // A
    FinderPattern finderPatternA1 = FinderPattern(
        value, startEnd, startEnd[0], startEnd[1], image.height ~/ 2);
    //{1, 8, 4, 1, 1};
    RSSExpandedReader rssExpandedReader = RSSExpandedReader();
    DataCharacter dataCharacter = rssExpandedReader.decodeDataCharacter(
        row, finderPatternA1, true, false);

    expect(19, dataCharacter.value);
    expect(1007, dataCharacter.checksumPortion);
  });
}
