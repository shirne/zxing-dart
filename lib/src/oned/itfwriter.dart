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

import '../barcode_format.dart';
import '../encode_hint_type.dart';
import 'one_dimensional_code_writer.dart';

/// This object renders a ITF code as a [BitMatrix].
///
/// @author erik.barbara@gmail.com (Erik Barbara)
class ITFWriter extends OneDimensionalCodeWriter {
  static const List<int> _START_PATTERN = [1, 1, 1, 1];
  static const List<int> _END_PATTERN = [3, 1, 1];

  static const int _W = 3; // Pixel width of a 3x wide line
  static const int _N = 1; // Pixed width of a narrow line

  // See [ITFReader.PATTERNS]
  static const List<List<int>> _PATTERNS = [
    [_N, _N, _W, _W, _N], // 0
    [_W, _N, _N, _N, _W], // 1
    [_N, _W, _N, _N, _W], // 2
    [_W, _W, _N, _N, _N], // 3
    [_N, _N, _W, _N, _W], // 4
    [_W, _N, _W, _N, _N], // 5
    [_N, _W, _W, _N, _N], // 6
    [_N, _N, _N, _W, _W], // 7
    [_W, _N, _N, _W, _N], // 8
    [_N, _W, _N, _W, _N] // 9
  ];

  // @protected
  @override
  List<BarcodeFormat> get supportedWriteFormats => [BarcodeFormat.ITF];

  @override
  List<bool> encodeContent(String contents,
      [Map<EncodeHintType, Object?>? hints]) {
    int length = contents.length;
    if (length % 2 != 0) {
      throw Exception("The length of the input should be even");
    }
    if (length > 80) {
      throw Exception(
          "Requested contents should be less than 80 digits long, but got $length");
    }

    OneDimensionalCodeWriter.checkNumeric(contents);

    List<bool> result = List.filled(9 + 9 * length, false);
    int pos =
        OneDimensionalCodeWriter.appendPattern(result, 0, _START_PATTERN, true);
    for (int i = 0; i < length; i += 2) {
      int one = int.parse(contents[i]);
      int two = int.parse(contents[i + 1]);
      List<int> encoding = List.filled(10, 0);
      for (int j = 0; j < 5; j++) {
        encoding[2 * j] = _PATTERNS[one][j];
        encoding[2 * j + 1] = _PATTERNS[two][j];
      }
      pos +=
          OneDimensionalCodeWriter.appendPattern(result, pos, encoding, true);
    }
    OneDimensionalCodeWriter.appendPattern(result, pos, _END_PATTERN, true);

    return result;
  }
}
