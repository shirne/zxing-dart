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
import '../encode_hint.dart';
import 'one_dimensional_code_writer.dart';

/// This object renders a ITF code as a [BitMatrix].
///
/// @author erik.barbara@gmail.com (Erik Barbara)
class ITFWriter extends OneDimensionalCodeWriter {
  static const List<int> _startPattern = [1, 1, 1, 1];
  static const List<int> _endPattern = [3, 1, 1];

  static const int _t = 3; // Pixel width of a 3x wide line
  static const int _n = 1; // Pixed width of a narrow line

  // See [ITFReader.PATTERNS]
  static const List<List<int>> _patterns = [
    [_n, _n, _t, _t, _n], // 0
    [_t, _n, _n, _n, _t], // 1
    [_n, _t, _n, _n, _t], // 2
    [_t, _t, _n, _n, _n], // 3
    [_n, _n, _t, _n, _t], // 4
    [_t, _n, _t, _n, _n], // 5
    [_n, _t, _t, _n, _n], // 6
    [_n, _n, _n, _t, _t], // 7
    [_t, _n, _n, _t, _n], // 8
    [_n, _t, _n, _t, _n] // 9
  ];

  // @protected
  @override
  List<BarcodeFormat> get supportedWriteFormats => [BarcodeFormat.itf];

  @override
  List<bool> encodeContent(
    String contents, [
    EncodeHint? hints,
  ]) {
    final length = contents.length;
    if (length % 2 != 0) {
      throw ArgumentError('The length of the input should be even');
    }
    if (length > 80) {
      throw ArgumentError(
        'Requested contents should be less than 80 '
        'digits long, but got $length',
      );
    }

    OneDimensionalCodeWriter.checkNumeric(contents);

    final result = List.filled(9 + 9 * length, false);
    int pos =
        OneDimensionalCodeWriter.appendPattern(result, 0, _startPattern, true);
    for (int i = 0; i < length; i += 2) {
      final one = int.parse(contents[i]);
      final two = int.parse(contents[i + 1]);
      final encoding = List.filled(10, 0);
      for (int j = 0; j < 5; j++) {
        encoding[2 * j] = _patterns[one][j];
        encoding[2 * j + 1] = _patterns[two][j];
      }
      pos +=
          OneDimensionalCodeWriter.appendPattern(result, pos, encoding, true);
    }
    OneDimensionalCodeWriter.appendPattern(result, pos, _endPattern, true);

    return result;
  }
}
