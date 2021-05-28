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
  final double latitude;
  final double longitude;
  final double altitude;
  final String query;

  GeoParsedResult(this.latitude, this.longitude, this.altitude, this.query)
      : super(ParsedResultType.GEO);

  String getGeoURI() {
    StringBuffer result = new StringBuffer();
    result.write("geo:");
    result.write(latitude);
    result.write(',');
    result.write(longitude);
    if (altitude > 0) {
      result.write(',');
      result.write(altitude);
    }
    if (query != null) {
      result.write('?');
      result.write(query);
    }
    return result.toString();
  }

  /**
   * @return latitude in degrees
   */
  double getLatitude() {
    return latitude;
  }

  /**
   * @return longitude in degrees
   */
  double getLongitude() {
    return longitude;
  }

  /**
   * @return altitude in meters. If not specified, in the geo URI, returns 0.0
   */
  double getAltitude() {
    return altitude;
  }

  /**
   * @return query string associated with geo URI or null if none exists
   */
  String getQuery() {
    return query;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = new StringBuffer(20);
    result.write(latitude);
    result.write(", ");
    result.write(longitude);
    if (altitude > 0.0) {
      result.write(", ");
      result.write(altitude);
      result.write('m');
    }
    if (query != null) {
      result.write(" (");
      result.write(query);
      result.write(')');
    }
    return result.toString();
  }
}
