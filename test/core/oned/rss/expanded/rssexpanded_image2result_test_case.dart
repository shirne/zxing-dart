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
 *
 * This software consists of contributions made by many individuals,
 * listed below:
 *
 * @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
 * @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
 *
 * These authors would like to acknowledge the Spanish Ministry of Industry,
 * Tourism and Trade, for the support in the project TSI020301-2008-2
 * "PIRAmIDE: Personalizable Interactions with Resources on AmI-enabled
 * Mobile Dynamic Environments", leaded by Treelogic
 * ( http://www.treelogic.com/ ):
 *
 *   http://www.piramidepse.com/
 *
 */






import 'dart:io';

import 'package:buffer_image/buffer_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/client.dart';
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

  void assertCorrectImage2result(String fileName, ExpandedProductParsedResult expected) async{
    String path = AbstractBlackBoxTestCase.buildTestBase("src/test/resources/blackbox/rssexpanded-1/").path + '/' + (fileName);

    BufferImage image = (await BufferImage.fromFile(File(path)))!;
    BinaryBitmap binaryMap =  BinaryBitmap( GlobalHistogramBinarizer( BufferedImageLuminanceSource(image)));
    int rowNumber = binaryMap.getHeight() ~/ 2;
    BitArray row = binaryMap.getBlackRow(rowNumber, null);

    Result theResult;
    try {
      RSSExpandedReader rssExpandedReader = new RSSExpandedReader();
      theResult = rssExpandedReader.decodeRow(rowNumber, row, null);
    } catch ( re) { // ReaderException
    fail(re.toString());
    return;
    }

    expect(BarcodeFormat.RSS_EXPANDED, theResult.getBarcodeFormat());

    ParsedResult result = ResultParser.parseResult(theResult);

    expect(expected, result);
  }

  test('testDecodeRow2result2', (){
    // (01)90012345678908(3103)001750
    ExpandedProductParsedResult expected =
        new ExpandedProductParsedResult("(01)90012345678908(3103)001750",
                                        "90012345678908",
                                        null, null, null, null, null, null,
                                        "001750",
                                        ExpandedProductParsedResult.KILOGRAM,
                                        "3", null, null, null, {});

    assertCorrectImage2result("2.png", expected);
  });



}
