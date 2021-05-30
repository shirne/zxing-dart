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

import '../../common/bit_matrix.dart';

import '../../result_point.dart';

/**
 * @author Guenther Grau
 */
class PDF417DetectorResult {
  final BitMatrix bits;
  final List<List<ResultPoint?>> points;

  PDF417DetectorResult(this.bits, this.points);

  BitMatrix getBits() {
    return bits;
  }

  List<List<ResultPoint?>> getPoints() {
    return points;
  }
}
