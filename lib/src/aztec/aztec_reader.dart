/*
 * Copyright 2010 ZXing authors
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
import '../binary_bitmap.dart';
import '../common/decoder_result.dart';
import '../decode_hint_type.dart';
import '../formats_exception.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import '../result_point_callback.dart';
import 'aztec_detector_result.dart';
import 'decoder/decoder.dart';
import 'detector/detector.dart';

/// This implementation can detect and decode Aztec codes in an image.
///
/// @author David Olivier
class AztecReader implements Reader {
  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    NotFoundException? notFoundException;
    FormatsException? formatException;
    Detector detector = Detector(image.blackMatrix);
    List<ResultPoint>? points;
    DecoderResult? decoderResult;
    try {
      AztecDetectorResult detectorResult = detector.detect(false);
      points = detectorResult.points;
      decoderResult = Decoder().decode(detectorResult);
    } on NotFoundException catch (e) {
      notFoundException = e;
    } on FormatsException catch (e) {
      formatException = e;
    }
    if (decoderResult == null) {
      try {
        AztecDetectorResult detectorResult = detector.detect(true);
        points = detectorResult.points;
        decoderResult = Decoder().decode(detectorResult);
      } on NotFoundException catch (_) {
        if (notFoundException != null) {
          throw notFoundException;
        }
        rethrow;
      } on FormatsException catch (_) {
        if (formatException != null) {
          throw formatException;
        }
        rethrow;
      }
    }

    if (hints != null) {
      ResultPointCallback? rpcb =
          hints[DecodeHintType.NEED_RESULT_POINT_CALLBACK]
              as ResultPointCallback?;
      if (rpcb != null) {
        for (ResultPoint point in points!) {
          rpcb.foundPossibleResultPoint(point);
        }
      }
    }

    Result result = Result.full(
        decoderResult.text,
        decoderResult.rawBytes,
        decoderResult.numBits,
        points!,
        BarcodeFormat.AZTEC,
        DateTime.now().millisecondsSinceEpoch);

    List<Uint8List>? byteSegments = decoderResult.byteSegments;
    if (byteSegments != null) {
      result.putMetadata(ResultMetadataType.BYTE_SEGMENTS, byteSegments);
    }
    String? ecLevel = decoderResult.ecLevel;
    if (ecLevel != null) {
      result.putMetadata(ResultMetadataType.ERROR_CORRECTION_LEVEL, ecLevel);
    }
    result.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER,
        "]z${decoderResult.symbologyModifier}");

    return result;
  }

  @override
  void reset() {
    // do nothing
  }
}
