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

import '../barcode_format.dart';
import '../binary_bitmap.dart';
import '../common/bit_array.dart';
import '../common/string_builder.dart';
import '../decode_hint_type.dart';
import '../formats_exception.dart';
import '../result.dart';
import 'ean13_reader.dart';
import 'upceanreader.dart';

/// Implements decoding of the UPC-A format.
///
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Sean Owen
class UPCAReader extends UPCEANReader {
  final UPCEANReader _ean13Reader = EAN13Reader();

  @override
  Result decodeRow(
    int rowNumber,
    BitArray row,
    Map<DecodeHintType, Object>? hints, [
    List<int>? startGuardRange,
  ]) {
    return _maybeReturnResult(
      _ean13Reader.decodeRow(rowNumber, row, hints, startGuardRange),
    );
  }

  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    return _maybeReturnResult(_ean13Reader.decode(image, hints));
  }

  @override
  BarcodeFormat get barcodeFormat => BarcodeFormat.upcA;

  @override
  int decodeMiddle(BitArray row, List<int> startRange, StringBuilder result) {
    return _ean13Reader.decodeMiddle(row, startRange, result);
  }

  static Result _maybeReturnResult(Result result) {
    final text = result.text;
    if (text[0] == '0') {
      final upcaResult = Result(
        text.substring(1),
        null,
        result.resultPoints,
        BarcodeFormat.upcA,
      );
      if (result.resultMetadata != null) {
        upcaResult.putAllMetadata(result.resultMetadata);
      }
      return upcaResult;
    } else {
      throw FormatsException.instance;
    }
  }
}
