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

import '../barcode_format.dart';
import '../common/bit_array.dart';
import '../not_found_exception.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'upceanreader.dart';

/// See [UPCEANExtension2Support]
class UPCEANExtension5Support {
  static const List<int> _CHECK_DIGIT_ENCODINGS = [
    0x18, 0x14, 0x12, 0x11, 0x0C, 0x06, 0x03, 0x0A, 0x09, 0x05 //
  ];

  final List<int> _decodeMiddleCounters = [0, 0, 0, 0];
  final StringBuffer _decodeRowStringBuffer = StringBuffer();

  Result decodeRow(int rowNumber, BitArray row, List<int> extensionStartRange) {
    final result = _decodeRowStringBuffer;
    result.clear();
    final end = _decodeMiddle(row, extensionStartRange, result);

    final resultString = result.toString();
    final extensionData = _parseExtensionString(resultString);

    final extensionResult = Result(
      resultString,
      null,
      [
        ResultPoint(
          (extensionStartRange[0] + extensionStartRange[1]) / 2.0,
          rowNumber.toDouble(),
        ),
        ResultPoint(end.toDouble(), rowNumber.toDouble()),
      ],
      BarcodeFormat.UPC_EAN_EXTENSION,
    );
    if (extensionData != null) {
      extensionResult.putAllMetadata(extensionData);
    }
    return extensionResult;
  }

  int _decodeMiddle(
    BitArray row,
    List<int> startRange,
    StringBuffer resultString,
  ) {
    final counters = _decodeMiddleCounters;
    counters.fillRange(0, 4, 0);
    final end = row.size;
    int rowOffset = startRange[1];

    int lgPatternFound = 0;

    for (int x = 0; x < 5 && rowOffset < end; x++) {
      final bestMatch = UPCEANReader.decodeDigit(
        row,
        counters,
        rowOffset,
        UPCEANReader.lAndGPatterns,
      );
      resultString.writeCharCode(48 /* 0 */ + bestMatch % 10);
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
      throw NotFoundException.instance;
    }

    final checkDigit = _determineCheckDigit(lgPatternFound);
    if (_extensionChecksum(resultString.toString()) != checkDigit) {
      throw NotFoundException.instance;
    }

    return rowOffset;
  }

  static int _extensionChecksum(String s) {
    final length = s.length;
    int sum = 0;
    for (int i = length - 2; i >= 0; i -= 2) {
      sum += s.codeUnitAt(i) - 48 /* 0 */;
    }
    sum *= 3;
    for (int i = length - 1; i >= 0; i -= 2) {
      sum += s.codeUnitAt(i) - 48 /* 0 */;
    }
    sum *= 3;
    return sum % 10;
  }

  static int _determineCheckDigit(int lgPatternFound) {
    for (int d = 0; d < 10; d++) {
      if (lgPatternFound == _CHECK_DIGIT_ENCODINGS[d]) {
        return d;
      }
    }
    throw NotFoundException.instance;
  }

  /// @param raw raw content of extension
  /// @return formatted interpretation of raw content as a [Map] mapping
  ///  one [ResultMetadataType] to appropriate value, or `null` if not known
  static Map<ResultMetadataType, Object>? _parseExtensionString(String raw) {
    if (raw.length != 5) {
      return null;
    }
    final value = _parseExtension5String(raw);
    if (value == null) {
      return null;
    }
    final result = <ResultMetadataType, Object>{};
    result[ResultMetadataType.SUGGESTED_PRICE] = value;
    return result;
  }

  static String? _parseExtension5String(String raw) {
    String currency;
    switch (raw[0]) {
      case '0':
        currency = '£';
        break;
      case '5':
        currency = r'$';
        break;
      case '9':
        // Reference: http://www.jollytech.com
        switch (raw) {
          case '90000':
            // No suggested retail price
            return null;
          case '99991':
            // Complementary
            return '0.00';
          case '99990':
            return 'Used';
        }
        // Otherwise... unknown currency?
        currency = '';
        break;
      default:
        currency = '';
        break;
    }
    final rawAmount = int.parse(raw.substring(1));
    final unitsString = (rawAmount ~/ 100).toString();
    final hundredths = rawAmount % 100;
    final hundredthsString = hundredths.toString().padLeft(2, '0');
    return '$currency$unitsString.$hundredthsString';
  }
}
