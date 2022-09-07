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

import '../common/bit_matrix.dart';
import '../common/decoder_result.dart';

import '../barcode_format.dart';
import '../binary_bitmap.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'decoder/decoder.dart';
import 'decoder/qrcode_decoder_meta_data.dart';
import 'detector/detector.dart';

/// This implementation can detect and decode QR Codes in an image.
///
/// @author Sean Owen
class QRCodeReader implements Reader {
  static final List<ResultPoint> _noPoints = [];

  final Decoder _decoder = Decoder();

  Decoder get decoder => _decoder;

  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    late DecoderResult decoderResult;
    late List<ResultPoint> points;
    if (hints != null && hints.containsKey(DecodeHintType.PURE_BARCODE)) {
      final bits = _extractPureBits(image.blackMatrix);
      decoderResult = _decoder.decodeMatrix(bits, hints);
      points = _noPoints;
    } else {
      final detectorResult = Detector(image.blackMatrix).detect(hints);
      decoderResult = _decoder.decodeMatrix(detectorResult.bits, hints);
      points = detectorResult.points;
    }

    // If the code was mirrored: swap the bottom-left and the top-right points.
    if (decoderResult.other is QRCodeDecoderMetaData) {
      (decoderResult.other as QRCodeDecoderMetaData)
          .applyMirroredCorrection(points);
    }

    final result = Result(
      decoderResult.text,
      decoderResult.rawBytes,
      points,
      BarcodeFormat.QR_CODE,
    );
    final byteSegments = decoderResult.byteSegments;
    if (byteSegments != null) {
      result.putMetadata(ResultMetadataType.BYTE_SEGMENTS, byteSegments);
    }
    final ecLevel = decoderResult.ecLevel;
    if (ecLevel != null) {
      result.putMetadata(ResultMetadataType.ERROR_CORRECTION_LEVEL, ecLevel);
    }
    if (decoderResult.hasStructuredAppend) {
      result.putMetadata(
        ResultMetadataType.STRUCTURED_APPEND_SEQUENCE,
        decoderResult.structuredAppendSequenceNumber,
      );
      result.putMetadata(
        ResultMetadataType.STRUCTURED_APPEND_PARITY,
        decoderResult.structuredAppendParity,
      );
    }
    result.putMetadata(
      ResultMetadataType.SYMBOLOGY_IDENTIFIER,
      ']Q${decoderResult.symbologyModifier}',
    );
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
    final leftTopBlack = image.getTopLeftOnBit();
    final rightBottomBlack = image.getBottomRightOnBit();
    if (leftTopBlack == null || rightBottomBlack == null) {
      throw NotFoundException.instance;
    }

    final calModuleSize = _moduleSize(leftTopBlack, image);

    int top = leftTopBlack[1];
    final bottom = rightBottomBlack[1];
    int left = leftTopBlack[0];
    int right = rightBottomBlack[0];

    // Sanity check!
    if (left >= right || top >= bottom) {
      throw NotFoundException.instance;
    }

    if (bottom - top != right - left) {
      // Special case, where bottom-right module wasn't black so we found something else in the last row
      // Assume it's a square, so use height as the width
      right = left + (bottom - top);
      if (right >= image.width) {
        // Abort if that would not make sense -- off image
        throw NotFoundException.instance;
      }
    }

    final matrixWidth = ((right - left + 1) / calModuleSize).round();
    final matrixHeight = ((bottom - top + 1) / calModuleSize).round();
    if (matrixWidth <= 0 || matrixHeight <= 0) {
      throw NotFoundException.instance;
    }
    if (matrixHeight != matrixWidth) {
      // Only possibly decode square regions
      throw NotFoundException.instance;
    }

    // Push in the "border" by half the module width so that we start
    // sampling in the middle of the module. Just in case the image is a
    // little off, this will help recover.
    final nudge = (calModuleSize ~/ 2.0);
    top += nudge;
    left += nudge;

    // But careful that this does not sample off the edge
    // "right" is the farthest-right valid pixel location -- right+1 is not necessarily
    // This is positive by how much the inner x loop below would be too large
    final nudgedTooFarRight =
        left + ((matrixWidth - 1) * calModuleSize).toInt() - right;
    if (nudgedTooFarRight > 0) {
      if (nudgedTooFarRight > nudge) {
        // Neither way fits; abort
        throw NotFoundException.instance;
      }
      left -= nudgedTooFarRight;
    }
    // See logic above
    final nudgedTooFarDown =
        top + ((matrixHeight - 1) * calModuleSize).toInt() - bottom;
    if (nudgedTooFarDown > 0) {
      if (nudgedTooFarDown > nudge) {
        // Neither way fits; abort
        throw NotFoundException.instance;
      }
      top -= nudgedTooFarDown;
    }

    // Now just read off the bits
    final bits = BitMatrix(matrixWidth, matrixHeight);
    for (int y = 0; y < matrixHeight; y++) {
      final iOffset = top + (y * calModuleSize).toInt();
      for (int x = 0; x < matrixWidth; x++) {
        if (image.get(left + (x * calModuleSize).toInt(), iOffset)) {
          bits.set(x, y);
        }
      }
    }
    return bits;
  }

  static double _moduleSize(List<int> leftTopBlack, BitMatrix image) {
    final height = image.height;
    final width = image.width;
    int x = leftTopBlack[0];
    int y = leftTopBlack[1];
    bool inBlack = true;
    int transitions = 0;
    while (x < width && y < height) {
      if (inBlack != image.get(x, y)) {
        if (++transitions == 5) {
          break;
        }
        inBlack = !inBlack;
      }
      x++;
      y++;
    }
    if (x == width || y == height) {
      throw NotFoundException.instance;
    }
    return (x - leftTopBlack[0]) / 7.0;
  }
}
