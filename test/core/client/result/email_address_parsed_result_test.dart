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

/// Tests [EmailAddressParsedResult].
///
void main() {
  void doTest(
    String contents,
    List<String>? tos,
    List<String>? ccs,
    List<String>? bccs,
    String? subject,
    String? body,
  ) {
    final fakeResult = Result(contents, null, null, BarcodeFormat.qrCode);
    final result = ResultParser.parseResult(fakeResult);
    expect(ParsedResultType.emailAddress, result.type);
    final emailResult = result as EmailAddressParsedResult;
    assertArrayEquals(tos, emailResult.tos);
    assertArrayEquals(ccs, emailResult.ccs);
    assertArrayEquals(bccs, emailResult.bccs);
    expect(subject, emailResult.subject);
    expect(body, emailResult.body);
  }

  void doTestSingle(String contents, String to, String? subject, String? body) {
    doTest(contents, [to], null, null, subject, body);
  }

  test('testEmailAddresses', () {
    final parser = EmailDoCoMoResultParser();
    assert(!parser.isBasicallyValidEmailAddress(null));
    assert(!parser.isBasicallyValidEmailAddress(''));
    assert(!parser.isBasicallyValidEmailAddress('123.365.com'));
    assert(!parser.isBasicallyValidEmailAddress('abc.def.com'));
    assert(!parser.isBasicallyValidEmailAddress('123@abcd.c'));
    assert(!parser.isBasicallyValidEmailAddress('123@abcd'));
    assert(!parser.isBasicallyValidEmailAddress('123@ab,cd.com'));
    assert(!parser.isBasicallyValidEmailAddress('123@ab#cd.com'));
    assert(!parser.isBasicallyValidEmailAddress('123@ab!#cd.com'));
    assert(!parser.isBasicallyValidEmailAddress('123@ab_cd.com'));
    assert(!parser.isBasicallyValidEmailAddress('123@-abcd.com'));
    assert(!parser.isBasicallyValidEmailAddress('123@abcd-.com'));
    assert(!parser.isBasicallyValidEmailAddress('123@abcd.c-m'));
    assert(parser.isBasicallyValidEmailAddress('123@abcd.com'));
    assert(parser.isBasicallyValidEmailAddress('123@ab-cd.com'));
    assert(parser.isBasicallyValidEmailAddress('abc.456@ab-cd.com'));
    assert(parser.isBasicallyValidEmailAddress('abc.456@ab-cd.BB-EZ-12.com'));
    assert(parser.isBasicallyValidEmailAddress('建設省.456@ab-cd.com'));
    assert(parser.isBasicallyValidEmailAddress('abc.Z456@ab-Cd9Z.co'));
    assert(parser.isBasicallyValidEmailAddress('建設省.aZ456@Ab-cd9Z.co'));
  });

  test('testEmailAddress', () {
    doTestSingle('srowen@example.org', 'srowen@example.org', null, null);
    doTestSingle('mailto:srowen@example.org', 'srowen@example.org', null, null);
  });

  test('testTos', () {
    doTest(
      'mailto:srowen@example.org,bob@example.org',
      ['srowen@example.org', 'bob@example.org'],
      null,
      null,
      null,
      null,
    );
    doTest(
      'mailto:?to=srowen@example.org,bob@example.org',
      ['srowen@example.org', 'bob@example.org'],
      null,
      null,
      null,
      null,
    );
  });

  test('testCCs', () {
    doTest(
      'mailto:?cc=srowen@example.org',
      null,
      ['srowen@example.org'],
      null,
      null,
      null,
    );
    doTest(
      'mailto:?cc=srowen@example.org,bob@example.org',
      null,
      ['srowen@example.org', 'bob@example.org'],
      null,
      null,
      null,
    );
  });

  test('testBCCs', () {
    doTest(
      'mailto:?bcc=srowen@example.org',
      null,
      null,
      ['srowen@example.org'],
      null,
      null,
    );
    doTest(
      'mailto:?bcc=srowen@example.org,bob@example.org',
      null,
      null,
      ['srowen@example.org', 'bob@example.org'],
      null,
      null,
    );
  });

  test('testAll', () {
    doTest(
      'mailto:bob@example.org?cc=foo@example.org&bcc=srowen@example.org&subject=baz&body=buzz',
      ['bob@example.org'],
      ['foo@example.org'],
      ['srowen@example.org'],
      'baz',
      'buzz',
    );
  });

  test('testEmailDocomo', () {
    doTestSingle(
      'MATMSG:TO:srowen@example.org;;',
      'srowen@example.org',
      null,
      null,
    );
    doTestSingle(
      'MATMSG:TO:srowen@example.org;SUB:Stuff;;',
      'srowen@example.org',
      'Stuff',
      null,
    );
    doTestSingle(
      'MATMSG:TO:srowen@example.org;SUB:Stuff;BODY:This is some text;;',
      'srowen@example.org',
      'Stuff',
      'This is some text',
    );
  });

  test('testSMTP', () {
    doTestSingle('smtp:srowen@example.org', 'srowen@example.org', null, null);
    doTestSingle('SMTP:srowen@example.org', 'srowen@example.org', null, null);
    doTestSingle(
      'smtp:srowen@example.org:foo',
      'srowen@example.org',
      'foo',
      null,
    );
    doTestSingle(
      'smtp:srowen@example.org:foo:bar',
      'srowen@example.org',
      'foo',
      'bar',
    );
  });
}
