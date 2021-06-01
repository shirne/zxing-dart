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

/// Encapsulates a since character value in an RSS barcode, including its checksum information.
class DataCharacter {
  final int _value;
  final int _checksumPortion;

  DataCharacter(this._value, this._checksumPortion);

  int getValue() {
    return _value;
  }

  int getChecksumPortion() {
    return _checksumPortion;
  }

  @override
  String toString() {
    return "$_value($_checksumPortion)";
  }

  @override
  operator ==(Object o) {
    if (!(o is DataCharacter)) {
      return false;
    }
    DataCharacter that = o;
    return _value == that._value && _checksumPortion == that._checksumPortion;
  }

  @override
  int get hashCode {
    return _value ^ _checksumPortion;
  }
}
