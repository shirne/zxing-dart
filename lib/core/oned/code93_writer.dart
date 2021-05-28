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
import 'code93_reader.dart';
import 'one_dimensional_code_writer.dart';

/**
 * This object renders a CODE93 code as a BitMatrix
 */
class Code93Writer extends OneDimensionalCodeWriter {
  @override
  List<BarcodeFormat> getSupportedWriteFormats() {
    return [BarcodeFormat.CODE_93];
  }

  /**
   * @param contents barcode contents to encode. It should not be encoded for extended characters.
   * @return a {@code List<bool>} of horizontal pixels (false = white, true = black)
   */
  @override
  List<bool> encodeContent(String contents) {
    contents = convertToExtended(contents);
    int length = contents.length;
    if (length > 80) {
      throw Exception(
          "Requested contents should be less than 80 digits long after converting to extended encoding, but got $length");
    }

    //length of code + 2 start/stop characters + 2 checksums, each of 9 bits, plus a termination bar
    int codeWidth = (contents.length + 2 + 2) * 9 + 1;

    List<bool> result = List.filled(codeWidth, false);

    //start character (*)
    int pos = appendPattern(result, 0, Code93Reader.ASTERISK_ENCODING);

    for (int i = 0; i < length; i++) {
      int indexInString = Code93Reader.ALPHABET_STRING.indexOf(contents[i]);
      pos += appendPattern(
          result, pos, Code93Reader.CHARACTER_ENCODINGS[indexInString]);
    }

    //add two checksums
    int check1 = computeChecksumIndex(contents, 20);
    pos += appendPattern(result, pos, Code93Reader.CHARACTER_ENCODINGS[check1]);

    //append the contents to reflect the first checksum added
    contents += Code93Reader.ALPHABET_STRING[check1];

    int check2 = computeChecksumIndex(contents, 15);
    pos += appendPattern(result, pos, Code93Reader.CHARACTER_ENCODINGS[check2]);

    //end character (*)
    pos += appendPattern(result, pos, Code93Reader.ASTERISK_ENCODING);

    //termination bar (single black bar)
    result[pos] = true;

    return result;
  }

  /**
   * @param target output to append to
   * @param pos start position
   * @param pattern pattern to append
   * @param startColor unused
   * @return 9
   * @deprecated without replacement; intended as an internal-only method
   */
  @deprecated
  static int appendPatternDpr(
      List<bool> target, int pos, List<int> pattern, bool startColor) {
    for (int bit in pattern) {
      target[pos++] = bit != 0;
    }
    return 9;
  }

  static int appendPattern(List<bool> target, int pos, int a) {
    for (int i = 0; i < 9; i++) {
      int temp = a & (1 << (8 - i));
      target[pos + i] = temp != 0;
    }
    return 9;
  }

  static int computeChecksumIndex(String contents, int maxWeight) {
    int weight = 1;
    int total = 0;

    for (int i = contents.length - 1; i >= 0; i--) {
      int indexInString = Code93Reader.ALPHABET_STRING.indexOf(contents[i]);
      total += indexInString * weight;
      if (++weight > maxWeight) {
        weight = 1;
      }
    }
    return total % 47;
  }

  static String convertToExtended(String contents) {
    int length = contents.length;
    StringBuffer extendedContent = new StringBuffer(length * 2);
    for (int i = 0; i < length; i++) {
      int character = contents.codeUnitAt(i);
      // ($)=a, (%)=b, (/)=c, (+)=d. see Code93Reader.ALPHABET_STRING
      if (character == 0) {
        // NUL: (%)U
        extendedContent.write("bU");
      } else if (character <= 26) {
        // SOH - SUB: ($)A - ($)Z
        extendedContent.write('a');
        extendedContent
            .write(String.fromCharCode('A'.codeUnitAt(0) + character - 1));
      } else if (character <= 31) {
        // ESC - US: (%)A - (%)E
        extendedContent.write('b');
        extendedContent
            .write(String.fromCharCode('A'.codeUnitAt(0) + character - 27));
      } else if (character == ' '.codeUnitAt(0) ||
          character == r'$'.codeUnitAt(0) ||
          character == '%'.codeUnitAt(0) ||
          character == '+'.codeUnitAt(0)) {
        // space $ % +
        extendedContent.write(character);
      } else if (character <= ','.codeUnitAt(0)) {
        // ! " # & ' ( ) * ,: (/)A - (/)L
        extendedContent.write('c');
        extendedContent.write(String.fromCharCode(
            'A'.codeUnitAt(0) + character - '!'.codeUnitAt(0)));
      } else if (character <= '9'.codeUnitAt(0)) {
        extendedContent.write(character);
      } else if (character == ':'.codeUnitAt(0)) {
        // :: (/)Z
        extendedContent.write("cZ");
      } else if (character <= '?'.codeUnitAt(0)) {
        // ; - ?: (%)F - (%)J
        extendedContent.write('b');
        extendedContent.write(String.fromCharCode(
            'F'.codeUnitAt(0) + character - ';'.codeUnitAt(0)));
      } else if (character == '@'.codeUnitAt(0)) {
        // @: (%)V
        extendedContent.write("bV");
      } else if (character <= 'Z'.codeUnitAt(0)) {
        // A - Z
        extendedContent.write(character);
      } else if (character <= '_'.codeUnitAt(0)) {
        // [ - _: (%)K - (%)O
        extendedContent.write('b');
        extendedContent.write(String.fromCharCode(
            'K'.codeUnitAt(0) + character - '['.codeUnitAt(0)));
      } else if (character == '`'.codeUnitAt(0)) {
        // `: (%)W
        extendedContent.write("bW");
      } else if (character <= 'z'.codeUnitAt(0)) {
        // a - z: (*)A - (*)Z
        extendedContent.write('d'.codeUnitAt(0));
        extendedContent.write(String.fromCharCode(
            'A'.codeUnitAt(0) + character - 'a'.codeUnitAt(0)));
      } else if (character <= 127) {
        // { - DEL: (%)P - (%)T
        extendedContent.write('b');
        extendedContent.write(String.fromCharCode(
            'P'.codeUnitAt(0) + character - '{'.codeUnitAt(0)));
      } else {
        throw Exception(
            "Requested content contains a non-encodable character: '" +
                String.fromCharCode(character) +
                "'");
      }
    }
    return extendedContent.toString();
  }
}
