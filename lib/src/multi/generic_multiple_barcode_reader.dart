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

import '../binary_bitmap.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../reader_exception.dart';
import '../result.dart';
import '../result_point.dart';
import 'multiple_barcode_reader.dart';

/// Attempts to locate multiple barcodes in an image by repeatedly decoding portion of the image.
/// After one barcode is found, the areas left, above, right and below the barcode's
/// [ResultPoint]s are scanned, recursively.
///
/// A caller may want to also employ [ByQuadrantReader] when attempting to find multiple
/// 2D barcodes, like QR Codes, in an image, where the presence of multiple barcodes might prevent
/// detecting any one of them.
///
/// That is, instead of passing a [Reader] a caller might pass
/// `ByQuadrantReader(reader)`.
///
/// @author Sean Owen
class GenericMultipleBarcodeReader implements MultipleBarcodeReader {
  static const int _MIN_DIMENSION_TO_RECUR = 100;
  static const int _MAX_DEPTH = 4;

  static const List<Result> EMPTY_RESULT_ARRAY = [];

  final Reader _delegate;

  GenericMultipleBarcodeReader(this._delegate);

  @override
  List<Result> decodeMultiple(BinaryBitmap image,
      [Map<DecodeHintType, Object>? hints]) {
    final results = <Result>[];
    _doDecodeMultiple(image, hints, results, 0, 0, 0);
    if (results.isEmpty) {
      throw NotFoundException.instance;
    }
    return results.toList();
  }

  void _doDecodeMultiple(BinaryBitmap image, Map<DecodeHintType, Object>? hints,
      List<Result> results, int xOffset, int yOffset, int currentDepth) {
    if (currentDepth > _MAX_DEPTH) {
      return;
    }

    Result result;
    try {
      result = _delegate.decode(image, hints);
    } on ReaderException catch (_) {
      return;
    }
    bool alreadyFound = false;
    for (Result existingResult in results) {
      if (existingResult.text == result.text) {
        alreadyFound = true;
        break;
      }
    }
    if (!alreadyFound) {
      results.add(_translateResultPoints(result, xOffset, yOffset));
    }
    final resultPoints = result.resultPoints;
    if (resultPoints == null || resultPoints.isEmpty) {
      return;
    }
    final width = image.width;
    final height = image.height;
    double minX = width.toDouble();
    double minY = height.toDouble();
    double maxX = 0.0;
    double maxY = 0.0;
    for (ResultPoint? point in resultPoints) {
      if (point == null) {
        continue;
      }
      final x = point.x;
      final y = point.y;
      if (x < minX) {
        minX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y > maxY) {
        maxY = y;
      }
    }

    // Decode left of barcode
    if (minX > _MIN_DIMENSION_TO_RECUR) {
      _doDecodeMultiple(image.crop(0, 0, minX.toInt(), height), hints, results,
          xOffset, yOffset, currentDepth + 1);
    }
    // Decode above barcode
    if (minY > _MIN_DIMENSION_TO_RECUR) {
      _doDecodeMultiple(image.crop(0, 0, width, minY.toInt()), hints, results,
          xOffset, yOffset, currentDepth + 1);
    }
    // Decode right of barcode
    if (maxX < width - _MIN_DIMENSION_TO_RECUR) {
      _doDecodeMultiple(
          image.crop(maxX.toInt(), 0, width - maxX.toInt(), height),
          hints,
          results,
          xOffset + maxX.toInt(),
          yOffset,
          currentDepth + 1);
    }
    // Decode below barcode
    if (maxY < height - _MIN_DIMENSION_TO_RECUR) {
      _doDecodeMultiple(
        image.crop(0, maxY.toInt(), width, height - maxY.toInt()),
        hints,
        results,
        xOffset,
        yOffset + maxY.toInt(),
        currentDepth + 1,
      );
    }
  }

  static Result _translateResultPoints(
      Result result, int xOffset, int yOffset) {
    final oldResultPoints = result.resultPoints;
    if (oldResultPoints == null) {
      return result;
    }
    final newResultPoints = <ResultPoint>[];
    for (int i = 0; i < oldResultPoints.length; i++) {
      final oldPoint = oldResultPoints[i];
      if (oldPoint != null) {
        newResultPoints
            .add(ResultPoint(oldPoint.x + xOffset, oldPoint.y + yOffset));
      }
    }
    final newResult = Result.full(
      result.text,
      result.rawBytes,
      result.numBits,
      newResultPoints,
      result.barcodeFormat,
      result.timestamp,
    );
    newResult.putAllMetadata(result.resultMetadata);
    return newResult;
  }
}
