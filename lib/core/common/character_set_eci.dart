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

import 'package:fast_gbk/fast_gbk.dart';
import 'package:unicode/unicode.dart';

import '../encoding/euc_kr.dart';
import '../encoding/cp437.dart';
import '../formats_exception.dart';
import 'string_utils.dart';

/// Encapsulates a Character Set ECI, according to "Extended Channel Interpretations" 5.3.1.1
/// of ISO 18004.
///
/// @author Sean Owen
class CharacterSetECI {
  // Enum name is a Java encoding valid for java.lang and java.io
  static final Cp437 = CharacterSetECI('Cp437', [0, 2], cp437);
  static final ISO8859_1 = CharacterSetECI('ISO8859_1', [1, 3], latin1, ['ISO-8859-1', 'iso-8859-1']);
  static final ISO8859_2 = CharacterSetECI('ISO8859_2', 4, latin1, ['ISO-8859-2', 'iso-8859-2']);
  static final ISO8859_3 = CharacterSetECI('ISO8859_3', 5, latin1, ['ISO-8859-3', 'iso-8859-3']);
  static final ISO8859_4 = CharacterSetECI('ISO8859_4', 6, latin1, ['ISO-8859-4', 'iso-8859-4']);
  static final ISO8859_5 = CharacterSetECI('ISO8859_5', 7, latin1, ['ISO-8859-5', 'iso-8859-5']);
  static final ISO8859_6 = CharacterSetECI('ISO8859_6', 8, latin1, ['ISO-8859-6', 'iso-8859-6']);
  static final ISO8859_7 = CharacterSetECI('ISO8859_7', 9, latin1, ['ISO-8859-7', 'iso-8859-7']);
  static final ISO8859_8 = CharacterSetECI('ISO8859_8', 10, latin1, ['ISO-8859-8', 'iso-8859-8']);
  static final ISO8859_9 = CharacterSetECI('ISO8859_9', 11, latin1, ['ISO-8859-9', 'iso-8859-9']);
  static final ISO8859_10 = CharacterSetECI('ISO8859_10', 12, latin1, ['ISO-8859-10', 'iso-8859-10']);
  static final ISO8859_11 = CharacterSetECI('ISO8859_11', 13, latin1, ['ISO-8859-11', 'iso-8859-11']);
  static final ISO8859_13 = CharacterSetECI('ISO8859_13', 15, latin1, ['ISO-8859-13', 'iso-8859-13']);
  static final ISO8859_14 = CharacterSetECI('ISO8859_14', 16, latin1, ['ISO-8859-14', 'iso-8859-14']);
  static final ISO8859_15 = CharacterSetECI('ISO8859_15', 17, latin1, ['ISO-8859-15', 'iso-8859-15']);
  static final ISO8859_16 = CharacterSetECI('ISO8859_16', 18, latin1, ['ISO-8859-16', 'iso-8859-16']);
  static final SJIS = CharacterSetECI('SJIS', 20, StringUtils.shiftJisCharset, ['Shift_JIS', 'shift-jis', 'ms932', 'ISO-2022-JP', 'JIS']);
  static final Cp1250 = CharacterSetECI('Cp1250', 21, latin1, 'windows-1250');
  static final Cp1251 = CharacterSetECI('Cp1251', 22, latin1, 'windows-1251');
  static final Cp1252 = CharacterSetECI('Cp1252', 23, latin1, 'windows-1252');
  static final Cp1256 = CharacterSetECI('Cp1256', 24, latin1, 'windows-1256');
  static final UnicodeBigUnmarked =
      CharacterSetECI('UnicodeBigUnmarked', 25, utf16, ['UTF-16BE', 'utf-16', 'utf-16be', 'UnicodeBig']);
  static final UTF8 = CharacterSetECI('UTF8', 26, utf8, ['UTF-8', 'utf-8']);
  static final ASCII = CharacterSetECI('ASCII', [27, 170], ascii, ['US-ASCII', 'us-ascii', 'ascii']);
  static final Big5 = CharacterSetECI('Big5', 28, gbk);
  static final GB18030 =
      CharacterSetECI('GB18030', 29, gbk, ['GB2312', 'gb2312', 'EUC_CN', 'GBK', 'gbk']);
  static final EUC_KR = CharacterSetECI('EUC_KR', 30, eucKr, ['EUC-KR', 'euc-kr']); // EUC-KR, KS_C_5601 and KS X 1001

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
      for (int value in eci._indexs) {
        _valueToEci[value] = eci;
      }
      _nameToEci[eci.name] = eci;
      for (String name in eci._otherEncodingNames) {
        _nameToEci[name] = eci;
      }
    }
  }

  final List<int> _indexs;
  final String name;
  final List<String> _otherEncodingNames;
  final Encoding? _charset;

  CharacterSetECI(this.name, dynamic value, this._charset, [dynamic otherEncodingNames])
      : _indexs = (value is int) ? [value] : value as List<int>,
        _otherEncodingNames =
            (otherEncodingNames == null || otherEncodingNames is String)
                ? [if(otherEncodingNames != null)otherEncodingNames]
                : otherEncodingNames as List<String>;

  int getValue() {
    return _indexs[0];
  }

  Encoding? getCharset() {
    return _charset;
  }

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
  /// @return {@code CharacterSetECI} representing ECI of given value, or null if it is legal but
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
