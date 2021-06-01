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
import '../common/string_builder.dart';

import '../barcode_format.dart';
import '../binary_bitmap.dart';
import '../decode_hint_type.dart';
import '../result.dart';
import 'ean13_reader.dart';
import 'upceanreader.dart';

/// <p>Implements decoding of the UPC-A format.</p>
///
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Sean Owen
class UPCAReader extends UPCEANReader {
  final UPCEANReader _ean13Reader = EAN13Reader();

  @override
  Result decodeRow(
      int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints,
      [List<int>? startGuardRange]) {
    return _maybeReturnResult(
        _ean13Reader.decodeRow(rowNumber, row, hints, startGuardRange));
  }

  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    return _maybeReturnResult(_ean13Reader.decode(image, hints));
  }

  @override
  BarcodeFormat getBarcodeFormat() {
    return BarcodeFormat.UPC_A;
  }

  @override
  int decodeMiddle(
      BitArray row, List<int> startRange, StringBuilder resultString) {
    return _ean13Reader.decodeMiddle(row, startRange, resultString);
  }

  static Result _maybeReturnResult(Result result) {
    String text = result.getText();
    if (text[0] == '0') {
      Result upcaResult = Result(text.substring(1), null,
          result.getResultPoints(), BarcodeFormat.UPC_A);
      if (result.getResultMetadata() != null) {
        upcaResult.putAllMetadata(result.getResultMetadata());
      }
      return upcaResult;
    } else {
      throw FormatException();
    }
  }
}
