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

import 'dart:typed_data';

import '../../qrcode/decoder/qrcode_decoder_meta_data.dart';
import '../../common/decoder_result.dart';
import '../../barcode_format.dart';
import '../../common/detector_result.dart';
import '../../binary_bitmap.dart';
import '../../decode_hint_type.dart';
import '../../qrcode/qrcode_reader.dart';
import '../../reader_exception.dart';
import '../../result.dart';
import '../../result_metadata_type.dart';
import '../../result_point.dart';
import '../multiple_barcode_reader.dart';
import 'detector/multi_detector.dart';

/// This implementation can detect and decode multiple QR Codes in an image.
///
/// @author Sean Owen
/// @author Hannes Erven
class QRCodeMultiReader extends QRCodeReader implements MultipleBarcodeReader {
  static final List<Result> _emptyResultArray = [];
  static final List<ResultPoint> _noPoints = [];

  @override
  List<Result> decodeMultiple(BinaryBitmap image,
      [Map<DecodeHintType, Object>? hints]) {
    List<Result> results = [];
    List<DetectorResult> detectorResults =
        MultiDetector(image.blackMatrix).detectMulti(hints);
    for (DetectorResult detectorResult in detectorResults) {
      try {
        DecoderResult decoderResult =
            decoder.decodeMatrix(detectorResult.bits, hints);
        List<ResultPoint> points = detectorResult.points;
        // If the code was mirrored: swap the bottom-left and the top-right points.
        if (decoderResult.other is QRCodeDecoderMetaData) {
          (decoderResult.other as QRCodeDecoderMetaData)
              .applyMirroredCorrection(points);
        }
        Result result = Result(decoderResult.text, decoderResult.rawBytes,
            points, BarcodeFormat.QR_CODE);
        List<Uint8List>? byteSegments = decoderResult.byteSegments;
        if (byteSegments != null) {
          result.putMetadata(ResultMetadataType.BYTE_SEGMENTS, byteSegments);
        }
        String? ecLevel = decoderResult.ecLevel;
        if (ecLevel != null) {
          result.putMetadata(
              ResultMetadataType.ERROR_CORRECTION_LEVEL, ecLevel);
        }
        if (decoderResult.hasStructuredAppend) {
          result.putMetadata(ResultMetadataType.STRUCTURED_APPEND_SEQUENCE,
              decoderResult.structuredAppendSequenceNumber);
          result.putMetadata(ResultMetadataType.STRUCTURED_APPEND_PARITY,
              decoderResult.structuredAppendParity);
        }
        results.add(result);
      } on ReaderException catch (_) {
        // ignore and continue
      }
    }
    if (results.isEmpty) {
      return _emptyResultArray;
    } else {
      results = processStructuredAppend(results);
      return results.toList();
    }
  }

  static List<Result> processStructuredAppend(List<Result> results) {
    List<Result> newResults = [];
    List<Result> saResults = [];
    for (Result result in results) {
      if (result.resultMetadata!
          .containsKey(ResultMetadataType.STRUCTURED_APPEND_SEQUENCE)) {
        saResults.add(result);
      } else {
        newResults.add(result);
      }
    }
    if (saResults.isEmpty) {
      return results;
    }

    // sort and concatenate the SA list items
    saResults.sort(_compareResult);
    StringBuffer newText = StringBuffer();
    BytesBuilder newRawBytes = BytesBuilder();
    BytesBuilder newByteSegment = BytesBuilder();
    //ByteArrayOutputStream newRawBytes = ByteArrayOutputStream();
    //ByteArrayOutputStream newByteSegment = ByteArrayOutputStream();
    for (Result saResult in saResults) {
      newText.write(saResult.text);
      List<int>? saBytes = saResult.rawBytes;
      if (saBytes != null) newRawBytes.add(saBytes);
      // @SuppressWarnings("unchecked")
      Iterable<Uint8List>? byteSegments =
          saResult.resultMetadata?[ResultMetadataType.BYTE_SEGMENTS]
              as Iterable<Uint8List>?;
      if (byteSegments != null) {
        for (Uint8List segment in byteSegments) {
          newByteSegment.add(segment);
        }
      }
    }

    Result newResult = Result(
        newText.toString(),
        Uint8List.fromList(newRawBytes.takeBytes()),
        _noPoints,
        BarcodeFormat.QR_CODE);
    if (newByteSegment.length > 0) {
      newResult.putMetadata(
          ResultMetadataType.BYTE_SEGMENTS, [newByteSegment.toBytes()]);
    }
    newResults.add(newResult);
    return newResults;
  }

  static int _compareResult(Result a, Result b) {
    int aNumber =
        (a.resultMetadata![ResultMetadataType.STRUCTURED_APPEND_SEQUENCE]
                as int?) ??
            0;
    int bNumber =
        (b.resultMetadata![ResultMetadataType.STRUCTURED_APPEND_SEQUENCE]
                as int?) ??
            0;
    return aNumber.compareTo(bNumber);
  }
}
