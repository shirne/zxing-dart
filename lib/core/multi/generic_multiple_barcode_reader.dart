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

/// <p>Attempts to locate multiple barcodes in an image by repeatedly decoding portion of the image.
/// After one barcode is found, the areas left, above, right and below the barcode's
/// {@link ResultPoint}s are scanned, recursively.</p>
///
/// <p>A caller may want to also employ {@link ByQuadrantReader} when attempting to find multiple
/// 2D barcodes, like QR Codes, in an image, where the presence of multiple barcodes might prevent
/// detecting any one of them.</p>
///
/// <p>That is, instead of passing a {@link Reader} a caller might pass
/// {@code new ByQuadrantReader(reader)}.</p>
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
    List<Result> results = [];
    _doDecodeMultiple(image, hints, results, 0, 0, 0);
    if (results.isEmpty) {
      throw NotFoundException.getNotFoundInstance();
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
      if (existingResult.getText() == result.getText()) {
        alreadyFound = true;
        break;
      }
    }
    if (!alreadyFound) {
      results.add(_translateResultPoints(result, xOffset, yOffset));
    }
    List<ResultPoint?>? resultPoints = result.getResultPoints();
    if (resultPoints == null || resultPoints.length == 0) {
      return;
    }
    int width = image.getWidth();
    int height = image.getHeight();
    double minX = width.toDouble();
    double minY = height.toDouble();
    double maxX = 0.0;
    double maxY = 0.0;
    for (ResultPoint? point in resultPoints) {
      if (point == null) {
        continue;
      }
      double x = point.getX();
      double y = point.getY();
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
          currentDepth + 1);
    }
  }

  static Result _translateResultPoints(Result result, int xOffset, int yOffset) {
    List<ResultPoint?>? oldResultPoints = result.getResultPoints();
    if (oldResultPoints == null) {
      return result;
    }
    List<ResultPoint> newResultPoints = [];
    for (int i = 0; i < oldResultPoints.length; i++) {
      ResultPoint? oldPoint = oldResultPoints[i];
      if (oldPoint != null) {
        newResultPoints.add(
            ResultPoint(oldPoint.getX() + xOffset, oldPoint.getY() + yOffset));
      }
    }
    Result newResult = Result.full(
        result.getText(),
        result.getRawBytes(),
        result.getNumBits(),
        newResultPoints,
        result.getBarcodeFormat(),
        result.getTimestamp());
    newResult.putAllMetadata(result.getResultMetadata());
    return newResult;
  }
}
