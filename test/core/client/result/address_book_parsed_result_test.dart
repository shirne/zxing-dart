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








import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/client.dart';
import 'package:zxing/zxing.dart';

import '../../utils.dart';

/// Tests [@link AddressBookParsedResult].
///
/// @author Sean Owen
void main(){

  void doTest(String contents,
      String? title,
      List<String>? names,
      String? pronunciation,
      List<String?>? addresses,
      List<String?>? emails,
      List<String?>? phoneNumbers,
      List<String?>? phoneTypes,
      String? org,
      List<String?>? urls,
      String? birthday,
      String? note) {
    Result fakeResult = Result(contents, null, null, BarcodeFormat.QR_CODE);
    ParsedResult result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.ADDRESS_BOOK, result.getType());
    AddressBookParsedResult addressResult = result as AddressBookParsedResult;
    expect(addressResult.getTitle(), title);
    assertArrayEquals(names, addressResult.getNames());
    expect(pronunciation, addressResult.getPronunciation());
    assertArrayEquals(addresses, addressResult.getAddresses());
    assertArrayEquals(emails, addressResult.getEmails());
    assertArrayEquals(phoneNumbers, addressResult.getPhoneNumbers());
    assertArrayEquals(phoneTypes, addressResult.getPhoneTypes());
    expect(addressResult.getOrg(), org);
    assertArrayEquals(urls, addressResult.getURLs());
    expect(addressResult.getBirthday(), birthday);
    expect(addressResult.getNote(), note);
  }

  test('testAddressBookDocomo', () {
    doTest("MECARD:N:Sean Owen;;", null, ["Sean Owen"], null, null, null, null, null, null, null, null, null);
    doTest("MECARD:NOTE:ZXing Team;N:Sean Owen;URL:google.com;EMAIL:srowen@example.org;;",
        null, ["Sean Owen"], null, null, ["srowen@example.org"], null, null, null,
        ["google.com"], null, "ZXing Team");
  });

  test('testAddressBookAU', () {
    doTest("MEMORY:foo\r\nNAME1:Sean\r\nTEL1:+12125551212\r\n",
        null, ["Sean"], null, null, null, ["+12125551212"], null, null, null, null, "foo");
  });

  test('testVCard', () {
    doTest("BEGIN:VCARD\r\nADR;HOME:123 Main St\r\nVERSION:2.1\r\nN:Owen;Sean\r\nEND:VCARD",
           null, ["Sean Owen"], null, ["123 Main St"], null, null, null, null, null, null, null);
  });

  test('testVCardFullN', () {
    doTest("BEGIN:VCARD\r\nVERSION:2.1\r\nN:Owen;Sean;T;Mr.;Esq.\r\nEND:VCARD",
           null, ["Mr. Sean T Owen Esq."], null, null, null, null, null, null, null, null, null);
  });

  test('testVCardFullN2', () {
    doTest("BEGIN:VCARD\r\nVERSION:2.1\r\nN:Owen;Sean;;;\r\nEND:VCARD",
           null, ["Sean Owen"], null, null, null, null, null, null, null, null, null);
  });

  test('testVCardFullN3', () {
    doTest("BEGIN:VCARD\r\nVERSION:2.1\r\nN:;Sean;;;\r\nEND:VCARD",
           null, ["Sean"], null, null, null, null, null, null, null, null, null);
  });

  test('testVCardCaseInsensitive', () {
    doTest("begin:vcard\r\nadr;HOME:123 Main St\r\nVersion:2.1\r\nn:Owen;Sean\r\nEND:VCARD",
           null, ["Sean Owen"], null, ["123 Main St"], null, null, null, null, null, null, null);
  });

  test('testEscapedVCard', () {
    doTest("BEGIN:VCARD\r\nADR;HOME:123\\;\\\\ Main\\, St\\nHome\r\nVERSION:2.1\r\nN:Owen;Sean\r\nEND:VCARD",
           null, ["Sean Owen"], null, ["123;\\ Main, St\nHome"], null, null, null, null, null, null, null);
  });

  test('testBizcard', () {
    doTest("BIZCARD:N:Sean;X:Owen;C:Google;A:123 Main St;M:+12125551212;E:srowen@example.org;",
        null, ["Sean Owen"], null, ["123 Main St"], ["srowen@example.org"],
        ["+12125551212"], null, "Google", null, null, null);
  });

  test('testSeveralAddresses', () {
    doTest("MECARD:N:Foo Bar;ORG:Company;TEL:5555555555;EMAIL:foo.bar@xyz.com;ADR:City, 10001;" +
           "ADR:City, 10001;NOTE:This is the memo.;;",
           null, ["Foo Bar"], null, ["City, 10001", "City, 10001"],
           ["foo.bar@xyz.com"],
           ["5555555555" ], null, "Company", null, null, "This is the memo.");
  });

  test('testQuotedPrintable', () {
    doTest("BEGIN:VCARD\r\nADR;HOME;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:;;" +
           "=38=38=20=4C=79=6E=62=72=6F=6F=6B=0D=0A=43=\r\n" +
           "=4F=20=36=39=39=\r\n" +
           "=39=39;;;\r\nEND:VCARD",
           null, null, null, ["88 Lynbrook\r\nCO 69999"],
           null, null, null, null, null, null, null);
  });

  test('testVCardEscape', () {
    doTest("BEGIN:VCARD\r\nNOTE:foo\\nbar\r\nEND:VCARD",
           null, null, null, null, null, null, null, null, null, null, "foo\nbar");
    doTest("BEGIN:VCARD\r\nNOTE:foo\\;bar\r\nEND:VCARD",
               null, null, null, null, null, null, null, null, null, null, "foo;bar");
    doTest("BEGIN:VCARD\r\nNOTE:foo\\\\bar\r\nEND:VCARD",
                   null, null, null, null, null, null, null, null, null, null, "foo\\bar");
    doTest("BEGIN:VCARD\r\nNOTE:foo\\,bar\r\nEND:VCARD",
                       null, null, null, null, null, null, null, null, null, null, "foo,bar");
  });

  test('testVCardValueURI', () {
    doTest("BEGIN:VCARD\r\nTEL;VALUE=uri:tel:+1-555-555-1212\r\nEND:VCARD",
        null, null, null, null, null, [ "+1-555-555-1212" ], <String?>[ null ],
        null, null, null, null);

    doTest("BEGIN:VCARD\r\nN;VALUE=text:Owen;Sean\r\nEND:VCARD",
        null, ["Sean Owen"], null, null, null, null, null, null, null, null, null);
  });

  test('testVCardTypes', () {
    doTest("BEGIN:VCARD\r\nTEL;HOME:\r\nTEL;WORK:10\r\nTEL:20\r\nTEL;CELL:30\r\nEND:VCARD",
           null, null, null, null, null, [ "10", "20", "30" ],
           <String?>[ "WORK", null, "CELL" ], null, null, null, null);
  });

}