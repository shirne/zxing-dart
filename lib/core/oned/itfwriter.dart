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
import 'one_dimensional_code_writer.dart';

/**
 * This object renders a ITF code as a {@link BitMatrix}.
 *
 * @author erik.barbara@gmail.com (Erik Barbara)
 */
class ITFWriter extends OneDimensionalCodeWriter {

  static final List<int> START_PATTERN = [1, 1, 1, 1];
  static final List<int> END_PATTERN = [3, 1, 1];

  static final int W = 3; // Pixel width of a 3x wide line
  static final int N = 1; // Pixed width of a narrow line

  // See ITFReader.PATTERNS

  static final List<List<int>> PATTERNS = [
      [N, N, W, W, N], // 0
      [W, N, N, N, W], // 1
      [N, W, N, N, W], // 2
      [W, W, N, N, N], // 3
      [N, N, W, N, W], // 4
      [W, N, W, N, N], // 5
      [N, W, W, N, N], // 6
      [N, N, N, W, W], // 7
      [W, N, N, W, N], // 8
      [N, W, N, W, N]  // 9
  ];

  @override
  List<BarcodeFormat> getSupportedWriteFormats() {
    return [BarcodeFormat.ITF];
  }

  @override
  List<bool> encodeContent(String contents) {
    int length = contents.length;
    if (length % 2 != 0) {
      throw Exception("The length of the input should be even");
    }
    if (length > 80) {
      throw Exception(
          "Requested contents should be less than 80 digits long, but got $length" );
    }

    OneDimensionalCodeWriter.checkNumeric(contents);

    List<bool> result = List.filled(9 + 9 * length, false);
    int pos = OneDimensionalCodeWriter.appendPattern(result, 0, START_PATTERN, true);
    for (int i = 0; i < length; i += 2) {
      int one = int.parse(contents[i]);
      int two = int.parse(contents[i+1]);
      List<int> encoding = List.filled(10, 0);
      for (int j = 0; j < 5; j++) {
        encoding[2 * j] = PATTERNS[one][j];
        encoding[2 * j + 1] = PATTERNS[two][j];
      }
      pos += OneDimensionalCodeWriter.appendPattern(result, pos, encoding, true);
    }
    OneDimensionalCodeWriter.appendPattern(result, pos, END_PATTERN, true);

    return result;
  }

}
