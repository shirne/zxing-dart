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

import '../../common/bit_matrix.dart';

/// Aztec 2D code representation
///
/// @author Rustam Abdullaev
class AztecCode {

  /// whether if compact instead of full mode
  late bool isCompact;

  /// size in pixels (width and height)
  late int size;

  /// number of levels
  late int layers;

  /// number of data codewords
  late int codeWords;

  /// the symbol image
  BitMatrix? matrix;

  AztecCode({
    this.isCompact = false,
    this.size = 0,
    this.layers = 0,
    this.codeWords = 0,
    this.matrix
  });
}
