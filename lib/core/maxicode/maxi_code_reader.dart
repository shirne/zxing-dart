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

import 'dart:math' as Math;

import 'package:zxing/core/common/bit_matrix.dart';
import 'package:zxing/core/common/decoder_result.dart';

import '../barcode_format.dart';
import '../binary_bitmap.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'decoder/decoder.dart';

/**
 * This implementation can detect and decode a MaxiCode in an image.
 */
class MaxiCodeReader implements Reader {
  static final List<ResultPoint> NO_POINTS = [];
  static final int MATRIX_WIDTH = 30;
  static final int MATRIX_HEIGHT = 33;

  final Decoder decoder = Decoder();

  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    // Note that MaxiCode reader effectively always assumes PURE_BARCODE mode
    // and can't detect it in an image
    BitMatrix bits = extractPureBits(image.getBlackMatrix());
    DecoderResult decoderResult = decoder.decode(bits, hints);
    Result result = Result(decoderResult.getText(),
        decoderResult.getRawBytes(), NO_POINTS, BarcodeFormat.MAXICODE);

    String? ecLevel = decoderResult.getECLevel();
    if (ecLevel != null) {
      result.putMetadata(ResultMetadataType.ERROR_CORRECTION_LEVEL, ecLevel);
    }
    return result;
  }

  @override
  void reset() {
    // do nothing
  }

  /**
   * This method detects a code in a "pure" image -- that is, pure monochrome image
   * which contains only an unrotated, unskewed, image of a code, with some white border
   * around it. This is a specialized method that works exceptionally fast in this special
   * case.
   */
  static BitMatrix extractPureBits(BitMatrix image) {
    List<int>? enclosingRectangle = image.getEnclosingRectangle();
    if (enclosingRectangle == null) {
      throw NotFoundException.getNotFoundInstance();
    }

    int left = enclosingRectangle[0];
    int top = enclosingRectangle[1];
    int width = enclosingRectangle[2];
    int height = enclosingRectangle[3];

    // Now just read off the bits
    BitMatrix bits = BitMatrix(MATRIX_WIDTH, MATRIX_HEIGHT);
    for (int y = 0; y < MATRIX_HEIGHT; y++) {
      int iy = top + (y * height + height ~/ 2) ~/ MATRIX_HEIGHT;
      for (int x = 0; x < MATRIX_WIDTH; x++) {
        // srowen: I don't quite understand why the formula below is necessary, but it
        // can walk off the image if left + width = the right boundary. So cap it.
        int ix = left +
            Math.min(
                (x * width + width ~/ 2 + (y & 0x01) * width ~/ 2) ~/
                    MATRIX_WIDTH,
                width);
        if (image.get(ix, iy)) {
          bits.set(x, y);
        }
      }
    }
    return bits;
  }
}
