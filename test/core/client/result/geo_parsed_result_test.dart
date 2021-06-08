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

import '../../utils.dart';

/// Tests {@link GeoParsedResult}.
///
/// @author Sean Owen
void main(){

  final int EPSILON = 10;

  void doTest(String contents,
      double latitude,
      double longitude,
      double altitude,
      String? query,
      String? uri) {
    Result fakeResult = new Result(contents, null, null, BarcodeFormat.QR_CODE);
    ParsedResult result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.GEO, result.getType());
    GeoParsedResult geoResult = result as GeoParsedResult;
    assertEqualOrNaN(latitude, geoResult.getLatitude(), EPSILON);
    assertEqualOrNaN(longitude, geoResult.getLongitude(), EPSILON);
    assertEqualOrNaN(altitude, geoResult.getAltitude(), EPSILON);
    expect(query, geoResult.getQuery());
    expect(uri == null ? contents.toLowerCase(/*Locale.ENGLISH*/) : uri, geoResult.getGeoURI());
  }

  test('testGeo', () {
    doTest("geo:1,2", 1.0, 2.0, 0.0, null, "geo:1.0,2.0");
    doTest("geo:80.33,-32.3344,3.35", 80.33, -32.3344, 3.35, null, null);
    doTest("geo:-20.33,132.3344,0.01", -20.33, 132.3344, 0.01, null, null);
    doTest("geo:-20.33,132.3344,0.01?q=foobar", -20.33, 132.3344, 0.01, "q=foobar", null);
    doTest("GEO:-20.33,132.3344,0.01?q=foobar", -20.33, 132.3344, 0.01, "q=foobar", null);
  });


}