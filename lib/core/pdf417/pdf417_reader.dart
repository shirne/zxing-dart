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

import 'dart:math' as Math;

import 'package:zxing/core/common/decoder_result.dart';
import 'package:zxing/core/multi/multiple_barcode_reader.dart';

import '../barcode_format.dart';
import '../binary_bitmap.dart';
import '../decode_hint_type.dart';
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

/**
 * This implementation can detect and decode PDF417 codes in an image.
 *
 * @author Guenther Grau
 */
class PDF417Reader implements Reader, MultipleBarcodeReader {
  static final List<Result> EMPTY_RESULT_ARRAY = [];

  /**
   * Locates and decodes a PDF417 code in an image.
   *
   * @return a String representing the content encoded by the PDF417 code
   * @throws NotFoundException if a PDF417 code cannot be found,
   * @throws FormatException if a PDF417 cannot be decoded
   */
  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    List<Result> result = decodeStatic(image, hints, false);
    if (result.length == 0 || result[0] == null) {
      throw NotFoundException.getNotFoundInstance();
    }
    return result[0];
  }

  static List<Result> decodeStatic(BinaryBitmap image,
      [Map<DecodeHintType, Object>? hints, bool multiple = true]) {
    List<Result> results = [];
    PDF417DetectorResult detectorResult =
        Detector.detect(image, hints, multiple);
    for (List<ResultPoint> points in detectorResult.getPoints()) {
      DecoderResult decoderResult = PDF417ScanningDecoder.decode(
          detectorResult.getBits(),
          points[4],
          points[5],
          points[6],
          points[7],
          getMinCodewordWidth(points),
          getMaxCodewordWidth(points));
      Result result = new Result(decoderResult.getText(),
          decoderResult.getRawBytes(), points, BarcodeFormat.PDF_417);
      result.putMetadata(ResultMetadataType.ERROR_CORRECTION_LEVEL,
          decoderResult.getECLevel()!);
      PDF417ResultMetadata pdf417ResultMetadata =
          decoderResult.getOther() as PDF417ResultMetadata;
      if (pdf417ResultMetadata != null) {
        result.putMetadata(
            ResultMetadataType.PDF417_EXTRA_METADATA, pdf417ResultMetadata);
      }
      result.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER,
          "]L${decoderResult.getSymbologyModifier()}");
      results.add(result);
    }
    return results.toList();
  }

  static int getMaxWidth(ResultPoint? p1, ResultPoint? p2) {
    if (p1 == null || p2 == null) {
      return 0;
    }
    return (p1.getX() - p2.getX()).abs().toInt();
  }

  static int getMinWidth(ResultPoint? p1, ResultPoint? p2) {
    if (p1 == null || p2 == null) {
      return -1 << 1; // Integer.MAX_VALUE;
    }
    return (p1.getX() - p2.getX()).abs().toInt();
  }

  static int getMaxCodewordWidth(List<ResultPoint> p) {
    return Math.max(
        Math.max(
            getMaxWidth(p[0], p[4]),
            getMaxWidth(p[6], p[2]) *
                PDF417Common.MODULES_IN_CODEWORD ~/
                PDF417Common.MODULES_IN_STOP_PATTERN),
        Math.max(
            getMaxWidth(p[1], p[5]),
            getMaxWidth(p[7], p[3]) *
                PDF417Common.MODULES_IN_CODEWORD ~/
                PDF417Common.MODULES_IN_STOP_PATTERN));
  }

  static int getMinCodewordWidth(List<ResultPoint> p) {
    return Math.min(
        Math.min(
            getMinWidth(p[0], p[4]),
            getMinWidth(p[6], p[2]) *
                PDF417Common.MODULES_IN_CODEWORD ~/
                PDF417Common.MODULES_IN_STOP_PATTERN),
        Math.min(
            getMinWidth(p[1], p[5]),
            getMinWidth(p[7], p[3]) *
                PDF417Common.MODULES_IN_CODEWORD ~/
                PDF417Common.MODULES_IN_STOP_PATTERN));
  }

  @override
  void reset() {
    // nothing needs to be reset
  }

  @override
  List<Result> decodeMultiple(BinaryBitmap image,
      [Map<DecodeHintType, Object>? hints]) {
    // TODO: implement decodeMultiple
    throw UnimplementedError();
  }
}
