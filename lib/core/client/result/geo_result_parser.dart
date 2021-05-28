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

import '../../result.dart';
import 'geo_parsed_result.dart';
import 'result_parser.dart';

/**
 * Parses a "geo:" URI result, which specifies a location on the surface of
 * the Earth as well as an optional altitude above the surface. See
 * <a href="http://tools.ietf.org/html/draft-mayrhofer-geo-uri-00">
 * http://tools.ietf.org/html/draft-mayrhofer-geo-uri-00</a>.
 *
 * @author Sean Owen
 */
class GeoResultParser extends ResultParser {
  static final RegExp GEO_URL_PATTERN = RegExp(
      "geo:([\\-0-9.]+),([\\-0-9.]+)(?:,([\\-0-9.]+))?(?:\\?(.*))?",
      caseSensitive: false);

  @override
  GeoParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    RegExpMatch? matcher = GEO_URL_PATTERN.firstMatch(rawText);
    if (matcher == null) {
      return null;
    }

    String query = matcher.group(4)!;

    double latitude;
    double longitude;
    double altitude;
    try {
      latitude = double.parse(matcher.group(1)!);
      if (latitude > 90.0 || latitude < -90.0) {
        return null;
      }
      longitude = double.parse(matcher.group(2)!);
      if (longitude > 180.0 || longitude < -180.0) {
        return null;
      }
      if (matcher.group(3) == null) {
        altitude = 0.0;
      } else {
        altitude = double.parse(matcher.group(3)!);
        if (altitude < 0.0) {
          return null;
        }
      }
    } catch (ignored) {
      //on NumberFormatException
      return null;
    }
    return GeoParsedResult(latitude, longitude, altitude, query);
  }
}
