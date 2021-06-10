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

import '../../result.dart';
import 'abstract_do_co_mo_result_parser.dart';
import 'email_address_parsed_result.dart';
import 'result_parser.dart';

/// Implements the "MATMSG" email message entry format.
///
/// Supported keys: TO, SUB, BODY
///
/// @author Sean Owen
class EmailDoCoMoResultParser extends AbstractDoCoMoResultParser {

  @override
  EmailAddressParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    if (!rawText.startsWith("MATMSG:")) {
      return null;
    }
    List<String>? tos = matchDoCoMoPrefixedField("TO:", rawText);
    if (tos == null) {
      return null;
    }
    for (String to in tos) {
      if (!isBasicallyValidEmailAddress(to)) {
        return null;
      }
    }
    String? subject = matchSingleDoCoMoPrefixedField("SUB:", rawText, false);
    String? body = matchSingleDoCoMoPrefixedField("BODY:", rawText, false);
    return EmailAddressParsedResult(tos, null, null, subject, body);
  }
}
