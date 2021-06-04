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

import '../common/bit_array.dart';

import '../barcode_format.dart';
import 'upceanreader.dart';

/// <p>Implements decoding of the EAN-8 format.</p>
///
/// @author Sean Owen
class EAN8Reader extends UPCEANReader {
  final List<int> _decodeMiddleCounters = [0, 0, 0, 0];

  EAN8Reader();

  @override
  int decodeMiddle(BitArray row, List<int> startRange, StringBuffer result) {
    List<int> counters = _decodeMiddleCounters;
    counters[0] = 0;
    counters[1] = 0;
    counters[2] = 0;
    counters[3] = 0;
    int end = row.getSize();
    int rowOffset = startRange[1];

    for (int x = 0; x < 4 && rowOffset < end; x++) {
      int bestMatch = UPCEANReader.decodeDigit(
          row, counters, rowOffset, UPCEANReader.L_PATTERNS);
      result.writeCharCode(48 /* 0 */ + bestMatch);
      for (int counter in counters) {
        rowOffset += counter;
      }
    }

    List<int> middleRange = UPCEANReader.findGuardPattern(
        row, rowOffset, true, UPCEANReader.MIDDLE_PATTERN);
    rowOffset = middleRange[1];

    for (int x = 0; x < 4 && rowOffset < end; x++) {
      int bestMatch = UPCEANReader.decodeDigit(
          row, counters, rowOffset, UPCEANReader.L_PATTERNS);
      result.writeCharCode(48 /* 0 */ + bestMatch);
      for (int counter in counters) {
        rowOffset += counter;
      }
    }

    return rowOffset;
  }

  @override
  BarcodeFormat getBarcodeFormat() {
    return BarcodeFormat.EAN_8;
  }
}
