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

/// Encapsulates an alignment pattern, which are the smaller square patterns found in
/// all but the simplest QR Codes.
///
/// @author Sean Owen
class AlignmentPattern extends ResultPoint {
  final double _estimatedModuleSize;

  AlignmentPattern(super.posX, super.posY, this._estimatedModuleSize);

  /// Determines if this alignment pattern "about equals" an alignment pattern at the stated
  /// position and size -- meaning, it is at nearly the same center with nearly the same size.
  bool aboutEquals(double moduleSize, double i, double j) {
    if ((i - y).abs() <= moduleSize && (j - x).abs() <= moduleSize) {
      final moduleSizeDiff = (moduleSize - _estimatedModuleSize).abs();
      return moduleSizeDiff <= 1.0 || moduleSizeDiff <= _estimatedModuleSize;
    }
    return false;
  }

  /// Combines this object's current estimate of a finder pattern position and module size
  /// with a new estimate. It returns a new [FinderPattern]` containing an average of the two.
  AlignmentPattern combineEstimate(double i, double j, double newModuleSize) {
    final combinedX = (x + j) / 2.0;
    final combinedY = (y + i) / 2.0;
    final combinedModuleSize = (_estimatedModuleSize + newModuleSize) / 2.0;
    return AlignmentPattern(combinedX, combinedY, combinedModuleSize);
  }
}
