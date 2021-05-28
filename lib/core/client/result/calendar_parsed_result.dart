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



import 'package:intl/intl.dart';
import 'package:zxing/core/client/result/parsed_result.dart';
import 'package:zxing/core/client/result/parsed_result_type.dart';

/**
 * Represents a parsed result that encodes a calendar event at a certain time, optionally
 * with attendees and a location.
 *
 * @author Sean Owen
 */
class CalendarParsedResult extends ParsedResult {

  static final RegExp RFC2445_DURATION =
  RegExp("P(?:(\\d+)W)?(?:(\\d+)D)?(?:T(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?)?");
  static final List<int> RFC2445_DURATION_FIELD_UNITS = [
      7 * 24 * 60 * 60 * 1000, // 1 week
      24 * 60 * 60 * 1000, // 1 day
      60 * 60 * 1000, // 1 hour
      60 * 1000, // 1 minute
      1000, // 1 second
  ];

  static final RegExp DATE_TIME = RegExp("[0-9]{8}(T[0-9]{6}Z?)?");

  final String? summary;
  late int start;
  late bool startAllDay;
  late int end;
  late bool endAllDay;
  final String? location;
  final String? organizer;
  final List<String>? attendees;
  final String? description;
  final double? latitude;
  final double? longitude;

  CalendarParsedResult(this.summary,
                              String? startString,
                              String? endString,
                              String? durationString,
                              this.location,
                              this.organizer,
                              this.attendees,
      this.description,
      this.latitude,
      this.longitude) :super(ParsedResultType.CALENDAR){

    try {
      this.start = parseDate(startString);
    } catch ( pe) { // ParseException
      throw Exception(pe.toString());
    }

    if (endString == null) {
      int durationMS = parseDurationMS(durationString);
      end = durationMS < 0 ? -1 : start + durationMS;
    } else {
      try {
        this.end = parseDate(endString);
      } catch ( pe) { // ParseException
        throw Exception(pe.toString());
      }
    }

    this.startAllDay = startString != null && startString.length == 8;
    this.endAllDay = endString != null && endString.length == 8;

  }

  String? getSummary() {
    return summary;
  }

  /**
   * @return start time
   * @deprecated use {@link #getStartTimestamp()}
   */
  @deprecated
  DateTime getStart() {
    return DateTime.fromMillisecondsSinceEpoch(start);
  }

  /**
   * @return start time
   * @see #getEndTimestamp()
   */
  int getStartTimestamp() {
    return start;
  }

  /**
   * @return true if start time was specified as a whole day
   */
  bool isStartAllDay() {
    return startAllDay;
  }

  /**
   * @return event end {@link Date}, or {@code null} if event has no duration
   * @deprecated use {@link #getEndTimestamp()}
   */
  @deprecated
  DateTime? getEnd() {
    return end < 0 ? null : DateTime.fromMillisecondsSinceEpoch(end);
  }

  /**
   * @return event end {@link Date}, or -1 if event has no duration
   * @see #getStartTimestamp()
   */
  int getEndTimestamp() {
    return end;
  }

  /**
   * @return true if end time was specified as a whole day
   */
  bool isEndAllDay() {
    return endAllDay;
  }

  String? getLocation() {
    return location;
  }

  String? getOrganizer() {
    return organizer;
  }

  List<String>? getAttendees() {
    return attendees;
  }

  String? getDescription() {
    return description;
  }

  double? getLatitude() {
    return latitude;
  }

  double? getLongitude() {
    return longitude;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppend(summary, result);
    ParsedResult.maybeAppend(format(startAllDay, start), result);
    ParsedResult.maybeAppend(format(endAllDay, end), result);
    ParsedResult.maybeAppend(location, result);
    ParsedResult.maybeAppend(organizer, result);
    ParsedResult.maybeAppendList(attendees, result);
    ParsedResult.maybeAppend(description, result);
    return result.toString();
  }

  /**
   * Parses a string as a date. RFC 2445 allows the start and end fields to be of type DATE (e.g. 20081021)
   * or DATE-TIME (e.g. 20081021T123000 for local time, or 20081021T123000Z for UTC).
   *
   * @param when The string to parse
   * @throws ParseException if not able to parse as a date
   */
  static int parseDate(String? when){
    if (when == null || !DATE_TIME.hasMatch(when)) {
      throw Exception('Date Parse error $when');
    }
    DateTime date = DateTime.parse(when);

    return date.millisecondsSinceEpoch;
  }

  static String? format(bool allDay, int timestamp) {
    if (timestamp < 0) {
      return null;
    }
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    // DateFormat.MEDIUM Jan 17, 2015, 7:16:02 PM
    DateFormat format = DateFormat.yMMMEd();
    if(!allDay) format.add_jms() ;
    return format.format(date);
  }

  static int parseDurationMS(String? durationString) {
    if (durationString == null) {
      return -1;
    }
    var m = RFC2445_DURATION.firstMatch(durationString);
    if (m == null) {
      return -1;
    }
    int durationMS = 0;
    for (int i = 0; i < RFC2445_DURATION_FIELD_UNITS.length; i++) {
      String? fieldValue = m.group(i + 1);
      if (fieldValue != null) {
        durationMS += RFC2445_DURATION_FIELD_UNITS[i] * int.parse(fieldValue);
      }
    }
    return durationMS;
  }

  static int parseDateTimeString(String dateTimeString){
    DateTime date = DateTime.parse(dateTimeString);
    return date.millisecondsSinceEpoch;
  }

}
