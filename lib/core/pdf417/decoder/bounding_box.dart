/*
 * Copyright 2013 ZXing authors
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

import '../../not_found_exception.dart';
import '../../result_point.dart';

/**
 * @author Guenther Grau
 */
class BoundingBox {
  final BitMatrix image;
  late ResultPoint topLeft;
  late ResultPoint bottomLeft;
  late ResultPoint topRight;
  late ResultPoint bottomRight;
  late int minX;
  late int maxX;
  late int minY;
  late int maxY;

  BoundingBox(this.image, ResultPoint? topLeft, ResultPoint? bottomLeft,
      ResultPoint? topRight, ResultPoint? bottomRight) {
    bool leftUnspecified = topLeft == null || bottomLeft == null;
    bool rightUnspecified = topRight == null || bottomRight == null;
    if (leftUnspecified && rightUnspecified) {
      throw NotFoundException.getNotFoundInstance();
    }
    if (leftUnspecified) {
      topLeft = ResultPoint(0, topRight!.getY());
      bottomLeft = ResultPoint(0, bottomRight!.getY());
    } else if (rightUnspecified) {
      topRight = ResultPoint(image.getWidth() - 1, topLeft.getY());
      bottomRight = ResultPoint(image.getWidth() - 1, bottomLeft.getY());
    }
    this.topLeft = topLeft;
    this.bottomLeft = bottomLeft;
    this.topRight = topRight;
    this.bottomRight = bottomRight;
    this.minX = Math.min(topLeft.getX().toInt(), bottomLeft.getX().toInt());
    this.maxX = Math.max(topRight.getX().toInt(), bottomRight.getX().toInt());
    this.minY = Math.min(topLeft.getY().toInt(), topRight.getY().toInt());
    this.maxY = Math.max(bottomLeft.getY().toInt(), bottomRight.getY().toInt());
  }

  BoundingBox.copy(BoundingBox boundingBox)
      : this.image = boundingBox.image,
        this.topLeft = boundingBox.topLeft,
        this.bottomLeft = boundingBox.bottomLeft,
        this.topRight = boundingBox.topRight,
        this.bottomRight = boundingBox.bottomRight,
        this.minX = boundingBox.minX,
        this.maxX = boundingBox.maxX,
        this.minY = boundingBox.minY,
        this.maxY = boundingBox.maxY;

  static BoundingBox? merge(BoundingBox? leftBox, BoundingBox? rightBox) {
    if (leftBox == null) {
      return rightBox;
    }
    if (rightBox == null) {
      return leftBox;
    }
    return BoundingBox(leftBox.image, leftBox.topLeft, leftBox.bottomLeft,
        rightBox.topRight, rightBox.bottomRight);
  }

  BoundingBox addMissingRows(
      int missingStartRows, int missingEndRows, bool isLeft) {
    ResultPoint newTopLeft = topLeft;
    ResultPoint newBottomLeft = bottomLeft;
    ResultPoint newTopRight = topRight;
    ResultPoint newBottomRight = bottomRight;

    if (missingStartRows > 0) {
      ResultPoint top = isLeft ? topLeft : topRight;
      int newMinY = top.getY().toInt() - missingStartRows;
      if (newMinY < 0) {
        newMinY = 0;
      }
      ResultPoint newTop = ResultPoint(top.getX(), newMinY.toDouble());
      if (isLeft) {
        newTopLeft = newTop;
      } else {
        newTopRight = newTop;
      }
    }

    if (missingEndRows > 0) {
      ResultPoint bottom = isLeft ? bottomLeft : bottomRight;
      int newMaxY = bottom.getY().toInt() + missingEndRows;
      if (newMaxY >= image.getHeight()) {
        newMaxY = image.getHeight() - 1;
      }
      ResultPoint newBottom =
          ResultPoint(bottom.getX(), newMaxY.toDouble());
      if (isLeft) {
        newBottomLeft = newBottom;
      } else {
        newBottomRight = newBottom;
      }
    }

    return BoundingBox(
        image, newTopLeft, newBottomLeft, newTopRight, newBottomRight);
  }

  int getMinX() {
    return minX;
  }

  int getMaxX() {
    return maxX;
  }

  int getMinY() {
    return minY;
  }

  int getMaxY() {
    return maxY;
  }

  ResultPoint getTopLeft() {
    return topLeft;
  }

  ResultPoint getTopRight() {
    return topRight;
  }

  ResultPoint getBottomLeft() {
    return bottomLeft;
  }

  ResultPoint getBottomRight() {
    return bottomRight;
  }
}
