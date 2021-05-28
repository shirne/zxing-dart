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

import 'package:zxing/core/common/detector/math_utils.dart';

import '../../not_found_exception.dart';
import '../one_dreader.dart';

/**
 * Superclass of {@link OneDReader} implementations that read barcodes in the RSS family
 * of formats.
 */
abstract class AbstractRSSReader extends OneDReader {
  static final double MAX_AVG_VARIANCE = 0.2;
  static final double MAX_INDIVIDUAL_VARIANCE = 0.45;

  static final double MIN_FINDER_PATTERN_RATIO = 9.5 / 12.0;
  static final double MAX_FINDER_PATTERN_RATIO = 12.5 / 14.0;

  final List<int> decodeFinderCounters;
  final List<int> dataCharacterCounters;
  final List<double> oddRoundingErrors;
  final List<double> evenRoundingErrors;
  final List<int> oddCounts;
  final List<int> evenCounts;

  AbstractRSSReader()
      : decodeFinderCounters = List.generate(4, (index) => 0),
        dataCharacterCounters = List.generate(8, (index) => 0),
        oddRoundingErrors = List.generate(4, (index) => 0),
        evenRoundingErrors = List.generate(4, (index) => 0),
        oddCounts = List.generate(4, (index) => 0),
        evenCounts = List.generate(4, (index) => 0);

  List<int> getDecodeFinderCounters() {
    return decodeFinderCounters;
  }

  List<int> getDataCharacterCounters() {
    return dataCharacterCounters;
  }

  List<double> getOddRoundingErrors() {
    return oddRoundingErrors;
  }

  List<double> getEvenRoundingErrors() {
    return evenRoundingErrors;
  }

  List<int> getOddCounts() {
    return oddCounts;
  }

  List<int> getEvenCounts() {
    return evenCounts;
  }

  static int parseFinderValue(
      List<int> counters, List<List<int>> finderPatterns) {
    for (int value = 0; value < finderPatterns.length; value++) {
      if (OneDReader.patternMatchVariance(
              counters, finderPatterns[value], MAX_INDIVIDUAL_VARIANCE) <
          MAX_AVG_VARIANCE) {
        return value;
      }
    }
    throw NotFoundException.getNotFoundInstance();
  }

  /**
   * @param array values to sum
   * @return sum of values
   * @deprecated call {@link MathUtils#sum(List<int>)}
   */
  @deprecated
  static int count(List<int> array) {
    return MathUtils.sum(array);
  }

  static void increment(List<int> array, List<double> errors) {
    int index = 0;
    double biggestError = errors[0];
    for (int i = 1; i < array.length; i++) {
      if (errors[i] > biggestError) {
        biggestError = errors[i];
        index = i;
      }
    }
    array[index]++;
  }

  static void decrement(List<int> array, List<double> errors) {
    int index = 0;
    double biggestError = errors[0];
    for (int i = 1; i < array.length; i++) {
      if (errors[i] < biggestError) {
        biggestError = errors[i];
        index = i;
      }
    }
    array[index]--;
  }

  static bool isFinderPattern(List<int> counters) {
    int firstTwoSum = counters[0] + counters[1];
    int sum = firstTwoSum + counters[2] + counters[3];
    double ratio = firstTwoSum / sum;
    if (ratio >= MIN_FINDER_PATTERN_RATIO &&
        ratio <= MAX_FINDER_PATTERN_RATIO) {
      // passes ratio test in spec, but see if the counts are unreasonable
      int minCounter = MathUtils.MAX_VALUE;
      int maxCounter = MathUtils.MIN_VALUE;
      for (int counter in counters) {
        if (counter > maxCounter) {
          maxCounter = counter;
        }
        if (counter < minCounter) {
          minCounter = counter;
        }
      }
      return maxCounter < 10 * minCounter;
    }
    return false;
  }
}
