/*
 * Copyright 2014 ZXing authors
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

import 'parsed_result_type.dart';
import 'parsed_result.dart';

/// Represents a parsed result that encodes a Vehicle Identification Number (VIN).
class VINParsedResult extends ParsedResult {
  final String _vin;
  final String _worldManufacturerID;
  final String _vehicleDescriptorSection;
  final String _vehicleIdentifierSection;
  final String? _countryCode;
  final String _vehicleAttributes;
  final int _modelYear;
  final int _plantCode;
  final String _sequentialNumber;

  VINParsedResult(
      this._vin,
      this._worldManufacturerID,
      this._vehicleDescriptorSection,
      this._vehicleIdentifierSection,
      this._countryCode,
      this._vehicleAttributes,
      this._modelYear,
      this._plantCode,
      this._sequentialNumber):super(ParsedResultType.VIN);

  String get vin => _vin;

  String get worldManufacturerID => _worldManufacturerID;

  String get vehicleDescriptorSection => _vehicleDescriptorSection;

  String get vehicleIdentifierSection => _vehicleIdentifierSection;

  String? get countryCode => _countryCode;

  String get vehicleAttributes => _vehicleAttributes;

  int get modelYear => _modelYear;

  int get plantCode => _plantCode;

  String get sequentialNumber => _sequentialNumber;

  @override
  String get displayResult {
    StringBuffer result = StringBuffer();
    result.write(_worldManufacturerID); result.write(' ');
    result.write(_vehicleDescriptorSection); result.write(' ');
    result.write(_vehicleIdentifierSection); result.write('\n');
    if (_countryCode != null) {
      result.write(_countryCode); result.write(' ');
    }
    result.write(_modelYear); result.write(' ');
    result.writeCharCode(_plantCode); result.write(' ');
    result.write(_sequentialNumber); result.write('\n');
    return result.toString();
  }
}
