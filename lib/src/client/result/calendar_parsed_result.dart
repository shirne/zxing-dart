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

import 'parsed_result.dart';
import 'parsed_result_type.dart';

/// Represents a parsed result that encodes a calendar event at a certain time, optionally
/// with attendees and a location.
///
/// @author Sean Owen
class CalendarParsedResult extends ParsedResult {

  static final RegExp _rfc2445Duration =
  RegExp(r"^P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$");
  static final List<int> _rfc2445DurationFieldUnits = [
      7 * 24 * 60 * 60 * 1000, // 1 week
      24 * 60 * 60 * 1000, // 1 day
      60 * 60 * 1000, // 1 hour
      60 * 1000, // 1 minute
      1000, // 1 second
  ];

  static final RegExp _dateTime = RegExp(r"^[0-9]{8}(T[0-9]{6}Z?)?$");

  final String? _summary;
  late int _start;
  late bool _startAllDay;
  late int _end;
  late bool _endAllDay;
  final String? _location;
  final String? _organizer;
  final List<String>? _attendees;
  final String? _description;
  final double? _latitude;
  final double? _longitude;

  CalendarParsedResult(this._summary,
                              String? startString,
                              String? endString,
                              String? durationString,
                              this._location,
                              this._organizer,
                              this._attendees,
      this._description,
      this._latitude,
      this._longitude) :super(ParsedResultType.CALENDAR){

    try {
      this._start = _parseDate(startString);
    } catch ( pe) { // ParseException
      throw Exception(pe.toString());
    }

    if (endString == null) {
      int durationMS = _parseDurationMS(durationString);
      _end = durationMS < 0 ? -1 : _start + durationMS;
    } else {
      try {
        this._end = _parseDate(endString);
      } catch ( pe) { // ParseException
        throw Exception(pe.toString());
      }
    }

    this._startAllDay = startString != null && startString.length == 8;
    this._endAllDay = endString != null && endString.length == 8;

  }

  String? getSummary() {
    return _summary;
  }

  /// @return start time
  /// @deprecated use {@link #getStartTimestamp()}
  @deprecated
  DateTime getStart() {
    return DateTime.fromMillisecondsSinceEpoch(_start);
  }

  /// @return start time
  /// @see #getEndTimestamp()
  int getStartTimestamp() {
    return _start;
  }

  /// @return true if start time was specified as a whole day
  bool isStartAllDay() {
    return _startAllDay;
  }

  /// @return event end {@link Date}, or {@code null} if event has no duration
  /// @deprecated use {@link #getEndTimestamp()}
  @deprecated
  DateTime? getEnd() {
    return _end < 0 ? null : DateTime.fromMillisecondsSinceEpoch(_end);
  }

  /// @return event end {@link Date}, or -1 if event has no duration
  /// @see #getStartTimestamp()
  int getEndTimestamp() {
    return _end;
  }

  /// @return true if end time was specified as a whole day
  bool isEndAllDay() {
    return _endAllDay;
  }

  String? getLocation() {
    return _location;
  }

  String? getOrganizer() {
    return _organizer;
  }

  List<String>? getAttendees() {
    return _attendees;
  }

  String? getDescription() {
    return _description;
  }

  double? getLatitude() {
    return _latitude;
  }

  double? getLongitude() {
    return _longitude;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppend(_summary, result);
    ParsedResult.maybeAppend(_format(_startAllDay, _start), result);
    ParsedResult.maybeAppend(_format(_endAllDay, _end), result);
    ParsedResult.maybeAppend(_location, result);
    ParsedResult.maybeAppend(_organizer, result);
    ParsedResult.maybeAppendList(_attendees, result);
    ParsedResult.maybeAppend(_description, result);
    return result.toString();
  }

  /// Parses a string as a date. RFC 2445 allows the start and end fields to be of type DATE (e.g. 20081021)
  /// or DATE-TIME (e.g. 20081021T123000 for local time, or 20081021T123000Z for UTC).
  ///
  /// @param when The string to parse
  /// @throws ParseException if not able to parse as a date
  static int _parseDate(String? when){
    if (when == null || !_dateTime.hasMatch(when)) {
      throw Exception('Date Parse error $when');
    }
    DateTime date = DateTime.parse(when);

    return date.millisecondsSinceEpoch;
  }

  static String? _format(bool allDay, int timestamp) {
    if (timestamp < 0) {
      return null;
    }
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    // DateFormat.MEDIUM Jan 17, 2015, 7:16:02 PM
    DateFormat format = DateFormat.yMMMEd();
    if(!allDay) format.add_jms() ;
    return format.format(date);
  }

  static int _parseDurationMS(String? durationString) {
    if (durationString == null) {
      return -1;
    }
    var m = _rfc2445Duration.firstMatch(durationString);
    if (m == null) {
      return -1;
    }
    int durationMS = 0;
    for (int i = 0; i < _rfc2445DurationFieldUnits.length; i++) {
      String? fieldValue = m.group(i + 1);
      if (fieldValue != null) {
        durationMS += _rfc2445DurationFieldUnits[i] * int.parse(fieldValue);
      }
    }
    return durationMS;
  }

}
