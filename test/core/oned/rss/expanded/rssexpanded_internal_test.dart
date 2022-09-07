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
    final path = File(
        '${AbstractBlackBoxTestCase.buildTestBase("test/resources/blackbox/rssexpanded-1/").path}/$fileName');
    return decodeImage(path.readAsBytesSync())!;
  }

  test('testFindFinderPatterns', () async {
    final image = readImage('2.png');
    final binaryMap = BinaryBitmap(
        GlobalHistogramBinarizer(BufferedImageLuminanceSource(image)));
    final rowNumber = binaryMap.height ~/ 2;
    final row = binaryMap.getBlackRow(rowNumber, null);
    final previousPairs = <ExpandedPair>[];

    final rssExpandedReader = RSSExpandedReader();
    final pair1 =
        rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair1);
    FinderPattern finderPattern = pair1.finderPattern!;
    //assertNotNull(finderPattern);
    expect(0, finderPattern.value);

    final pair2 =
        rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair2);
    finderPattern = pair2.finderPattern!;
    //assertNotNull(finderPattern);
    expect(1, finderPattern.value);

    final pair3 =
        rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair3);
    finderPattern = pair3.finderPattern!;
    //assertNotNull(finderPattern);
    expect(1, finderPattern.value);

    expect(
      () => rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber),
      throwsA(TypeMatcher<NotFoundException>()),
    );
  });

  test('testRetrieveNextPairPatterns', () async {
    final image = readImage('3.png');
    final binaryMap = BinaryBitmap(
        GlobalHistogramBinarizer(BufferedImageLuminanceSource(image)));
    final rowNumber = binaryMap.height ~/ 2;
    final row = binaryMap.getBlackRow(rowNumber, null);
    final previousPairs = <ExpandedPair>[];

    final rssExpandedReader = RSSExpandedReader();
    final pair1 =
        rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair1);
    var finderPattern = pair1.finderPattern;
    expect(finderPattern, isNotNull);
    expect(0, finderPattern!.value);

    final pair2 = rssExpandedReader.retrieveNextPair(
      row,
      previousPairs,
      rowNumber,
    )!;
    previousPairs.add(pair2);
    finderPattern = pair2.finderPattern;
    expect(finderPattern, isNotNull);
    expect(0, finderPattern!.value);
  });

  test('testDecodeCheckCharacter', () async {
    final image = readImage('3.png');
    final binaryMap = BinaryBitmap(
        GlobalHistogramBinarizer(BufferedImageLuminanceSource(image)));
    final row = binaryMap.getBlackRow(binaryMap.height ~/ 2, null);

    //image pixels where the A1 pattern starts (at 124) and ends (at 214)
    final startEnd = [145, 243];
    const value = 0; // A
    final finderPatternA1 = FinderPattern(
      value,
      startEnd,
      startEnd[0],
      startEnd[1],
      image.height ~/ 2,
    );
    //{1, 8, 4, 1, 1};
    final rssExpandedReader = RSSExpandedReader();
    final dataCharacter = rssExpandedReader.decodeDataCharacter(
      row,
      finderPatternA1,
      true,
      true,
    );

    expect(98, dataCharacter.value);
  });

  test('testDecodeDataCharacter', () async {
    final image = readImage('3.png');
    final binaryMap = BinaryBitmap(
        GlobalHistogramBinarizer(BufferedImageLuminanceSource(image)));
    final row = binaryMap.getBlackRow(binaryMap.height ~/ 2, null);

    //image pixels where the A1 pattern starts (at 124) and ends (at 214)
    final startEnd = [145, 243];
    const value = 0; // A
    final finderPatternA1 = FinderPattern(
        value, startEnd, startEnd[0], startEnd[1], image.height ~/ 2);
    //{1, 8, 4, 1, 1};
    final rssExpandedReader = RSSExpandedReader();
    final dataCharacter = rssExpandedReader.decodeDataCharacter(
        row, finderPatternA1, true, false);

    expect(19, dataCharacter.value);
    expect(1007, dataCharacter.checksumPortion);
  });
}
