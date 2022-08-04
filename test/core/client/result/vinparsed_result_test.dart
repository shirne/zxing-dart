/*
 * Copyright 2014 ZXing authors
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
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/zxing.dart';

/// Tests [VINParsedResult].
void main() {
  void doTest(
      String contents,
      String wmi,
      String vds,
      String vis,
      String country,
      String attributes,
      int year,
      int plant,
      String sequential) {
    Result fakeResult = Result(contents, null, null, BarcodeFormat.CODE_39);
    ParsedResult result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.VIN, result.type);
    VINParsedResult vinResult = result as VINParsedResult;
    expect(wmi, vinResult.worldManufacturerID);
    expect(vds, vinResult.vehicleDescriptorSection);
    expect(vis, vinResult.vehicleIdentifierSection);
    expect(country, vinResult.countryCode);
    expect(attributes, vinResult.vehicleAttributes);
    expect(year, vinResult.modelYear);
    expect(plant, vinResult.plantCode);
    expect(sequential, vinResult.sequentialNumber);
  }

  test('testNotVIN', () {
    Result fakeResult =
        Result('1M8GDM9A1KP042788', null, null, BarcodeFormat.CODE_39);
    ParsedResult result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.TEXT, result.type);
    fakeResult =
        Result('1M8GDM9AXKP042788', null, null, BarcodeFormat.CODE_128);
    result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.TEXT, result.type);
  });

  test('testVIN', () {
    doTest('1M8GDM9AXKP042788', '1M8', 'GDM9AX', 'KP042788', 'US', 'GDM9A',
        1989, 80 /* P */, '042788');
    doTest('I1M8GDM9AXKP042788', '1M8', 'GDM9AX', 'KP042788', 'US', 'GDM9A',
        1989, 80 /* P */, '042788');
    doTest('LJCPCBLCX11000237', 'LJC', 'PCBLCX', '11000237', 'CN', 'PCBLC',
        2001, 49 /* 1 */, '000237');
  });
}
