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

import 'dart:convert';

import '../../result.dart';
import 'address_book_auresult_parser.dart';
import 'address_book_do_co_mo_result_parser.dart';
import 'bizcard_result_parser.dart';
import 'bookmark_do_co_mo_result_parser.dart';
import 'email_address_result_parser.dart';
import 'email_do_co_mo_result_parser.dart';
import 'expanded_product_result_parser.dart';
import 'geo_result_parser.dart';
import 'isbnresult_parser.dart';
import 'parsed_result.dart';
import 'product_result_parser.dart';
import 'smsmmsresult_parser.dart';
import 'smstommstoresult_parser.dart';
import 'smtpresult_parser.dart';
import 'tel_result_parser.dart';
import 'text_parsed_result.dart';
import 'uriresult_parser.dart';
import 'urltoresult_parser.dart';
import 'vcard_result_parser.dart';
import 'vevent_result_parser.dart';
import 'vinresult_parser.dart';
import 'wifi_result_parser.dart';

/// Abstract class representing the result of decoding a barcode, as more than
/// a String -- as some type of structured data.
///
/// This might be a subclass which represents a URL, or an e-mail address.
/// [parseResult(Result)] will turn a raw decoded string into the
/// most appropriate type of structured representation.
///
/// @author Sean Owen
abstract class ResultParser {
  static final List<ResultParser> _parsers = [
    BookmarkDoCoMoResultParser(),
    AddressBookDoCoMoResultParser(),
    EmailDoCoMoResultParser(),
    AddressBookAUResultParser(),
    VCardResultParser(),
    BizcardResultParser(),
    VEventResultParser(),
    EmailAddressResultParser(),
    SMTPResultParser(),
    TelResultParser(),
    SMSMMSResultParser(),
    SMSTOMMSTOResultParser(),
    GeoResultParser(),
    WifiResultParser(),
    URLTOResultParser(),
    URIResultParser(),
    ISBNResultParser(),
    ProductResultParser(),
    ExpandedProductResultParser(),
    VINResultParser(),
  ];

  static final RegExp _digits = RegExp(r"^\d+$");
  static final Pattern _ampersand = "&";
  static final Pattern _equals = "=";
  static final String _byteOrderMark = "\ufeff";

  static final List<String> emptyStrArray = [];

  /// Attempts to parse the raw [Result]'s contents as a particular type
  /// of information (email, URL, etc.) and return a [ParsedResult] encapsulating
  /// the result of parsing.
  ///
  /// @param theResult the raw [Result] to parse
  /// @return [ParsedResult] encapsulating the parsing result
  ParsedResult? parse(Result result);

  static ParsedResult parseResult(Result result) {
    for (ResultParser parser in _parsers) {
      ParsedResult? theResult = parser.parse(result);
      if (theResult != null) {
        return theResult;
      }
    }
    return TextParsedResult(result.text, null);
  }

  static String getMassagedText(Result result) {
    String text = result.text;
    if (text.startsWith(_byteOrderMark)) {
      text = text.substring(1);
    }
    return text;
  }

  //@protected
  List<String>? maybeWrap(String? value) {
    return value == null ? null : [value];
  }

  //@protected
  String unescapeBackslash(String escaped) {
    int backslash = escaped.indexOf('\\');
    if (backslash < 0) {
      return escaped;
    }
    int max = escaped.length;
    StringBuffer unescaped = StringBuffer();
    unescaped.write(escaped.substring(0, backslash));
    bool nextIsEscaped = false;
    for (int i = backslash; i < max; i++) {
      String c = escaped[i];
      if (nextIsEscaped || c != '\\') {
        unescaped.write(c);
        nextIsEscaped = false;
      } else {
        nextIsEscaped = true;
      }
    }
    return unescaped.toString();
  }

  //@protected
  static int parseHexDigit(String chr) {
    int c = chr.codeUnitAt(0);
    if (c >= 48 /*'0'*/ && c <= 57 /*'9'*/) {
      return c - 48;
    }
    if (c >= 97 /*'a'*/ && c <= 102 /*'f'*/) {
      return 10 + (c - 97);
    }
    if (c >= 65 /*'A'*/ && c <= 70 /*'F'*/) {
      return 10 + (c - 65);
    }
    return -1;
  }

  //@protected
  bool isStringOfDigits(String? value, int length) {
    return value != null &&
        length > 0 &&
        length == value.length &&
        _digits.hasMatch(value);
  }

  // @protected
  static bool isSubstringOfDigits(String? value, int offset, int length) {
    if (value == null || length <= 0) {
      return false;
    }
    int max = offset + length;
    return value.length >= max &&
        _digits.hasMatch(value.substring(offset, max));
  }

  Map<String, String>? parseNameValuePairs(String uri) {
    int paramStart = uri.indexOf('?');
    if (paramStart < 0) {
      return null;
    }
    Map<String, String> result = {};
    for (String keyValue in uri.substring(paramStart + 1).split(_ampersand)) {
      _appendKeyValue(keyValue, result);
    }
    return result;
  }

  void _appendKeyValue(String keyValue, Map<String, String> result) {
    List<String> keyValueTokens = keyValue.split(_equals); // todo 2
    if (keyValueTokens.length == 2) {
      String key = keyValueTokens[0];
      String value = keyValueTokens[1];
      try {
        value = urlDecode(value);
        result[key] = value;
      } catch (_) {
        // IllegalArgumentException
        // continue; invalid data such as an escape like %0t
      }
    }
  }

  String urlDecode(String encoded) {
    try {
      //todo decodeFull or decodeComponent or decodeQueryComponent ?
      return Uri.decodeQueryComponent(encoded, encoding: utf8);
    } catch (_) {
      // UnsupportedEncodingException
      rethrow; // can't happen
    }
  }

  List<String>? matchPrefixedField(
      String prefix, String rawText, String endChar, bool trim) {
    List<String>? matches;
    int i = 0;
    int max = rawText.length;
    while (i < max) {
      i = rawText.indexOf(prefix, i);
      if (i < 0) {
        break;
      }
      i += prefix.length; // Skip past this prefix we found to start
      int start = i; // Found the start of a match here
      bool more = true;
      while (more) {
        i = rawText.indexOf(endChar, i);
        if (i < 0) {
          // No terminating end character? uh, done. Set i such that loop terminates and break
          i = rawText.length;
          more = false;
        } else if (_countPrecedingBackslashes(rawText, i) % 2 != 0) {
          // semicolon was escaped (odd count of preceding backslashes) so continue
          i++;
        } else {
          // found a match
          matches ??= [];
          String element = unescapeBackslash(rawText.substring(start, i));
          if (trim) {
            element = element.trim();
          }
          if (element.isNotEmpty) {
            matches.add(element);
          }
          i++;
          more = false;
        }
      }
    }
    if (matches == null || matches.isEmpty) {
      return null;
    }
    return matches.toList();
  }

  int _countPrecedingBackslashes(String s, int pos) {
    int count = 0;
    for (int i = pos - 1; i >= 0; i--) {
      if (s[i] == '\\') {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  String? matchSinglePrefixedField(
      String prefix, String rawText, String endChar, bool trim) {
    List<String>? matches = matchPrefixedField(prefix, rawText, endChar, trim);
    return matches == null ? null : matches[0];
  }
}
