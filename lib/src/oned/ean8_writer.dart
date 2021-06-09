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

import 'package:flutter/cupertino.dart';

import '../barcode_format.dart';
import '../formats_exception.dart';
import 'one_dimensional_code_writer.dart';
import 'upceanreader.dart';
import 'upceanwriter.dart';

/// This object renders an EAN8 code as a {@link BitMatrix}.
///
/// @author aripollak@gmail.com (Ari Pollak)
class EAN8Writer extends UPCEANWriter {
  static const int _CODE_WIDTH = 3 + // start guard
      (7 * 4) + // left bars
      5 + // middle guard
      (7 * 4) + // right bars
      3; // end guard

  @override
  @protected
  List<BarcodeFormat> get supportedWriteFormats => [BarcodeFormat.EAN_8];

  /// @return a byte array of horizontal pixels (false = white, true = black)
  @override
  List<bool> encodeContent(String contents) {
    int length = contents.length;
    switch (length) {
      case 7:
        // No check digit present, calculate it and add it
        int check;
        try {
          check = UPCEANReader.getStandardUPCEANChecksum(contents);
        } catch (fe) {
          throw ArgumentError(fe);
        }
        contents += check.toString();
        break;
      case 8:
        try {
          if (!UPCEANReader.checkStandardUPCEANChecksum(contents)) {
            throw ArgumentError("Contents do not pass checksum");
          }
        } on FormatsException catch (_) {
          throw ArgumentError("Illegal contents");
        }
        break;
      default:
        // IllegalArgumentException
        throw ArgumentError(
            "Requested contents should be 7 or 8 digits long, but got $length");
    }

    OneDimensionalCodeWriter.checkNumeric(contents);

    List<bool> result = List.filled(_CODE_WIDTH, false);
    int pos = 0;

    pos += OneDimensionalCodeWriter.appendPattern(
        result, pos, UPCEANReader.START_END_PATTERN, true);

    for (int i = 0; i <= 3; i++) {
      int digit = int.parse(contents[i]);
      pos += OneDimensionalCodeWriter.appendPattern(
          result, pos, UPCEANReader.L_PATTERNS[digit], false);
    }

    pos += OneDimensionalCodeWriter.appendPattern(
        result, pos, UPCEANReader.MIDDLE_PATTERN, false);

    for (int i = 4; i <= 7; i++) {
      int digit = int.parse(contents[i]);
      pos += OneDimensionalCodeWriter.appendPattern(
          result, pos, UPCEANReader.L_PATTERNS[digit], true);
    }
    OneDimensionalCodeWriter.appendPattern(
        result, pos, UPCEANReader.START_END_PATTERN, true);

    return result;
  }
}
