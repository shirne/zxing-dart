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
import '../common/bit_matrix.dart';
import '../encode_hint_type.dart';
import '../writer.dart';
import 'ean13_writer.dart';

/// This object renders a UPC-A code as a [BitMatrix].
///
/// @author qwandor@google.com (Andrew Walbran)
class UPCAWriter implements Writer {
  final EAN13Writer _subWriter = EAN13Writer();

  @override
  BitMatrix encode(String contents, BarcodeFormat format, int width, int height,
      [Map<EncodeHintType, Object>? hints]) {
    if (format != BarcodeFormat.UPC_A) {
      throw ArgumentError('Can only encode UPC-A, but got $format');
    }
    // Transform a UPC-A code into the equivalent EAN-13 code and write it that way
    return _subWriter.encode(
        '0$contents', BarcodeFormat.EAN_13, width, height, hints);
  }
}
