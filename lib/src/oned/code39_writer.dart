/*
 * Copyright 2010 ZXing authors
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
import 'code39_reader.dart';
import 'one_dimensional_code_writer.dart';

/// This object renders a CODE39 code as a [BitMatrix].
///
/// @author erik.barbara@gmail.com (Erik Barbara)
class Code39Writer extends OneDimensionalCodeWriter {
  @override
  List<BarcodeFormat> get supportedWriteFormats => [BarcodeFormat.CODE_39];

  @override
  List<bool> encodeContent(String contents,
      [Map<EncodeHintType, Object?>? hints]) {
    int length = contents.length;
    if (length > 80) {
      throw Exception(
          "Requested contents should be less than 80 digits long, but got $length");
    }

    for (int i = 0; i < length; i++) {
      int indexInString = Code39Reader.ALPHABET_STRING.indexOf(contents[i]);
      if (indexInString < 0) {
        contents = _tryToConvertToExtendedMode(contents);
        length = contents.length;
        if (length > 80) {
          throw Exception(
              "Requested contents should be less than 80 digits long, but got $length (extended full ASCII mode)");
        }
        break;
      }
    }

    List<int> widths = List.filled(9, 0);
    int codeWidth = 24 + 1 + (13 * length);
    List<bool> result = List.filled(codeWidth, false);
    _toIntArray(Code39Reader.ASTERISK_ENCODING, widths);
    int pos = OneDimensionalCodeWriter.appendPattern(result, 0, widths, true);
    List<int> narrowWhite = [1];
    pos +=
        OneDimensionalCodeWriter.appendPattern(result, pos, narrowWhite, false);
    //append next character to byte matrix
    for (int i = 0; i < length; i++) {
      int indexInString = Code39Reader.ALPHABET_STRING.indexOf(contents[i]);
      _toIntArray(Code39Reader.CHARACTER_ENCODINGS[indexInString], widths);
      pos += OneDimensionalCodeWriter.appendPattern(result, pos, widths, true);
      pos += OneDimensionalCodeWriter.appendPattern(
          result, pos, narrowWhite, false);
    }
    _toIntArray(Code39Reader.ASTERISK_ENCODING, widths);
    OneDimensionalCodeWriter.appendPattern(result, pos, widths, true);
    return result;
  }

  static void _toIntArray(int a, List<int> toReturn) {
    for (int i = 0; i < 9; i++) {
      int temp = a & (1 << (8 - i));
      toReturn[i] = temp == 0 ? 1 : 2;
    }
  }

  static String _tryToConvertToExtendedMode(String contents) {
    int length = contents.length;
    StringBuffer extendedContent = StringBuffer();
    for (int i = 0; i < length; i++) {
      String character = contents[i];
      switch (character) {
        case '\u0000':
          extendedContent.write("%U");
          break;
        case ' ':
        case '-':
        case '.':
          extendedContent.write(character);
          break;
        case '@':
          extendedContent.write("%V");
          break;
        case '`':
          extendedContent.write("%W");
          break;
        default:
          int c = character.codeUnitAt(0);
          if (c <= 26) {
            extendedContent.write(r'$');
            extendedContent.writeCharCode((65 /* A */ + (c - 1)));
          } else if (c < 32 /*   */) {
            extendedContent.write('%');
            extendedContent.writeCharCode((65 /* A */ + (c - 27)));
          } else if (c <= 44 /* , */ || character == '/' || character == ':') {
            extendedContent.write('/');
            extendedContent.writeCharCode((65 /* A */ + (c - 33)));
          } else if (c <= 57 /* 9 */) {
            extendedContent.writeCharCode((48 /* 0 */ + (c - 48)));
          } else if (c <= 63 /* ? */) {
            extendedContent.write('%');
            extendedContent.writeCharCode((70 /* F */ + (c - 59)));
          } else if (c <= 90 /* Z */) {
            extendedContent.writeCharCode((65 /* A */ + (c - 65)));
          } else if (c <= 95 /* _ */) {
            extendedContent.write('%');
            extendedContent.writeCharCode((75 /* K */ + (c - 91)));
          } else if (c <= 122 /* z */) {
            extendedContent.write('+');
            extendedContent.writeCharCode((65 /* A */ + (c - 97)));
          } else if (c <= 127) {
            extendedContent.write('%');
            extendedContent.writeCharCode((80 /* P */ + (c - 123)));
          } else {
            throw Exception(
                "Requested content contains a non-encodable character: '" +
                    contents[i] +
                    "'");
          }
          break;
      }
    }

    return extendedContent.toString();
  }
}
