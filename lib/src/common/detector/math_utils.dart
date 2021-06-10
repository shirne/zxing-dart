/*
 * Copyright 2012 ZXing authors
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

import 'package:fixnum/fixnum.dart';

/// General math-related and numeric utility functions.
class MathUtils {
  static const MIN_VALUE = -2147483648;
  static const MAX_VALUE = 2147483647;

  MathUtils();

  /// Ends up being a bit faster than {@link Math#round(double)}. This merely rounds its
  /// argument to the nearest int, where x.5 rounds up to x+1. Semantics of this shortcut
  /// differ slightly from {@link Math#round(double)} in that half rounds down for negative
  /// values. -2.5 rounds to -3, not -2. For purposes here it makes no difference.
  ///
  /// @param d real value to round
  /// @return nearest `int`
  static int round(double d) {
    if(d.isNaN )return 0;
    if(d.isInfinite){
      if(d.sign == 1){
        return MAX_VALUE;
      }else{
        return MIN_VALUE;
      }
    }
    return (d + (d < 0.0 ? -0.5 : 0.5)).toInt();
  }

  /// @param aX point A x coordinate
  /// @param aY point A y coordinate
  /// @param bX point B x coordinate
  /// @param bY point B y coordinate
  /// @return Euclidean distance between points A and B
  static double distance(double aX, double aY, double bX, double bY) {
    double xDiff = aX - bX;
    double yDiff = aY - bY;
    return Math.sqrt(xDiff * xDiff + yDiff * yDiff);
  }

  /// @param array values to sum
  /// @return sum of values in array
  static int sum(List<int> array) {
    int count = 0;
    for (int a in array) {
      count += a;
    }
    return count;
  }

  /*static int bitCount(int num) {
    int count = 0;
    while (num > 0) {
      num = num & (num - 1);
      count++;
    }
    return count;
  }*/

   static int bitCount(int i){
    i = i - ((i >> 1) & 0x55555555);
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
    i = (i + (i >> 4)) & 0x0f0f0f0f;
    i = i + (i >> 8);
    i = i + (i >> 16);
    return i & 0x3f;
  }

  static int binarySearch(List<int> arr, int value, [int start = 0, int? end]) {
    late int mid;
    if (end == null) end = arr.length - 1;
    while (start <= end!) {
      mid = start + ((end - start) / 2).round();
      if (arr[mid] == value) return mid;
      if (arr[mid] < value)
        start = mid + 1;
      else
        end = mid - 1;
    }
    return -1;
  }

  static bool isDigit(int ch) {
    return ch >= 48 /* 0 */ && ch <= 57 /* 9 */;
  }

  static int numberOfLeadingZeros(int i) {
    if (i == 0) return 32;
    int n = 1;
    if (i >> 16 == 0) {
      n += 16;
      i <<= 16;
    }
    if (i >> 24 == 0) {
      n += 8;
      i <<= 8;
    }
    if (i >> 28 == 0) {
      n += 4;
      i <<= 4;
    }
    if (i >> 30 == 0) {
      n += 2;
      i <<= 2;
    }
    n -= i >> 31;
    return n;
  }

  static int numberOfTrailingZeros(int i) {
    return Int32(i).numberOfTrailingZeros();
  }
}
