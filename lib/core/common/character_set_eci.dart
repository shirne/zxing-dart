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

/**
 * Encapsulates a Character Set ECI, according to "Extended Channel Interpretations" 5.3.1.1
 * of ISO 18004.
 *
 * @author Sean Owen
 */
class CharacterSetECI {
  // Enum name is a Java encoding valid for java.lang and java.io
  static final Cp437 = CharacterSetECI('Cp437', [0, 2]);
  static final ISO8859_1 = CharacterSetECI('ISO8859_1', [1, 3], "ISO-8859-1");
  static final ISO8859_2 = CharacterSetECI('ISO8859_2', 4, "ISO-8859-2");
  static final ISO8859_3 = CharacterSetECI('ISO8859_3', 5, "ISO-8859-3");
  static final ISO8859_4 = CharacterSetECI('ISO8859_4', 6, "ISO-8859-4");
  static final ISO8859_5 = CharacterSetECI('ISO8859_5', 7, "ISO-8859-5");
  static final ISO8859_6 = CharacterSetECI('ISO8859_6', 8, "ISO-8859-6");
  static final ISO8859_7 = CharacterSetECI('ISO8859_7', 9, "ISO-8859-7");
  static final ISO8859_8 = CharacterSetECI('ISO8859_8', 10, "ISO-8859-8");
  static final ISO8859_9 = CharacterSetECI('ISO8859_9', 11, "ISO-8859-9");
  static final ISO8859_10 = CharacterSetECI('ISO8859_10', 12, "ISO-8859-10");
  static final ISO8859_11 = CharacterSetECI('ISO8859_11', 13, "ISO-8859-11");
  static final ISO8859_13 = CharacterSetECI('ISO8859_13', 15, "ISO-8859-13");
  static final ISO8859_14 = CharacterSetECI('ISO8859_14', 16, "ISO-8859-14");
  static final ISO8859_15 = CharacterSetECI('ISO8859_15', 17, "ISO-8859-15");
  static final ISO8859_16 = CharacterSetECI('ISO8859_16', 18, "ISO-8859-16");
  static final SJIS = CharacterSetECI('SJIS', 20, "Shift_JIS");
  static final Cp1250 = CharacterSetECI('Cp1250', 21, "windows-1250");
  static final Cp1251 = CharacterSetECI('Cp1251', 22, "windows-1251");
  static final Cp1252 = CharacterSetECI('Cp1252', 23, "windows-1252");
  static final Cp1256 = CharacterSetECI('Cp1256', 24, "windows-1256");
  static final UnicodeBigUnmarked =
      CharacterSetECI('UnicodeBigUnmarked', 25, ["UTF-16BE", "UnicodeBig"]);
  static final UTF8 = CharacterSetECI('UTF8', 26, "UTF-8");
  static final ASCII = CharacterSetECI('ASCII', [27, 170], "US-ASCII");
  static final Big5 = CharacterSetECI('Big5', 28);
  static final GB18030 =
      CharacterSetECI('GB18030', 29, ["GB2312", "EUC_CN", "GBK"]);
  static final EUC_KR = CharacterSetECI('EUC_KR', 30, "EUC-KR");

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
  static final Map<int, CharacterSetECI> VALUE_TO_ECI = {};
  static final Map<String, CharacterSetECI> NAME_TO_ECI = {};
  static init() {
    for (CharacterSetECI eci in values) {
      for (int value in eci.indexs) {
        VALUE_TO_ECI[value] = eci;
      }
      NAME_TO_ECI[eci.name] = eci;
      for (String name in eci.otherEncodingNames) {
        NAME_TO_ECI[name] = eci;
      }
    }
  }

  final List<int> indexs;
  final String name;
  final List<String> otherEncodingNames;

  CharacterSetECI(this.name, dynamic value, [dynamic otherEncodingNames])
      : indexs = (value is int) ? [value] : value as List<int>,
        otherEncodingNames =
            (otherEncodingNames == null || otherEncodingNames is String)
                ? [otherEncodingNames]
                : otherEncodingNames as List<String>;

  int getValue() {
    return indexs[0];
  }

  Encoding? getCharset() {
    return Encoding.getByName(name);
  }

  /**
   * @param charset Java character set object
   * @return CharacterSetECI representing ECI for character encoding, or null if it is legal
   *   but unsupported
   */
  static CharacterSetECI getCharacterSetECI(Encoding charset) {
    if (NAME_TO_ECI.isEmpty) {
      init();
    }
    return NAME_TO_ECI[charset.name]!;
  }

  /**
   * @param value character set ECI value
   * @return {@code CharacterSetECI} representing ECI of given value, or null if it is legal but
   *   unsupported
   * @throws FormatException if ECI value is invalid
   */
  static CharacterSetECI? getCharacterSetECIByValue(int value) {
    if (value < 0 || value >= 900) {
      throw FormatException();
    }
    if (VALUE_TO_ECI.isEmpty) {
      init();
    }
    return VALUE_TO_ECI[value];
  }

  /**
   * @param name character set ECI encoding name
   * @return CharacterSetECI representing ECI for character encoding, or null if it is legal
   *   but unsupported
   */
  static CharacterSetECI? getCharacterSetECIByName(String name) {
    return NAME_TO_ECI[name];
  }
}
