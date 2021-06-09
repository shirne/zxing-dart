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
  final List<String>? _tos;
  final List<String>? _ccs;
  final List<String>? _bccs;
  final String? _subject;
  final String? _body;

  EmailAddressParsedResult(
      dynamic tos, [this._ccs, this._bccs, this._subject, this._body])
      : this._tos = tos is String ? [tos] : tos as List<String>?,
        super(ParsedResultType.EMAIL_ADDRESS);

  /// @return first elements of {@link #getTos()} or {@code null} if none
  /// @deprecated use {@link #getTos()}
  @deprecated
  String? get emailAddress => _tos == null || _tos!.length == 0 ? null : _tos![0];

  List<String>? get tos => _tos;

  List<String>? get ccs => _ccs;

  List<String>? get bccs => _bccs;

  String? get subject => _subject;

  String? get body => _body;

  /// @return "mailto:"
  /// @deprecated without replacement
  @deprecated
  String get mailtoURI => "mailto:";

  @override
  String get displayResult {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppendList(_tos, result);
    ParsedResult.maybeAppendList(_ccs, result);
    ParsedResult.maybeAppendList(_bccs, result);
    ParsedResult.maybeAppend(_subject, result);
    ParsedResult.maybeAppend(_body, result);
    return result.toString();
  }
}
