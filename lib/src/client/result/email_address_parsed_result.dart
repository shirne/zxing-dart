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

import 'parsed_result.dart';
import 'parsed_result_type.dart';

/// Represents a parsed result that encodes an email message including recipients, subject
/// and body text.
///
/// @author Sean Owen
class EmailAddressParsedResult extends ParsedResult {
  List<String>? _tos;
  List<String>? _ccs;
  List<String>? _bccs;
  String? subject;
  String? body;

  EmailAddressParsedResult(
      dynamic tos, [this._ccs, this._bccs, this.subject, this.body])
      : this._tos = tos is String ? [tos] : tos as List<String>?,
        super(ParsedResultType.EMAIL_ADDRESS);

  /// @return first elements of [tos] or `null` if none
  /// @deprecated use [tos]
  @deprecated
  String? get emailAddress => _tos == null || _tos!.length == 0 ? null : _tos![0];

  List<String>? get tos => _tos;

  List<String>? get ccs => _ccs;

  List<String>? get bccs => _bccs;

  addTo(String to){
    if(_tos == null){
      _tos = [];
    }
    _tos!.add(to);
  }
  addCC(String to){
    if(_ccs == null){
      _ccs = [];
    }
    _ccs!.add(to);
  }

  addBCC(String to){
    if(_bccs == null){
      _bccs = [];
    }
    _bccs!.add(to);
  }


  /// @return "mailto:"
  /// @deprecated without replacement
  @deprecated
  String get mailtoURI => "mailto:";

  @override
  String get displayResult {
    StringBuffer result = StringBuffer();
    maybeAppendList(_tos, result);
    maybeAppendList(_ccs, result);
    maybeAppendList(_bccs, result);
    maybeAppend(subject, result);
    maybeAppend(body, result);
    return result.toString();
  }
}
