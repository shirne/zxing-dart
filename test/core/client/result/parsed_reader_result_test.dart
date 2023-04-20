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

import 'package:intl/intl.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/zxing.dart';

/// Tests [ParsedResult].
///
void main() {
  //@Before
  //void setUp() {
  //  Locale.setDefault(Locale.ENGLISH);
  //  TimeZone.setDefault(TimeZone.getTimeZone("GMT"));
  //}

  String formatDate(int year, int month, int day, [bool isLocal = false]) {
    final format = DateFormat.yMMMEd();
    late DateTime date;
    if (isLocal) {
      date = DateTime(year, month, day);
    } else {
      date = DateTime.utc(year, month, day);
    }
    return format.format(date.toLocal());
  }

  String formatTime(
    int year,
    int month,
    int day,
    int hour,
    int min,
    int sec, [
    bool isLocal = false,
  ]) {
    final format = DateFormat.yMMMEd()..add_jms();
    late DateTime date;
    if (isLocal) {
      date = DateTime(year, month, day, hour, min, sec);
    } else {
      date = DateTime.utc(year, month, day, hour, min, sec);
    }
    return format.format(date.toLocal());
  }

  // QR code is arbitrary
  void doTestResult(
    String contents,
    String goldenResult,
    ParsedResultType type, [
    BarcodeFormat format = BarcodeFormat.qrCode,
  ]) {
    final fakeResult = Result(contents, null, null, format);
    final result = ResultParser.parseResult(fakeResult);
    //assertNotNull(result);
    expect(type, result.type);

    final String displayResult = result.displayResult;
    expect(goldenResult, displayResult);
  }

  test('testTextType', () {
    doTestResult('', '', ParsedResultType.text);
    doTestResult('foo', 'foo', ParsedResultType.text);
    doTestResult('Hi.', 'Hi.', ParsedResultType.text);
    doTestResult('This is a test', 'This is a test', ParsedResultType.text);
    doTestResult(
      'This is a test\nwith newlines',
      'This is a test\nwith newlines',
      ParsedResultType.text,
    );
    doTestResult(
      'This: a test with lots of @ nearly-random punctuation! No? OK then.',
      'This: a test with lots of @ nearly-random punctuation! No? OK then.',
      ParsedResultType.text,
    );
  });

  test('testBookmarkType', () {
    doTestResult(
      'MEBKM:URL:google.com;;',
      'http://google.com',
      ParsedResultType.uri,
    );
    doTestResult(
      'MEBKM:URL:google.com;TITLE:Google;;',
      'Google\nhttp://google.com',
      ParsedResultType.uri,
    );
    doTestResult(
      'MEBKM:TITLE:Google;URL:google.com;;',
      'Google\nhttp://google.com',
      ParsedResultType.uri,
    );
    doTestResult(
      'MEBKM:URL:http://google.com;;',
      'http://google.com',
      ParsedResultType.uri,
    );
    doTestResult(
      'MEBKM:URL:HTTPS://google.com;;',
      'HTTPS://google.com',
      ParsedResultType.uri,
    );
  });

  test('testURLTOType', () {
    doTestResult(
      'urlto:foo:bar.com',
      'foo\nhttp://bar.com',
      ParsedResultType.uri,
    );
    doTestResult(
      'URLTO:foo:bar.com',
      'foo\nhttp://bar.com',
      ParsedResultType.uri,
    );
    doTestResult('URLTO::bar.com', 'http://bar.com', ParsedResultType.uri);
    doTestResult(
      'URLTO::http://bar.com',
      'http://bar.com',
      ParsedResultType.uri,
    );
  });

  test('testEmailType', () {
    doTestResult(
      'MATMSG:TO:srowen@example.org;;',
      'srowen@example.org',
      ParsedResultType.emailAddress,
    );
    doTestResult(
      'MATMSG:TO:srowen@example.org;SUB:Stuff;;',
      'srowen@example.org\nStuff',
      ParsedResultType.emailAddress,
    );
    doTestResult(
      'MATMSG:TO:srowen@example.org;SUB:Stuff;BODY:This is some text;;',
      'srowen@example.org\nStuff\nThis is some text',
      ParsedResultType.emailAddress,
    );
    doTestResult(
      'MATMSG:SUB:Stuff;BODY:This is some text;TO:srowen@example.org;;',
      'srowen@example.org\nStuff\nThis is some text',
      ParsedResultType.emailAddress,
    );
    doTestResult(
      'TO:srowen@example.org;SUB:Stuff;BODY:This is some text;;',
      'TO:srowen@example.org;SUB:Stuff;BODY:This is some text;;',
      ParsedResultType.text,
    );
  });

  test('testEmailAddressType', () {
    doTestResult(
      'srowen@example.org',
      'srowen@example.org',
      ParsedResultType.emailAddress,
    );
    doTestResult(
      'mailto:srowen@example.org',
      'srowen@example.org',
      ParsedResultType.emailAddress,
    );
    doTestResult(
      'MAILTO:srowen@example.org',
      'srowen@example.org',
      ParsedResultType.emailAddress,
    );
    doTestResult(
      'srowen@example',
      'srowen@example',
      ParsedResultType.emailAddress,
    );
    doTestResult('srowen', 'srowen', ParsedResultType.text);
    doTestResult("Let's meet @ 2", "Let's meet @ 2", ParsedResultType.text);
  });

  test('testAddressBookType', () {
    doTestResult(
      'MECARD:N:Sean Owen;;',
      'Sean Owen',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'MECARD:TEL:+12125551212;N:Sean Owen;;',
      'Sean Owen\n+12125551212',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'MECARD:TEL:+12125551212;N:Sean Owen;URL:google.com;;',
      'Sean Owen\n+12125551212\ngoogle.com',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'MECARD:TEL:+12125551212;N:Sean Owen;URL:google.com;EMAIL:srowen@example.org;',
      'Sean Owen\n+12125551212\nsrowen@example.org\ngoogle.com',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'MECARD:ADR:76 9th Ave;N:Sean Owen;URL:google.com;EMAIL:srowen@example.org;',
      'Sean Owen\n76 9th Ave\nsrowen@example.org\ngoogle.com',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'MECARD:BDAY:19760520;N:Sean Owen;URL:google.com;EMAIL:srowen@example.org;',
      'Sean Owen\nsrowen@example.org\ngoogle.com\n19760520',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'MECARD:ORG:Google;N:Sean Owen;URL:google.com;EMAIL:srowen@example.org;',
      'Sean Owen\nGoogle\nsrowen@example.org\ngoogle.com',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'MECARD:NOTE:ZXing Team;N:Sean Owen;URL:google.com;EMAIL:srowen@example.org;',
      'Sean Owen\nsrowen@example.org\ngoogle.com\nZXing Team',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'N:Sean Owen;TEL:+12125551212;;',
      'N:Sean Owen;TEL:+12125551212;;',
      ParsedResultType.text,
    );
  });

  test('testAddressBookAUType', () {
    doTestResult('MEMORY:\r\n', '', ParsedResultType.addressBook);
    doTestResult(
      'MEMORY:foo\r\nNAME1:Sean\r\n',
      'Sean\nfoo',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'TEL1:+12125551212\r\nMEMORY:\r\n',
      '+12125551212',
      ParsedResultType.addressBook,
    );
  });

  test('testBizcard', () {
    doTestResult(
      'BIZCARD:N:Sean;X:Owen;C:Google;A:123 Main St;M:+12225551212;E:srowen@example.org;',
      'Sean Owen\nGoogle\n123 Main St\n+12225551212\nsrowen@example.org',
      ParsedResultType.addressBook,
    );
  });

  test('testUPCA', () {
    doTestResult(
      '123456789012',
      '123456789012',
      ParsedResultType.product,
      BarcodeFormat.upcA,
    );
    doTestResult(
      '1234567890123',
      '1234567890123',
      ParsedResultType.product,
      BarcodeFormat.upcA,
    );
    doTestResult('12345678901', '12345678901', ParsedResultType.text);
  });

  test('testUPCE', () {
    doTestResult(
      '01234565',
      '01234565',
      ParsedResultType.product,
      BarcodeFormat.upcE,
    );
  });

  test('testEAN', () {
    doTestResult(
      '00393157',
      '00393157',
      ParsedResultType.product,
      BarcodeFormat.ean8,
    );
    doTestResult('00393158', '00393158', ParsedResultType.text);
    doTestResult(
      '5051140178499',
      '5051140178499',
      ParsedResultType.product,
      BarcodeFormat.ean13,
    );
    doTestResult('5051140178490', '5051140178490', ParsedResultType.text);
  });

  test('testISBN', () {
    doTestResult(
      '9784567890123',
      '9784567890123',
      ParsedResultType.isbn,
      BarcodeFormat.ean13,
    );
    doTestResult(
      '9794567890123',
      '9794567890123',
      ParsedResultType.isbn,
      BarcodeFormat.ean13,
    );
    doTestResult('97845678901', '97845678901', ParsedResultType.text);
    doTestResult('97945678901', '97945678901', ParsedResultType.text);
  });

  test('testURI', () {
    doTestResult(
      'http://google.com',
      'http://google.com',
      ParsedResultType.uri,
    );
    doTestResult('google.com', 'http://google.com', ParsedResultType.uri);
    doTestResult(
      'https://google.com',
      'https://google.com',
      ParsedResultType.uri,
    );
    doTestResult(
      'HTTP://google.com',
      'HTTP://google.com',
      ParsedResultType.uri,
    );
    doTestResult(
      'http://google.com/foobar',
      'http://google.com/foobar',
      ParsedResultType.uri,
    );
    doTestResult(
      'https://google.com:443/foobar',
      'https://google.com:443/foobar',
      ParsedResultType.uri,
    );
    doTestResult(
      'google.com:443',
      'http://google.com:443',
      ParsedResultType.uri,
    );
    doTestResult(
      'google.com:443/',
      'http://google.com:443/',
      ParsedResultType.uri,
    );
    doTestResult(
      'google.com:443/foobar',
      'http://google.com:443/foobar',
      ParsedResultType.uri,
    );
    doTestResult(
      'http://google.com:443/foobar',
      'http://google.com:443/foobar',
      ParsedResultType.uri,
    );
    doTestResult(
      'https://google.com:443/foobar',
      'https://google.com:443/foobar',
      ParsedResultType.uri,
    );
    doTestResult(
      'ftp://google.com/fake',
      'ftp://google.com/fake',
      ParsedResultType.uri,
    );
    doTestResult(
      'gopher://google.com/obsolete',
      'gopher://google.com/obsolete',
      ParsedResultType.uri,
    );
  });

  test('testGeo', () {
    doTestResult('geo:1,2', '1.0, 2.0', ParsedResultType.geo);
    doTestResult('GEO:1,2', '1.0, 2.0', ParsedResultType.geo);
    doTestResult('geo:1,2,3', '1.0, 2.0, 3.0m', ParsedResultType.geo);
    doTestResult(
      'geo:80.33,-32.3344,3.35',
      '80.33, -32.3344, 3.35m',
      ParsedResultType.geo,
    );
    doTestResult('geo', 'geo', ParsedResultType.text);
    doTestResult('geography', 'geography', ParsedResultType.text);
  });

  test('testTel', () {
    doTestResult('tel:+15551212', '+15551212', ParsedResultType.tel);
    doTestResult('TEL:+15551212', '+15551212', ParsedResultType.tel);
    doTestResult('tel:212 555 1212', '212 555 1212', ParsedResultType.tel);
    doTestResult('tel:2125551212', '2125551212', ParsedResultType.tel);
    doTestResult('tel:212-555-1212', '212-555-1212', ParsedResultType.tel);
    doTestResult('tel', 'tel', ParsedResultType.text);
    doTestResult('telephone', 'telephone', ParsedResultType.text);
  });

  test('testVCard', () {
    doTestResult('BEGIN:VCARD\r\nEND:VCARD', '', ParsedResultType.addressBook);
    doTestResult(
      'BEGIN:VCARD\r\nN:Owen;Sean\r\nEND:VCARD',
      'Sean Owen',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'BEGIN:VCARD\r\nVERSION:2.1\r\nN:Owen;Sean\r\nEND:VCARD',
      'Sean Owen',
      ParsedResultType.addressBook,
    );
    doTestResult(
      'BEGIN:VCARD\r\nADR;HOME:123 Main St\r\nVERSION:2.1\r\nN:Owen;Sean\r\nEND:VCARD',
      'Sean Owen\n123 Main St',
      ParsedResultType.addressBook,
    );
    doTestResult('BEGIN:VCARD', '', ParsedResultType.addressBook);
  });

  test('testVEvent', () {
    // UTC times
    doTestResult(
      'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nSUMMARY:foo\r\nDTSTART:20080504T123456Z\r\n'
          'DTEND:20080505T234555Z\r\nEND:VEVENT\r\nEND:VCALENDAR',
      'foo\n${formatTime(2008, 5, 4, 12, 34, 56)}\n${formatTime(2008, 5, 5, 23, 45, 55)}',
      ParsedResultType.calendar,
    );
    doTestResult(
      'BEGIN:VEVENT\r\nSUMMARY:foo\r\nDTSTART:20080504T123456Z\r\n'
          'DTEND:20080505T234555Z\r\nEND:VEVENT',
      'foo\n${formatTime(2008, 5, 4, 12, 34, 56)}\n${formatTime(2008, 5, 5, 23, 45, 55)}',
      ParsedResultType.calendar,
    );
    // Local times
    doTestResult(
      'BEGIN:VEVENT\r\nSUMMARY:foo\r\nDTSTART:20080504T123456\r\n'
          'DTEND:20080505T234555\r\nEND:VEVENT',
      'foo\n${formatTime(2008, 5, 4, 12, 34, 56, true)}\n${formatTime(2008, 5, 5, 23, 45, 55, true)}',
      ParsedResultType.calendar,
    );
    // Date only (all day event)
    doTestResult(
      'BEGIN:VEVENT\r\nSUMMARY:foo\r\nDTSTART:20080504\r\n'
          'DTEND:20080505\r\nEND:VEVENT',
      'foo\n${formatDate(2008, 5, 4, true)}\n${formatDate(2008, 5, 5, true)}',
      ParsedResultType.calendar,
    );
    // Start time only
    doTestResult(
      'BEGIN:VEVENT\r\nSUMMARY:foo\r\nDTSTART:20080504T123456Z\r\nEND:VEVENT',
      'foo\n${formatTime(2008, 5, 4, 12, 34, 56)}',
      ParsedResultType.calendar,
    );
    doTestResult(
      'BEGIN:VEVENT\r\nSUMMARY:foo\r\nDTSTART:20080504T123456\r\nEND:VEVENT',
      'foo\n${formatTime(2008, 5, 4, 12, 34, 56, true)}',
      ParsedResultType.calendar,
    );
    doTestResult(
      'BEGIN:VEVENT\r\nSUMMARY:foo\r\nDTSTART:20080504\r\nEND:VEVENT',
      'foo\n${formatDate(2008, 5, 4, true)}',
      ParsedResultType.calendar,
    );
    doTestResult(
      'BEGIN:VEVENT\r\nDTEND:20080505T\r\nEND:VEVENT',
      'BEGIN:VEVENT\r\nDTEND:20080505T\r\nEND:VEVENT',
      ParsedResultType.text,
    );
    // Yeah, it's OK that this is thought of as maybe a URI as long as it's not CALENDAR
    // Make sure illegal entries without newlines don't crash
    doTestResult(
      'BEGIN:VEVENTSUMMARY:EventDTSTART:20081030T122030ZDTEND:20081030T132030ZEND:VEVENT',
      'BEGIN:VEVENTSUMMARY:EventDTSTART:20081030T122030ZDTEND:20081030T132030ZEND:VEVENT',
      ParsedResultType.uri,
    );
  });

  test('testSMS', () {
    doTestResult('sms:+15551212', '+15551212', ParsedResultType.sms);
    doTestResult('SMS:+15551212', '+15551212', ParsedResultType.sms);
    doTestResult('sms:+15551212;via=999333', '+15551212', ParsedResultType.sms);
    doTestResult(
      'sms:+15551212?subject=foo&body=bar',
      '+15551212\nfoo\nbar',
      ParsedResultType.sms,
    );
    doTestResult(
      'sms:+15551212,+12124440101',
      '+15551212\n+12124440101',
      ParsedResultType.sms,
    );
  });

  test('testSMSTO', () {
    doTestResult('SMSTO:+15551212', '+15551212', ParsedResultType.sms);
    doTestResult('smsto:+15551212', '+15551212', ParsedResultType.sms);
    doTestResult(
      'smsto:+15551212:subject',
      '+15551212\nsubject',
      ParsedResultType.sms,
    );
    doTestResult(
      'smsto:+15551212:My message',
      '+15551212\nMy message',
      ParsedResultType.sms,
    );
    // Need to handle question mark in the subject
    doTestResult(
      "smsto:+15551212:What's up?",
      "+15551212\nWhat's up?",
      ParsedResultType.sms,
    );
    // Need to handle colon in the subject
    doTestResult(
      'smsto:+15551212:Directions: Do this',
      '+15551212\nDirections: Do this',
      ParsedResultType.sms,
    );
    doTestResult(
      "smsto:212-555-1212:Here's a longer message. Should be fine.",
      "212-555-1212\nHere's a longer message. Should be fine.",
      ParsedResultType.sms,
    );
  });

  test('testMMS', () {
    doTestResult('mms:+15551212', '+15551212', ParsedResultType.sms);
    doTestResult('MMS:+15551212', '+15551212', ParsedResultType.sms);
    doTestResult('mms:+15551212;via=999333', '+15551212', ParsedResultType.sms);
    doTestResult(
      'mms:+15551212?subject=foo&body=bar',
      '+15551212\nfoo\nbar',
      ParsedResultType.sms,
    );
    doTestResult(
      'mms:+15551212,+12124440101',
      '+15551212\n+12124440101',
      ParsedResultType.sms,
    );
  });

  test('testMMSTO', () {
    doTestResult('MMSTO:+15551212', '+15551212', ParsedResultType.sms);
    doTestResult('mmsto:+15551212', '+15551212', ParsedResultType.sms);
    doTestResult(
      'mmsto:+15551212:subject',
      '+15551212\nsubject',
      ParsedResultType.sms,
    );
    doTestResult(
      'mmsto:+15551212:My message',
      '+15551212\nMy message',
      ParsedResultType.sms,
    );
    doTestResult(
      "mmsto:+15551212:What's up?",
      "+15551212\nWhat's up?",
      ParsedResultType.sms,
    );
    doTestResult(
      'mmsto:+15551212:Directions: Do this',
      '+15551212\nDirections: Do this',
      ParsedResultType.sms,
    );
    doTestResult(
      "mmsto:212-555-1212:Here's a longer message. Should be fine.",
      "212-555-1212\nHere's a longer message. Should be fine.",
      ParsedResultType.sms,
    );
  });
}
