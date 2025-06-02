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

import '../../common/detector/math_utils.dart';
import '../../not_found_exception.dart';
import '../one_dreader.dart';

/// Superclass of [OneDReader] implementations that read barcodes in the RSS family
/// of formats.
abstract class AbstractRSSReader extends OneDReader {
  static const double _maxAvgVariance = 0.2;
  static const double _maxIndividualVariance = 0.45;

  /// Minimum ratio 10:12 (minus 0.5 for variance), from section 7.2.7 of ISO/IEC 24724:2006.
  static const double _minFinderPatternRatio = 9.5 / 12.0;

  /// Maximum ratio 12:14 (plus 0.5 for variance), from section 7.2.7 of ISO/IEC 24724:2006.
  static const double _maxFinderPatternRatio = 12.5 / 14.0;

  final List<int> _decodeFinderCounters;
  final List<int> _dataCharacterCounters;
  final List<double> _oddRoundingErrors;
  final List<double> _evenRoundingErrors;
  final List<int> _oddCounts;
  final List<int> _evenCounts;

  // @protected
  AbstractRSSReader()
      : _decodeFinderCounters = List.filled(4, 0),
        _dataCharacterCounters = List.filled(8, 0),
        _oddRoundingErrors = List.filled(4, 0),
        _evenRoundingErrors = List.filled(4, 0),
        _oddCounts = List.filled(4, 0),
        _evenCounts = List.filled(4, 0);

  // @protected
  List<int> get decodeFinderCounters => _decodeFinderCounters;

  // @protected
  List<int> get dataCharacterCounters => _dataCharacterCounters;

  // @protected
  List<double> get oddRoundingErrors => _oddRoundingErrors;

  // @protected
  List<double> get evenRoundingErrors => _evenRoundingErrors;

  // @protected
  List<int> get oddCounts => _oddCounts;

  // @protected
  List<int> get evenCounts => _evenCounts;

  // @protected
  static int parseFinderValue(
    List<int> counters,
    List<List<int>> finderPatterns,
  ) {
    for (int value = 0; value < finderPatterns.length; value++) {
      if (OneDReader.patternMatchVariance(
            counters,
            finderPatterns[value],
            _maxIndividualVariance,
          ) <
          _maxAvgVariance) {
        return value;
      }
    }
    throw NotFoundException.instance;
  }

  /// @param array values to sum
  /// @return sum of values
  /// @deprecated call [MathUtils.sum(List<int>)]
  // @protected
  @Deprecated('call [MathUtils::sum]')
  static int count(List<int> array) {
    return MathUtils.sum(array);
  }

  // @protected
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

  // @protected
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

  // @protected
  static bool isFinderPattern(List<int> counters) {
    final firstTwoSum = counters[0] + counters[1];
    final sum = firstTwoSum + counters[2] + counters[3];
    final ratio = firstTwoSum / sum;
    if (ratio >= _minFinderPatternRatio && ratio <= _maxFinderPatternRatio) {
      // passes ratio test in spec, but see if the counts are unreasonable
      int minCounter = MathUtils.maxValue;
      int maxCounter = MathUtils.minValue;
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
