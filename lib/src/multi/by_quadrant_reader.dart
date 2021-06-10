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
import '../result.dart';
import '../result_point.dart';

/// This class attempts to decode a barcode from an image, not by scanning the whole image,
/// but by scanning subsets of the image.
///
/// This is important when there may be multiple barcodes in
/// an image, and detecting a barcode may find parts of multiple barcode and fail to decode
/// (e.g. QR Codes). Instead this scans the four quadrants of the image -- and also the center
/// 'quadrant' to cover the case where a barcode is found in the center.
///
/// See [GenericMultipleBarcodeReader]
class ByQuadrantReader implements Reader {
  final Reader _delegate;

  ByQuadrantReader(this._delegate);

  @override
  Result decode(BinaryBitmap image, [Map<DecodeHintType, Object>? hints]) {
    int width = image.width;
    int height = image.height;
    int halfWidth = width ~/ 2;
    int halfHeight = height ~/ 2;

    try {
      // No need to call makeAbsolute as results will be relative to original top left here
      return _delegate.decode(image.crop(0, 0, halfWidth, halfHeight), hints);
    } on NotFoundException catch (_) {
      // continue
    }

    try {
      Result result = _delegate.decode(
          image.crop(halfWidth, 0, halfWidth, halfHeight), hints);
      _makeAbsolute(result.resultPoints, halfWidth, 0);
      return result;
    } on NotFoundException catch (_) {
      // continue
    }

    try {
      Result result = _delegate.decode(
          image.crop(0, halfHeight, halfWidth, halfHeight), hints);
      _makeAbsolute(result.resultPoints, 0, halfHeight);
      return result;
    } on NotFoundException catch (_) {
      // continue
    }

    try {
      Result result = _delegate.decode(
          image.crop(halfWidth, halfHeight, halfWidth, halfHeight), hints);
      _makeAbsolute(result.resultPoints, halfWidth, halfHeight);
      return result;
    } on NotFoundException catch (_) {
      // continue
    }

    int quarterWidth = halfWidth ~/ 2;
    int quarterHeight = halfHeight ~/ 2;
    BinaryBitmap center =
        image.crop(quarterWidth, quarterHeight, halfWidth, halfHeight);
    Result result = _delegate.decode(center, hints);
    _makeAbsolute(result.resultPoints, quarterWidth, quarterHeight);
    return result;
  }

  @override
  void reset() {
    _delegate.reset();
  }

  static void _makeAbsolute(
      List<ResultPoint?>? points, int leftOffset, int topOffset) {
    if (points != null) {
      for (int i = 0; i < points.length; i++) {
        ResultPoint? relative = points[i];
        if (relative != null) {
          points[i] = ResultPoint(
              relative.x + leftOffset, relative.y + topOffset);
        }
      }
    }
  }
}
