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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/zxing.dart';

void main() {
  test('testRSSExpanded', () {
    final uncommonAIs = <String, String>{};
    uncommonAIs['123'] = '544654';
    final result = Result(
      '(01)66546(13)001205(3932)4455(3102)6544(123)544654',
      null,
      null,
      BarcodeFormat.rssExpanded,
    );
    final o = ExpandedProductResultParser().parse(result)!;
    //assertNotNull(o);
    expect('66546', o.productID);
    assert(o.sscc == null);
    assert(o.lotNumber == null);
    assert(o.productionDate == null);
    expect('001205', o.packagingDate);
    assert(o.bestBeforeDate == null);
    assert(o.expirationDate == null);
    expect('6544', o.weight);
    expect('KG', o.weightType);
    expect('2', o.weightIncrement);
    expect('5', o.price);
    expect('2', o.priceIncrement);
    expect('445', o.priceCurrency);
    expect(uncommonAIs, o.uncommonAIs);
  });
}
