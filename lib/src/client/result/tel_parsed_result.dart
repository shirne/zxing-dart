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

/// Represents a parsed result that encodes a telephone number.
///
/// @author Sean Owen
class TelParsedResult extends ParsedResult {
  final String? _number;
  final String? _telURI;
  final String? _title;

  TelParsedResult(this._number, this._telURI, this._title)
      : super(ParsedResultType.TEL);

  String? get number => _number;

  String? get telURI => _telURI;

  String? get title => _title;

  @override
  String get displayResult {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppend(_number, result);
    ParsedResult.maybeAppend(_title, result);
    return result.toString();
  }
}
