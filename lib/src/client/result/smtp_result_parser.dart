/*
 * Copyright 2010 ZXing authors
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
import 'email_address_parsed_result.dart';
import 'result_parser.dart';

/// Parses an "smtp:" URI result, whose format is not standardized but appears to be like:
/// `smtp[:subject[:body]]`.
///
/// @author Sean Owen
class SMTPResultParser extends ResultParser {
  @override
  EmailAddressParsedResult? parse(Result result) {
    final rawText = ResultParser.getMassagedText(result);
    if (!(rawText.startsWith('smtp:') || rawText.startsWith('SMTP:'))) {
      return null;
    }
    String emailAddress = rawText.substring(5);
    String? subject;
    String? body;
    int colon = emailAddress.indexOf(':');
    if (colon >= 0) {
      subject = emailAddress.substring(colon + 1);
      emailAddress = emailAddress.substring(0, colon);
      colon = subject.indexOf(':');
      if (colon >= 0) {
        body = subject.substring(colon + 1);
        subject = subject.substring(0, colon);
      }
    }
    return EmailAddressParsedResult([emailAddress], null, null, subject, body);
  }
}
