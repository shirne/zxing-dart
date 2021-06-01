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

  String getVIN() {
    return _vin;
  }

  String getWorldManufacturerID() {
    return _worldManufacturerID;
  }

  String getVehicleDescriptorSection() {
    return _vehicleDescriptorSection;
  }

  String getVehicleIdentifierSection() {
    return _vehicleIdentifierSection;
  }

  String? getCountryCode() {
    return _countryCode;
  }

  String getVehicleAttributes() {
    return _vehicleAttributes;
  }

  int getModelYear() {
    return _modelYear;
  }

  int getPlantCode() {
    return _plantCode;
  }

  String getSequentialNumber() {
    return _sequentialNumber;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = StringBuffer();
    result.write(_worldManufacturerID); result.write(' ');
    result.write(_vehicleDescriptorSection); result.write(' ');
    result.write(_vehicleIdentifierSection); result.write('\n');
    if (_countryCode != null) {
      result.write(_countryCode); result.write(' ');
    }
    result.writeCharCode(_modelYear); result.write(' ');
    result.writeCharCode(_plantCode); result.write(' ');
    result.write(_sequentialNumber); result.write('\n');
    return result.toString();
  }
}
