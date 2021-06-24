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

import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';

void main() {
  final int accp = 10000;

  void assertPointEquals(double expectedX, double expectedY, double sourceX,
      double sourceY, PerspectiveTransform pt) {
    List<double> points = [sourceX, sourceY];
    pt.transformPoints(points);
    assert((expectedX * accp).round() == (points[0] * accp).round(),
        "$expectedX ${points[0]},");
    assert((expectedY * accp).round() == (points[1] * accp).round(),
        "$expectedY ${points[1]},");
  }

  test('testSquareToQuadrilateral', () {
    PerspectiveTransform pt = PerspectiveTransform.squareToQuadrilateral(
        2.0, 3.0, 10.0, 4.0, 16.0, 15.0, 4.0, 9.0);
    assertPointEquals(2.0, 3.0, 0.0, 0.0, pt);
    assertPointEquals(10.0, 4.0, 1.0, 0.0, pt);
    assertPointEquals(4.0, 9.0, 0.0, 1.0, pt);
    assertPointEquals(16.0, 15.0, 1.0, 1.0, pt);
    assertPointEquals(6.535211, 6.8873234, 0.5, 0.5, pt);
    assertPointEquals(48.0, 42.42857, 1.5, 1.5, pt);
  });

  test('testQuadrilateralToQuadrilateral', () {
    PerspectiveTransform pt = PerspectiveTransform.quadrilateralToQuadrilateral(
        2.0,
        3.0,
        10.0,
        4.0,
        16.0,
        15.0,
        4.0,
        9.0,
        103.0,
        110.0,
        300.0,
        120.0,
        290.0,
        270.0,
        150.0,
        280.0);
    assertPointEquals(103.0, 110.0, 2.0, 3.0, pt);
    assertPointEquals(300.0, 120.0, 10.0, 4.0, pt);
    assertPointEquals(290.0, 270.0, 16.0, 15.0, pt);
    assertPointEquals(150.0, 280.0, 4.0, 9.0, pt);
    assertPointEquals(7.1516876, -64.60185, 0.5, 0.5, pt);
    assertPointEquals(328.09116, 334.16385, 50.0, 50.0, pt);
  });
}
