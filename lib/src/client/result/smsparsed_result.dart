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

/// Represents a parsed result that encodes an SMS message, including recipients, subject
/// and body text.
///
/// @author Sean Owen
class SMSParsedResult extends ParsedResult {
  final List<String> _numbers;
  final List<String>? _vias;
  final String? _subject;
  final String? _body;

  SMSParsedResult.single(String number, String? via, this._subject, this._body)
      : _numbers = [number],
        _vias = [if(via != null)via],
        super(ParsedResultType.SMS);

  SMSParsedResult(this._numbers, this._vias, this._subject, this._body)
      : super(ParsedResultType.SMS);

  String get smsURI {
    StringBuffer result = StringBuffer();
    result.write("sms:");
    bool first = true;
    for (int i = 0; i < _numbers.length; i++) {
      if (first) {
        first = false;
      } else {
        result.write(',');
      }
      result.write(_numbers[i]);
      if (_vias != null && _vias!.length > i) {
        result.write(";via=");
        result.write(_vias![i]);
      }
    }
    bool hasBody = _body != null;
    bool hasSubject = _subject != null;
    if (hasBody || hasSubject) {
      result.write('?');
      if (hasBody) {
        result.write("body=");
        result.write(_body);
      }
      if (hasSubject) {
        if (hasBody) {
          result.write('&');
        }
        result.write("subject=");
        result.write(_subject);
      }
    }
    return result.toString();
  }

  List<String> get numbers => _numbers;

  List<String>? get vias => _vias;

  String? get subject => _subject;

  String? get body => _body;

  @override
  String get displayResult {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppendList(_numbers, result);
    ParsedResult.maybeAppend(_subject, result);
    ParsedResult.maybeAppend(_body, result);
    return result.toString();
  }
}
