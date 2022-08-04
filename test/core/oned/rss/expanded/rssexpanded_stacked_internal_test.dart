/*
 * Copyright (C) 2012 ZXing authors
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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/oned.dart';

import 'test_case_util.dart';

/// Tests [RSSExpandedReader] handling of stacked RSS barcodes.
void main() {
  test('testDecodingRowByRow', () async {
    final rssExpandedReader = RSSExpandedReader();

    final binaryMap = TestCaseUtil.getBinaryBitmap(
        'test/resources/blackbox/rssexpandedstacked-2/1000.png');

    final firstRowNumber = binaryMap.height ~/ 3;
    final firstRow = binaryMap.getBlackRow(firstRowNumber, null);
    try {
      rssExpandedReader.decodeRow2pairs(firstRowNumber, firstRow);
      fail('NotFoundException expected');
    } catch (_) {
      // NotFoundException
      // ok
    }

    expect(1, rssExpandedReader.rows.length);
    final firstExpandedRow = rssExpandedReader.rows[0];
    expect(firstRowNumber, firstExpandedRow.rowNumber);

    expect(2, firstExpandedRow.pairs.length);

    firstExpandedRow.pairs[1].finderPattern!.startEnd[1] = 0;

    final secondRowNumber = 2 * binaryMap.height ~/ 3;
    final secondRow = binaryMap.getBlackRow(secondRowNumber, null);
    secondRow.reverse();

    final totalPairs =
        rssExpandedReader.decodeRow2pairs(secondRowNumber, secondRow);

    final result = RSSExpandedReader.constructResult(totalPairs);
    expect('(01)98898765432106(3202)012345(15)991231', result.text);
  });

  test('testCompleteDecode', () async {
    final rssExpandedReader = RSSExpandedReader();

    final binaryMap = TestCaseUtil.getBinaryBitmap(
        'test/resources/blackbox/rssexpandedstacked-2/1000.png');

    final result = rssExpandedReader.decode(binaryMap);
    expect('(01)98898765432106(3202)012345(15)991231', result.text);
  });
}
