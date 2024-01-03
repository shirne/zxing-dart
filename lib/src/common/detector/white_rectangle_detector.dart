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

import '../../not_found_exception.dart';
import '../../result_point.dart';
import '../bit_matrix.dart';
import 'math_utils.dart';

/// Detects a candidate barcode-like rectangular region within an image.
///
/// It starts around the center of the image, increases the size of the candidate
/// region until it finds a white rectangular region. By keeping track of the
/// last black points it encountered, it determines the corners of the barcode.
///
/// @author David Olivier
class WhiteRectangleDetector {
  static const int _initSize = 10;
  static const int _corr = 1;

  final BitMatrix _image;
  final int _height;
  final int _width;
  final int _leftInit;
  final int _rightInit;
  final int _downInit;
  final int _upInit;

  /// @param image barcode image to find a rectangle in
  /// @param initSize initial size of search area around center
  /// @param x x position of search center
  /// @param y y position of search center
  /// @throws NotFoundException if image is too small to accommodate `initSize`
  WhiteRectangleDetector(
    this._image, [
    int initSize = _initSize,
    int? x,
    int? y,
  ])  : _height = _image.height,
        _width = _image.width,
        _leftInit = (x ?? _image.width ~/ 2) - initSize ~/ 2,
        _rightInit = (x ?? _image.width ~/ 2) + initSize ~/ 2,
        _upInit = (y ?? _image.height ~/ 2) - initSize ~/ 2,
        _downInit = (y ?? _image.height ~/ 2) + initSize ~/ 2 {
    if (_upInit < 0 ||
        _leftInit < 0 ||
        _downInit >= _height ||
        _rightInit >= _width) {
      throw NotFoundException.instance;
    }
  }

  /// <p>
  /// Detects a candidate barcode-like rectangular region within an image. It
  /// starts around the center of the image, increases the size of the candidate
  /// region until it finds a white rectangular region.
  /// </p>
  ///
  /// @return [ResultPoint][] describing the corners of the rectangular
  ///         region. The first and last points are opposed on the diagonal, as
  ///         are the second and third. The first point will be the topmost
  ///         point and the last, the bottommost. The second point will be
  ///         leftmost and the third, the rightmost
  /// @throws NotFoundException if no Data Matrix Code can be found
  List<ResultPoint> detect() {
    int left = _leftInit;
    int right = _rightInit;
    int up = _upInit;
    int down = _downInit;
    bool sizeExceeded = false;
    bool aBlackPointFoundOnBorder = true;

    bool atLeastOneBlackPointFoundOnRight = false;
    bool atLeastOneBlackPointFoundOnBottom = false;
    bool atLeastOneBlackPointFoundOnLeft = false;
    bool atLeastOneBlackPointFoundOnTop = false;

    while (aBlackPointFoundOnBorder) {
      aBlackPointFoundOnBorder = false;

      // .....
      // .   |
      // .....
      bool rightBorderNotWhite = true;
      while ((rightBorderNotWhite || !atLeastOneBlackPointFoundOnRight) &&
          right < _width) {
        rightBorderNotWhite = containsBlackPoint(up, down, right, false);
        if (rightBorderNotWhite) {
          right++;
          aBlackPointFoundOnBorder = true;
          atLeastOneBlackPointFoundOnRight = true;
        } else if (!atLeastOneBlackPointFoundOnRight) {
          right++;
        }
      }

      if (right >= _width) {
        sizeExceeded = true;
        break;
      }

      // .....
      // .   .
      // .___.
      bool bottomBorderNotWhite = true;
      while ((bottomBorderNotWhite || !atLeastOneBlackPointFoundOnBottom) &&
          down < _height) {
        bottomBorderNotWhite = containsBlackPoint(left, right, down, true);
        if (bottomBorderNotWhite) {
          down++;
          aBlackPointFoundOnBorder = true;
          atLeastOneBlackPointFoundOnBottom = true;
        } else if (!atLeastOneBlackPointFoundOnBottom) {
          down++;
        }
      }

      if (down >= _height) {
        sizeExceeded = true;
        break;
      }

      // .....
      // |   .
      // .....
      bool leftBorderNotWhite = true;
      while ((leftBorderNotWhite || !atLeastOneBlackPointFoundOnLeft) &&
          left >= 0) {
        leftBorderNotWhite = containsBlackPoint(up, down, left, false);
        if (leftBorderNotWhite) {
          left--;
          aBlackPointFoundOnBorder = true;
          atLeastOneBlackPointFoundOnLeft = true;
        } else if (!atLeastOneBlackPointFoundOnLeft) {
          left--;
        }
      }

      if (left < 0) {
        sizeExceeded = true;
        break;
      }

      // .___.
      // .   .
      // .....
      bool topBorderNotWhite = true;
      while (
          (topBorderNotWhite || !atLeastOneBlackPointFoundOnTop) && up >= 0) {
        topBorderNotWhite = containsBlackPoint(left, right, up, true);
        if (topBorderNotWhite) {
          up--;
          aBlackPointFoundOnBorder = true;
          atLeastOneBlackPointFoundOnTop = true;
        } else if (!atLeastOneBlackPointFoundOnTop) {
          up--;
        }
      }

      if (up < 0) {
        sizeExceeded = true;
        break;
      }
    }

    if (!sizeExceeded) {
      final maxSize = right - left;

      ResultPoint? z;
      for (int i = 1; z == null && i < maxSize; i++) {
        z = getBlackPointOnSegment(
          left.toDouble(),
          (down - i).toDouble(),
          (left + i).toDouble(),
          down.toDouble(),
        );
      }

      if (z == null) {
        throw NotFoundException.instance;
      }

      ResultPoint? t;
      //go down right
      for (int i = 1; t == null && i < maxSize; i++) {
        t = getBlackPointOnSegment(
          left.toDouble(),
          (up + i).toDouble(),
          (left + i).toDouble(),
          up.toDouble(),
        );
      }

      if (t == null) {
        throw NotFoundException.instance;
      }

      ResultPoint? x;
      //go down left
      for (int i = 1; x == null && i < maxSize; i++) {
        x = getBlackPointOnSegment(
          right.toDouble(),
          (up + i).toDouble(),
          (right - i).toDouble(),
          up.toDouble(),
        );
      }

      if (x == null) {
        throw NotFoundException.instance;
      }

      ResultPoint? y;
      //go up left
      for (int i = 1; y == null && i < maxSize; i++) {
        y = getBlackPointOnSegment(
          right.toDouble(),
          (down - i).toDouble(),
          (right - i).toDouble(),
          down.toDouble(),
        );
      }

      if (y == null) {
        throw NotFoundException.instance;
      }

      return centerEdges(y, z, x, t);
    } else {
      throw NotFoundException.instance;
    }
  }

  ResultPoint? getBlackPointOnSegment(
    double aX,
    double aY,
    double bX,
    double bY,
  ) {
    final dist = MathUtils.round(MathUtils.distance(aX, aY, bX, bY));
    final xStep = (bX - aX) / dist;
    final yStep = (bY - aY) / dist;

    for (int i = 0; i < dist; i++) {
      final x = MathUtils.round(aX + i * xStep);
      final y = MathUtils.round(aY + i * yStep);
      if (_image.get(x, y)) {
        return ResultPoint(x.toDouble(), y.toDouble());
      }
    }
    return null;
  }

  /// recenters the points of a constant distance towards the center
  ///
  /// @param y bottom most point
  /// @param z left most point
  /// @param x right most point
  /// @param t top most point
  /// @return [ResultPoint][] describing the corners of the rectangular
  ///         region. The first and last points are opposed on the diagonal, as
  ///         are the second and third. The first point will be the topmost
  ///         point and the last, the bottommost. The second point will be
  ///         leftmost and the third, the rightmost
  List<ResultPoint> centerEdges(
    ResultPoint y,
    ResultPoint z,
    ResultPoint x,
    ResultPoint t,
  ) {
    //
    //       t            t
    //  z                      x
    //        x    OR    z
    //   y                    y
    //

    final yi = y.x;
    final yj = y.y;
    final zi = z.x;
    final zj = z.y;
    final xi = x.x;
    final xj = x.y;
    final ti = t.x;
    final tj = t.y;

    if (yi < _width / 2.0) {
      return [
        ResultPoint(ti - _corr, tj + _corr),
        ResultPoint(zi + _corr, zj + _corr),
        ResultPoint(xi - _corr, xj - _corr),
        ResultPoint(yi + _corr, yj - _corr),
      ];
    } else {
      return [
        ResultPoint(ti + _corr, tj + _corr),
        ResultPoint(zi + _corr, zj - _corr),
        ResultPoint(xi - _corr, xj + _corr),
        ResultPoint(yi - _corr, yj - _corr),
      ];
    }
  }

  /// Determines whether a segment contains a black point
  ///
  /// @param a          min value of the scanned coordinate
  /// @param b          max value of the scanned coordinate
  /// @param fixed      value of fixed coordinate
  /// @param horizontal set to true if scan must be horizontal, false if vertical
  /// @return true if a black point has been found, else false.
  bool containsBlackPoint(int a, int b, int fixed, bool horizontal) {
    if (horizontal) {
      for (int x = a; x <= b; x++) {
        if (_image.get(x, fixed)) {
          return true;
        }
      }
    } else {
      for (int y = a; y <= b; y++) {
        if (_image.get(fixed, y)) {
          return true;
        }
      }
    }

    return false;
  }
}
