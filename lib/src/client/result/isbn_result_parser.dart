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

import '../../barcode_format.dart';
import '../../result.dart';
import 'isbn_parsed_result.dart';
import 'result_parser.dart';

/// Parses strings of digits that represent a ISBN.
///
/// @author jbreiden@google.com (Jeff Breidenbach)
class ISBNResultParser extends ResultParser {
  /// See <a href="http://www.bisg.org/isbn-13/for.dummies.html">ISBN-13 For Dummies</a>
  @override
  ISBNParsedResult? parse(Result result) {
    final format = result.barcodeFormat;
    if (format != BarcodeFormat.ean13) {
      return null;
    }
    final rawText = ResultParser.getMassagedText(result);
    final length = rawText.length;
    if (length != 13) {
      return null;
    }
    if (!rawText.startsWith('978') && !rawText.startsWith('979')) {
      return null;
    }

    return ISBNParsedResult(rawText);
  }
}
