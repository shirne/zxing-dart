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

/**
 * Partially implements the iCalendar format's "VEVENT" format for specifying a
 * calendar event. See RFC 2445. This supports SUMMARY, LOCATION, GEO, DTSTART and DTEND fields.
 *
 * @author Sean Owen
 */
class VEventResultParser extends ResultParser {

  @override
  CalendarParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    int vEventStart = rawText.indexOf("BEGIN:VEVENT");
    if (vEventStart < 0) {
      return null;
    }

    String? summary = matchSingleVCardPrefixedField("SUMMARY", rawText);
    String? start = matchSingleVCardPrefixedField("DTSTART", rawText);
    if (start == null) {
      return null;
    }
    String? end = matchSingleVCardPrefixedField("DTEND", rawText);
    String? duration = matchSingleVCardPrefixedField("DURATION", rawText);
    String? location = matchSingleVCardPrefixedField("LOCATION", rawText);
    String? organizer = stripMailto(matchSingleVCardPrefixedField("ORGANIZER", rawText));

    List<String>? attendees = matchVCardPrefixedField("ATTENDEE", rawText);
    if (attendees != null) {
      for (int i = 0; i < attendees.length; i++) {
        attendees[i] = stripMailto(attendees[i])!;
      }
    }
    String? description = matchSingleVCardPrefixedField("DESCRIPTION", rawText);

    String? geoString = matchSingleVCardPrefixedField("GEO", rawText);
    double latitude;
    double longitude;
    if (geoString == null) {
      latitude = double.nan;
      longitude = double.nan;
    } else {
      int semicolon = geoString.indexOf(';');
      if (semicolon < 0) {
        return null;
      }
      try {
        latitude = double.parse(geoString.substring(0, semicolon));
        longitude = double.parse(geoString.substring(semicolon + 1));
      } catch ( ignored) { // NumberFormatException
        return null;
      }
    }

    try {
      return CalendarParsedResult(summary,
                                      start,
                                      end,
                                      duration,
                                      location,
                                      organizer,
                                      attendees,
                                      description,
                                      latitude,
                                      longitude);
    } catch ( _) { // IllegalArgumentException
      return null;
    }
  }

  static String? matchSingleVCardPrefixedField(String prefix,
                                                      String rawText) {
    List<String>? values = VCardResultParser.matchSingleVCardPrefixedField(prefix, rawText, true, false);
    return values == null || values.isEmpty ? null : values[0];
  }

  static List<String>? matchVCardPrefixedField(String prefix, String rawText) {
    List<List<String>>? values = VCardResultParser.matchVCardPrefixedField(prefix, rawText, true, false);
    if (values == null || values.isEmpty) {
      return null;
    }
    int size = values.length;
    List<String> result = List.generate(size, (index) => values[index][0]);

    return result;
  }

  static String? stripMailto(String? s) {
    if (s != null && (s.startsWith("mailto:") || s.startsWith("MAILTO:"))) {
      s = s.substring(7);
    }
    return s;
  }

}
