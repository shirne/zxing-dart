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

import 'result_parser.dart';

/// DoCoMo's parser utils
///
/// See
/// <a href="http://www.nttdocomo.co.jp/english/service/imode/make/content/barcode/about/s2.html">
/// DoCoMo's documentation</a> about the result types represented by subclasses of this class.
///
/// @author Sean Owen
abstract class AbstractDoCoMoResultParser extends ResultParser {
  static const emailLocal = '[^:]+';
  static const emailDomain =
      '([0-9a-zA-Z]+[0-9a-zA-Z\\-]+[0-9a-zA-Z]+\\.)+[a-zA-Z]{2,}';
  static final emailRegExp = RegExp('^$emailLocal@$emailDomain\$');

  List<String>? matchDoCoMoPrefixedField(String prefix, String rawText) =>
      matchPrefixedField(prefix, rawText, ';', true);

  String? matchSingleDoCoMoPrefixedField(
    String prefix,
    String rawText,
    bool trim,
  ) =>
      matchSinglePrefixedField(prefix, rawText, ';', trim);

  /// This implements only the most basic checking for an email address's validity -- that it contains
  /// an '@' and contains no characters disallowed by RFC 2822. This is an overly lenient definition of
  /// validity. We want to generally be lenient here since this class is only intended to encapsulate what's
  /// in a barcode, not "judge" it.
  bool isBasicallyValidEmailAddress(String? email) =>
      email != null && emailRegExp.hasMatch(email) && email.contains('@');
}
