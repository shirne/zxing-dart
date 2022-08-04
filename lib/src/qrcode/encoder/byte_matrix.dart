/*
 * Copyright 2008 ZXing authors
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

import 'dart:typed_data';

/// JAVAPORT: The original code was a 2D array of ints, but since it only ever gets assigned
/// -1, 0, and 1, I'm going to use less memory and go with bytes.
///
/// @author dswitkin@google.com (Daniel Switkin)
class ByteMatrix {
  final List<Int8List> _bytes;
  final int _width;
  final int _height;

  ByteMatrix(this._width, this._height)
      : _bytes = List.generate(_height, (index) => Int8List(_width));

  int get height => _height;

  int get width => _width;

  int get(int x, int y) => _bytes[y][x];

  /// @return an internal representation as bytes, in row-major order. array[y][x] represents point (x,y)
  List<Int8List> get bytes => _bytes;

  void set(int x, int y, int value) {
    _bytes[y][x] = value;
  }

  void clear(int value) {
    for (Int8List aByte in _bytes) {
      aByte.fillRange(0, aByte.length, value);
    }
  }

  @override
  String toString() {
    final result = StringBuffer();
    for (int y = 0; y < _height; ++y) {
      final bytesY = _bytes[y];
      for (int x = 0; x < _width; ++x) {
        switch (bytesY[x]) {
          case 0:
            result.write(' 0');
            break;
          case 1:
            result.write(' 1');
            break;
          default:
            result.write('  ');
            break;
        }
      }
      result.write('\n');
    }
    return result.toString();
  }
}
