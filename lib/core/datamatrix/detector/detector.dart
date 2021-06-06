/*
 * Copyright 2008 ZXing authors
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

import '../../common/bit_matrix.dart';
import '../../common/detector/white_rectangle_detector.dart';
import '../../common/detector_result.dart';
import '../../common/grid_sampler.dart';

import '../../result_point.dart';

/// <p>Encapsulates logic that can detect a Data Matrix Code in an image, even if the Data Matrix Code
/// is rotated or skewed, or partially obscured.</p>
///
/// @author Sean Owen
class Detector {
  final BitMatrix _image;
  final WhiteRectangleDetector _rectangleDetector;

  Detector(this._image) : this._rectangleDetector = WhiteRectangleDetector(_image);

  /// <p>Detects a Data Matrix Code in an image.</p>
  ///
  /// @return {@link DetectorResult} encapsulating results of detecting a Data Matrix Code
  /// @throws NotFoundException if no Data Matrix Code can be found
  DetectorResult detect() {
    List<ResultPoint> cornerPoints = _rectangleDetector.detect();

    List<ResultPoint> points = _detectSolid1(cornerPoints);
    points = _detectSolid2(points);
    points[3] = _correctTopRight(points)!;
    //if (points[3] == null) {
    //  throw NotFoundException.instance;
    //}
    points = _shiftToModuleCenter(points);

    ResultPoint topLeft = points[0];
    ResultPoint bottomLeft = points[1];
    ResultPoint bottomRight = points[2];
    ResultPoint topRight = points[3];

    int dimensionTop = _transitionsBetween(topLeft, topRight) + 1;
    int dimensionRight = _transitionsBetween(bottomRight, topRight) + 1;
    if ((dimensionTop & 0x01) == 1) {
      dimensionTop += 1;
    }
    if ((dimensionRight & 0x01) == 1) {
      dimensionRight += 1;
    }

    if (4 * dimensionTop < 6 * dimensionRight &&
        4 * dimensionRight < 6 * dimensionTop) {
      // The matrix is square
      dimensionTop = dimensionRight = Math.max(dimensionTop, dimensionRight);
    }

    BitMatrix bits = _sampleGrid(_image, topLeft, bottomLeft, bottomRight,
        topRight, dimensionTop, dimensionRight);

    return DetectorResult(
        bits, [topLeft, bottomLeft, bottomRight, topRight]);
  }

  static ResultPoint _shiftPoint(ResultPoint point, ResultPoint to, int div) {
    double x = (to.getX() - point.getX()) / (div + 1);
    double y = (to.getY() - point.getY()) / (div + 1);
    return ResultPoint(point.getX() + x, point.getY() + y);
  }

  static ResultPoint _moveAway(ResultPoint point, double fromX, double fromY) {
    double x = point.getX();
    double y = point.getY();

    if (x < fromX) {
      x -= 1;
    } else {
      x += 1;
    }

    if (y < fromY) {
      y -= 1;
    } else {
      y += 1;
    }

    return ResultPoint(x, y);
  }

  /// Detect a solid side which has minimum transition.
  List<ResultPoint> _detectSolid1(List<ResultPoint> cornerPoints) {
    // 0  2
    // 1  3
    ResultPoint pointA = cornerPoints[0];
    ResultPoint pointB = cornerPoints[1];
    ResultPoint pointC = cornerPoints[3];
    ResultPoint pointD = cornerPoints[2];

    int trAB = _transitionsBetween(pointA, pointB);
    int trBC = _transitionsBetween(pointB, pointC);
    int trCD = _transitionsBetween(pointC, pointD);
    int trDA = _transitionsBetween(pointD, pointA);

    // 0..3
    // :  :
    // 1--2
    int min = trAB;
    List<ResultPoint> points = [pointD, pointA, pointB, pointC];
    if (min > trBC) {
      min = trBC;
      points[0] = pointA;
      points[1] = pointB;
      points[2] = pointC;
      points[3] = pointD;
    }
    if (min > trCD) {
      min = trCD;
      points[0] = pointB;
      points[1] = pointC;
      points[2] = pointD;
      points[3] = pointA;
    }
    if (min > trDA) {
      points[0] = pointC;
      points[1] = pointD;
      points[2] = pointA;
      points[3] = pointB;
    }

    return points;
  }

  /// Detect a second solid side next to first solid side.
  List<ResultPoint> _detectSolid2(List<ResultPoint> points) {
    // A..D
    // :  :
    // B--C
    ResultPoint pointA = points[0];
    ResultPoint pointB = points[1];
    ResultPoint pointC = points[2];
    ResultPoint pointD = points[3];

    // Transition detection on the edge is not stable.
    // To safely detect, shift the points to the module center.
    int tr = _transitionsBetween(pointA, pointD);
    ResultPoint pointBs = _shiftPoint(pointB, pointC, (tr + 1) * 4);
    ResultPoint pointCs = _shiftPoint(pointC, pointB, (tr + 1) * 4);
    int trBA = _transitionsBetween(pointBs, pointA);
    int trCD = _transitionsBetween(pointCs, pointD);

    // 0..3
    // |  :
    // 1--2
    if (trBA < trCD) {
      // solid sides: A-B-C
      points[0] = pointA;
      points[1] = pointB;
      points[2] = pointC;
      points[3] = pointD;
    } else {
      // solid sides: B-C-D
      points[0] = pointB;
      points[1] = pointC;
      points[2] = pointD;
      points[3] = pointA;
    }

    return points;
  }

  /// Calculates the corner position of the white top right module.
  ResultPoint? _correctTopRight(List<ResultPoint> points) {
    // A..D
    // |  :
    // B--C
    ResultPoint pointA = points[0];
    ResultPoint pointB = points[1];
    ResultPoint pointC = points[2];
    ResultPoint pointD = points[3];

    // shift points for safe transition detection.
    int trTop = _transitionsBetween(pointA, pointD);
    int trRight = _transitionsBetween(pointB, pointD);
    ResultPoint pointAs = _shiftPoint(pointA, pointB, (trRight + 1) * 4);
    ResultPoint pointCs = _shiftPoint(pointC, pointB, (trTop + 1) * 4);

    trTop = _transitionsBetween(pointAs, pointD);
    trRight = _transitionsBetween(pointCs, pointD);

    ResultPoint candidate1 = ResultPoint(
        pointD.getX() + (pointC.getX() - pointB.getX()) / (trTop + 1),
        pointD.getY() + (pointC.getY() - pointB.getY()) / (trTop + 1));
    ResultPoint candidate2 = ResultPoint(
        pointD.getX() + (pointA.getX() - pointB.getX()) / (trRight + 1),
        pointD.getY() + (pointA.getY() - pointB.getY()) / (trRight + 1));

    if (!_isValid(candidate1)) {
      if (_isValid(candidate2)) {
        return candidate2;
      }
      return null;
    }
    if (!_isValid(candidate2)) {
      return candidate1;
    }

    int sumc1 = _transitionsBetween(pointAs, candidate1) +
        _transitionsBetween(pointCs, candidate1);
    int sumc2 = _transitionsBetween(pointAs, candidate2) +
        _transitionsBetween(pointCs, candidate2);

    if (sumc1 > sumc2) {
      return candidate1;
    } else {
      return candidate2;
    }
  }

  /// Shift the edge points to the module center.
  List<ResultPoint> _shiftToModuleCenter(List<ResultPoint> points) {
    // A..D
    // |  :
    // B--C
    ResultPoint pointA = points[0];
    ResultPoint pointB = points[1];
    ResultPoint pointC = points[2];
    ResultPoint pointD = points[3];

    // calculate pseudo dimensions
    int dimH = _transitionsBetween(pointA, pointD) + 1;
    int dimV = _transitionsBetween(pointC, pointD) + 1;

    // shift points for safe dimension detection
    ResultPoint pointAs = _shiftPoint(pointA, pointB, dimV * 4);
    ResultPoint pointCs = _shiftPoint(pointC, pointB, dimH * 4);

    //  calculate more precise dimensions
    dimH = _transitionsBetween(pointAs, pointD) + 1;
    dimV = _transitionsBetween(pointCs, pointD) + 1;
    if ((dimH & 0x01) == 1) {
      dimH += 1;
    }
    if ((dimV & 0x01) == 1) {
      dimV += 1;
    }

    // WhiteRectangleDetector returns points inside of the rectangle.
    // I want points on the edges.
    double centerX =
        (pointA.getX() + pointB.getX() + pointC.getX() + pointD.getX()) / 4;
    double centerY =
        (pointA.getY() + pointB.getY() + pointC.getY() + pointD.getY()) / 4;
    pointA = _moveAway(pointA, centerX, centerY);
    pointB = _moveAway(pointB, centerX, centerY);
    pointC = _moveAway(pointC, centerX, centerY);
    pointD = _moveAway(pointD, centerX, centerY);

    ResultPoint pointBs;
    ResultPoint pointDs;

    // shift points to the center of each modules
    pointAs = _shiftPoint(pointA, pointB, dimV * 4);
    pointAs = _shiftPoint(pointAs, pointD, dimH * 4);
    pointBs = _shiftPoint(pointB, pointA, dimV * 4);
    pointBs = _shiftPoint(pointBs, pointC, dimH * 4);
    pointCs = _shiftPoint(pointC, pointD, dimV * 4);
    pointCs = _shiftPoint(pointCs, pointB, dimH * 4);
    pointDs = _shiftPoint(pointD, pointC, dimV * 4);
    pointDs = _shiftPoint(pointDs, pointA, dimH * 4);

    return [pointAs, pointBs, pointCs, pointDs];
  }

  bool _isValid(ResultPoint p) {
    return p.getX() >= 0 &&
        p.getX() < _image.getWidth() &&
        p.getY() > 0 &&
        p.getY() < _image.getHeight();
  }

  static BitMatrix _sampleGrid(
      BitMatrix image,
      ResultPoint topLeft,
      ResultPoint bottomLeft,
      ResultPoint bottomRight,
      ResultPoint topRight,
      int dimensionX,
      int dimensionY) {
    GridSampler sampler = GridSampler.getInstance();

    return sampler.sampleGridBulk(
        image,
        dimensionX,
        dimensionY,
        0.5,
        0.5,
        dimensionX - 0.5,
        0.5,
        dimensionX - 0.5,
        dimensionY - 0.5,
        0.5,
        dimensionY - 0.5,
        topLeft.getX(),
        topLeft.getY(),
        topRight.getX(),
        topRight.getY(),
        bottomRight.getX(),
        bottomRight.getY(),
        bottomLeft.getX(),
        bottomLeft.getY());
  }

  /// Counts the number of black/white transitions between two points, using something like Bresenham's algorithm.
  int _transitionsBetween(ResultPoint from, ResultPoint to) {
    // See QR Code Detector, sizeOfBlackWhiteBlackRun()
    int fromX = from.getX().toInt();
    int fromY = from.getY().toInt();
    int toX = to.getX().toInt();
    int toY = to.getY().toInt();
    bool steep = (toY - fromY).abs() > (toX - fromX).abs();
    if (steep) {
      int temp = fromX;
      fromX = fromY;
      fromY = temp;
      temp = toX;
      toX = toY;
      toY = temp;
    }

    int dx = (toX - fromX).abs();
    int dy = (toY - fromY).abs();
    int error = -dx ~/ 2;
    int ystep = fromY < toY ? 1 : -1;
    int xstep = fromX < toX ? 1 : -1;
    int transitions = 0;
    bool inBlack = _image.get(steep ? fromY : fromX, steep ? fromX : fromY);
    for (int x = fromX, y = fromY; x != toX; x += xstep) {
      bool isBlack = _image.get(steep ? y : x, steep ? x : y);
      if (isBlack != inBlack) {
        transitions++;
        inBlack = isBlack;
      }
      error += dy;
      if (error > 0) {
        if (y == toY) {
          break;
        }
        y += ystep;
        error -= dx;
      }
    }
    return transitions;
  }
}
