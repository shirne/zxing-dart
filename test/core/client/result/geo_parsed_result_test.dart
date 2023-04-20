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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/zxing.dart';

import '../../utils.dart';

/// Tests [GeoParsedResult].
///
void main() {
  const int epsilon = 10;

  void doTest(
    String contents,
    double latitude,
    double longitude,
    double altitude,
    String? query,
    String? uri,
  ) {
    final fakeResult = Result(contents, null, null, BarcodeFormat.qrCode);
    final result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.geo, result.type);
    final geoResult = result as GeoParsedResult;
    assertEqualOrNaN(latitude, geoResult.latitude, epsilon);
    assertEqualOrNaN(longitude, geoResult.longitude, epsilon);
    assertEqualOrNaN(altitude, geoResult.altitude, epsilon);
    expect(query, geoResult.query);
    expect(uri ?? contents.toLowerCase(/*Locale.ENGLISH*/), geoResult.geoURI);
  }

  test('testGeo', () {
    doTest('geo:1,2', 1.0, 2.0, 0.0, null, 'geo:1.0,2.0');
    doTest('geo:80.33,-32.3344,3.35', 80.33, -32.3344, 3.35, null, null);
    doTest('geo:-20.33,132.3344,0.01', -20.33, 132.3344, 0.01, null, null);
    doTest(
      'geo:-20.33,132.3344,0.01?q=foobar',
      -20.33,
      132.3344,
      0.01,
      'q=foobar',
      null,
    );
    doTest(
      'GEO:-20.33,132.3344,0.01?q=foobar',
      -20.33,
      132.3344,
      0.01,
      'q=foobar',
      null,
    );
  });
}
