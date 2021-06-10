/*
 * Copyright 2007 ZXing authors
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
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/zxing.dart';

/// Tests [ProductParsedResult].
///
void main(){

  void doTest(String contents, String normalized, BarcodeFormat format) {
    Result fakeResult = new Result(contents, null, null, format);
    ParsedResult result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.PRODUCT, result.type);
    ProductParsedResult productResult = result as ProductParsedResult;
    expect(contents, productResult.productID);
    expect(normalized, productResult.normalizedProductID);
  }


  test('testProduct', () {
    doTest("123456789012", "123456789012", BarcodeFormat.UPC_A);
    doTest("00393157", "00393157", BarcodeFormat.EAN_8);
    doTest("5051140178499", "5051140178499", BarcodeFormat.EAN_13);
    doTest("01234565", "012345000065", BarcodeFormat.UPC_E);
  });

}