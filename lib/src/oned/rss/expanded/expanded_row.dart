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

import '../../../common/utils.dart';
import 'expanded_pair.dart';

/// One row of an RSS Expanded Stacked symbol, consisting of 1+ expanded pairs.
class ExpandedRow {
  final List<ExpandedPair> _pairs;
  final int _rowNumber;

  ExpandedRow(List<ExpandedPair> pairs, this._rowNumber)
      : _pairs = pairs.toList();

  List<ExpandedPair> get pairs => _pairs;

  int get rowNumber => _rowNumber;

  bool isEquivalent(List<ExpandedPair> otherPairs) {
    return _pairs == otherPairs;
  }

  @override
  String toString() {
    return '{ $_pairs }';
  }

  /// Two rows are equal if they contain the same pairs in the same order.
  @override
  bool operator ==(Object other) {
    if (other is! ExpandedRow) {
      return false;
    }
    return Utils.arrayEquals(_pairs, other._pairs);
  }

  @override
  int get hashCode {
    return _pairs.hashCode;
  }
}
