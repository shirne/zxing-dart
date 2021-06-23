/*
 * Copyright 2013 ZXing authors
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



/// @author Guenther Grau
class BarcodeValue {
  final Map<int, int> _values = {};

  /// Add an occurrence of a value
  void setValue(int value) {
    int confidence = _values[value] ?? 0;
    _values[value] = ++confidence;
  }

  /// Determines the maximum occurrence of a set value and returns all values which were set with this occurrence.
  /// @return an array of int, containing the values with the highest occurrence, or null, if no value was set
  List<int> getValue() {
    int maxConfidence = -1;
    List<int> result = [];
    for (MapEntry<int, int> entry in _values.entries) {
      if (entry.value > maxConfidence) {
        maxConfidence = entry.value;
        result.clear();
        result.add(entry.key);
      } else if (entry.value == maxConfidence) {
        result.add(entry.key);
      }
    }
    return result;
  }

  int getConfidence(int value) {
    return _values[value] ?? 0;
  }
}
