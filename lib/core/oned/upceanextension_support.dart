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
import '../result.dart';
import 'upceanextension2_support.dart';
import 'upceanextension5_support.dart';
import 'upceanreader.dart';

class UPCEANExtensionSupport {
  static const List<int> _EXTENSION_START_PATTERN = [1, 1, 2];

  final UPCEANExtension2Support _twoSupport = UPCEANExtension2Support();
  final UPCEANExtension5Support _fiveSupport = UPCEANExtension5Support();

  Result decodeRow(int rowNumber, BitArray row, int rowOffset) {
    List<int> extensionStartRange = UPCEANReader.findGuardPattern(
        row, rowOffset, false, _EXTENSION_START_PATTERN);
    try {
      return _fiveSupport.decodeRow(rowNumber, row, extensionStartRange);
    } catch (ignored) {
      // ReaderException
      return _twoSupport.decodeRow(rowNumber, row, extensionStartRange);
    }
  }
}
