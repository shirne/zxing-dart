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

import 'package:charset/charset.dart';
import 'package:convert/convert.dart';

import '../formats_exception.dart';
import 'string_utils.dart';

/// Encapsulates a Character Set ECI, according to "Extended Channel Interpretations" 5.3.1.1
/// of ISO 18004.
///
/// @author Sean Owen
class CharacterSetECI {
  // Enum name is a Java encoding valid for java.lang and java.io
  static final Cp437 = CharacterSetECI('cp437', [0, 2], cp437);
  static final ISO8859_1 = CharacterSetECI('iso8859_1', [1, 3], latin1, ['latin-1', 'iso-8859-1']);
  static final ISO8859_2 = CharacterSetECI('iso8859_2', 4, latin2, ['latin-2', 'iso-8859-2']);
  static final ISO8859_3 = CharacterSetECI('iso8859_3', 5, latin3, ['latin-3', 'iso-8859-3']);
  static final ISO8859_4 = CharacterSetECI('iso8859_4', 6, latin4, ['latin-4', 'iso-8859-4']);
  static final ISO8859_5 = CharacterSetECI('iso8859_5', 7, latinCyrillic, ['cyrillic', 'iso-8859-5']);
  static final ISO8859_6 = CharacterSetECI('iso8859_6', 8, latinArabic, ['arabic', 'iso-8859-6']);
  static final ISO8859_7 = CharacterSetECI('iso8859_7', 9, latinGreek, ['greek', 'iso-8859-7']);
  static final ISO8859_8 = CharacterSetECI('iso8859_8', 10, latinHebrew, ['hebrew', 'iso-8859-8']);
  static final ISO8859_9 = CharacterSetECI('iso8859_9', 11, latin5, ['latin-5', 'iso-8859-9']);
  static final ISO8859_10 = CharacterSetECI('iso8859_10', 12, latin6, ['latin-6', 'iso-8859-10']);
  static final ISO8859_11 = CharacterSetECI('iso8859_11', 13, latinThai, ['tis620', 'iso-8859-11']);
  static final ISO8859_13 = CharacterSetECI('iso8859_13', 15, latin7, ['latin-7', 'iso-8859-13']);
  static final ISO8859_14 = CharacterSetECI('iso8859_14', 16, latin8, ['latin-8', 'iso-8859-14']);
  static final ISO8859_15 = CharacterSetECI('iso8859_15', 17, latin9, ['latin-9', 'iso-8859-15']);
  static final ISO8859_16 = CharacterSetECI('iso8859_16', 18, latin10, ['latin-10', 'iso-8859-16']);
  static final SJIS = CharacterSetECI('sjis', 20, StringUtils.shiftJisCharset, ['shift-jis', 'ms932', 'iso-2022-jp', 'jis']);
  static final Cp1250 = CharacterSetECI('cp1250', 21, cp437, 'windows-1250');
  static final Cp1251 = CharacterSetECI('cp1251', 22, cp437, 'windows-1251');
  static final Cp1252 = CharacterSetECI('cp1252', 23, cp437, 'windows-1252');
  static final Cp1256 = CharacterSetECI('cp1256', 24, cp437, 'windows-1256');
  static final UnicodeBigUnmarked =
      CharacterSetECI('unicode-big-unmarked', 25, utf16, ['utf-16be', 'utf-16', 'utf-16be', 'unicode-big']);
  static final UTF8 = CharacterSetECI('utf8', 26, utf8, ['utf-8']);
  static final ASCII = CharacterSetECI('ascii', [27, 170], ascii, ['us-ascii', 'ascii']);
  static final Big5 = CharacterSetECI('big5', 28, gbk);
  static final GB18030 =
      CharacterSetECI('gb18030', 29, gbk, ['gb-2312', 'gb2312', 'euc_cn', 'gbk']);
  static final EUC_KR = CharacterSetECI('euc_kr', 30, eucKr, ['ks_c_5601', 'euc-kr']); // EUC-KR, KS_C_5601 and KS X 1001

  static final values = [
    Cp437,
    ISO8859_1,
    ISO8859_2,
    ISO8859_3,
    ISO8859_4,
    ISO8859_5,
    ISO8859_6,
    ISO8859_7,
    ISO8859_8,
    ISO8859_9,
    ISO8859_10,
    ISO8859_11,
    ISO8859_13,
    ISO8859_14,
    ISO8859_15,
    ISO8859_16,
    SJIS,
    Cp1250,
    Cp1251,
    Cp1252,
    Cp1256,
    UnicodeBigUnmarked,
    UTF8,
    ASCII,
    Big5,
    GB18030,
    EUC_KR,
  ];
  static final Map<int, CharacterSetECI> _valueToEci = {};
  static final Map<String, CharacterSetECI> _nameToEci = {};
  static init() {
    for (CharacterSetECI eci in values) {
      for (int value in eci._indexes) {
        _valueToEci[value] = eci;
      }
      _nameToEci[eci.name] = eci;
      for (String name in eci._otherEncodingNames) {
        _nameToEci[name] = eci;
      }
    }
  }

  final List<int> _indexes;
  final String name;
  final List<String> _otherEncodingNames;
  final Encoding? _charset;

  CharacterSetECI(this.name, dynamic value, this._charset, [dynamic otherEncodingNames])
      : _indexes = (value is int) ? [value] : value as List<int>,
        _otherEncodingNames =
            (otherEncodingNames == null || otherEncodingNames is String)
                ? [if(otherEncodingNames != null)otherEncodingNames]
                : otherEncodingNames as List<String>;

  int get value => _indexes[0];

  Encoding? get charset => _charset;

  /// @param charset Java character set object
  /// @return CharacterSetECI representing ECI for character encoding, or null if it is legal
  ///   but unsupported
  static CharacterSetECI? getCharacterSetECI(Encoding charset) {
    if (_nameToEci.isEmpty) {
      init();
    }
    return _nameToEci[charset.name];
  }

  /// @param value character set ECI value
  /// @return `CharacterSetECI` representing ECI of given value, or null if it is legal but
  ///   unsupported
  /// @throws FormatException if ECI value is invalid
  static CharacterSetECI? getCharacterSetECIByValue(int value) {
    if (value < 0 || value >= 900) {
      throw FormatsException.instance;
    }
    if (_valueToEci.isEmpty) {
      init();
    }
    return _valueToEci[value];
  }

  /// @param name character set ECI encoding name
  /// @return CharacterSetECI representing ECI for character encoding, or null if it is legal
  ///   but unsupported
  static CharacterSetECI? getCharacterSetECIByName(String name) {
    if (_nameToEci.isEmpty) {
      init();
    }
    return _nameToEci[name];
  }
}
