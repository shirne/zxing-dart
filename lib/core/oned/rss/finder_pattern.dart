/*
 * Copyright 2009 ZXing authors
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

import '../../result_point.dart';

/**
 * Encapsulates an RSS barcode finder pattern, including its start/end position and row.
 */
class FinderPattern {
  final int value;
  final List<int> startEnd;
  final List<ResultPoint> resultPoints;

  FinderPattern(this.value, this.startEnd, int start, int end, int rowNumber)
      : resultPoints = [
          ResultPoint(start.toDouble(), rowNumber.toDouble()),
          ResultPoint(end.toDouble(), rowNumber.toDouble())
        ];

  int getValue() {
    return value;
  }

  List<int> getStartEnd() {
    return startEnd;
  }

  List<ResultPoint> getResultPoints() {
    return resultPoints;
  }

  @override
  operator ==(Object o) {
    if (!(o is FinderPattern)) {
      return false;
    }
    FinderPattern that = o;
    return value == that.value;
  }

  @override
  int get hashCode {
    return value;
  }
}
