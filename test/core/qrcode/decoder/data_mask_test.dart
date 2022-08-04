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
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';

void main() {
  test('testMask0', () {
    testMaskAcrossDimensions(0, (i, j) => (i + j) % 2 == 0);
  });

  test('testMask1', () {
    testMaskAcrossDimensions(1, (i, j) => i % 2 == 0);
  });

  test('testMask2', () {
    testMaskAcrossDimensions(2, (i, j) => j % 3 == 0);
  });

  test('testMask3', () {
    testMaskAcrossDimensions(3, (i, j) => (i + j) % 3 == 0);
  });

  test('testMask4', () {
    testMaskAcrossDimensions(4, (i, j) => (i ~/ 2 + j ~/ 3) % 2 == 0);
  });

  test('testMask5', () {
    testMaskAcrossDimensions(5, (i, j) => (i * j) % 2 + (i * j) % 3 == 0);
  });

  test('testMask6', () {
    testMaskAcrossDimensions(6, (i, j) => ((i * j) % 2 + (i * j) % 3) % 2 == 0);
  });

  test('testMask7', () {
    testMaskAcrossDimensions(7, (i, j) => ((i + j) % 2 + (i * j) % 3) % 2 == 0);
  });
}

void testMaskAcrossDimensions(
    int reference, bool Function(int, int) condition) {
  final mask = DataMask.values[reference];
  for (int version = 1; version <= 40; version++) {
    final dimension = 17 + 4 * version;
    testMask(mask, dimension, condition);
  }
}

void testMask(DataMask mask, int dimension, bool Function(int, int) condition) {
  final bits = BitMatrix(dimension);
  mask.unmaskBitMatrix(bits, dimension);
  for (int i = 0; i < dimension; i++) {
    for (int j = 0; j < dimension; j++) {
      expect(condition(i, j), bits.get(j, i), reason: '$dimension($i,$j)');
    }
  }
}
