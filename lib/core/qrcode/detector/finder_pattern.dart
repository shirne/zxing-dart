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


import '../../result_point.dart';

/// <p>Encapsulates a finder pattern, which are the three square patterns found in
/// the corners of QR Codes. It also encapsulates a count of similar finder patterns,
/// as a convenience to the finder's bookkeeping.</p>
///
/// @author Sean Owen
class FinderPattern extends ResultPoint {
  final double _estimatedModuleSize;
  final int _count;

  FinderPattern(double posX, double posY, this._estimatedModuleSize,
      [this._count = 1])
      : super(posX, posY);

  double getEstimatedModuleSize() {
    return _estimatedModuleSize;
  }

  int getCount() {
    return _count;
  }

  /// <p>Determines if this finder pattern "about equals" a finder pattern at the stated
  /// position and size -- meaning, it is at nearly the same center with nearly the same size.</p>
  bool aboutEquals(double moduleSize, double i, double j) {
    if ((i - getY()).abs() <= moduleSize && (j - getX()).abs() <= moduleSize) {
      double moduleSizeDiff = (moduleSize - _estimatedModuleSize).abs();
      return moduleSizeDiff <= 1.0 || moduleSizeDiff <= _estimatedModuleSize;
    }
    return false;
  }

  /// Combines this object's current estimate of a finder pattern position and module size
  /// with a new estimate. It returns a new {@code FinderPattern} containing a weighted average
  /// based on count.
  FinderPattern combineEstimate(double i, double j, double newModuleSize) {
    int combinedCount = _count + 1;
    double combinedX = (_count * getX() + j) / combinedCount;
    double combinedY = (_count * getY() + i) / combinedCount;
    double combinedModuleSize =
        (_count * _estimatedModuleSize + newModuleSize) / combinedCount;
    return FinderPattern(
        combinedX, combinedY, combinedModuleSize, combinedCount);
  }
}
