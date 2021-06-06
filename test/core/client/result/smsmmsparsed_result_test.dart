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








import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/client.dart';
import 'package:zxing/zxing.dart';

import '../../utils.dart';

/// Tests {@link SMSParsedResult}.
///
/// @author Sean Owen
void main(){

  void doTest(String contents,
      String number,
      String? subject,
      String? body,
      String? via,
      String parsedURI) {
    Result fakeResult = new Result(contents, null, null, BarcodeFormat.QR_CODE);
    ParsedResult result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.SMS, result.getType());
    SMSParsedResult smsResult = result as SMSParsedResult;
    assertArrayEquals(<String>[number], smsResult.getNumbers());
    expect(subject, smsResult.getSubject());
    expect(body, smsResult.getBody());
    assertArrayEquals(via == null ? <String>[] : <String>[via], smsResult.getVias());
    expect(parsedURI, smsResult.getSMSURI());
  }

  test('testSMS', () {
    doTest("sms:+15551212", "+15551212", null, null, null, "sms:+15551212");
    doTest("sms:+15551212?subject=foo&body=bar", "+15551212", "foo", "bar", null,
           "sms:+15551212?body=bar&subject=foo");
    doTest("sms:+15551212;via=999333", "+15551212", null, null, "999333",
           "sms:+15551212;via=999333");
  });

  test('testMMS', () {
    doTest("mms:+15551212", "+15551212", null, null, null, "sms:+15551212");
    doTest("mms:+15551212?subject=foo&body=bar", "+15551212", "foo", "bar", null,
           "sms:+15551212?body=bar&subject=foo");
    doTest("mms:+15551212;via=999333", "+15551212", null, null, "999333",
           "sms:+15551212;via=999333");
  });



}
