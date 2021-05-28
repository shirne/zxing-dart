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

import 'barcode_format.dart';
import 'result_metadata_type.dart';
import 'result_point.dart';

/**
 * <p>Encapsulates the result of decoding a barcode within an image.</p>
 *
 * @author Sean Owen
 */
class Result {
  final String text;
  final Uint8List? rawBytes;
  final int numBits;
  List<ResultPoint?>? resultPoints;
  final BarcodeFormat format;
  Map<ResultMetadataType, Object>? resultMetadata;
  final int timestamp;

  Result(this.text, this.rawBytes, this.resultPoints, this.format,
      [int? timestamp])
      : this.numBits = rawBytes == null ? 0 : 8 * rawBytes.length,
        this.timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Result.full(this.text, this.rawBytes, this.numBits, this.resultPoints,
      this.format, this.timestamp);

  /**
   * @return raw text encoded by the barcode
   */
  String getText() {
    return text;
  }

  /**
   * @return raw bytes encoded by the barcode, if applicable, otherwise {@code null}
   */
  Uint8List? getRawBytes() {
    return rawBytes;
  }

  /**
   * @return how many bits of {@link #getRawBytes()} are valid; typically 8 times its length
   * @since 3.3.0
   */
  int getNumBits() {
    return numBits;
  }

  /**
   * @return points related to the barcode in the image. These are typically points
   *         identifying finder patterns or the corners of the barcode. The exact meaning is
   *         specific to the type of barcode that was decoded.
   */
  List<ResultPoint?>? getResultPoints() {
    return resultPoints;
  }

  /**
   * @return {@link BarcodeFormat} representing the format of the barcode that was decoded
   */
  BarcodeFormat getBarcodeFormat() {
    return format;
  }

  /**
   * @return {@link Map} mapping {@link ResultMetadataType} keys to values. May be
   *   {@code null}. This contains optional metadata about what was detected about the barcode,
   *   like orientation.
   */
  Map<ResultMetadataType, Object>? getResultMetadata() {
    return resultMetadata;
  }

  void putMetadata(ResultMetadataType type, Object value) {
    if (resultMetadata == null) {
      resultMetadata = ResultMetadataType.values
          .asMap()
          .map<ResultMetadataType, Object>((idx, item) => MapEntry(item, item));
    }
    resultMetadata![type] = value;
  }

  void putAllMetadata(Map<ResultMetadataType, Object>? metadata) {
    if (metadata != null) {
      if (resultMetadata == null) {
        resultMetadata = metadata;
      } else {
        resultMetadata!.addAll(metadata);
      }
    }
  }

  void addResultPoints(List<ResultPoint?>? newPoints) {
    if(newPoints != null)resultPoints!.addAll(newPoints);
  }

  int getTimestamp() {
    return timestamp;
  }

  @override
  String toString() {
    return text;
  }
}
