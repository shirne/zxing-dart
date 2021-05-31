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

import 'dart:typed_data';

import '../barcode_format.dart';
import '../common/bit_matrix.dart';
import '../common/decoder_result.dart';
import '../common/detector_result.dart';

import '../binary_bitmap.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'decoder/decoder.dart';
import 'detector/detector.dart';

/**
 * This implementation can detect and decode Data Matrix codes in an image.
 *
 * @author bbrown@google.com (Brian Brown)
 */
class DataMatrixReader implements Reader {
  static const List<ResultPoint> _NO_POINTS = [];

  final Decoder _decoder = Decoder();

  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    DecoderResult decoderResult;
    List<ResultPoint> points;
    if (hints != null && hints.containsKey(DecodeHintType.PURE_BARCODE)) {
      BitMatrix bits = _extractPureBits(image.getBlackMatrix());
      decoderResult = _decoder.decodeMatrix(bits);
      points = _NO_POINTS;
    } else {
      DetectorResult detectorResult = Detector(image.getBlackMatrix()).detect();
      decoderResult = _decoder.decodeMatrix(detectorResult.getBits());
      points = detectorResult.getPoints();
    }
    Result result = Result(decoderResult.getText(),
        decoderResult.getRawBytes(), points, BarcodeFormat.DATA_MATRIX);
    List<Uint8List>? byteSegments = decoderResult.getByteSegments();
    if (byteSegments != null) {
      result.putMetadata(ResultMetadataType.BYTE_SEGMENTS, byteSegments);
    }
    String? ecLevel = decoderResult.getECLevel();
    if (ecLevel != null) {
      result.putMetadata(ResultMetadataType.ERROR_CORRECTION_LEVEL, ecLevel);
    }
    result.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER,
        "]d${decoderResult.getSymbologyModifier()}");
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
  static BitMatrix _extractPureBits(BitMatrix image) {
    List<int>? leftTopBlack = image.getTopLeftOnBit();
    List<int>? rightBottomBlack = image.getBottomRightOnBit();
    if (leftTopBlack == null || rightBottomBlack == null) {
      throw NotFoundException.getNotFoundInstance();
    }

    int calModuleSize = _moduleSize(leftTopBlack, image);

    int top = leftTopBlack[1];
    int bottom = rightBottomBlack[1];
    int left = leftTopBlack[0];
    int right = rightBottomBlack[0];

    int matrixWidth = (right - left + 1) ~/ calModuleSize;
    int matrixHeight = (bottom - top + 1) ~/ calModuleSize;
    if (matrixWidth <= 0 || matrixHeight <= 0) {
      throw NotFoundException.getNotFoundInstance();
    }

    // Push in the "border" by half the module width so that we start
    // sampling in the middle of the module. Just in case the image is a
    // little off, this will help recover.
    int nudge = calModuleSize ~/ 2;
    top += nudge;
    left += nudge;

    // Now just read off the bits
    BitMatrix bits = BitMatrix(matrixWidth, matrixHeight);
    for (int y = 0; y < matrixHeight; y++) {
      int iOffset = top + y * calModuleSize;
      for (int x = 0; x < matrixWidth; x++) {
        if (image.get(left + x * calModuleSize, iOffset)) {
          bits.set(x, y);
        }
      }
    }
    return bits;
  }

  static int _moduleSize(List<int> leftTopBlack, BitMatrix image) {
    int width = image.getWidth();
    int x = leftTopBlack[0];
    int y = leftTopBlack[1];
    while (x < width && image.get(x, y)) {
      x++;
    }
    if (x == width) {
      throw NotFoundException.getNotFoundInstance();
    }

    int moduleSize = x - leftTopBlack[0];
    if (moduleSize == 0) {
      throw NotFoundException.getNotFoundInstance();
    }
    return moduleSize;
  }
}
