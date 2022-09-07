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

/// This class implements a perspective transform in two dimensions. Given four source and four
/// destination points, it will compute the transformation implied between them. The code is based
/// directly upon section 3.4.2 of George Wolberg's "Digital Image Warping"; see pages 54-56.
///
/// @author Sean Owen
class PerspectiveTransform {
  final double a11;
  final double a12;
  final double a13;
  final double a21;
  final double a22;
  final double a23;
  final double a31;
  final double a32;
  final double a33;

  PerspectiveTransform._(
    this.a11,
    this.a21,
    this.a31,
    this.a12,
    this.a22,
    this.a32,
    this.a13,
    this.a23,
    this.a33,
  );

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
    double y3p,
  ) {
    final qToS = quadrilateralToSquare(x0, y0, x1, y1, x2, y2, x3, y3);
    final sToQ = squareToQuadrilateral(x0p, y0p, x1p, y1p, x2p, y2p, x3p, y3p);
    return sToQ.times(qToS);
  }

  void transformPoints(List<double> points) {
    final maxI = points.length - 1; // points.length must be even
    for (int i = 0; i < maxI; i += 2) {
      final x = points[i];
      final y = points[i + 1];
      final denominator = a13 * x + a23 * y + a33;
      points[i] = (a11 * x + a21 * y + a31) / denominator;
      points[i + 1] = (a12 * x + a22 * y + a32) / denominator;
    }
  }

  void transformPointsPair(List<double> xValues, List<double> yValues) {
    final n = xValues.length;
    for (int i = 0; i < n; i++) {
      final x = xValues[i];
      final y = yValues[i];
      final denominator = a13 * x + a23 * y + a33;
      xValues[i] = (a11 * x + a21 * y + a31) / denominator;
      yValues[i] = (a12 * x + a22 * y + a32) / denominator;
    }
  }

  static PerspectiveTransform squareToQuadrilateral(
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    final dx3 = x0 - x1 + x2 - x3;
    final dy3 = y0 - y1 + y2 - y3;
    if (dx3 == 0.0 && dy3 == 0.0) {
      // Affine
      return PerspectiveTransform._(
        x1 - x0,
        x2 - x1,
        x0,
        y1 - y0,
        y2 - y1,
        y0,
        0.0,
        0.0,
        1.0,
      );
    } else {
      final dx1 = x1 - x2;
      final dx2 = x3 - x2;
      final dy1 = y1 - y2;
      final dy2 = y3 - y2;
      final denominator = dx1 * dy2 - dx2 * dy1;
      final a13 = (dx3 * dy2 - dx2 * dy3) / denominator;
      final a23 = (dx1 * dy3 - dx3 * dy1) / denominator;
      return PerspectiveTransform._(
        x1 - x0 + a13 * x1,
        x3 - x0 + a23 * x3,
        x0,
        y1 - y0 + a13 * y1,
        y3 - y0 + a23 * y3,
        y0,
        a13,
        a23,
        1.0,
      );
    }
  }

  /// Here, the adjoint serves as the inverse:
  static PerspectiveTransform quadrilateralToSquare(
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) =>
      squareToQuadrilateral(x0, y0, x1, y1, x2, y2, x3, y3).buildAdjoint();

  /// Adjoint is the transpose of the cofactor matrix:
  PerspectiveTransform buildAdjoint() => PerspectiveTransform._(
        a22 * a33 - a23 * a32,
        a23 * a31 - a21 * a33,
        a21 * a32 - a22 * a31,
        a13 * a32 - a12 * a33,
        a11 * a33 - a13 * a31,
        a12 * a31 - a11 * a32,
        a12 * a23 - a13 * a22,
        a13 * a21 - a11 * a23,
        a11 * a22 - a12 * a21,
      );

  PerspectiveTransform times(PerspectiveTransform other) =>
      PerspectiveTransform._(
        a11 * other.a11 + a21 * other.a12 + a31 * other.a13,
        a11 * other.a21 + a21 * other.a22 + a31 * other.a23,
        a11 * other.a31 + a21 * other.a32 + a31 * other.a33,
        a12 * other.a11 + a22 * other.a12 + a32 * other.a13,
        a12 * other.a21 + a22 * other.a22 + a32 * other.a23,
        a12 * other.a31 + a22 * other.a32 + a32 * other.a33,
        a13 * other.a11 + a23 * other.a12 + a33 * other.a13,
        a13 * other.a21 + a23 * other.a22 + a33 * other.a23,
        a13 * other.a31 + a23 * other.a32 + a33 * other.a33,
      );
}
