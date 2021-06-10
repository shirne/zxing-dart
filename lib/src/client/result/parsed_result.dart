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

import 'parsed_result_type.dart';

/// Abstract class representing the result of decoding a barcode, as more than
/// a String -- as some type of structured data.
///
/// This might be a subclass which represents a URL,
/// or an e-mail address. ResultParser.parseResult([Result]) will turn a raw
/// decoded string into the most appropriate type of structured representation.
///
/// @author Sean Owen
abstract class ParsedResult {
  final ParsedResultType _type;

  ParsedResult(this._type);

  ParsedResultType get type => _type;

  String get displayResult;

  @override
  String toString() {
    return displayResult;
  }

  static void maybeAppend(String? value, StringBuffer result) {
    if (value != null && value.isNotEmpty) {
      // Don't add a newline before the first value
      if (result.length > 0) {
        result.write('\n');
      }
      result.write(value);
    }
  }

  static void maybeAppendList(List<String>? values, StringBuffer result) {
    if (values != null) {
      for (String value in values) {
        maybeAppend(value, result);
      }
    }
  }
}
