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

import 'expanded_pair.dart';

/**
 * One row of an RSS Expanded Stacked symbol, consisting of 1+ expanded pairs.
 */
class ExpandedRow {
  final List<ExpandedPair> pairs;
  final int rowNumber;
  /** Did this row of the image have to be reversed (mirrored) to recognize the pairs? */
  final bool wasReversed;

  ExpandedRow(this.pairs, this.rowNumber, this.wasReversed);

  List<ExpandedPair> getPairs() {
    return this.pairs;
  }

  int getRowNumber() {
    return this.rowNumber;
  }

  bool isEquivalent(List<ExpandedPair> otherPairs) {
    return this.pairs == otherPairs;
  }

  @override
  String toString() {
    return "{ $pairs }";
  }

  /**
   * Two rows are equal if they contain the same pairs in the same order.
   */
  @override
  bool equals(Object o) {
    if (!(o is ExpandedRow)) {
      return false;
    }
    ExpandedRow that = o;
    return this.pairs == that.pairs && wasReversed == that.wasReversed;
  }

  @override
  int get hashCode {
    return pairs.hashCode ^ wasReversed.hashCode;
  }
}
