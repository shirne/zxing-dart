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

import 'package:zxing/core/client/result/parsed_result_type.dart';

import 'parsed_result.dart';

/**
 * Represents a parsed result that encodes a Vehicle Identification Number (VIN).
 */
class VINParsedResult extends ParsedResult {
  final String vin;
  final String worldManufacturerID;
  final String vehicleDescriptorSection;
  final String vehicleIdentifierSection;
  final String? countryCode;
  final String vehicleAttributes;
  final int modelYear;
  final int plantCode;
  final String sequentialNumber;

  VINParsedResult(
      this.vin,
      this.worldManufacturerID,
      this.vehicleDescriptorSection,
      this.vehicleIdentifierSection,
      this.countryCode,
      this.vehicleAttributes,
      this.modelYear,
      this.plantCode,
      this.sequentialNumber):super(ParsedResultType.VIN);

  String getVIN() {
    return vin;
  }

  String getWorldManufacturerID() {
    return worldManufacturerID;
  }

  String getVehicleDescriptorSection() {
    return vehicleDescriptorSection;
  }

  String getVehicleIdentifierSection() {
    return vehicleIdentifierSection;
  }

  String? getCountryCode() {
    return countryCode;
  }

  String getVehicleAttributes() {
    return vehicleAttributes;
  }

  int getModelYear() {
    return modelYear;
  }

  int getPlantCode() {
    return plantCode;
  }

  String getSequentialNumber() {
    return sequentialNumber;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = StringBuffer();
    result.write(worldManufacturerID); result.write(' ');
    result.write(vehicleDescriptorSection); result.write(' ');
    result.write(vehicleIdentifierSection); result.write('\n');
    if (countryCode != null) {
      result.write(countryCode); result.write(' ');
    }
    result.writeCharCode(modelYear); result.write(' ');
    result.writeCharCode(plantCode); result.write(' ');
    result.write(sequentialNumber); result.write('\n');
    return result.toString();
  }
}
