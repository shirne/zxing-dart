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

import '../../result.dart';
import 'result_parser.dart';
import 'smsparsed_result.dart';

/// <p>Parses an "sms:" URI result, which specifies a number to SMS.
/// See <a href="http://tools.ietf.org/html/rfc5724"> RFC 5724</a> on this.</p>
///
/// <p>This class supports "via" syntax for numbers, which is not part of the spec.
/// For example "+12125551212;via=+12124440101" may appear as a number.
/// It also supports a "subject" query parameter, which is not mentioned in the spec.
/// These are included since they were mentioned in earlier IETF drafts and might be
/// used.</p>
///
/// <p>This actually also parses URIs starting with "mms:" and treats them all the same way,
/// and effectively converts them to an "sms:" URI for purposes of forwarding to the platform.</p>
///
/// @author Sean Owen
class SMSMMSResultParser extends ResultParser {
  @override
  SMSParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    if (!(rawText.startsWith("sms:") ||
        rawText.startsWith("SMS:") ||
        rawText.startsWith("mms:") ||
        rawText.startsWith("MMS:"))) {
      return null;
    }

    // Check up front if this is a URI syntax string with query arguments
    Map<String, String>? nameValuePairs = ResultParser.parseNameValuePairs(rawText);
    String? subject;
    String? body;
    bool querySyntax = false;
    if (nameValuePairs != null && nameValuePairs.isNotEmpty) {
      subject = nameValuePairs["subject"];
      body = nameValuePairs["body"];
      querySyntax = true;
    }

    // Drop sms, query portion
    int queryStart = rawText.indexOf('?', 4);
    String smsURIWithoutQuery;
    // If it's not query syntax, the question mark is part of the subject or message
    if (queryStart < 0 || !querySyntax) {
      smsURIWithoutQuery = rawText.substring(4);
    } else {
      smsURIWithoutQuery = rawText.substring(4, queryStart);
    }

    int lastComma = -1;
    int comma;
    List<String> numbers = [''];
    List<String> vias = [''];
    while (
        (comma = smsURIWithoutQuery.indexOf(',', lastComma + 1)) > lastComma) {
      String numberPart = smsURIWithoutQuery.substring(lastComma + 1, comma);
      _addNumberVia(numbers, vias, numberPart);
      lastComma = comma;
    }
    _addNumberVia(numbers, vias, smsURIWithoutQuery.substring(lastComma + 1));

    return SMSParsedResult(numbers.toList(), vias.toList(), subject, body);
  }

  static void _addNumberVia(
      List<String> numbers, List<String> vias, String numberPart) {
    int numberEnd = numberPart.indexOf(';');
    if (numberEnd < 0) {
      numbers.add(numberPart);
      vias.add(''); //todo null
    } else {
      numbers.add(numberPart.substring(0, numberEnd));
      String maybeVia = numberPart.substring(numberEnd + 1);
      String via;
      if (maybeVia.startsWith("via=")) {
        via = maybeVia.substring(4);
      } else {
        via = ''; //todo null
      }
      vias.add(via);
    }
  }
}
