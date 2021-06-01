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

import 'package:buffer_image/buffer_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/common.dart';
import 'package:zxing/oned.dart';
import 'package:zxing/zxing.dart';

import '../../../buffered_image_luminance_source.dart';
import '../../../common/abstract_black_box.dart';

/**
 * @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
 * @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
 */
void main(){


  Future<BufferImage> readImage(String fileName) async{
    File path = File( AbstractBlackBoxTestCase.buildTestBase("src/test/resources/blackbox/rssexpanded-1/").path +'/'+ fileName);
    return (await BufferImage.fromFile(path))!;
  }

  test('testFindFinderPatterns', () async{
    BufferImage image = await readImage("2.png");
    BinaryBitmap binaryMap = new BinaryBitmap(new GlobalHistogramBinarizer(new BufferedImageLuminanceSource(image)));
    int rowNumber = binaryMap.getHeight() ~/ 2;
    BitArray row = binaryMap.getBlackRow(rowNumber, null);
    List<ExpandedPair> previousPairs = [];

    RSSExpandedReader rssExpandedReader = new RSSExpandedReader();
    ExpandedPair pair1 = rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair1);
    FinderPattern finderPattern = pair1.getFinderPattern()!;
    //assertNotNull(finderPattern);
    expect(0, finderPattern.getValue());

    ExpandedPair pair2 = rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair2);
    finderPattern = pair2.getFinderPattern()!;
    //assertNotNull(finderPattern);
    expect(1, finderPattern.getValue());

    ExpandedPair pair3 = rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair3);
    finderPattern = pair3.getFinderPattern()!;
    //assertNotNull(finderPattern);
    expect(1, finderPattern.getValue());

    try {
      rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber);
      //   the previous was the last pair
      fail( "NotFoundException expected");
    } catch ( _) { // NotFoundException
      // ok
    }
  });

  test('testRetrieveNextPairPatterns', () async{
    BufferImage image = await readImage("3.png");
    BinaryBitmap binaryMap = new BinaryBitmap(new GlobalHistogramBinarizer(new BufferedImageLuminanceSource(image)));
    int rowNumber = binaryMap.getHeight() ~/ 2;
    BitArray row = binaryMap.getBlackRow(rowNumber, null);
    List<ExpandedPair> previousPairs = [];

    RSSExpandedReader rssExpandedReader = new RSSExpandedReader();
    ExpandedPair pair1 = rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair1);
    FinderPattern finderPattern = pair1.getFinderPattern()!;
    //assertNotNull(finderPattern);
    expect(0, finderPattern.getValue());

    ExpandedPair pair2 = rssExpandedReader.retrieveNextPair(row, previousPairs, rowNumber)!;
    previousPairs.add(pair2);
    finderPattern = pair2.getFinderPattern()!;
    //assertNotNull(finderPattern);
    expect(0, finderPattern.getValue());
  });

  test('testDecodeCheckCharacter', () async{
    BufferImage image = await readImage("3.png");
    BinaryBitmap binaryMap = new BinaryBitmap(new GlobalHistogramBinarizer(new BufferedImageLuminanceSource(image)));
    BitArray row = binaryMap.getBlackRow(binaryMap.getHeight() ~/ 2, null);

    List<int> startEnd = [145, 243]; //image pixels where the A1 pattern starts (at 124) and ends (at 214)
    int value = 0; // A
    FinderPattern finderPatternA1 = new FinderPattern(value, startEnd, startEnd[0], startEnd[1], image.height ~/ 2);
    //{1, 8, 4, 1, 1};
    RSSExpandedReader rssExpandedReader = new RSSExpandedReader();
    DataCharacter dataCharacter = rssExpandedReader.decodeDataCharacter(row, finderPatternA1, true, true);

    expect(98, dataCharacter.getValue());
  });

  test('testDecodeDataCharacter', () async{
    BufferImage image = await readImage("3.png");
    BinaryBitmap binaryMap = new BinaryBitmap(new GlobalHistogramBinarizer(new BufferedImageLuminanceSource(image)));
    BitArray row = binaryMap.getBlackRow(binaryMap.getHeight() ~/ 2, null);

    List<int> startEnd = [145, 243]; //image pixels where the A1 pattern starts (at 124) and ends (at 214)
    int value = 0; // A
    FinderPattern finderPatternA1 = new FinderPattern(value, startEnd, startEnd[0], startEnd[1], image.height ~/ 2);
    //{1, 8, 4, 1, 1};
    RSSExpandedReader rssExpandedReader = new RSSExpandedReader();
    DataCharacter dataCharacter = rssExpandedReader.decodeDataCharacter(row, finderPatternA1, true, false);

    expect(19, dataCharacter.getValue());
    expect(1007, dataCharacter.getChecksumPortion());
  });

}
