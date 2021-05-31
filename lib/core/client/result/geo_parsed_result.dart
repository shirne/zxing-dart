/*
 * Copyright 2008 ZXing authors
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

import 'parsed_result.dart';
import 'parsed_result_type.dart';

/**
 * Represents a parsed result that encodes a geographic coordinate, with latitude,
 * longitude and altitude.
 *
 * @author Sean Owen
 */
class GeoParsedResult extends ParsedResult {
  final double _latitude;
  final double _longitude;
  final double _altitude;
  final String? _query;

  GeoParsedResult(this._latitude, this._longitude, this._altitude, this._query)
      : super(ParsedResultType.GEO);

  String getGeoURI() {
    StringBuffer result = StringBuffer();
    result.write("geo:");
    result.write(_latitude);
    result.write(',');
    result.write(_longitude);
    if (_altitude > 0) {
      result.write(',');
      result.write(_altitude);
    }
    if (_query != null) {
      result.write('?');
      result.write(_query);
    }
    return result.toString();
  }

  /**
   * @return latitude in degrees
   */
  double getLatitude() {
    return _latitude;
  }

  /**
   * @return longitude in degrees
   */
  double getLongitude() {
    return _longitude;
  }

  /**
   * @return altitude in meters. If not specified, in the geo URI, returns 0.0
   */
  double getAltitude() {
    return _altitude;
  }

  /**
   * @return query string associated with geo URI or null if none exists
   */
  String? getQuery() {
    return _query;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = StringBuffer();
    result.write(_latitude);
    result.write(", ");
    result.write(_longitude);
    if (_altitude > 0.0) {
      result.write(", ");
      result.write(_altitude);
      result.write('m');
    }
    if (_query != null) {
      result.write(" (");
      result.write(_query);
      result.write(')');
    }
    return result.toString();
  }
}
