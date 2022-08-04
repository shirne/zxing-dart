/*
 * Copyright 2007 ZXing authors
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

import 'aztec/aztec_reader.dart';
import 'barcode_format.dart';
import 'binary_bitmap.dart';
import 'datamatrix/data_matrix_reader.dart';
import 'decode_hint_type.dart';
import 'maxicode/maxi_code_reader.dart';
import 'not_found_exception.dart';
import 'oned/multi_format_one_dreader.dart';
import 'pdf417/pdf417_reader.dart';
import 'qrcode/qrcode_reader.dart';
import 'reader.dart';
import 'reader_exception.dart';
import 'result.dart';

/// MultiFormatReader is a convenience class and the main entry point into the library for most uses.
/// By default it attempts to decode all barcode formats that the library supports. Optionally, you
/// can provide a hints object to request different behavior, for example only decoding QR codes.
///
/// @author Sean Owen
/// @author dswitkin@google.com (Daniel Switkin)
class MultiFormatReader implements Reader {
  //static final List<Reader> _emptyReaderArray = [];

  Map<DecodeHintType, Object>? _hints;
  List<Reader>? _readers;

  /// Decode an image using the hints provided. Does not honor existing state.
  ///
  /// @param image The pixel data to decode
  /// @param hints The hints to use, clearing the previous state.
  /// @return The contents of the image
  /// @throws NotFoundException Any errors which occurred
  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    setHints(hints);
    return _decodeInternal(image);
  }

  /// Decode an image using the state set up by calling setHints() previously. Continuous scan
  /// clients will get a <b>large</b> speed increase by using this instead of decode().
  ///
  /// @param image The pixel data to decode
  /// @return The contents of the image
  /// @throws NotFoundException Any errors which occurred
  Result decodeWithState(BinaryBitmap image) {
    // Make sure to set up the default state so we don't crash
    if (_readers == null) {
      setHints(null);
    }
    return _decodeInternal(image);
  }

  /// This method adds state to the MultiFormatReader. By setting the hints once, subsequent calls
  /// to decodeWithState(image) can reuse the same set of readers without reallocating memory. This
  /// is important for performance in continuous scan clients.
  ///
  /// @param hints The set of hints to use for subsequent calls to decode(image)
  void setHints(Map<DecodeHintType, Object>? hints) {
    _hints = hints;

    final tryHarder = hints?.containsKey(DecodeHintType.TRY_HARDER) ?? false;
    // @SuppressWarnings("unchecked")
    final formats =
        hints?[DecodeHintType.POSSIBLE_FORMATS] as List<BarcodeFormat>?;
    final readers = <Reader>[];
    if (formats != null) {
      final addOneDReader = formats.contains(BarcodeFormat.UPC_A) ||
          formats.contains(BarcodeFormat.UPC_E) ||
          formats.contains(BarcodeFormat.EAN_13) ||
          formats.contains(BarcodeFormat.EAN_8) ||
          formats.contains(BarcodeFormat.CODABAR) ||
          formats.contains(BarcodeFormat.CODE_39) ||
          formats.contains(BarcodeFormat.CODE_93) ||
          formats.contains(BarcodeFormat.CODE_128) ||
          formats.contains(BarcodeFormat.ITF) ||
          formats.contains(BarcodeFormat.RSS_14) ||
          formats.contains(BarcodeFormat.RSS_EXPANDED);
      // Put 1D readers upfront in "normal" mode
      if (addOneDReader && !tryHarder) {
        readers.add(MultiFormatOneDReader(hints));
      }
      if (formats.contains(BarcodeFormat.QR_CODE)) {
        readers.add(QRCodeReader());
      }
      if (formats.contains(BarcodeFormat.DATA_MATRIX)) {
        readers.add(DataMatrixReader());
      }
      if (formats.contains(BarcodeFormat.AZTEC)) {
        readers.add(AztecReader());
      }
      if (formats.contains(BarcodeFormat.PDF_417)) {
        readers.add(PDF417Reader());
      }
      if (formats.contains(BarcodeFormat.MAXICODE)) {
        readers.add(MaxiCodeReader());
      }
      // At end in "try harder" mode
      if (addOneDReader && tryHarder) {
        readers.add(MultiFormatOneDReader(hints));
      }
    }
    if (readers.isEmpty) {
      if (!tryHarder) {
        readers.add(MultiFormatOneDReader(hints));
      }

      readers.add(QRCodeReader());
      readers.add(DataMatrixReader());
      readers.add(AztecReader());
      readers.add(PDF417Reader());
      readers.add(MaxiCodeReader());

      if (tryHarder) {
        readers.add(MultiFormatOneDReader(hints));
      }
    }
    _readers = readers; //.toList();
  }

  @override
  void reset() {
    if (_readers != null) {
      for (Reader reader in _readers!) {
        reader.reset();
      }
    }
  }

  Result _decodeInternal(BinaryBitmap image) {
    if (_readers != null) {
      for (Reader reader in _readers!) {
        try {
          return reader.decode(image, _hints);
        } on ReaderException catch (_) {
          // continue
        }
      }
      if (_hints != null && _hints!.containsKey(DecodeHintType.ALSO_INVERTED)) {
        // Calling all readers again with inverted image
        image.blackMatrix.flip();
        for (Reader reader in _readers!) {
          try {
            return reader.decode(image, _hints);
          } on ReaderException catch (_) {
            // continue
          }
        }
      }
    }
    throw NotFoundException.instance;
  }
}
