/*
 * Copyright (C) 2010 ZXing authors
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



import '../common/bit_array.dart';

import '../barcode_format.dart';
import '../not_found_exception.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import '../result.dart';
import 'upceanreader.dart';

/// @see UPCEANExtension2Support
class UPCEANExtension5Support {

  static const List<int> _CHECK_DIGIT_ENCODINGS = [
      0x18, 0x14, 0x12, 0x11, 0x0C, 0x06, 0x03, 0x0A, 0x09, 0x05 // 
  ];

  final List<int> _decodeMiddleCounters = [0,0,0,0];
  final StringBuffer _decodeRowStringBuffer = StringBuffer();

  Result decodeRow(int rowNumber, BitArray row, List<int> extensionStartRange){

    StringBuffer result = _decodeRowStringBuffer;
    result.clear();
    int end = _decodeMiddle(row, extensionStartRange, result);

    String resultString = result.toString();
    Map<ResultMetadataType,Object>? extensionData = _parseExtensionString(resultString);

    Result extensionResult =
        Result(resultString,
                   null,
                   [
                       ResultPoint((extensionStartRange[0] + extensionStartRange[1]) / 2.0, rowNumber.toDouble()),
                       ResultPoint(end.toDouble(), rowNumber.toDouble()),
                   ],
                   BarcodeFormat.UPC_EAN_EXTENSION);
    if (extensionData != null) {
      extensionResult.putAllMetadata(extensionData);
    }
    return extensionResult;
  }

  int _decodeMiddle(BitArray row, List<int> startRange, StringBuffer resultString){
    List<int> counters = _decodeMiddleCounters;
    counters[0] = 0;
    counters[1] = 0;
    counters[2] = 0;
    counters[3] = 0;
    int end = row.getSize();
    int rowOffset = startRange[1];

    int lgPatternFound = 0;

    for (int x = 0; x < 5 && rowOffset < end; x++) {
      int bestMatch = UPCEANReader.decodeDigit(row, counters, rowOffset, UPCEANReader.L_AND_G_PATTERNS);
      resultString.writeCharCode('0'.codeUnitAt(0) + bestMatch % 10);
      for (int counter in counters) {
        rowOffset += counter;
      }
      if (bestMatch >= 10) {
        lgPatternFound |= 1 << (4 - x);
      }
      if (x != 4) {
        // Read off separator if not last
        rowOffset = row.getNextSet(rowOffset);
        rowOffset = row.getNextUnset(rowOffset);
      }
    }

    if (resultString.length != 5) {
      throw NotFoundException.getNotFoundInstance();
    }

    int checkDigit = _determineCheckDigit(lgPatternFound);
    if (_extensionChecksum(resultString.toString()) != checkDigit) {
      throw NotFoundException.getNotFoundInstance();
    }

    return rowOffset;
  }

  static int _extensionChecksum(String s) {
    int length = s.length;
    int sum = 0;
    for (int i = length - 2; i >= 0; i -= 2) {
      sum += s.codeUnitAt(i) - '0'.codeUnitAt(0);
    }
    sum *= 3;
    for (int i = length - 1; i >= 0; i -= 2) {
      sum += s.codeUnitAt(i) - '0'.codeUnitAt(0);
    }
    sum *= 3;
    return sum % 10;
  }

  static int _determineCheckDigit(int lgPatternFound)
     {
    for (int d = 0; d < 10; d++) {
      if (lgPatternFound == _CHECK_DIGIT_ENCODINGS[d]) {
        return d;
      }
    }
    throw NotFoundException.getNotFoundInstance();
  }

  /// @param raw raw content of extension
  /// @return formatted interpretation of raw content as a {@link Map} mapping
  ///  one {@link ResultMetadataType} to appropriate value, or {@code null} if not known
  static Map<ResultMetadataType,Object>? _parseExtensionString(String raw) {
    if (raw.length != 5) {
      return null;
    }
    Object? value = _parseExtension5String(raw);
    if (value == null) {
      return null;
    }
    Map<ResultMetadataType,Object> result = {};
    result[ResultMetadataType.SUGGESTED_PRICE] = value;
    return result;
  }

  static String? _parseExtension5String(String raw) {
    String currency;
    switch (raw[0]) {
      case '0':
        currency = "£";
        break;
      case '5':
        currency = r"$";
        break;
      case '9':
        // Reference: http://www.jollytech.com
        switch (raw) {
          case "90000":
            // No suggested retail price
            return null;
          case "99991":
            // Complementary
            return "0.00";
          case "99990":
            return "Used";
        }
        // Otherwise... unknown currency?
        currency = "";
        break;
      default:
        currency = "";
        break;
    }
    int rawAmount = int.parse(raw.substring(1));
    String unitsString = (rawAmount / 100).toString();
    int hundredths = rawAmount % 100;
    String hundredthsString = hundredths.toString().padLeft(2, '0');
    return currency + unitsString + '.' + hundredthsString;
  }

}
