/*
 * Copyright 2009 ZXing authors
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
import '../encode_hint.dart';
import '../formats_exception.dart';
import 'one_dimensional_code_writer.dart';
import 'upcean_reader.dart';
import 'upcean_writer.dart';
import 'upce_reader.dart';

/// This object renders an UPC-E code as a [BitMatrix].
///
/// @author 0979097955s@gmail.com (RX)
class UPCEWriter extends UPCEANWriter {
  static const int _codeWidth = 3 + // start guard
      (7 * 6) + // bars
      6; // end guard

  @override
  List<BarcodeFormat> get supportedWriteFormats => [BarcodeFormat.upcE];

  @override
  List<bool> encodeContent(
    String contents, [
    EncodeHint? hints,
  ]) {
    final length = contents.length;
    switch (length) {
      case 7:
        // No check digit present, calculate it and add it
        int check;
        try {
          check = UPCEANReader.getStandardUPCEANChecksum(
            UPCEReader.convertUPCEtoUPCA(contents),
          );
        } on FormatsException catch (fe) {
          //
          throw ArgumentError(fe);
        }
        contents += check.toString();
        break;
      case 8:
        try {
          if (!UPCEANReader.checkStandardUPCEANChecksum(
            UPCEReader.convertUPCEtoUPCA(contents),
          )) {
            throw ArgumentError('Contents do not pass checksum');
          }
        } on FormatsException catch (_) {
          //
          throw ArgumentError('Illegal contents');
        }
        break;
      default:
        throw ArgumentError(
          'Requested contents should be 7 or 8 digits long, but got $length',
        );
    }

    OneDimensionalCodeWriter.checkNumeric(contents);

    final firstDigit = int.parse(contents[0]);
    if (firstDigit != 0 && firstDigit != 1) {
      throw ArgumentError('Number system must be 0 or 1');
    }

    final checkDigit = int.parse(contents[7]);
    final parities =
        UPCEReader.numsysAndCheckDigitPatterns[firstDigit][checkDigit];
    final result = List.filled(_codeWidth, false);

    int pos = OneDimensionalCodeWriter.appendPattern(
      result,
      0,
      UPCEANReader.startEndPattern,
      true,
    );

    for (int i = 1; i <= 6; i++) {
      int digit = int.parse(contents[i]);
      if ((parities >> (6 - i) & 1) == 1) {
        digit += 10;
      }
      pos += OneDimensionalCodeWriter.appendPattern(
        result,
        pos,
        UPCEANReader.lAndGPatterns[digit],
        false,
      );
    }

    OneDimensionalCodeWriter.appendPattern(
      result,
      pos,
      UPCEANReader.endPattern,
      false,
    );

    return result;
  }
}
