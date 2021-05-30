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













import 'product_result_parser.dart';
import 'smsmmsresult_parser.dart';
import 'smstommstoresult_parser.dart';
import 'uriresult_parser.dart';
import 'urltoresult_parser.dart';
import 'vevent_result_parser.dart';
import 'vinresult_parser.dart';
import 'wifi_result_parser.dart';

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
import 'smtpresult_parser.dart';
import 'tel_result_parser.dart';
import 'text_parsed_result.dart';
import 'vcard_result_parser.dart';

/**
 * <p>Abstract class representing the result of decoding a barcode, as more than
 * a String -- as some type of structured data. This might be a subclass which represents
 * a URL, or an e-mail address. {@link #parseResult(Result)} will turn a raw
 * decoded string into the most appropriate type of structured representation.</p>
 *
 * <p>Thanks to Jeff Griffin for proposing rewrite of these classes that relies less
 * on exception-based mechanisms during parsing.</p>
 *
 * @author Sean Owen
 */
abstract class ResultParser {

  static final List<ResultParser> PARSERS = [
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

  static final RegExp DIGITS = RegExp("\\d+");
  static final RegExp AMPERSAND = RegExp("&");
  static final RegExp EQUALS = RegExp("=");
  static final String BYTE_ORDER_MARK = "\ufeff";

  static final List<String> EMPTY_STR_ARRAY = [];

  /**
   * Attempts to parse the raw {@link Result}'s contents as a particular type
   * of information (email, URL, etc.) and return a {@link ParsedResult} encapsulating
   * the result of parsing.
   *
   * @param theResult the raw {@link Result} to parse
   * @return {@link ParsedResult} encapsulating the parsing result
   */
  ParsedResult? parse(Result theResult);

  static String getMassagedText(Result result) {
    String text = result.getText();
    if (text.startsWith(BYTE_ORDER_MARK)) {
      text = text.substring(1);
    }
    return text;
  }

  static ParsedResult parseResult(Result theResult) {
    for (ResultParser parser in PARSERS) {
      ParsedResult? result = parser.parse(theResult);
      if (result != null) {
        return result;
      }
    }
    return TextParsedResult(theResult.getText(), null);
  }

  static void maybeAppend(String? value, StringBuffer result) {
    if (value != null) {
      result.write('\n');
      result.write(value);
    }
  }

  static void maybeAppendList(List<String>? value, StringBuffer result) {
    if (value != null) {
      for (String s in value) {
        result.write('\n');
        result.write(s);
      }
    }
  }

  static List<String>? maybeWrap(String? value) {
    return value == null ? null : [ value ];
  }

  static String unescapeBackslash(String escaped) {
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

  static int parseHexDigit(String chr) {
    int c = chr.codeUnitAt(0);
    if (c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
      return c - '0'.codeUnitAt(0);
    }
    if (c >= 'a'.codeUnitAt(0) && c <= 'f'.codeUnitAt(0)) {
      return 10 + (c - 'a'.codeUnitAt(0));
    }
    if (c >= 'A'.codeUnitAt(0) && c <= 'F'.codeUnitAt(0)) {
      return 10 + (c - 'A'.codeUnitAt(0));
    }
    return -1;
  }

  static bool isStringOfDigits(String? value, int length) {
    return value != null && length > 0 && length == value.length && DIGITS.hasMatch(value);
  }

  static bool isSubstringOfDigits(String? value, int offset, int length) {
    if (value == null || length <= 0) {
      return false;
    }
    int max = offset + length;
    return value.length >= max && DIGITS.hasMatch(value.substring(offset, max));
  }

  static Map<String,String>? parseNameValuePairs(String uri) {
    int paramStart = uri.indexOf('?');
    if (paramStart < 0) {
      return null;
    }
    Map<String,String> result = {};
    for (String keyValue in uri.substring(paramStart + 1).split(AMPERSAND)) {
      appendKeyValue(keyValue, result);
    }
    return result;
  }

  static void appendKeyValue(String keyValue, Map<String,String> result) {
    List<String> keyValueTokens = keyValue.split(EQUALS); // todo 2
    if (keyValueTokens.length == 2) {
      String key = keyValueTokens[0];
      String value = keyValueTokens[1];
      try {
        value = urlDecode(value);
        result[key] = value;
      } catch ( iae) { // IllegalArgumentException
        // continue; invalid data such as an escape like %0t
      }
    }
  }

  static String urlDecode(String encoded) {
    try {
      return urlDecode(encoded);
    } catch ( uee) { // UnsupportedEncodingException
      throw Exception(uee); // can't happen
    }
  }

  static List<String>? matchPrefixedField(String prefix, String rawText, String endChar, bool trim) {
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
        } else if (countPrecedingBackslashes(rawText, i) % 2 != 0) {
          // semicolon was escaped (odd count of preceding backslashes) so continue
          i++;
        } else {
          // found a match
          if (matches == null) {
            matches = ['','','']; // lazy init
          }
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

  static int countPrecedingBackslashes(String s, int pos) {
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

  static String? matchSinglePrefixedField(String prefix, String rawText, String endChar, bool trim) {
    List<String>? matches = matchPrefixedField(prefix, rawText, endChar, trim);
    return matches == null ? null : matches[0];
  }

}
