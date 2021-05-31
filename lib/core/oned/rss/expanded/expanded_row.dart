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
  final List<ExpandedPair> _pairs;
  final int _rowNumber;
  /** Did this row of the image have to be reversed (mirrored) to recognize the pairs? */
  final bool _wasReversed;

  ExpandedRow(this._pairs, this._rowNumber, this._wasReversed);

  List<ExpandedPair> getPairs() {
    return this._pairs;
  }

  int getRowNumber() {
    return this._rowNumber;
  }

  bool isEquivalent(List<ExpandedPair> otherPairs) {
    return this._pairs == otherPairs;
  }

  @override
  String toString() {
    return "{ $_pairs }";
  }

  /**
   * Two rows are equal if they contain the same pairs in the same order.
   */
  @override
  operator ==(Object o) {
    if (!(o is ExpandedRow)) {
      return false;
    }
    ExpandedRow that = o;
    return this._pairs == that._pairs && _wasReversed == that._wasReversed;
  }

  @override
  int get hashCode {
    return _pairs.hashCode ^ _wasReversed.hashCode;
  }
}
