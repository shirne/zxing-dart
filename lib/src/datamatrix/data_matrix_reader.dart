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

import '../barcode_format.dart';
import '../common/bit_matrix.dart';
import '../common/decoder_result.dart';

import '../binary_bitmap.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'decoder/decoder.dart';
import 'detector/detector.dart';

/// This implementation can detect and decode Data Matrix codes in an image.
///
/// @author bbrown@google.com (Brian Brown)
class DataMatrixReader implements Reader {
  static const List<ResultPoint> _noPoints = [];

  final Decoder _decoder = Decoder();

  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    DecoderResult decoderResult;
    List<ResultPoint> points;
    if (hints != null && hints.containsKey(DecodeHintType.pureBarcode)) {
      final bits = _extractPureBits(image.blackMatrix);
      decoderResult = _decoder.decodeMatrix(bits);
      points = _noPoints;
    } else {
      final detectorResult = Detector(image.blackMatrix).detect();
      decoderResult = _decoder.decodeMatrix(detectorResult.bits);
      points = detectorResult.points;
    }
    final result = Result(
      decoderResult.text,
      decoderResult.rawBytes,
      points,
      BarcodeFormat.dataMatrix,
    );
    final byteSegments = decoderResult.byteSegments;
    if (byteSegments != null) {
      result.putMetadata(ResultMetadataType.byteSegments, byteSegments);
    }
    final ecLevel = decoderResult.ecLevel;
    if (ecLevel != null) {
      result.putMetadata(ResultMetadataType.errorCorrectionLevel, ecLevel);
    }
    result.putMetadata(
      ResultMetadataType.symbologyIdentifier,
      ']d${decoderResult.symbologyModifier}',
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
    final right = rightBottomBlack[0];

    final matrixWidth = (right - left + 1) ~/ calModuleSize;
    final matrixHeight = (bottom - top + 1) ~/ calModuleSize;
    if (matrixWidth <= 0 || matrixHeight <= 0) {
      throw NotFoundException.instance;
    }

    // Push in the "border" by half the module width so that we start
    // sampling in the middle of the module. Just in case the image is a
    // little off, this will help recover.
    final nudge = calModuleSize ~/ 2;
    top += nudge;
    left += nudge;

    // Now just read off the bits
    final bits = BitMatrix(matrixWidth, matrixHeight);
    for (int y = 0; y < matrixHeight; y++) {
      final iOffset = top + y * calModuleSize;
      for (int x = 0; x < matrixWidth; x++) {
        if (image.get(left + x * calModuleSize, iOffset)) {
          bits.set(x, y);
        }
      }
    }
    return bits;
  }

  static int _moduleSize(List<int> leftTopBlack, BitMatrix image) {
    final width = image.width;
    int x = leftTopBlack[0];
    final y = leftTopBlack[1];
    while (x < width && image.get(x, y)) {
      x++;
    }
    if (x == width) {
      throw NotFoundException.instance;
    }

    final moduleSize = x - leftTopBlack[0];
    if (moduleSize == 0) {
      throw NotFoundException.instance;
    }
    return moduleSize;
  }
}
