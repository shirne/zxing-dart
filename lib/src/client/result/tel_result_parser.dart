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
import 'tel_parsed_result.dart';

/// Parses a "tel:" URI result, which specifies a phone number.
///
/// @author Sean Owen
class TelResultParser extends ResultParser {
  @override
  TelParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    if (!rawText.startsWith("tel:") && !rawText.startsWith("TEL:")) {
      return null;
    }
    // Normalize "TEL:" to "tel:"
    String telURI =
        rawText.startsWith("TEL:") ? "tel:${rawText.substring(4)}" : rawText;
    // Drop tel, query portion
    int queryStart = rawText.indexOf('?', 4);
    String number = queryStart < 0
        ? rawText.substring(4)
        : rawText.substring(4, queryStart);
    return TelParsedResult(number, telURI, null);
  }
}
