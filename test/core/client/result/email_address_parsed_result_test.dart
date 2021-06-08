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
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/zxing.dart';

import '../../utils.dart';

/// Tests {@link EmailAddressParsedResult}.
///
/// @author Sean Owen
void main(){


  void doTest(String contents,
      List<String>? tos,
      List<String>? ccs,
      List<String>? bccs,
      String? subject,
      String? body) {
    Result fakeResult = new Result(contents, null, null, BarcodeFormat.QR_CODE);
    ParsedResult result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.EMAIL_ADDRESS, result.getType());
    EmailAddressParsedResult emailResult = result as EmailAddressParsedResult;
    assertArrayEquals(tos, emailResult.getTos());
    assertArrayEquals(ccs, emailResult.getCCs());
    assertArrayEquals(bccs, emailResult.getBCCs());
    expect(subject, emailResult.getSubject());
    expect(body, emailResult.getBody());
  }



  void doTestSingle(String contents,
      String to,
      String? subject,
      String? body) {
    doTest(contents, [to], null, null, subject, body);
  }

  test('testEmailAddress', () {
    doTestSingle("srowen@example.org", "srowen@example.org", null, null);
    doTestSingle("mailto:srowen@example.org", "srowen@example.org", null, null);
  });

  test('testTos', () {
    doTest("mailto:srowen@example.org,bob@example.org",
           ["srowen@example.org", "bob@example.org"],
           null, null, null, null);
    doTest("mailto:?to=srowen@example.org,bob@example.org",
           ["srowen@example.org", "bob@example.org"],
           null, null, null, null);
  });

  test('testCCs', () {
    doTest("mailto:?cc=srowen@example.org",
           null,
           ["srowen@example.org"],
           null, null, null);
    doTest("mailto:?cc=srowen@example.org,bob@example.org",
           null,
           ["srowen@example.org", "bob@example.org"],
           null, null, null);
  });

  test('testBCCs', () {
    doTest("mailto:?bcc=srowen@example.org",
           null, null,
           ["srowen@example.org"],
           null, null);
    doTest("mailto:?bcc=srowen@example.org,bob@example.org",
           null, null,
           ["srowen@example.org", "bob@example.org"],
           null, null);
  });

  test('testAll', () {
    doTest("mailto:bob@example.org?cc=foo@example.org&bcc=srowen@example.org&subject=baz&body=buzz",
           ["bob@example.org"],
           ["foo@example.org"],
           ["srowen@example.org"],
           "baz",
           "buzz");
  });

  test('testEmailDocomo', () {
    doTestSingle("MATMSG:TO:srowen@example.org;;", "srowen@example.org", null, null);
    doTestSingle("MATMSG:TO:srowen@example.org;SUB:Stuff;;", "srowen@example.org", "Stuff", null);
    doTestSingle("MATMSG:TO:srowen@example.org;SUB:Stuff;BODY:This is some text;;", "srowen@example.org",
        "Stuff", "This is some text");
  });

  test('testSMTP', () {
    doTestSingle("smtp:srowen@example.org", "srowen@example.org", null, null);
    doTestSingle("SMTP:srowen@example.org", "srowen@example.org", null, null);
    doTestSingle("smtp:srowen@example.org:foo", "srowen@example.org", "foo", null);
    doTestSingle("smtp:srowen@example.org:foo:bar", "srowen@example.org", "foo", "bar");
  });


}