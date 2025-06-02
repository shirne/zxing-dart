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

import '../../not_found_exception.dart';
import '../../result_point.dart';
import '../bit_matrix.dart';

/// A somewhat generic detector that looks for a barcode-like rectangular region within an image.
///
/// It looks within a mostly white region of an image for a region of black and white, but mostly
/// black. It returns the four corners of the region, as best it can determine.
///
/// @author Sean Owen
/// @deprecated without replacement since 3.3.0
@Deprecated('no replacement since 3.3.0')
class MonochromeRectangleDetector {
  static const int _maxModules = 32;

  final BitMatrix _image;

  MonochromeRectangleDetector(this._image);

  /// <p>Detects a rectangular region of black and white -- mostly black -- with a region of mostly
  /// white, in an image.</p>
  ///
  /// @return [ResultPoint][] describing the corners of the rectangular region. The first and
  ///  last points are opposed on the diagonal, as are the second and third. The first point will be
  ///  the topmost point and the last, the bottommost. The second point will be leftmost and the
  ///  third, the rightmost
  /// @throws NotFoundException if no Data Matrix Code can be found
  List<ResultPoint> detect() {
    final height = _image.height;
    final width = _image.width;
    final halfHeight = height ~/ 2;
    final halfWidth = width ~/ 2;
    final deltaY = math.max(1, height ~/ (_maxModules * 8));
    final deltaX = math.max(1, width ~/ (_maxModules * 8));

    int top = 0;
    int bottom = height;
    int left = 0;
    int right = width;
    ResultPoint pointA = findCornerFromCenter(
      halfWidth,
      0,
      left,
      right,
      halfHeight,
      -deltaY,
      top,
      bottom,
      halfWidth ~/ 2,
    );
    top = pointA.y.toInt() - 1;
    final pointB = findCornerFromCenter(
      halfWidth,
      -deltaX,
      left,
      right,
      halfHeight,
      0,
      top,
      bottom,
      halfHeight ~/ 2,
    );
    left = pointB.x.toInt() - 1;
    final pointC = findCornerFromCenter(
      halfWidth,
      deltaX,
      left,
      right,
      halfHeight,
      0,
      top,
      bottom,
      halfHeight ~/ 2,
    );
    right = pointC.x.toInt() + 1;
    final pointD = findCornerFromCenter(
      halfWidth,
      0,
      left,
      right,
      halfHeight,
      deltaY,
      top,
      bottom,
      halfWidth ~/ 2,
    );
    bottom = pointD.y.toInt() + 1;

    // Go try to find point A again with better information -- might have been off at first.
    pointA = findCornerFromCenter(
      halfWidth,
      0,
      left,
      right,
      halfHeight,
      -deltaY,
      top,
      bottom,
      halfWidth ~/ 4,
    );

    return [pointA, pointB, pointC, pointD];
  }

  /// Attempts to locate a corner of the barcode by scanning up, down, left or right from a center
  /// point which should be within the barcode.
  ///
  /// @param centerX center's x component (horizontal)
  /// @param deltaX same as deltaY but change in x per step instead
  /// @param left minimum value of x
  /// @param right maximum value of x
  /// @param centerY center's y component (vertical)
  /// @param deltaY change in y per step. If scanning up this is negative; down, positive;
  ///  left or right, 0
  /// @param top minimum value of y to search through (meaningless when di == 0)
  /// @param bottom maximum value of y
  /// @param maxWhiteRun maximum run of white pixels that can still be considered to be within
  ///  the barcode
  /// @return a [ResultPoint] encapsulating the corner that was found
  /// @throws NotFoundException if such a point cannot be found
  ResultPoint findCornerFromCenter(
    int centerX,
    int deltaX,
    int left,
    int right,
    int centerY,
    int deltaY,
    int top,
    int bottom,
    int maxWhiteRun,
  ) {
    List<int>? lastRange;
    for (int y = centerY, x = centerX;
        y < bottom && y >= top && x < right && x >= left;
        y += deltaY, x += deltaX) {
      List<int>? range;
      if (deltaX == 0) {
        // horizontal slices, up and down
        range = blackWhiteRange(y, maxWhiteRun, left, right, true);
      } else {
        // vertical slices, left and right
        range = blackWhiteRange(x, maxWhiteRun, top, bottom, false);
      }
      if (range == null) {
        if (lastRange == null) {
          throw NotFoundException.instance;
        }
        // lastRange was found
        if (deltaX == 0) {
          final lastY = y - deltaY;
          if (lastRange[0] < centerX) {
            if (lastRange[1] > centerX) {
              // straddle, choose one or the other based on direction
              return ResultPoint(
                lastRange[deltaY > 0 ? 0 : 1].toDouble(),
                lastY.toDouble(),
              );
            }
            return ResultPoint(lastRange[0].toDouble(), lastY.toDouble());
          } else {
            return ResultPoint(lastRange[1].toDouble(), lastY.toDouble());
          }
        } else {
          final lastX = x - deltaX;
          if (lastRange[0] < centerY) {
            if (lastRange[1] > centerY) {
              return ResultPoint(
                lastX.toDouble(),
                lastRange[deltaX < 0 ? 0 : 1].toDouble(),
              );
            }
            return ResultPoint(lastX.toDouble(), lastRange[0].toDouble());
          } else {
            return ResultPoint(lastX.toDouble(), lastRange[1].toDouble());
          }
        }
      }
      lastRange = range;
    }
    throw NotFoundException.instance;
  }

  /// Computes the start and end of a region of pixels, either horizontally or vertically, that could
  /// be part of a Data Matrix barcode.
  ///
  /// @param fixedDimension if scanning horizontally, this is the row (the fixed vertical location)
  ///  where we are scanning. If scanning vertically it's the column, the fixed horizontal location
  /// @param maxWhiteRun largest run of white pixels that can still be considered part of the
  ///  barcode region
  /// @param minDim minimum pixel location, horizontally or vertically, to consider
  /// @param maxDim maximum pixel location, horizontally or vertically, to consider
  /// @param horizontal if true, we're scanning left-right, instead of up-down
  /// @return `List<int>` with start and end of found range, or null if no such range is found
  ///  (e.g. only white was found)
  List<int>? blackWhiteRange(
    int fixedDimension,
    int maxWhiteRun,
    int minDim,
    int maxDim,
    bool horizontal,
  ) {
    final center = (minDim + maxDim) ~/ 2;

    // Scan left/up first
    int start = center;
    while (start >= minDim) {
      if (horizontal
          ? _image.get(start, fixedDimension)
          : _image.get(fixedDimension, start)) {
        start--;
      } else {
        final whiteRunStart = start;
        do {
          start--;
        } while (start >= minDim &&
            !(horizontal
                ? _image.get(start, fixedDimension)
                : _image.get(fixedDimension, start)));
        final whiteRunSize = whiteRunStart - start;
        if (start < minDim || whiteRunSize > maxWhiteRun) {
          start = whiteRunStart;
          break;
        }
      }
    }
    start++;

    // Then try right/down
    int end = center;
    while (end < maxDim) {
      if (horizontal
          ? _image.get(end, fixedDimension)
          : _image.get(fixedDimension, end)) {
        end++;
      } else {
        final whiteRunStart = end;
        do {
          end++;
        } while (end < maxDim &&
            !(horizontal
                ? _image.get(end, fixedDimension)
                : _image.get(fixedDimension, end)));
        final whiteRunSize = end - whiteRunStart;
        if (end >= maxDim || whiteRunSize > maxWhiteRun) {
          end = whiteRunStart;
          break;
        }
      }
    }
    end--;

    return end > start ? [start, end] : null;
  }
}
