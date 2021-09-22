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

import 'dart:convert';
import 'dart:typed_data';

import '../../common/character_set_eci.dart';

import '../../result.dart';
import 'address_book_parsed_result.dart';
import 'result_parser.dart';

/// Parses contact information formatted according to the VCard (2.1) format. This is not a complete
/// implementation but should parse information as commonly encoded in 2D barcodes.
///
/// @author Sean Owen
class VCardResultParser extends ResultParser {
  static final RegExp _beginVcard = RegExp("BEGIN:VCARD", caseSensitive: false);
  static final RegExp _vcardLikeDate = RegExp(r"^\d{4}-?\d{2}-?\d{2}$");
  static final RegExp _crLfSpaceTab = RegExp("\r\n[ \t]");
  static final RegExp _newlineEscape = RegExp(r"\\[nN]");
  static final RegExp _vcardEscapes = RegExp(r"\\([,;\\])");
  static final Pattern _equal = "=";
  static final Pattern _semicolon = ";";
  static final RegExp _unescapedSemicolons = RegExp(r"(?<!\\);+");
  static final Pattern _comma = ",";
  static final RegExp _semicolonOrComma = RegExp("[;,]");

  @override
  AddressBookParsedResult? parse(Result result) {
    // Although we should insist on the raw text ending with "END:VCARD", there's no reason
    // to throw out everything else we parsed just because this was omitted. In fact, Eclair
    // is doing just that, and we can't parse its contacts without this leniency.
    String rawText = ResultParser.getMassagedText(result);
    if (!_beginVcard.hasMatch(rawText)) {
      return null;
    }
    List<List<String>>? names =
        matchVCardPrefixedField("FN", rawText, true, false);
    if (names == null) {
      // If no display names found, look for regular name fields and format them
      names = matchVCardPrefixedField("N", rawText, true, false);
      _formatNames(names);
    }
    List<String>? nicknameString =
        matchSingleVCardPrefixedField("NICKNAME", rawText, true, false);
    List<String>? nicknames =
        nicknameString == null ? null : nicknameString[0].split(_comma);
    List<List<String>>? phoneNumbers =
        matchVCardPrefixedField("TEL", rawText, true, false);
    List<List<String>>? emails =
        matchVCardPrefixedField("EMAIL", rawText, true, false);
    List<String>? note =
        matchSingleVCardPrefixedField("NOTE", rawText, false, false);
    List<List<String>>? addresses =
        matchVCardPrefixedField("ADR", rawText, true, true);
    List<String>? org =
        matchSingleVCardPrefixedField("ORG", rawText, true, true);
    List<String>? birthday =
        matchSingleVCardPrefixedField("BDAY", rawText, true, false);
    if (birthday != null && !_isLikeVCardDate(birthday[0])) {
      birthday = null;
    }
    List<String>? title =
        matchSingleVCardPrefixedField("TITLE", rawText, true, false);
    List<List<String>>? urls =
        matchVCardPrefixedField("URL", rawText, true, false);
    List<String>? instantMessenger =
        matchSingleVCardPrefixedField("IMPP", rawText, true, false);
    List<String>? geoString =
        matchSingleVCardPrefixedField("GEO", rawText, true, false);
    List<String>? geo =
        geoString == null ? null : geoString[0].split(_semicolonOrComma);
    if (geo != null && geo.length != 2) {
      geo = null;
    }
    return AddressBookParsedResult.full(
        _toPrimaryValues(names),
        nicknames,
        null,
        _toPrimaryValues(phoneNumbers),
        _toTypes(phoneNumbers),
        _toPrimaryValues(emails),
        _toTypes(emails),
        _toPrimaryValue(instantMessenger),
        _toPrimaryValue(note),
        _toPrimaryValues(addresses),
        _toTypes(addresses),
        _toPrimaryValue(org),
        _toPrimaryValue(birthday),
        _toPrimaryValue(title),
        _toPrimaryValues(urls),
        geo);
  }

  static List<List<String>>? matchVCardPrefixedField(
      String prefix, String rawText, bool trim, bool parseFieldDivider) {
    List<List<String>>? matches;
    int i = 0;
    int max = rawText.length;
    var reg =
        RegExp("(?:^|\n)" + prefix + "(?:;([^:]*))?:", caseSensitive: false);
    while (i < max) {
      // At start or after newline, match prefix, followed by optional metadata
      // (led by ;) ultimately ending in colon
      var regMatches = reg.allMatches(rawText, i);

      if (regMatches.isEmpty) break;
      var matcher = regMatches.first;
      i = matcher.end; // group 0 = whole pattern; end(0) is past final colon

      if (i > 0) {
        //  i--; // Find from i-1 not i since looking at the preceding character
      }

      String? metadataString = matcher.group(1); // group 1 = metadata substring
      List<String>? metadata;
      bool quotedPrintable = false;
      String? quotedPrintableCharset;
      String? valueType;
      if (metadataString != null) {
        for (String metadatum in metadataString.split(_semicolon)) {
          metadata ??= [];
          metadata.add(metadatum);
          List<String> metadatumTokens = metadatum.split(_equal); // todo , 2
          if (metadatumTokens.length > 1) {
            String key = metadatumTokens[0];
            String value = metadatumTokens[1];
            if ("ENCODING" == key.toUpperCase() &&
                "QUOTED-PRINTABLE" == value.toUpperCase()) {
              quotedPrintable = true;
            } else if ("CHARSET" == key.toUpperCase()) {
              quotedPrintableCharset = value;
            } else if ("VALUE" == key.toUpperCase()) {
              valueType = value;
            }
          }
        }
      }

      int matchStart = i; // Found the start of a match here

      while ((i = rawText.indexOf('\n', i)) >= 0) {
        // Really, end in \r\n
        if (i < rawText.length - 1 && // But if followed by tab or space,
            (rawText[i + 1] == ' ' || // this is only a continuation
                rawText[i + 1] == '\t')) {
          i += 2; // Skip \n and continutation whitespace
        } else if (quotedPrintable && // If preceded by = in quoted printable
            ((i >= 1 && rawText[i - 1] == '=') || // this is a continuation
                (i >= 2 && rawText[i - 2] == '='))) {
          i++; // Skip \n
        } else {
          break;
        }
      }

      if (i < 0) {
        // No terminating end character? uh, done. Set i such that loop terminates and break
        i = max;
      } else if (i > matchStart) {
        // found a match
        matches ??= [];
        if (i >= 1 && rawText[i - 1] == '\r') {
          i--; // Back up over \r, which really should be there
        }
        String element = rawText.substring(matchStart, i);
        if (trim) {
          element = element.trim();
        }
        if (quotedPrintable) {
          element = _decodeQuotedPrintable(element, quotedPrintableCharset);
          if (parseFieldDivider) {
            element = element.replaceAll(_unescapedSemicolons, "\n").trim();
          }
        } else {
          if (parseFieldDivider) {
            element = element.replaceAll(_unescapedSemicolons, "\n").trim();
          }
          element = element.replaceAll(_crLfSpaceTab, "");
          element = element.replaceAll(_newlineEscape, "\n");
          element = element.replaceAllMapped(_vcardEscapes, (m) => "${m[1]}");
        }
        // Only handle VALUE=uri specially
        if ("uri" == valueType) {
          // Don't actually support dereferencing URIs, but use scheme-specific part not URI
          // as value, to support tel: and mailto:
          try {
            element = Uri.parse(element).path;
          } catch (_) {
            // IllegalArgumentException
            // ignore
          }
        }
        if (metadata == null) {
          List<String> match = [];
          match.add(element);
          matches.add(match);
        } else {
          metadata.insert(0, element);
          matches.add(metadata);
        }
        i++;
      } else {
        i++;
      }
    }

    return matches;
  }

  static String _decodeQuotedPrintable(String value, String? charset) {
    int length = value.length;
    StringBuffer result = StringBuffer();
    BytesBuilder fragmentBuffer = BytesBuilder();
    for (int i = 0; i < length; i++) {
      String c = value[i];
      switch (c) {
        case '\r':
        case '\n':
          break;
        case '=':
          if (i < length - 2) {
            String nextChar = value[i + 1];
            if (nextChar != '\r' && nextChar != '\n') {
              String nextNextChar = value[i + 2];
              int firstDigit = ResultParser.parseHexDigit(nextChar);
              int secondDigit = ResultParser.parseHexDigit(nextNextChar);
              if (firstDigit >= 0 && secondDigit >= 0) {
                fragmentBuffer.addByte((firstDigit << 4) + secondDigit);
              } // else ignore it, assume it was incorrectly encoded
              i += 2;
            }
          }
          break;
        default:
          _maybeAppendFragment(fragmentBuffer, charset, result);
          result.write(c);
      }
    }
    _maybeAppendFragment(fragmentBuffer, charset, result);
    return result.toString();
  }

  static void _maybeAppendFragment(
      BytesBuilder fragmentBuffer, String? charset, StringBuffer result) {
    if (fragmentBuffer.length > 0) {
      Uint8List fragmentBytes = fragmentBuffer.takeBytes();
      String fragment;
      if (charset == null) {
        fragment = utf8.decode(fragmentBytes);
      } else {
        try {
          fragment = CharacterSetECI.getCharacterSetECIByName(charset)!
              .charset!
              .decode(fragmentBytes);
        } catch (_) {
          // UnsupportedEncodingException
          fragment = utf8.decode(fragmentBytes);
        }
      }
      fragmentBuffer.clear();
      result.write(fragment);
    }
  }

  static List<String>? matchSingleVCardPrefixedField(
      String prefix, String rawText, bool trim, bool parseFieldDivider) {
    List<List<String>>? values =
        matchVCardPrefixedField(prefix, rawText, trim, parseFieldDivider);
    return values == null || values.isEmpty ? null : values[0];
  }

  static String? _toPrimaryValue(List<String>? list) {
    return list == null || list.isEmpty ? null : list[0];
  }

  static List<String>? _toPrimaryValues(List<List<String>>? lists) {
    if (lists == null || lists.isEmpty) {
      return null;
    }
    List<String> result = [];
    for (List<String> list in lists) {
      String? value = list.isNotEmpty ? list[0] : null;
      if (value != null && value.isNotEmpty) {
        result.add(value);
      }
    }
    return result.toList();
  }

  static List<String?>? _toTypes(List<List<String>>? lists) {
    if (lists == null || lists.isEmpty) {
      return null;
    }
    List<String?> result = [];
    for (List<String> list in lists) {
      String? value = list.isNotEmpty ? list[0] : null;
      if (value != null && value.isNotEmpty) {
        String? type;
        for (int i = 1; i < list.length; i++) {
          String metadatum = list[i];
          int equals = metadatum.indexOf('=');
          if (equals < 0) {
            // take the whole thing as a usable label
            type = metadatum;
            break;
          }
          if ("TYPE" == metadatum.substring(0, equals).toUpperCase()) {
            type = metadatum.substring(equals + 1);
            break;
          }
        }
        result.add(type);
      }
    }
    return result.toList();
  }

  static bool _isLikeVCardDate(String? value) {
    return value == null || _vcardLikeDate.hasMatch(value);
  }

  /// Formats name fields of the form "Public;John;Q.;Reverend;III" into a form like
  /// "Reverend John Q. III".
  ///
  /// @param names name values to format, in place
  static void _formatNames(Iterable<List<String>>? names) {
    if (names != null) {
      for (List<String> list in names) {
        String name = list[0];
        List<String> components = List.filled(5, '');
        int start = 0;
        int end = -1;
        int componentIndex = 0;
        while (componentIndex < components.length - 1 &&
            (end = name.indexOf(';', start)) >= 0) {
          components[componentIndex] = name.substring(start, end);
          componentIndex++;
          start = end + 1;
        }
        components[componentIndex] = name.substring(start);
        StringBuffer newName = StringBuffer();
        _maybeAppendComponent(components, 3, newName);
        _maybeAppendComponent(components, 1, newName);
        _maybeAppendComponent(components, 2, newName);
        _maybeAppendComponent(components, 0, newName);
        _maybeAppendComponent(components, 4, newName);
        list[0] = newName.toString().trim();
      }
    }
  }

  static void _maybeAppendComponent(
      List<String> components, int i, StringBuffer newName) {
    if (components.length > i && components[i].isNotEmpty) {
      if (newName.length > 0) {
        newName.write(' ');
      }
      newName.write(components[i]);
    }
  }
}
