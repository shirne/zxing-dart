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

import 'dart:math' as math;

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';

/// Tests [MathUtils].
void main() {
  test('testRound', () {
    expect(-1, MathUtils.round(-1.0));
    expect(0, MathUtils.round(0.0));
    expect(1, MathUtils.round(1.0));

    expect(2, MathUtils.round(1.9));
    expect(2, MathUtils.round(2.1));

    expect(3, MathUtils.round(2.5));

    expect(-2, MathUtils.round(-1.9));
    expect(-2, MathUtils.round(-2.1));

    expect(-3, MathUtils.round(-2.5)); // This differs from Math.round()

    expect(
        MathUtils.MAX_VALUE, MathUtils.round(MathUtils.MAX_VALUE.toDouble()));
    expect(
        MathUtils.MIN_VALUE, MathUtils.round(MathUtils.MIN_VALUE.toDouble()));

    // todo ??
    expect(MathUtils.MAX_VALUE,
        MathUtils.round(double.infinity)); //Float.POSITIVE_INFINITY
    expect(MathUtils.MIN_VALUE,
        MathUtils.round(double.negativeInfinity)); //Float.NEGATIVE_INFINITY

    expect(0, MathUtils.round(double.nan));
  });

  test('testDistance', () {
    expect(math.sqrt(8.0), MathUtils.distance(1.0, 2.0, 3.0, 4.0));
    expect(0.0, MathUtils.distance(1.0, 2.0, 1.0, 2.0));

    expect(math.sqrt(8.0), MathUtils.distance(1, 2, 3, 4));
    expect(0.0, MathUtils.distance(1, 2, 1, 2));
  });

  test('testSum', () {
    expect(0, MathUtils.sum([]));
    expect(1, MathUtils.sum([1]));
    expect(4, MathUtils.sum([1, 3]));
    expect(0, MathUtils.sum([-1, 1]));
  });

  test('numberOfTrailingZeros', () {
    Map<int, int> tZeros = {
      0: 32,
      1: 0,
      7: 0,
      8: 3,
      15: 0,
      16: 4,
      17: 0,
      110: 1,
      124: 2,
      156: 2,
      263: 0,
      998: 1,
      65536: 16,
      75216: 4,
      452216: 3,
      3599263: 0,
      2599265: 0,
      521145851: 0
    };
    tZeros.forEach((key, value) {
      expect(MathUtils.numberOfTrailingZeros(key), value,
          reason: '$key => $value');
    });
  });
}
