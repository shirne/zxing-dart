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

import 'dart:math';
import 'dart:typed_data';

import '../../common/bit_matrix.dart';
import '../../common/detector/math_utils.dart';
import '../../common/detector/white_rectangle_detector.dart';
import '../../common/grid_sampler.dart';
import '../../common/reedsolomon/generic_gf.dart';
import '../../common/reedsolomon/reed_solomon_decoder.dart';
import '../../common/reedsolomon/reed_solomon_exception.dart';
import '../../not_found_exception.dart';
import '../../result_point.dart';
import '../aztec_detector_result.dart';

class Point {
  final int _x;
  final int _y;

  ResultPoint toResultPoint() {
    return ResultPoint(_x.toDouble(), _y.toDouble());
  }

  Point(this._x, this._y);

  int get x => _x;

  int get y => _y;

  @override
  String toString() => '<$_x $_y>';
}

/// Encapsulates logic that can detect an Aztec Code in an image, even if the Aztec Code
/// is rotated or skewed, or partially obscured.
///
/// @author David Olivier
/// @author Frank Yellin
class Detector {
  static const List<int> _EXPECTED_CORNER_BITS = [
    0xee0, // 07340  XXX .XX X.. ...
    0x1dc, // 00734  ... XXX .XX X..
    0x83b, // 04073  X.. ... XXX .XX
    0x707, // 03407 .XX X.. ... XXX
  ];

  final BitMatrix _image;

  late bool _compact;
  late int _nbLayers;
  late int _nbDataBlocks;
  late int _nbCenterLayers;
  late int _shift;

  Detector(this._image);

  /// Detects an Aztec Code in an image.
  ///
  /// @param isMirror if true, image is a mirror-image of original
  /// @return [AztecDetectorResult] encapsulating results of detecting an Aztec Code
  /// @throws NotFoundException if no Aztec Code can be found
  AztecDetectorResult detect([bool isMirror = false]) {
    // 1. Get the center of the aztec matrix
    final Point pCenter = _getMatrixCenter();

    // 2. Get the center points of the four diagonal points just outside the bull's eye
    //  [topRight, bottomRight, bottomLeft, topLeft]
    final List<ResultPoint> bullsEyeCorners = _getBullsEyeCorners(pCenter);

    if (isMirror) {
      final ResultPoint temp = bullsEyeCorners[0];
      bullsEyeCorners[0] = bullsEyeCorners[2];
      bullsEyeCorners[2] = temp;
    }

    // 3. Get the size of the matrix and other parameters from the bull's eye
    _extractParameters(bullsEyeCorners);

    // 4. Sample the grid
    final BitMatrix bits = _sampleGrid(
      _image,
      bullsEyeCorners[_shift % 4],
      bullsEyeCorners[(_shift + 1) % 4],
      bullsEyeCorners[(_shift + 2) % 4],
      bullsEyeCorners[(_shift + 3) % 4],
    );

    // 5. Get the corners of the matrix.
    final List<ResultPoint> corners = _getMatrixCornerPoints(bullsEyeCorners);

    return AztecDetectorResult(
      bits,
      corners,
      _compact,
      _nbDataBlocks,
      _nbLayers,
    );
  }

  /// Extracts the number of data layers and data blocks from the layer around the bull's eye.
  ///
  /// @param bullsEyeCorners the array of bull's eye corners
  /// @throws NotFoundException in case of too many errors or invalid parameters
  void _extractParameters(List<ResultPoint> bullsEyeCorners) {
    if (!_isValidPoint(bullsEyeCorners[0]) ||
        !_isValidPoint(bullsEyeCorners[1]) ||
        !_isValidPoint(bullsEyeCorners[2]) ||
        !_isValidPoint(bullsEyeCorners[3])) {
      throw NotFoundException.instance;
    }
    final int length = 2 * _nbCenterLayers;
    // Get the bits around the bull's eye
    final List<int> sides = [
      _sampleLine(bullsEyeCorners[0], bullsEyeCorners[1], length), // Right side
      _sampleLine(bullsEyeCorners[1], bullsEyeCorners[2], length), // Bottom
      _sampleLine(bullsEyeCorners[2], bullsEyeCorners[3], length), // Left side
      _sampleLine(bullsEyeCorners[3], bullsEyeCorners[0], length) // Top
    ];

    // bullsEyeCorners[shift] is the corner of the bulls'eye that has three
    // orientation marks.
    // sides[shift] is the row/column that goes from the corner with three
    // orientation marks to the corner with two.
    _shift = _getRotation(sides, length);

    // Flatten the parameter bits into a single 28- or 40-bit long
    int parameterData = 0;
    for (int i = 0; i < 4; i++) {
      final int side = sides[(_shift + i) % 4];
      if (_compact) {
        // Each side of the form ..XXXXXXX. where Xs are parameter data
        parameterData <<= 7;
        parameterData += (side >> 1) & 0x7F;
      } else {
        // Each side of the form ..XXXXX.XXXXX. where Xs are parameter data
        parameterData <<= 10;
        parameterData += ((side >> 2) & (0x1f << 5)) + ((side >> 1) & 0x1F);
      }
    }

    // Corrects parameter data using RS.  Returns just the data portion
    // without the error correction.
    final correctedData = _getCorrectedParameterData(parameterData, _compact);

    if (_compact) {
      // 8 bits:  2 bits layers and 6 bits data blocks
      _nbLayers = (correctedData >> 6) + 1;
      _nbDataBlocks = (correctedData & 0x3F) + 1;
    } else {
      // 16 bits:  5 bits layers and 11 bits data blocks
      _nbLayers = (correctedData >> 11) + 1;
      _nbDataBlocks = (correctedData & 0x7FF) + 1;
    }
  }

  static int _getRotation(List<int> sides, int length) {
    // In a normal pattern, we expect to See
    //   **    .*             D       A
    //   *      *
    //
    //   .      *
    //   ..    ..             C       B
    //
    // Grab the 3 bits from each of the sides the form the locator pattern and concatenate
    // into a 12-bit integer.  Start with the bit at A
    int cornerBits = 0;
    for (int side in sides) {
      // XX......X where X's are orientation marks
      final int t = ((side >> (length - 2)) << 1) + (side & 1);
      cornerBits = (cornerBits << 3) + t;
    }
    // Mov the bottom bit to the top, so that the three bits of the locator pattern at A are
    // together.  cornerBits is now:
    //  3 orientation bits at A || 3 orientation bits at B || ... || 3 orientation bits at D
    cornerBits = ((cornerBits & 1) << 11) + (cornerBits >> 1);
    // The result shift indicates which element of List<BullsEyeCorners> goes into the top-left
    // corner. Since the four rotation values have a Hamming distance of 8, we
    // can easily tolerate two errors.
    for (int shift = 0; shift < 4; shift++) {
      if (MathUtils.bitCount(cornerBits ^ _EXPECTED_CORNER_BITS[shift]) <= 2) {
        return shift;
      }
    }
    throw NotFoundException.instance;
  }

  /// Corrects the parameter bits using Reed-Solomon algorithm.
  ///
  /// @param parameterData parameter bits
  /// @param compact true if this is a compact Aztec code
  /// @throws NotFoundException if the array contains too many errors
  static int _getCorrectedParameterData(int parameterData, bool compact) {
    int numCodewords;
    int numDataCodewords;

    if (compact) {
      numCodewords = 7;
      numDataCodewords = 2;
    } else {
      numCodewords = 10;
      numDataCodewords = 4;
    }

    final int numECCodewords = numCodewords - numDataCodewords;
    final Int32List parameterWords = Int32List(numCodewords);
    for (int i = numCodewords - 1; i >= 0; --i) {
      parameterWords[i] = parameterData & 0xF;
      parameterData >>= 4;
    }
    try {
      final ReedSolomonDecoder rsDecoder =
          ReedSolomonDecoder(GenericGF.aztecParam);
      rsDecoder.decode(parameterWords, numECCodewords);
    } on ReedSolomonException catch (_) {
      throw NotFoundException.instance;
    }
    // Toss the error correction.  Just return the data as an integer
    int result = 0;
    for (int i = 0; i < numDataCodewords; i++) {
      result = (result << 4) + parameterWords[i];
    }
    return result;
  }

  /// Finds the corners of a bull-eye centered on the passed point.
  /// This returns the centers of the diagonal points just outside the bull's eye
  /// Returns [topRight, bottomRight, bottomLeft, topLeft]
  ///
  /// @param pCenter Center point
  /// @return The corners of the bull-eye
  /// @throws NotFoundException If no valid bull-eye can be found
  List<ResultPoint> _getBullsEyeCorners(Point pCenter) {
    Point pina = pCenter;
    Point pinb = pCenter;
    Point pinc = pCenter;
    Point pind = pCenter;

    bool color = true;

    for (_nbCenterLayers = 1; _nbCenterLayers < 9; _nbCenterLayers++) {
      final Point pouta = _getFirstDifferent(pina, color, 1, -1);
      final Point poutb = _getFirstDifferent(pinb, color, 1, 1);
      final Point poutc = _getFirstDifferent(pinc, color, -1, 1);
      final Point poutd = _getFirstDifferent(pind, color, -1, -1);

      //d      a
      //
      //c      b

      if (_nbCenterLayers > 2) {
        final double q = _distance(poutd, pouta) *
            _nbCenterLayers /
            (_distance(pind, pina) * (_nbCenterLayers + 2));
        if (q < 0.75 ||
            q > 1.25 ||
            !_isWhiteOrBlackRectangle(pouta, poutb, poutc, poutd)) {
          break;
        }
      }

      pina = pouta;
      pinb = poutb;
      pinc = poutc;
      pind = poutd;

      color = !color;
    }

    if (_nbCenterLayers != 5 && _nbCenterLayers != 7) {
      throw NotFoundException.instance;
    }

    _compact = _nbCenterLayers == 5;

    // Expand the square by .5 pixel in each direction so that we're on the border
    // between the white square and the black square
    final ResultPoint pinax = ResultPoint(pina.x + 0.5, pina.y - 0.5);
    final ResultPoint pinbx = ResultPoint(pinb.x + 0.5, pinb.y + 0.5);
    final ResultPoint pincx = ResultPoint(pinc.x - 0.5, pinc.y + 0.5);
    final ResultPoint pindx = ResultPoint(pind.x - 0.5, pind.y - 0.5);

    // Expand the square so that its corners are the centers of the points
    // just outside the bull's eye.
    return _expandSquare(
      [pinax, pinbx, pincx, pindx],
      2 * _nbCenterLayers - 3,
      2 * _nbCenterLayers,
    );
  }

  /// Finds a candidate center point of an Aztec code from an image
  ///
  /// @return the center point
  Point _getMatrixCenter() {
    ResultPoint pointA;
    ResultPoint pointB;
    ResultPoint pointC;
    ResultPoint pointD;

    //Get a white rectangle that can be the border of the matrix in center bull's eye or
    try {
      final List<ResultPoint> cornerPoints =
          WhiteRectangleDetector(_image).detect();
      pointA = cornerPoints[0];
      pointB = cornerPoints[1];
      pointC = cornerPoints[2];
      pointD = cornerPoints[3];
    } on NotFoundException catch (_) {
      //

      // This exception can be in case the initial rectangle is white
      // In that case, surely in the bull's eye, we try to expand the rectangle.
      final int cx = _image.width ~/ 2;
      final int cy = _image.height ~/ 2;
      pointA = _getFirstDifferent(Point(cx + 7, cy - 7), false, 1, -1)
          .toResultPoint();
      pointB = _getFirstDifferent(Point(cx + 7, cy + 7), false, 1, 1)
          .toResultPoint();
      pointC = _getFirstDifferent(Point(cx - 7, cy + 7), false, -1, 1)
          .toResultPoint();
      pointD = _getFirstDifferent(Point(cx - 7, cy - 7), false, -1, -1)
          .toResultPoint();
    }

    //Compute the center of the rectangle
    int cx = MathUtils.round((pointA.x + pointD.x + pointB.x + pointC.x) / 4.0);
    int cy = MathUtils.round((pointA.y + pointD.y + pointB.y + pointC.y) / 4.0);

    // Redetermine the white rectangle starting from previously computed center.
    // This will ensure that we end up with a white rectangle in center bull's eye
    // in order to compute a more accurate center.
    try {
      final List<ResultPoint> cornerPoints =
          WhiteRectangleDetector(_image, 15, cx, cy).detect();
      pointA = cornerPoints[0];
      pointB = cornerPoints[1];
      pointC = cornerPoints[2];
      pointD = cornerPoints[3];
    } on NotFoundException catch (_) {
      // This exception can be in case the initial rectangle is white
      // In that case we try to expand the rectangle.
      pointA = _getFirstDifferent(Point(cx + 7, cy - 7), false, 1, -1)
          .toResultPoint();
      pointB = _getFirstDifferent(Point(cx + 7, cy + 7), false, 1, 1)
          .toResultPoint();
      pointC = _getFirstDifferent(Point(cx - 7, cy + 7), false, -1, 1)
          .toResultPoint();
      pointD = _getFirstDifferent(Point(cx - 7, cy - 7), false, -1, -1)
          .toResultPoint();
    }

    // Recompute the center of the rectangle
    cx = MathUtils.round((pointA.x + pointD.x + pointB.x + pointC.x) / 4.0);
    cy = MathUtils.round((pointA.y + pointD.y + pointB.y + pointC.y) / 4.0);

    return Point(cx, cy);
  }

  /// Gets the Aztec code corners from the bull's eye corners and the parameters.
  ///
  /// @param bullsEyeCorners the array of bull's eye corners
  /// @return the array of aztec code corners
  List<ResultPoint> _getMatrixCornerPoints(List<ResultPoint> bullsEyeCorners) {
    return _expandSquare(bullsEyeCorners, 2 * _nbCenterLayers, _getDimension());
  }

  /// Creates a BitMatrix by sampling the provided image.
  /// topLeft, topRight, bottomRight, and bottomLeft are the centers of the squares on the
  /// diagonal just outside the bull's eye.
  BitMatrix _sampleGrid(
    BitMatrix image,
    ResultPoint topLeft,
    ResultPoint topRight,
    ResultPoint bottomRight,
    ResultPoint bottomLeft,
  ) {
    final GridSampler sampler = GridSampler.getInstance();
    final int dimension = _getDimension();

    final double low = dimension / 2.0 - _nbCenterLayers;
    final double high = dimension / 2.0 + _nbCenterLayers;

    return sampler.sampleGridBulk(
      image,
      dimension,
      dimension,
      low,
      low, // topleft
      high,
      low, // topright
      high,
      high, // bottomright
      low,
      high, // bottomleft
      topLeft.x,
      topLeft.y,
      topRight.x,
      topRight.y,
      bottomRight.x,
      bottomRight.y,
      bottomLeft.x,
      bottomLeft.y,
    );
  }

  /// Samples a line.
  ///
  /// @param p1   start point (inclusive)
  /// @param p2   end point (exclusive)
  /// @param size number of bits
  /// @return the array of bits as an int (first bit is high-order bit of result)
  int _sampleLine(ResultPoint p1, ResultPoint p2, int size) {
    int result = 0;

    final double d = _distanceResult(p1, p2);
    final double moduleSize = d / size;
    final double px = p1.x;
    final double py = p1.y;
    final double dx = moduleSize * (p2.x - p1.x) / d;
    final double dy = moduleSize * (p2.y - p1.y) / d;
    for (int i = 0; i < size; i++) {
      if (_image.get(
        MathUtils.round(px + i * dx),
        MathUtils.round(py + i * dy),
      )) {
        result |= 1 << (size - i - 1);
      }
    }
    return result;
  }

  /// return true if the border of the rectangle passed in parameter is compound of white points only
  ///         or black points only
  bool _isWhiteOrBlackRectangle(Point p1, Point p2, Point p3, Point p4) {
    final int corr = 3;

    p1 = Point(max(0, p1.x - corr), min(_image.height - 1, p1.y + corr));
    p2 = Point(max(0, p2.x - corr), max(0, p2.y - corr));
    p3 = Point(
      min(_image.height - 1, p3.x + corr),
      max(0, min(_image.height - 1, p3.y - corr)),
    );
    p4 = Point(
      min(_image.width - 1, p4.x + corr),
      min(_image.height - 1, p4.y + corr),
    );

    final int cInit = _getColor(p4, p1);

    if (cInit == 0) {
      return false;
    }

    int c = _getColor(p1, p2);

    if (c != cInit) {
      return false;
    }

    c = _getColor(p2, p3);

    if (c != cInit) {
      return false;
    }

    c = _getColor(p3, p4);

    return c == cInit;
  }

  /// Gets the color of a segment
  ///
  /// return 1 if segment more than 90% black, -1 if segment is more than 90% white, 0 else
  int _getColor(Point p1, Point p2) {
    final double d = _distance(p1, p2);
    if (d == 0.0) {
      return 0;
    }
    final double dx = (p2.x - p1.x) / d;
    final double dy = (p2.y - p1.y) / d;
    int error = 0;

    double px = p1.x.toDouble();
    double py = p1.y.toDouble();

    final bool colorModel = _image.get(p1.x, p1.y);

    final int iMax = d.floor();
    for (int i = 0; i < iMax; i++) {
      if (_image.get(MathUtils.round(px), MathUtils.round(py)) != colorModel) {
        error++;
      }
      px += dx;
      py += dy;
    }

    final double errRatio = error / d;

    if (errRatio > 0.1 && errRatio < 0.9) {
      return 0;
    }

    return (errRatio <= 0.1) == colorModel ? 1 : -1;
  }

  /// Gets the coordinate of the first point with a different color in the given direction
  Point _getFirstDifferent(Point init, bool color, int dx, int dy) {
    int x = init.x + dx;
    int y = init.y + dy;

    while (_isValid(x, y) && _image.get(x, y) == color) {
      x += dx;
      y += dy;
    }

    x -= dx;
    y -= dy;

    while (_isValid(x, y) && _image.get(x, y) == color) {
      x += dx;
    }
    x -= dx;

    while (_isValid(x, y) && _image.get(x, y) == color) {
      y += dy;
    }
    y -= dy;

    return Point(x, y);
  }

  /// Expand the square represented by the corner points by pushing out equally in all directions
  ///
  /// @param cornerPoints the corners of the square, which has the bull's eye at its center
  /// @param oldSide the original length of the side of the square in the target bit matrix
  /// @param newSide the new length of the size of the square in the target bit matrix
  /// @return the corners of the expanded square
  static List<ResultPoint> _expandSquare(
    List<ResultPoint> cornerPoints,
    int oldSide,
    int newSide,
  ) {
    final double ratio = newSide / (2.0 * oldSide);
    double dx = cornerPoints[0].x - cornerPoints[2].x;
    double dy = cornerPoints[0].y - cornerPoints[2].y;
    double centerx = (cornerPoints[0].x + cornerPoints[2].x) / 2.0;
    double centery = (cornerPoints[0].y + cornerPoints[2].y) / 2.0;

    final ResultPoint result0 =
        ResultPoint(centerx + ratio * dx, centery + ratio * dy);
    final ResultPoint result2 =
        ResultPoint(centerx - ratio * dx, centery - ratio * dy);

    dx = cornerPoints[1].x - cornerPoints[3].x;
    dy = cornerPoints[1].y - cornerPoints[3].y;
    centerx = (cornerPoints[1].x + cornerPoints[3].x) / 2.0;
    centery = (cornerPoints[1].y + cornerPoints[3].y) / 2.0;
    final ResultPoint result1 =
        ResultPoint(centerx + ratio * dx, centery + ratio * dy);
    final ResultPoint result3 =
        ResultPoint(centerx - ratio * dx, centery - ratio * dy);

    return [result0, result1, result2, result3];
  }

  bool _isValid(int x, int y) {
    return x >= 0 && x < _image.width && y >= 0 && y < _image.height;
  }

  bool _isValidPoint(ResultPoint point) {
    final int x = MathUtils.round(point.x);
    final int y = MathUtils.round(point.y);
    return _isValid(x, y);
  }

  static double _distance(Point a, Point b) {
    return MathUtils.distance(
      a.x.toDouble(),
      a.y.toDouble(),
      b.x.toDouble(),
      b.y.toDouble(),
    );
  }

  static double _distanceResult(ResultPoint a, ResultPoint b) {
    return MathUtils.distance(a.x, a.y, b.x, b.y);
  }

  int _getDimension() {
    if (_compact) {
      return 4 * _nbLayers + 11;
    }
    return 4 * _nbLayers + 2 * ((2 * _nbLayers + 6) ~/ 15) + 15;
  }
}
