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

/// Parses an "smsto:" URI result, whose format is not standardized but appears to be like:
/// `smsto:number(:body)`.
///
/// This actually also parses URIs starting with "smsto:", "mmsto:", "SMSTO:", and
/// "MMSTO:", and treats them all the same way, and effectively converts them to an "sms:" URI
/// for purposes of forwarding to the platform.
///
/// @author Sean Owen
class SMSTOMMSTOResultParser extends ResultParser {
  @override
  SMSParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    if (!(rawText.startsWith("smsto:") ||
        rawText.startsWith("SMSTO:") ||
        rawText.startsWith("mmsto:") ||
        rawText.startsWith("MMSTO:"))) {
      return null;
    }
    // Thanks to dominik.wild for suggesting this enhancement to support
    // smsto:number:body URIs
    String number = rawText.substring(6);
    String? body;
    int bodyStart = number.indexOf(':');
    if (bodyStart >= 0) {
      body = number.substring(bodyStart + 1);
      number = number.substring(0, bodyStart);
    }
    return SMSParsedResult.single(number, null, null, body);
  }
}
