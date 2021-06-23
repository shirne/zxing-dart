/*
 * Copyright 2012 ZXing authors
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

import 'dart:math';

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/pdf417.dart';

import 'abstract_error_correction.dart';


void main() {
  const List<int> PDF417_TEST = [
    48, 901, 56, 141, 627, 856, 330, 69, 244, 900, 852, 169, 843, 895, 852, 895, 913, 154, 845, 778, 387, 89, 869,
    901, 219, 474, 543, 650, 169, 201, 9, 160, 35, 70, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900,
    900, 900];
  const List<int> PDF417_TEST_WITH_EC = [
    48, 901, 56, 141, 627, 856, 330, 69, 244, 900, 852, 169, 843, 895, 852, 895, 913, 154, 845, 778, 387, 89, 869,
    901, 219, 474, 543, 650, 169, 201, 9, 160, 35, 70, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900,
    900, 900, 769, 843, 591, 910, 605, 206, 706, 917, 371, 469, 79, 718, 47, 777, 249, 262, 193, 620, 597, 477, 450,
    806, 908, 309, 153, 871, 686, 838, 185, 674, 68, 679, 691, 794, 497, 479, 234, 250, 496, 43, 347, 582, 882, 536,
    322, 317, 273, 194, 917, 237, 420, 859, 340, 115, 222, 808, 866, 836, 417, 121, 833, 459, 64, 159];
  final int eccBytes = PDF417_TEST_WITH_EC.length - PDF417_TEST.length;
  final int errorLimit = eccBytes;
  final int maxErrors = errorLimit ~/ 2;
  final int maxErasures = errorLimit;

  final ErrorCorrection ec = new ErrorCorrection();

  void checkDecode(List<int> received, [List<int> erasures = const []]) {
    ec.decode(received, eccBytes, erasures);
    for (int i = 0; i < PDF417_TEST.length; i++) {
      expect(received[i], PDF417_TEST[i]);
    }
  }

  test('testNoError', () {
    List<int> received = PDF417_TEST_WITH_EC.toList();
    // no errors
    checkDecode(received);
  });

  test('testOneError', () {
    Random random = AbstractErrorCorrectionTestCase.getRandom();
    for (int i = 0; i < PDF417_TEST_WITH_EC.length; i++) {
      List<int> received = PDF417_TEST_WITH_EC.toList();
      received[i] = random.nextInt(256);
      checkDecode(received);
    }
  });

  test('testMaxErrors', () {
    Random random = AbstractErrorCorrectionTestCase.getRandom();
    for (int testIterations = 0; testIterations < 100; testIterations++) {
      // # iterations is kind of arbitrary
      List<int> received = PDF417_TEST_WITH_EC.toList();
      AbstractErrorCorrectionTestCase.corrupt(received, maxErrors, random);
      checkDecode(received);
    }
  });

  test('testTooManyErrors', () {
    List<int> received = PDF417_TEST_WITH_EC.toList();
    Random random = AbstractErrorCorrectionTestCase.getRandom();
    AbstractErrorCorrectionTestCase.corrupt(received, maxErrors + 1, random);
    try {
      checkDecode(received);
      fail("Should not have decoded");
    } catch (_) {
      // ChecksumException
      // good
    }
  });
}
