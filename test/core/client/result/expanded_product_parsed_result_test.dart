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
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/zxing.dart';

/// @author Antonio Manuel Benjumea Conde, Servinform, S.A.
/// @author Agustín Delgado, Servinform, S.A.
void main(){

  test('testRSSExpanded', () {
    Map<String,String> uncommonAIs = {};
    uncommonAIs["123"] = "544654";
    Result result =
        new Result("(01)66546(13)001205(3932)4455(3102)6544(123)544654", null, null, BarcodeFormat.RSS_EXPANDED);
    ExpandedProductParsedResult o = new ExpandedProductResultParser().parse(result)!;
    //assertNotNull(o);
    expect("66546", o.getProductID());
    assert(o.getSscc()==null);
    assert(o.getLotNumber()==null);
    assert(o.getProductionDate()==null);
    expect("001205", o.getPackagingDate());
    assert(o.getBestBeforeDate()==null);
    assert(o.getExpirationDate()==null);
    expect("6544", o.getWeight());
    expect("KG", o.getWeightType());
    expect("2", o.getWeightIncrement());
    expect("5", o.getPrice());
    expect("2", o.getPriceIncrement());
    expect("445", o.getPriceCurrency());
    expect(uncommonAIs, o.getUncommonAIs());
  });
}
