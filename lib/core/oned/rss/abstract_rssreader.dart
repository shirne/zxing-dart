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

import 'package:flutter/cupertino.dart';

import '../../common/detector/math_utils.dart';

import '../../not_found_exception.dart';
import '../one_dreader.dart';

/// Superclass of {@link OneDReader} implementations that read barcodes in the RSS family
/// of formats.
abstract class AbstractRSSReader extends OneDReader {
  static const double _MAX_AVG_VARIANCE = 0.2;
  static const double _MAX_INDIVIDUAL_VARIANCE = 0.45;

  static const double _MIN_FINDER_PATTERN_RATIO = 9.5 / 12.0;
  static const double _MAX_FINDER_PATTERN_RATIO = 12.5 / 14.0;

  final List<int> _decodeFinderCounters;
  final List<int> _dataCharacterCounters;
  final List<double> _oddRoundingErrors;
  final List<double> _evenRoundingErrors;
  final List<int> _oddCounts;
  final List<int> _evenCounts;

  @protected
  AbstractRSSReader()
      : _decodeFinderCounters = List.generate(4, (index) => 0),
        _dataCharacterCounters = List.generate(8, (index) => 0),
        _oddRoundingErrors = List.generate(4, (index) => 0),
        _evenRoundingErrors = List.generate(4, (index) => 0),
        _oddCounts = List.generate(4, (index) => 0),
        _evenCounts = List.generate(4, (index) => 0);

  @protected
  List<int> getDecodeFinderCounters() {
    return _decodeFinderCounters;
  }

  @protected
  List<int> getDataCharacterCounters() {
    return _dataCharacterCounters;
  }

  @protected
  List<double> getOddRoundingErrors() {
    return _oddRoundingErrors;
  }

  @protected
  List<double> getEvenRoundingErrors() {
    return _evenRoundingErrors;
  }

  @protected
  List<int> getOddCounts() {
    return _oddCounts;
  }

  @protected
  List<int> getEvenCounts() {
    return _evenCounts;
  }

  @protected
  static int parseFinderValue(
      List<int> counters, List<List<int>> finderPatterns) {
    for (int value = 0; value < finderPatterns.length; value++) {
      if (OneDReader.patternMatchVariance(
              counters, finderPatterns[value], _MAX_INDIVIDUAL_VARIANCE) <
          _MAX_AVG_VARIANCE) {
        return value;
      }
    }
    throw NotFoundException.getNotFoundInstance();
  }

  /// @param array values to sum
  /// @return sum of values
  /// @deprecated call {@link MathUtils#sum(List<int>)}
  @deprecated
  @protected
  static int count(List<int> array) {
    return MathUtils.sum(array);
  }

  @protected
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

  @protected
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

  @protected
  static bool isFinderPattern(List<int> counters) {
    int firstTwoSum = counters[0] + counters[1];
    int sum = firstTwoSum + counters[2] + counters[3];
    double ratio = firstTwoSum / sum;
    if (ratio >= _MIN_FINDER_PATTERN_RATIO &&
        ratio <= _MAX_FINDER_PATTERN_RATIO) {
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
