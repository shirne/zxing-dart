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

import 'package:flutter/cupertino.dart';

import '../common/bit_array.dart';
import '../common/string_builder.dart';

import '../barcode_format.dart';
import '../not_found_exception.dart';
import 'upceanreader.dart';

/// <p>Implements decoding of the UPC-E format.</p>
/// <p><a href="http://www.barcodeisland.com/upce.phtml">This</a> is a great reference for
/// UPC-E information.</p>
///
/// @author Sean Owen
class UPCEReader extends UPCEANReader {
  /// The pattern that marks the middle, and end, of a UPC-E pattern.
  /// There is no "second half" to a UPC-E barcode.
  static const List<int> _MIDDLE_END_PATTERN = [1, 1, 1, 1, 1, 1];

  // For an UPC-E barcode, the final digit is represented by the parities used
  // to encode the middle six digits, according to the table below.
  //
  //                Parity of next 6 digits
  //    Digit   0     1     2     3     4     5
  //       0    Even   Even  Even Odd  Odd   Odd
  //       1    Even   Even  Odd  Even Odd   Odd
  //       2    Even   Even  Odd  Odd  Even  Odd
  //       3    Even   Even  Odd  Odd  Odd   Even
  //       4    Even   Odd   Even Even Odd   Odd
  //       5    Even   Odd   Odd  Even Even  Odd
  //       6    Even   Odd   Odd  Odd  Even  Even
  //       7    Even   Odd   Even Odd  Even  Odd
  //       8    Even   Odd   Even Odd  Odd   Even
  //       9    Even   Odd   Odd  Even Odd   Even
  //
  // The encoding is represented by the following array, which is a bit pattern
  // using Odd = 0 and Even = 1. For example, 5 is represented by:
  //
  //              Odd Even Even Odd Odd Even
  // in binary:
  //                0    1    1   0   0    1   == 0x19
  //

  /// See {@link #L_AND_G_PATTERNS}; these values similarly represent patterns of
  /// even-odd parity encodings of digits that imply both the number system (0 or 1)
  /// used, and the check digit.
  static const List<List<int>> NUMSYS_AND_CHECK_DIGIT_PATTERNS = [
    [0x38, 0x34, 0x32, 0x31, 0x2C, 0x26, 0x23, 0x2A, 0x29, 0x25],
    [0x07, 0x0B, 0x0D, 0x0E, 0x13, 0x19, 0x1C, 0x15, 0x16, 0x1A]
  ];

  final List<int> _decodeMiddleCounters = [0, 0, 0, 0];

  UPCEReader();

  @override
  @protected
  int decodeMiddle(BitArray row, List<int> startRange, StringBuilder result) {
    List<int> counters = _decodeMiddleCounters;
    counters[0] = 0;
    counters[1] = 0;
    counters[2] = 0;
    counters[3] = 0;
    int end = row.getSize();
    int rowOffset = startRange[1];

    int lgPatternFound = 0;

    for (int x = 0; x < 6 && rowOffset < end; x++) {
      int bestMatch = UPCEANReader.decodeDigit(
          row, counters, rowOffset, UPCEANReader.lAndGPatterns);
      result.write(String.fromCharCode(48 /* 0 */ + bestMatch % 10));
      for (int counter in counters) {
        rowOffset += counter;
      }
      if (bestMatch >= 10) {
        lgPatternFound |= 1 << (5 - x);
      }
    }

    _determineNumSysAndCheckDigit(result, lgPatternFound);

    return rowOffset;
  }

  @override
  @protected
  List<int> decodeEnd(BitArray row, int endStart) {
    return UPCEANReader.findGuardPattern(row, endStart, true, _MIDDLE_END_PATTERN);
  }

  @override
  @protected
  bool checkChecksum(String s) {
    return super.checkChecksum(convertUPCEtoUPCA(s));
  }

  static void _determineNumSysAndCheckDigit(
      StringBuilder resultString, int lgPatternFound) {
    for (int numSys = 0; numSys <= 1; numSys++) {
      for (int d = 0; d < 10; d++) {
        if (lgPatternFound == NUMSYS_AND_CHECK_DIGIT_PATTERNS[numSys][d]) {
          resultString.insert(
              0, String.fromCharCode(48 /* 0 */ + numSys));
          resultString.write(String.fromCharCode(48 /* 0 */ + d));
          return;
        }
      }
    }
    throw NotFoundException.getNotFoundInstance();
  }

  @override
  BarcodeFormat getBarcodeFormat() {
    return BarcodeFormat.UPC_E;
  }

  /// Expands a UPC-E value back into its full, equivalent UPC-A code value.
  ///
  /// @param upce UPC-E code as string of digits
  /// @return equivalent UPC-A code as string of digits
  static String convertUPCEtoUPCA(String upce) {
    List<int> upceChars = List.generate(6, (index)=>upce.codeUnitAt(index+1));
    // upce.getChars(1, 7, upceChars, 0);
    StringBuffer result = StringBuffer();
    result.write(upce[0]);
    int lastChar = upceChars[5];
    switch (String.fromCharCode(lastChar)) {
      case '0':
      case '1':
      case '2':
        result.write(String.fromCharCodes(upceChars.getRange(0, 2))); // 0, 2
        result.writeCharCode(lastChar);
        result.write("0000");
        result.write(String.fromCharCodes(upceChars.getRange(2, 5))); // 2, 3
        break;
      case '3':
        result.write(String.fromCharCodes(upceChars.getRange(0, 3))); // 0, 3
        result.write("00000");
        result.write(String.fromCharCodes(upceChars.getRange(3, 5))); // 3, 2
        break;
      case '4':
        result.write(String.fromCharCodes(upceChars.getRange(0, 4))); // 0, 4
        result.write("00000");
        result.writeCharCode(upceChars[4]);
        break;
      default:
        result.write(String.fromCharCodes(upceChars.getRange(0, 5))); // 0, 5
        result.write("0000");
        result.writeCharCode(lastChar);
        break;
    }
    // Only append check digit in conversion if supplied
    if (upce.length >= 8) {
      result.write(upce[7]);
    }
    return result.toString();
  }
}
