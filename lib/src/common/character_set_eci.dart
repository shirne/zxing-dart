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

import '../formats_exception.dart';

// ignore_for_file: non_constant_identifier_names

/// Encapsulates a Character Set ECI, according to "Extended Channel Interpretations" 5.3.1.1
/// of ISO 18004.
///
/// @author Sean Owen
class CharacterSetECI {
  // Enum name is a Java encoding valid for java.lang and java.io
  static final Cp437 = CharacterSetECI('cp437', [0, 2]);
  static final ISO8859_1 =
      CharacterSetECI('iso-8859-1', [1, 3], ['latin-1', 'iso8859_1']);
  static final ISO8859_2 =
      CharacterSetECI('iso-8859-2', 4, ['latin-2', 'iso8859_2']);
  static final ISO8859_3 =
      CharacterSetECI('iso-8859-3', 5, ['latin-3', 'iso8859_3']);
  static final ISO8859_4 =
      CharacterSetECI('iso-8859-4', 6, ['latin-4', 'iso8859_4']);
  static final ISO8859_5 =
      CharacterSetECI('iso-8859-5', 7, ['cyrillic', 'iso8859_5']);
  //static final ISO8859_6 =
  //    CharacterSetECI('iso-8859-6', 8, ['arabic', 'iso8859_6']);
  static final ISO8859_7 =
      CharacterSetECI('iso-8859-7', 9, ['greek', 'iso8859_7']);
  //static final ISO8859_8 =
  //    CharacterSetECI('iso-8859-8', 10, ['hebrew', 'iso8859_8']);
  static final ISO8859_9 =
      CharacterSetECI('iso-8859-9', 11, ['latin-5', 'iso8859_9']);
  //static final ISO8859_10 =
  //    CharacterSetECI('iso-8859-10', 12, ['latin-6', 'iso8859_10']);
  //static final ISO8859_11 =
  //    CharacterSetECI('iso-8859-11', 13, ['tis620', 'iso8859_11']);
  static final ISO8859_13 =
      CharacterSetECI('iso-8859-13', 15, ['latin-7', 'iso8859_13']);
  //static final ISO8859_14 =
  //    CharacterSetECI('iso-8859-14', 16, ['latin-8', 'iso8859_14']);
  static final ISO8859_15 =
      CharacterSetECI('iso-8859-15', 17, ['latin-9', 'iso8859_15']);
  static final ISO8859_16 =
      CharacterSetECI('iso-8859-16', 18, ['latin-10', 'iso8859_16']);
  static final SJIS = CharacterSetECI(
      'shift-jis', 20, ['sjis', 'shift_jis', 'ms932', 'iso-2022-jp', 'jis']);
  static final Cp1250 =
      CharacterSetECI('cp1250', 21, ['windows-1250', 'windows1250']);
  static final Cp1251 =
      CharacterSetECI('cp1251', 22, ['windows-1251', 'windows1251']);
  static final Cp1252 =
      CharacterSetECI('cp1252', 23, ['windows-1252', 'windows1252']);
  static final Cp1256 =
      CharacterSetECI('cp1256', 24, ['windows-1256', 'windows1256']);
  static final UnicodeBigUnmarked = CharacterSetECI('utf-16', 25,
      ['utf-16be', 'unicode-big-unmarked', 'utf-16be', 'unicode-big']);
  static final UTF8 = CharacterSetECI('utf-8', 26, ['utf8']);
  static final ASCII =
      CharacterSetECI('ascii', [27, 170], ['us-ascii', 'ascii']);
  static final Big5 = CharacterSetECI('big5', 28);
  static final GB18030 =
      CharacterSetECI('gb18030', 29, ['gb-2312', 'gb2312', 'euc_cn', 'gbk']);

  // EUC-KR, KS_C_5601 and KS X 1001
  static final EUC_KR = CharacterSetECI('euc_kr', 30, ['ks_c_5601', 'euc-kr']);

  static final values = [
    Cp437,
    ISO8859_1,
    ISO8859_2,
    ISO8859_3,
    ISO8859_4,
    ISO8859_5,
    //ISO8859_6,
    ISO8859_7,
    //ISO8859_8,
    ISO8859_9,
    //ISO8859_10,
    //ISO8859_11,
    ISO8859_13,
    //ISO8859_14,
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

  CharacterSetECI(this.name, dynamic value, [dynamic otherEncodingNames])
      : _indexes = (value is int) ? [value] : value as List<int>,
        _otherEncodingNames =
            (otherEncodingNames == null || otherEncodingNames is String)
                ? [if (otherEncodingNames != null) otherEncodingNames]
                : otherEncodingNames as List<String>;

  int get value => _indexes[0];

  Encoding? get charset => Charset.getByName(name);

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
    return _nameToEci[name.toLowerCase()];
  }
}
