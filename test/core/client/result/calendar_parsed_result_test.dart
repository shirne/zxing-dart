/*
 * Copyright 2007 ZXing authors
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




import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/zxing.dart';

import '../../utils.dart';

/// Tests [CalendarParsedResult].
///
void main(){

  dateEqual(String? date, int? timestamp){
    if(date != null && timestamp != null) {
      DateTime date1 = DateTime.parse(date).toLocal();
      expect(date1.millisecondsSinceEpoch, timestamp, reason: "日期解析错误 $date");
    }else{
      assert(date == null && timestamp == null);
    }
  }

  //@Before
  //void setUp() {
  //  Locale.setDefault(Locale.ENGLISH);
  //  TimeZone.setDefault(TimeZone.getTimeZone("GMT"));
  //}



  void doTest(String contents,
      String? description,
      String? summary,
      String? location,
      String startString,
      String? endString,
      [String? organizer,
        List<String>? attendees,
        double latitude = double.nan,
        double longitude = double.nan]) {
    Result fakeResult = new Result(contents, null, null, BarcodeFormat.QR_CODE);
    ParsedResult result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.CALENDAR, result.type);
    CalendarParsedResult calResult = result as CalendarParsedResult;
    expect(calResult.description, description);
    expect(calResult.summary, summary);
    expect(calResult.location, location);
    dateEqual(startString, calResult.startTimestamp);
    dateEqual(endString, calResult.endTimestamp < 0 ? null : calResult.endTimestamp);
    expect(calResult.organizer, organizer);
    assertArrayEquals(attendees, calResult.attendees);
    assertEqualOrNaN(latitude, calResult.latitude!);
    assertEqualOrNaN(longitude, calResult.longitude!);
  }

  test('testStartEnd', () {
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "DTEND:20080505T234555Z\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        null, null, null, "20080504T123456Z", "20080505T234555Z");
  });

  test('testNoVCalendar', () {
    doTest(
        "BEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "DTEND:20080505T234555Z\r\n" +
        "END:VEVENT",
        null, null, null, "20080504T123456Z", "20080505T234555Z");
  });

  test('testStart', () {
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        null, null, null, "20080504T123456Z", null);
  });

  test('testDuration', () {
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "DURATION:P1D\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        null, null, null, "20080504T123456Z", "20080505T123456Z");
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "DURATION:P1DT2H3M4S\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        null, null, null, "20080504T123456Z", "20080505T143800Z");
  });

  test('testSummary', () {
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "SUMMARY:foo\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        null, "foo", null, "20080504T123456Z", null);
  });

  test('testLocation', () {
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "LOCATION:Miami\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        null, null, "Miami", "20080504T123456Z", null);
  });

  test('testDescription', () {
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "DESCRIPTION:This is a test\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        "This is a test", null, null, "20080504T123456Z", null);
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "DESCRIPTION:This is a test\r\n\t with a continuation\r\n" +        
        "END:VEVENT\r\nEND:VCALENDAR",
        "This is a test with a continuation", null, null, "20080504T123456Z", null);
  });

  test('testGeo', () {
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "GEO:-12.345;-45.678\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        null, null, null, "20080504T123456Z", null, null, null, -12.345, -45.678);
  });

  test('testBadGeo', () {
    // Not parsed as VEVENT
    Result fakeResult = new Result("BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "GEO:-12.345\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR", null, null, BarcodeFormat.QR_CODE);
    ParsedResult result = ResultParser.parseResult(fakeResult);
    expect(result.type, ParsedResultType.TEXT);
  });

  test('testOrganizer', () {
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "ORGANIZER:mailto:bob@example.org\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        null, null, null, "20080504T123456Z", null, "bob@example.org", null, double.nan, double.nan);
  });

  test('testAttendees', () {
    doTest(
        "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n" +
        "DTSTART:20080504T123456Z\r\n" +
        "ATTENDEE:mailto:bob@example.org\r\n" +
        "ATTENDEE:mailto:alice@example.org\r\n" +
        "END:VEVENT\r\nEND:VCALENDAR",
        null, null, null, "20080504T123456Z", null, null,
        ["bob@example.org", "alice@example.org"], double.nan, double.nan);
  });

  test('testVEventEscapes', () {
    doTest("BEGIN:VEVENT\n" +
           "CREATED:20111109T110351Z\n" +
           "LAST-MODIFIED:20111109T170034Z\n" +
           "DTSTAMP:20111109T170034Z\n" +
           "UID:0f6d14ef-6cb7-4484-9080-61447ccdf9c2\n" +
           "SUMMARY:Summary line\n" +
           "CATEGORIES:Private\n" +
           "DTSTART;TZID=Europe/Vienna:20111110T110000\n" +
           "DTEND;TZID=Europe/Vienna:20111110T120000\n" +
           "LOCATION:Location\\, with\\, escaped\\, commas\n" +
           "DESCRIPTION:Meeting with a friend\\nlook at homepage first\\n\\n\n" +
           "  \\n\n" +
           "SEQUENCE:1\n" +
           "X-MOZ-GENERATION:1\n" +
           "END:VEVENT",
           "Meeting with a friend\nlook at homepage first\n\n\n  \n",
           "Summary line",
           "Location, with, escaped, commas",
           "20111110T110000",
           "20111110T120000");
  });

  test('testAllDayValueDate', () {
    doTest("BEGIN:VEVENT\n" +
           "DTSTART;VALUE=DATE:20111110\n" +
           "DTEND;VALUE=DATE:20111110\n" +
           "END:VEVENT",
           null, null, null, "20111110T000000", "20111110T000000");
  });




}