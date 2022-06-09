/*
 * Copyright 2009 ZXing authors
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
import '../checksum_exception.dart';
import '../common/decoder_result.dart';
import '../common/detector/math_utils.dart';
import '../decode_hint_type.dart';
import '../formats_exception.dart';
import '../multi/multiple_barcode_reader.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'decoder/pdf417_scanning_decoder.dart';
import 'detector/detector.dart';
import 'detector/pdf417_detector_result.dart';
import 'pdf417_common.dart';
import 'pdf417_result_metadata.dart';

/// This implementation can detect and decode PDF417 codes in an image.
///
/// @author Guenther Grau
class PDF417Reader implements Reader, MultipleBarcodeReader {
  //static const List<Result> _EMPTY_RESULT_ARRAY = [];

  /// Locates and decodes a PDF417 code in an image.
  ///
  /// @return a String representing the content encoded by the PDF417 code
  /// @throws NotFoundException if a PDF417 code cannot be found,
  /// @throws FormatException if a PDF417 cannot be decoded
  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    List<Result> result = _decodeStatic(image, hints, false);
    if (result.isEmpty) {
      // || result[0] == null
      throw NotFoundException.instance;
    }
    return result[0];
  }

  @override
  List<Result> decodeMultiple(BinaryBitmap image,
      [Map<DecodeHintType, Object>? hints]) {
    try {
      return _decodeStatic(image, hints, true);
    } on FormatsException catch (_) {
      throw NotFoundException.instance;
    } on ChecksumException catch (_) {
      throw NotFoundException.instance;
    }
  }

  static List<Result> _decodeStatic(BinaryBitmap image,
      [Map<DecodeHintType, Object>? hints, bool multiple = true]) {
    List<Result> results = [];
    PDF417DetectorResult detectorResult =
        Detector.detect(image, hints, multiple);
    for (List<ResultPoint?> points in detectorResult.points) {
      DecoderResult decoderResult = PDF417ScanningDecoder.decode(
          detectorResult.bits,
          points[4],
          points[5],
          points[6],
          points[7],
          _getMinCodewordWidth(points),
          _getMaxCodewordWidth(points));
      Result result = Result(decoderResult.text, decoderResult.rawBytes, points,
          BarcodeFormat.PDF_417);
      result.putMetadata(
          ResultMetadataType.ERROR_CORRECTION_LEVEL, decoderResult.ecLevel!);
      PDF417ResultMetadata? pdf417ResultMetadata =
          decoderResult.other as PDF417ResultMetadata?;
      if (pdf417ResultMetadata != null) {
        result.putMetadata(
            ResultMetadataType.PDF417_EXTRA_METADATA, pdf417ResultMetadata);
      }
      result.putMetadata(
          ResultMetadataType.ORIENTATION, detectorResult.rotation);
      result.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER,
          "]L${decoderResult.symbologyModifier}");
      results.add(result);
    }
    return results;
  }

  static int _getMaxWidth(ResultPoint? p1, ResultPoint? p2) {
    if (p1 == null || p2 == null) {
      return 0;
    }
    return (p1.x - p2.x).abs().toInt();
  }

  static int _getMinWidth(ResultPoint? p1, ResultPoint? p2) {
    if (p1 == null || p2 == null) {
      return MathUtils.MAX_VALUE; // Integer.MAX_VALUE;
    }
    return (p1.x - p2.x).abs().toInt();
  }

  static int _getMaxCodewordWidth(List<ResultPoint?> p) {
    return math.max(
        math.max(
            _getMaxWidth(p[0], p[4]),
            _getMaxWidth(p[6], p[2]) *
                PDF417Common.MODULES_IN_CODEWORD ~/
                PDF417Common.MODULES_IN_STOP_PATTERN),
        math.max(
            _getMaxWidth(p[1], p[5]),
            _getMaxWidth(p[7], p[3]) *
                PDF417Common.MODULES_IN_CODEWORD ~/
                PDF417Common.MODULES_IN_STOP_PATTERN));
  }

  static int _getMinCodewordWidth(List<ResultPoint?> p) {
    return math.min(
        math.min(
            _getMinWidth(p[0], p[4]),
            _getMinWidth(p[6], p[2]) *
                PDF417Common.MODULES_IN_CODEWORD ~/
                PDF417Common.MODULES_IN_STOP_PATTERN),
        math.min(
            _getMinWidth(p[1], p[5]),
            _getMinWidth(p[7], p[3]) *
                PDF417Common.MODULES_IN_CODEWORD ~/
                PDF417Common.MODULES_IN_STOP_PATTERN));
  }

  @override
  void reset() {
    // nothing needs to be reset
  }
}
