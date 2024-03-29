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

import 'common/detector/math_utils.dart';

/// Encapsulates a point of interest in an image containing a barcode.
///
/// Typically, this would be the location of a finder pattern or the corner
/// of the barcode, for example.
class ResultPoint {
  final double _x;
  final double _y;

  ResultPoint(this._x, this._y);

  double get x => _x;

  double get y => _y;

  @override
  bool operator ==(Object other) {
    if (other is ResultPoint) {
      final otherPoint = other;
      return _x == otherPoint._x && _y == otherPoint._y;
    }
    return false;
  }

  @override
  int get hashCode {
    return 31 * _x.toInt() + _y.toInt();
  }

  @override
  String toString() {
    return '($_x,$_y)';
  }

  /// Orders an array of three ResultPoints in an order [A,B,C] such that AB is less than AC
  /// and BC is less than AC, and the angle between BC and BA is less than 180 degrees.
  ///
  /// @param patterns array of three [ResultPoint] to order
  static void orderBestPatterns(List<ResultPoint> patterns) {
    // Find distances between pattern centers
    final zeroOneDistance = distance(patterns[0], patterns[1]);
    final oneTwoDistance = distance(patterns[1], patterns[2]);
    final zeroTwoDistance = distance(patterns[0], patterns[2]);

    ResultPoint pointA;
    ResultPoint pointB;
    ResultPoint pointC;
    // Assume one closest to other two is B; A and C will just be guesses at first
    if (oneTwoDistance >= zeroOneDistance &&
        oneTwoDistance >= zeroTwoDistance) {
      pointB = patterns[0];
      pointA = patterns[1];
      pointC = patterns[2];
    } else if (zeroTwoDistance >= oneTwoDistance &&
        zeroTwoDistance >= zeroOneDistance) {
      pointB = patterns[1];
      pointA = patterns[0];
      pointC = patterns[2];
    } else {
      pointB = patterns[2];
      pointA = patterns[0];
      pointC = patterns[1];
    }

    // Use cross product to figure out whether A and C are correct or flipped.
    // This asks whether BC x BA has a positive z component, which is the arrangement
    // we want for A, B, C. If it's negative, then we've got it flipped around and
    // should swap A and C.
    if (crossProductZ(pointA, pointB, pointC) < 0.0) {
      final temp = pointA;
      pointA = pointC;
      pointC = temp;
    }

    patterns[0] = pointA;
    patterns[1] = pointB;
    patterns[2] = pointC;
  }

  /// @param pattern1 first pattern
  /// @param pattern2 second pattern
  /// @return distance between two points
  static double distance(ResultPoint pattern1, ResultPoint pattern2) {
    return MathUtils.distance(pattern1.x, pattern1.y, pattern2.x, pattern2.y);
  }

  /// Returns the z component of the cross product between vectors BC and BA.
  static double crossProductZ(
    ResultPoint pointA,
    ResultPoint pointB,
    ResultPoint pointC,
  ) {
    final bX = pointB.x;
    final bY = pointB.y;
    return ((pointC.x - bX) * (pointA.y - bY)) -
        ((pointC.y - bY) * (pointA.x - bX));
  }
}
