/*
 * Copyright 2011 ZXing authors
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

import 'dart:math' as math;

import '../barcode_format.dart';
import '../binary_bitmap.dart';
import '../common/bit_matrix.dart';
import '../decode_hint.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'decoder/decoder.dart';

/// This implementation can detect and decode a MaxiCode in an image.
class MaxiCodeReader implements Reader {
  static const List<ResultPoint> _noPoints = [];
  static const int _matrixWidth = 30;
  static const int _matrixHeight = 33;

  final Decoder _decoder = Decoder();

  @override
  Result decode(BinaryBitmap image, [DecodeHint? hints]) {
    // Note that MaxiCode reader effectively always assumes PURE_BARCODE mode
    // and can't detect it in an image
    final bits = _extractPureBits(image.blackMatrix);
    final decoderResult = _decoder.decode(bits, hints);
    final result = Result(
      decoderResult.text,
      decoderResult.rawBytes,
      _noPoints,
      BarcodeFormat.maxicode,
    );

    result.putMetadata(
      ResultMetadataType.errorsCorrected,
      decoderResult.errorsCorrected ?? 0,
    );
    final ecLevel = decoderResult.ecLevel;
    if (ecLevel != null) {
      result.putMetadata(ResultMetadataType.errorCorrectionLevel, ecLevel);
    }
    return result;
  }

  @override
  void reset() {
    // do nothing
  }

  /// This method detects a code in a "pure" image -- that is, pure monochrome image
  /// which contains only an unrotated, unskewed, image of a code, with some white border
  /// around it. This is a specialized method that works exceptionally fast in this special
  /// case.
  static BitMatrix _extractPureBits(BitMatrix image) {
    final enclosingRectangle = image.getEnclosingRectangle();
    if (enclosingRectangle == null) {
      throw NotFoundException.instance;
    }

    final left = enclosingRectangle[0];
    final top = enclosingRectangle[1];
    final width = enclosingRectangle[2];
    final height = enclosingRectangle[3];

    // Now just read off the bits
    final bits = BitMatrix(_matrixWidth, _matrixHeight);
    for (int y = 0; y < _matrixHeight; y++) {
      final iy = top +
          math.min<int>(
            (y * height + height ~/ 2) ~/ _matrixHeight,
            height - 1,
          );
      for (int x = 0; x < _matrixWidth; x++) {
        // srowen: I don't quite understand why the formula below is necessary, but it
        // can walk off the image if left + width = the right boundary. So cap it.
        final ix = left +
            math.min<int>(
              (x * width + width ~/ 2 + (y & 0x01) * width ~/ 2) ~/
                  _matrixWidth,
              width - 1,
            );
        if (image.get(ix, iy)) {
          bits.set(x, y);
        }
      }
    }
    return bits;
  }
}
