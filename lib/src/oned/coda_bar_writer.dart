/*
 * Copyright 2011 ZXing authors
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
import '../common/detector/math_utils.dart';
import '../encode_hint_type.dart';
import 'coda_bar_reader.dart';
import 'one_dimensional_code_writer.dart';

/// This class renders CodaBar as `List<bool>`.
///
/// @author dsbnatut@gmail.com (Kazuki Nishiura)
class CodaBarWriter extends OneDimensionalCodeWriter {
  static const List<String> _startEndChars = ['A', 'B', 'C', 'D'];
  static const List<String> _altStartEndChars = ['T', 'N', '*', 'E'];
  static const List<String> _charsWhichAreTenLengthEachAfterDecoded = [
    '/', ':', '+', '.' //
  ];
  //START_END_CHARS[0];
  static const String _defaultGuard = 'A';

  //@protected
  @override
  List<BarcodeFormat> get supportedWriteFormats => [BarcodeFormat.codabar];

  @override
  List<bool> encodeContent(
    String contents, [
    Map<EncodeHintType, Object?>? hints,
  ]) {
    if (contents.length < 2) {
      // Can't have a start/end guard, so tentatively add default guards
      contents = _defaultGuard + contents + _defaultGuard;
    } else {
      // Verify input and calculate decoded length.
      final firstChar = contents[0].toUpperCase();
      final lastChar = contents[contents.length - 1].toUpperCase();
      final startsNormal = _startEndChars.contains(firstChar);
      final endsNormal = _startEndChars.contains(lastChar);
      final startsAlt = _altStartEndChars.contains(firstChar);
      final endsAlt = _altStartEndChars.contains(lastChar);
      if (startsNormal) {
        if (!endsNormal) {
          throw ArgumentError('Invalid start/end guards: $contents');
        }
        // else already has valid start/end
      } else if (startsAlt) {
        if (!endsAlt) {
          throw ArgumentError('Invalid start/end guards: $contents');
        }
        // else already has valid start/end
      } else {
        // Doesn't start with a guard
        if (endsNormal || endsAlt) {
          throw ArgumentError('Invalid start/end guards: $contents');
        }
        // else doesn't end with guard either, so add a default
        contents = _defaultGuard + contents + _defaultGuard;
      }
    }

    // The start character and the end character are decoded to 10 length each.
    int resultLength = 20;
    for (int i = 1; i < contents.length - 1; i++) {
      if (MathUtils.isDigit(contents.codeUnitAt(i)) ||
          contents[i] == '-' ||
          contents[i] == r'$') {
        resultLength += 9;
      } else if (_charsWhichAreTenLengthEachAfterDecoded
          .contains(contents[i])) {
        resultLength += 10;
      } else {
        throw ArgumentError("Cannot encode : '${contents[i]}'");
      }
    }
    // A blank is placed between each character.
    resultLength += contents.length - 1;

    final result = List.generate(resultLength, (index) => false);
    int position = 0;
    for (int index = 0; index < contents.length; index++) {
      String c = contents[index].toUpperCase();
      if (index == 0 || index == contents.length - 1) {
        // The start/end chars are not in the CodaBarReader.ALPHABET.
        switch (c) {
          case 'T':
            c = 'A';
            break;
          case 'N':
            c = 'B';
            break;
          case '*':
            c = 'C';
            break;
          case 'E':
            c = 'D';
            break;
        }
      }
      int code = 0;
      for (int i = 0; i < CodaBarReader.alphaBet.length; i++) {
        // Found any, because I checked above.
        if (c.codeUnitAt(0) == CodaBarReader.alphaBet[i]) {
          code = CodaBarReader.characterEncodings[i];
          break;
        }
      }
      bool color = true;
      int counter = 0;
      int bit = 0;
      while (bit < 7) {
        // A character consists of 7 digit.
        result[position] = color;
        position++;
        if (((code >> (6 - bit)) & 1) == 0 || counter == 1) {
          color = !color; // Flip the color.
          bit++;
          counter = 0;
        } else {
          counter++;
        }
      }
      if (index < contents.length - 1) {
        result[position] = false;
        position++;
      }
    }
    return result;
  }
}
