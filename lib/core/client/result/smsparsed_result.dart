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

import 'parsed_result.dart';
import 'parsed_result_type.dart';

/**
 * Represents a parsed result that encodes an SMS message, including recipients, subject
 * and body text.
 *
 * @author Sean Owen
 */
class SMSParsedResult extends ParsedResult {
  final List<String> numbers;
  final List<String>? vias;
  final String? subject;
  final String? body;

  SMSParsedResult.single(String number, String? via, this.subject, this.body)
      : numbers = [number],
        vias = [if(via != null)via],
        super(ParsedResultType.SMS);

  SMSParsedResult(this.numbers, this.vias, this.subject, this.body)
      : super(ParsedResultType.SMS);

  String getSMSURI() {
    StringBuffer result = new StringBuffer();
    result.write("sms:");
    bool first = true;
    for (int i = 0; i < numbers.length; i++) {
      if (first) {
        first = false;
      } else {
        result.write(',');
      }
      result.write(numbers[i]);
      if (vias != null && vias!.length > i) {
        result.write(";via=");
        result.write(vias![i]);
      }
    }
    bool hasBody = body != null;
    bool hasSubject = subject != null;
    if (hasBody || hasSubject) {
      result.write('?');
      if (hasBody) {
        result.write("body=");
        result.write(body);
      }
      if (hasSubject) {
        if (hasBody) {
          result.write('&');
        }
        result.write("subject=");
        result.write(subject);
      }
    }
    return result.toString();
  }

  List<String> getNumbers() {
    return numbers;
  }

  List<String>? getVias() {
    return vias;
  }

  String? getSubject() {
    return subject;
  }

  String? getBody() {
    return body;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = new StringBuffer(100);
    ParsedResult.maybeAppendList(numbers, result);
    ParsedResult.maybeAppend(subject, result);
    ParsedResult.maybeAppend(body, result);
    return result.toString();
  }
}
