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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/pdf417.dart';
import 'package:zxing_lib/zxing.dart';

import 'abstract_error_correction.dart';

void main() {
  const List<int> pdf417Test = [
    48, 901, 56, 141, 627, 856, 330, 69, 244, 900, 852, 169, 843, 895, 852, //
    895, 913, 154, 845, 778, 387, 89, 869, 901, 219, 474, 543, 650, 169, 201,
    9, 160, 35, 70, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900,
    900, 900, 900
  ];
  const List<int> pdf417TestWithEc = [
    48, 901, 56, 141, 627, 856, 330, 69, 244, 900, 852, 169, 843, 895, 852, //
    895, 913, 154, 845, 778, 387, 89, 869, 901, 219, 474, 543, 650, 169, 201,
    9, 160, 35, 70, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900, 900,
    900, 900, 769, 843, 591, 910, 605, 206, 706, 917, 371, 469, 79, 718, 47,
    777, 249, 262, 193, 620, 597, 477, 450, 806, 908, 309, 153, 871, 686, 838,
    185, 674, 68, 679, 691, 794, 497, 479, 234, 250, 496, 43, 347, 582, 882,
    536, 322, 317, 273, 194, 917, 237, 420, 859, 340, 115, 222, 808, 866, 836,
    417, 121, 833, 459, 64, 159
  ];
  final int eccBytes = pdf417TestWithEc.length - pdf417Test.length;
  final int errorLimit = eccBytes;
  final int maxErrors = errorLimit ~/ 2;
  //final int maxErasures = errorLimit;

  final ErrorCorrection ec = ErrorCorrection();

  void checkDecode(List<int> received, [List<int> erasures = const []]) {
    ec.decode(received, eccBytes, erasures);
    for (int i = 0; i < pdf417Test.length; i++) {
      expect(received[i], pdf417Test[i]);
    }
  }

  test('testNoError', () {
    final received = pdf417TestWithEc.toList();
    // no errors
    checkDecode(received);
  });

  test('testOneError', () {
    final random = AbstractErrorCorrectionTestCase.getRandom();
    for (int i = 0; i < pdf417TestWithEc.length; i++) {
      final received = pdf417TestWithEc.toList();
      received[i] = random.nextInt(256);
      checkDecode(received);
    }
  });

  test('testMaxErrors', () {
    final random = AbstractErrorCorrectionTestCase.getRandom();
    for (int testIterations = 0; testIterations < 100; testIterations++) {
      // # iterations is kind of arbitrary
      final received = pdf417TestWithEc.toList();
      AbstractErrorCorrectionTestCase.corrupt(received, maxErrors, random);
      checkDecode(received);
    }
  });

  test('testTooManyErrors', () {
    final received = pdf417TestWithEc.toList();
    final random = AbstractErrorCorrectionTestCase.getRandom();
    AbstractErrorCorrectionTestCase.corrupt(received, maxErrors + 1, random);
    expect(
      () => checkDecode(received),
      throwsA(TypeMatcher<ChecksumException>()),
    );
  });
}
