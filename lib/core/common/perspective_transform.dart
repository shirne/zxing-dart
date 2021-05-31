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

/**
 * <p>This class implements a perspective transform in two dimensions. Given four source and four
 * destination points, it will compute the transformation implied between them. The code is based
 * directly upon section 3.4.2 of George Wolberg's "Digital Image Warping"; see pages 54-56.</p>
 *
 * @author Sean Owen
 */
class PerspectiveTransform {
  final double _a11;
  final double _a12;
  final double _a13;
  final double _a21;
  final double _a22;
  final double _a23;
  final double _a31;
  final double _a32;
  final double _a33;

  PerspectiveTransform._(this._a11, this._a21, this._a31, this._a12, this._a22,
      this._a32, this._a13, this._a23, this._a33);

  static PerspectiveTransform quadrilateralToQuadrilateral(
      double x0,
      double y0,
      double x1,
      double y1,
      double x2,
      double y2,
      double x3,
      double y3,
      double x0p,
      double y0p,
      double x1p,
      double y1p,
      double x2p,
      double y2p,
      double x3p,
      double y3p) {
    PerspectiveTransform qToS =
        quadrilateralToSquare(x0, y0, x1, y1, x2, y2, x3, y3);
    PerspectiveTransform sToQ =
        squareToQuadrilateral(x0p, y0p, x1p, y1p, x2p, y2p, x3p, y3p);
    return sToQ.times(qToS);
  }

  void transformPoints(List<double> points) {
    double a11 = this._a11;
    double a12 = this._a12;
    double a13 = this._a13;
    double a21 = this._a21;
    double a22 = this._a22;
    double a23 = this._a23;
    double a31 = this._a31;
    double a32 = this._a32;
    double a33 = this._a33;
    int maxI = points.length - 1; // points.length must be even
    for (int i = 0; i < maxI; i += 2) {
      double x = points[i];
      double y = points[i + 1];
      double denominator = a13 * x + a23 * y + a33;
      points[i] = (a11 * x + a21 * y + a31) / denominator;
      points[i + 1] = (a12 * x + a22 * y + a32) / denominator;
    }
  }

  void transformPointsPair(List<double> xValues, List<double> yValues) {
    int n = xValues.length;
    for (int i = 0; i < n; i++) {
      double x = xValues[i];
      double y = yValues[i];
      double denominator = _a13 * x + _a23 * y + _a33;
      xValues[i] = (_a11 * x + _a21 * y + _a31) / denominator;
      yValues[i] = (_a12 * x + _a22 * y + _a32) / denominator;
    }
  }

  static PerspectiveTransform squareToQuadrilateral(double x0, double y0,
      double x1, double y1, double x2, double y2, double x3, double y3) {
    double dx3 = x0 - x1 + x2 - x3;
    double dy3 = y0 - y1 + y2 - y3;
    if (dx3 == 0.0 && dy3 == 0.0) {
      // Affine
      return PerspectiveTransform._(
          x1 - x0, x2 - x1, x0, y1 - y0, y2 - y1, y0, 0.0, 0.0, 1.0);
    } else {
      double dx1 = x1 - x2;
      double dx2 = x3 - x2;
      double dy1 = y1 - y2;
      double dy2 = y3 - y2;
      double denominator = dx1 * dy2 - dx2 * dy1;
      double a13 = (dx3 * dy2 - dx2 * dy3) / denominator;
      double a23 = (dx1 * dy3 - dx3 * dy1) / denominator;
      return PerspectiveTransform._(x1 - x0 + a13 * x1, x3 - x0 + a23 * x3,
          x0, y1 - y0 + a13 * y1, y3 - y0 + a23 * y3, y0, a13, a23, 1.0);
    }
  }

  static PerspectiveTransform quadrilateralToSquare(double x0, double y0,
      double x1, double y1, double x2, double y2, double x3, double y3) {
    // Here, the adjoint serves as the inverse:
    return squareToQuadrilateral(x0, y0, x1, y1, x2, y2, x3, y3).buildAdjoint();
  }

  PerspectiveTransform buildAdjoint() {
    // Adjoint is the transpose of the cofactor matrix:
    return PerspectiveTransform._(
        _a22 * _a33 - _a23 * _a32,
        _a23 * _a31 - _a21 * _a33,
        _a21 * _a32 - _a22 * _a31,
        _a13 * _a32 - _a12 * _a33,
        _a11 * _a33 - _a13 * _a31,
        _a12 * _a31 - _a11 * _a32,
        _a12 * _a23 - _a13 * _a22,
        _a13 * _a21 - _a11 * _a23,
        _a11 * _a22 - _a12 * _a21);
  }

  PerspectiveTransform times(PerspectiveTransform other) {
    return PerspectiveTransform._(
        _a11 * other._a11 + _a21 * other._a12 + _a31 * other._a13,
        _a11 * other._a21 + _a21 * other._a22 + _a31 * other._a23,
        _a11 * other._a31 + _a21 * other._a32 + _a31 * other._a33,
        _a12 * other._a11 + _a22 * other._a12 + _a32 * other._a13,
        _a12 * other._a21 + _a22 * other._a22 + _a32 * other._a23,
        _a12 * other._a31 + _a22 * other._a32 + _a32 * other._a33,
        _a13 * other._a11 + _a23 * other._a12 + _a33 * other._a13,
        _a13 * other._a21 + _a23 * other._a22 + _a33 * other._a23,
        _a13 * other._a31 + _a23 * other._a32 + _a33 * other._a33);
  }
}
