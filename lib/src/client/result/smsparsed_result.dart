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
  List<String>? _vias;
  String? subject;
  String? body;

  SMSParsedResult.single(String number, String? via, this.subject, this.body)
      : _numbers = [number],
        _vias = [if (via != null) via],
        super(ParsedResultType.SMS);

  SMSParsedResult(this._numbers, this._vias, this.subject, this.body)
      : super(ParsedResultType.SMS);

  void addNumber(String num, [String? via]) {
    _numbers.add(num);
    if (via != null) {
      _vias ??= List.filled(_numbers.length - 1, '');
      _vias!.add(via);
    } else if (_vias != null) {
      _vias!.add('');
    }
  }

  String get smsURI {
    final result = StringBuffer();
    result.write('sms:');
    bool first = true;
    for (int i = 0; i < _numbers.length; i++) {
      if (first) {
        first = false;
      } else {
        result.write(',');
      }
      result.write(_numbers[i]);
      if (_vias != null && _vias!.length > i) {
        result.write(';via=');
        result.write(_vias![i]);
      }
    }
    final hasBody = body != null;
    final hasSubject = subject != null;
    if (hasBody || hasSubject) {
      result.write('?');
      if (hasBody) {
        result.write('body=');
        result.write(body);
      }
      if (hasSubject) {
        if (hasBody) {
          result.write('&');
        }
        result.write('subject=');
        result.write(subject);
      }
    }
    return result.toString();
  }

  List<String> get numbers => _numbers;

  List<String>? get vias => _vias;

  @override
  String get displayResult {
    final result = StringBuffer();
    maybeAppendList(_numbers, result);
    maybeAppend(subject, result);
    maybeAppend(body, result);
    return result.toString();
  }
}
