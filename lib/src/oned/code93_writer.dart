/*
 * Copyright 2015 ZXing authors
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

import '../barcode_format.dart';
import '../encode_hint_type.dart';
import 'code93_reader.dart';
import 'one_dimensional_code_writer.dart';

/// This object renders a CODE93 code as a BitMatrix
class Code93Writer extends OneDimensionalCodeWriter {
  // @protected
  @override
  List<BarcodeFormat> get supportedWriteFormats => [BarcodeFormat.code93];

  /// @param contents barcode contents to encode. It should not be encoded for extended characters.
  /// @return a {@code List<bool>} of horizontal pixels (false = white, true = black)
  @override
  List<bool> encodeContent(
    String contents, [
    Map<EncodeHintType, Object?>? hints,
  ]) {
    contents = convertToExtended(contents);
    final length = contents.length;
    if (length > 80) {
      throw ArgumentError(
        'Requested contents should be less than 80 digits long '
        'after converting to extended encoding, but got $length',
      );
    }

    //length of code + 2 start/stop characters + 2 checksums, each of 9 bits, plus a termination bar
    final codeWidth = (contents.length + 2 + 2) * 9 + 1;

    final result = List.filled(codeWidth, false);

    //start character (*)
    int pos = _appendPattern(result, 0, Code93Reader.asteriskEncoding);

    for (int i = 0; i < length; i++) {
      final indexInString = Code93Reader.alphabetString.indexOf(contents[i]);
      pos += _appendPattern(
        result,
        pos,
        Code93Reader.characterEncodings[indexInString],
      );
    }

    //add two checksums
    final check1 = _computeChecksumIndex(contents, 20);
    pos += _appendPattern(result, pos, Code93Reader.characterEncodings[check1]);

    //append the contents to reflect the first checksum added
    contents += Code93Reader.alphabetString[check1];

    final check2 = _computeChecksumIndex(contents, 15);
    pos += _appendPattern(result, pos, Code93Reader.characterEncodings[check2]);

    //end character (*)
    pos += _appendPattern(result, pos, Code93Reader.asteriskEncoding);

    //termination bar (single black bar)
    result[pos] = true;

    return result;
  }

  /// @param target output to append to
  /// @param pos start position
  /// @param pattern pattern to append
  /// @param startColor unused
  /// @return 9
  /// @deprecated without replacement; intended as an internal-only method
  @Deprecated('not replacement; intended as an internal-only method')
  static int appendPatternDpr(
    List<bool> target,
    int pos,
    List<int> pattern,
    bool startColor,
  ) {
    for (int bit in pattern) {
      target[pos++] = bit != 0;
    }
    return 9;
  }

  static int _appendPattern(List<bool> target, int pos, int a) {
    for (int i = 0; i < 9; i++) {
      final temp = a & (1 << (8 - i));
      target[pos + i] = temp != 0;
    }
    return 9;
  }

  static int _computeChecksumIndex(String contents, int maxWeight) {
    int weight = 1;
    int total = 0;

    for (int i = contents.length - 1; i >= 0; i--) {
      final indexInString = Code93Reader.alphabetString.indexOf(contents[i]);
      total += indexInString * weight;
      if (++weight > maxWeight) {
        weight = 1;
      }
    }
    return total % 47;
  }

  static String convertToExtended(String contents) {
    final length = contents.length;
    final extCont = StringBuffer();
    for (int i = 0; i < length; i++) {
      final character = contents.codeUnitAt(i);
      // ($)=a, (%)=b, (/)=c, (+)=d. see Code93Reader.ALPHABET_STRING
      if (character == 0) {
        // NUL: (%)U
        extCont.write('bU');
      } else if (character <= 26) {
        // SOH - SUB: ($)A - ($)Z
        extCont.write('a');
        extCont.writeCharCode(65 /* A */ + character - 1);
      } else if (character <= 31) {
        // ESC - US: (%)A - (%)E
        extCont.write('b');
        extCont.writeCharCode(65 /* A */ + character - 27);
      } else if (character == 32 /*   */ ||
          character == 36 /* $ */ ||
          character == 37 /* % */ ||
          character == 43 /* + */) {
        // space $ % +
        extCont.writeCharCode(character);
      } else if (character <= 44 /* , */) {
        // ! " # & ' ( ) * ,: (/)A - (/)L
        extCont.write('c');
        extCont.writeCharCode(65 /* A */ + character - 33 /* ! */);
      } else if (character <= 57 /* 9 */) {
        extCont.writeCharCode(character);
      } else if (character == 58 /* : */) {
        // :: (/)Z
        extCont.write('cZ');
      } else if (character <= 63 /* ? */) {
        // ; - ?: (%)F - (%)J
        extCont.write('b');
        extCont.writeCharCode(70 /* F */ + character - 59 /* ; */);
      } else if (character == 64 /* @ */) {
        // @: (%)V
        extCont.write('bV');
      } else if (character <= 90 /* Z */) {
        // A - Z
        extCont.writeCharCode(character);
      } else if (character <= 95 /* _ */) {
        // [ - _: (%)K - (%)O
        extCont.write('b');
        extCont.writeCharCode(75 /* K */ + character - 91 /* [ */);
      } else if (character == 96 /* ` */) {
        // `: (%)W
        extCont.write('bW');
      } else if (character <= 122 /* z */) {
        // a - z: (*)A - (*)Z
        extCont.writeCharCode(100 /* d */);
        extCont.writeCharCode(65 /* A */ + character - 97 /* a */);
      } else if (character <= 127) {
        // { - DEL: (%)P - (%)T
        extCont.write('b');
        extCont.writeCharCode(80 /* P */ + character - 123 /* { */);
      } else {
        throw ArgumentError(
          "Requested content contains a non-encodable character: 'chr($character)'",
        );
      }
    }
    return extCont.toString();
  }
}
