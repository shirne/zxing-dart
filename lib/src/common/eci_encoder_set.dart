/*
 * Copyright 2021 ZXing authors
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

import 'package:charset/charset.dart';

import 'character_set_eci.dart';

/// Set of CharsetEncoders for a given input string
///
/// Invariants:
/// - The list contains only encoders from CharacterSetECI (list is shorter then the list of encoders available on
///   the platform for which ECI values are defined).
/// - The list contains encoders at least one encoder for every character in the input.
/// - The first encoder in the list is always the ISO-8859-1 encoder even of no character in the input can be encoded
///       by it.
/// - If the input contains a character that is not in ISO-8859-1 then the last two entries in the list will be the
///   UTF-8 encoder and the UTF-16BE encoder.
///
/// @author Alex Geller
class ECIEncoderSet {
  // List of encoders that potentially encode characters not in ISO-8859-1 in one byte.
  /* private */ static final List<Encoding> ENCODERS = [
    "IBM437",
    "ISO-8859-2",
    "ISO-8859-3",
    "ISO-8859-4",
    "ISO-8859-5",
    "ISO-8859-6",
    "ISO-8859-7",
    "ISO-8859-8",
    "ISO-8859-9",
    "ISO-8859-10",
    "ISO-8859-11",
    "ISO-8859-13",
    "ISO-8859-14",
    "ISO-8859-15",
    "ISO-8859-16",
    "windows-1250",
    "windows-1251",
    "windows-1252",
    "windows-1256",
    "Shift_JIS"
  ]
      .map<Encoding?>(
          (name) => CharacterSetECI.getCharacterSetECIByName(name)?.charset)
      .whereType<Encoding>()
      .toList();

  final List<Encoding> encoders = [];
  late int _priorityEncoderIndex;

  /// Constructs an encoder set
  ///
  /// @param stringToEncode the string that needs to be encoded
  /// @param priorityCharset The preferred {@link Charset} or null.
  /// @param fnc1 fnc1 denotes the character in the input that represents the FNC1 character or -1 for a non-GS1 bar
  /// code. When specified, it is considered an error to pass it as argument to the methods canEncode() or encode().
  ECIEncoderSet(String stringToEncode, Encoding? priorityCharset, int fnc1) {
    List<Encoding> neededEncoders = [];

    //we always need the ISO-8859-1 encoder. It is the default encoding
    neededEncoders.add(Latin1Codec());
    bool needUnicodeEncoder =
        priorityCharset != null && priorityCharset.name.startsWith("UTF");

    //Walk over the input string and see if all characters can be encoded with the list of encoders
    for (int i = 0; i < stringToEncode.length; i++) {
      bool canEncode = false;
      for (Encoding encoder in neededEncoders) {
        int c = stringToEncode.codeUnitAt(i);
        if (c == fnc1 || Charset.canDecode(encoder, [c])) {
          canEncode = true;
          break;
        }
      }

      if (!canEncode) {
        //for the character at position i we don't yet have an encoder in the list
        for (Encoding encoder in ENCODERS) {
          if (Charset.canDecode(encoder, [stringToEncode.codeUnitAt(i)])) {
            //Good, we found an encoder that can encode the character. We add him to the list and continue scanning
            //the input
            neededEncoders.add(encoder);
            canEncode = true;
            break;
          }
        }
      }

      if (!canEncode) {
        //The character is not encodeable by any of the single byte encoders so we remember that we will need a
        //Unicode encoder.
        needUnicodeEncoder = true;
      }
    }

    if (neededEncoders.length == 1 && !needUnicodeEncoder) {
      //the entire input can be encoded by the ISO-8859-1 encoder
      encoders.add(neededEncoders[0]);
    } else {
      // we need more than one single byte encoder or we need a Unicode encoder.
      // In this case we append a UTF-8 and UTF-16 encoder to the list
      encoders.addAll(neededEncoders);
      encoders.add(Utf8Codec());
      encoders.add(Utf16Codec());
    }

    //Compute priorityEncoderIndex by looking up priorityCharset in encoders
    int priorityEncoderIndexValue = -1;
    if (priorityCharset != null) {
      for (int i = 0; i < encoders.length; i++) {
        if (priorityCharset.name == encoders[i].name) {
          priorityEncoderIndexValue = i;
          break;
        }
      }
    }
    _priorityEncoderIndex = priorityEncoderIndexValue;
    //invariants
    assert(encoders[0].name == latin1.name);
  }

  int get length {
    return encoders.length;
  }

  String getCharsetName(int index) {
    assert(index < length);
    return encoders[index].name;
  }

  Encoding getCharset(int index) {
    assert(index < length);
    return encoders[index];
  }

  int getECIValue(int encoderIndex) {
    return CharacterSetECI.getCharacterSetECI(encoders[encoderIndex])?.value ??
        0;
  }

  ///  returns -1 if no priority charset was defined
  int get priorityEncoderIndex {
    return _priorityEncoderIndex;
  }

  bool canEncode(int c, int encoderIndex) {
    assert(encoderIndex < length);
    Encoding encoder = encoders[encoderIndex];
    return Charset.canEncode(encoder, String.fromCharCode(c));
  }

  Uint8List encode(dynamic s, int encoderIndex) {
    assert(encoderIndex < length);
    Encoding encoder = encoders[encoderIndex];
    if (s is int) {
      assert(Charset.canEncode(encoder, String.fromCharCode(s)));
      return Uint8List.fromList(encoder.encode(String.fromCharCode(s)));
    }
    return Uint8List.fromList(encoder.encode(s));
  }
}
