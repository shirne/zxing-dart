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
import 'calendar_parsed_result.dart';
import 'result_parser.dart';
import 'vcard_result_parser.dart';

/// Partially implements the iCalendar format's "VEVENT" format for specifying a
/// calendar event. See RFC 2445. This supports SUMMARY, LOCATION, GEO, DTSTART and DTEND fields.
///
/// @author Sean Owen
class VEventResultParser extends ResultParser {
  @override
  CalendarParsedResult? parse(Result result) {
    final rawText = ResultParser.getMassagedText(result);
    final vEventStart = rawText.indexOf('BEGIN:VEVENT');
    if (vEventStart < 0) {
      return null;
    }

    final summary = _matchSingleVCardPrefixedField('SUMMARY', rawText);
    final start = _matchSingleVCardPrefixedField('DTSTART', rawText);
    if (start == null) {
      return null;
    }
    final end = _matchSingleVCardPrefixedField('DTEND', rawText);
    final duration = _matchSingleVCardPrefixedField('DURATION', rawText);
    final location = _matchSingleVCardPrefixedField('LOCATION', rawText);
    final organizer =
        _stripMailto(_matchSingleVCardPrefixedField('ORGANIZER', rawText));

    final attendees = _matchVCardPrefixedField('ATTENDEE', rawText);
    if (attendees != null) {
      for (int i = 0; i < attendees.length; i++) {
        attendees[i] = _stripMailto(attendees[i])!;
      }
    }
    final description = _matchSingleVCardPrefixedField('DESCRIPTION', rawText);

    final geoString = _matchSingleVCardPrefixedField('GEO', rawText);
    double latitude;
    double longitude;
    if (geoString == null) {
      latitude = double.nan;
      longitude = double.nan;
    } else {
      final semicolon = geoString.indexOf(';');
      if (semicolon < 0) {
        return null;
      }
      try {
        latitude = double.parse(geoString.substring(0, semicolon));
        longitude = double.parse(geoString.substring(semicolon + 1));
      } catch (_) {
        // NumberFormatException
        return null;
      }
    }

    try {
      return CalendarParsedResult(summary, start, end, duration, location,
          organizer, attendees, description, latitude, longitude);
    } catch (_) {
      // IllegalArgumentException
      return null;
    }
  }

  static String? _matchSingleVCardPrefixedField(String prefix, String rawText) {
    final values = VCardResultParser.matchSingleVCardPrefixedField(
        prefix, rawText, true, false);
    return values == null || values.isEmpty ? null : values[0];
  }

  static List<String>? _matchVCardPrefixedField(String prefix, String rawText) {
    final values =
        VCardResultParser.matchVCardPrefixedField(prefix, rawText, true, false);
    if (values == null || values.isEmpty) {
      return null;
    }
    final size = values.length;
    final result = List.generate(size, (index) => values[index][0]);

    return result;
  }

  static String? _stripMailto(String? s) {
    if (s != null && (s.startsWith('mailto:') || s.startsWith('MAILTO:'))) {
      s = s.substring(7);
    }
    return s;
  }
}
