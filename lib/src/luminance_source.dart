/*
 * Copyright 2009 ZXing authors
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

import 'inverted_luminance_source.dart';

/// The purpose of this class hierarchy is to abstract different bitmap implementations across
/// platforms into a standard interface for requesting greyscale luminance values. The interface
/// only provides immutable methods; therefore crop and rotation create copies. This is to ensure
/// that one Reader does not modify the original luminance source and leave it in an unknown state
/// for other Readers in the chain.
///
/// @author dswitkin@google.com (Daniel Switkin)
abstract class LuminanceSource {
  final int _width;
  final int _height;

  LuminanceSource(this._width, this._height);

  /// Fetches one row of luminance data from the underlying platform's bitmap. Values range from
  /// 0 (black) to 255 (white). Because Java does not have an unsigned byte type, callers will have
  /// to bitwise and with 0xff for each value. It is preferable for implementations of this method
  /// to only fetch this row rather than the whole image, since no 2D Readers may be installed and
  /// getMatrix() may never be called.
  ///
  /// @param y The row to fetch, which must be in [0,getHeight())
  /// @param row An optional preallocated array. If null or too small, it will be ignored.
  ///            Always use the returned object, and ignore the .length of the array.
  /// @return An array containing the luminance data.
  Int8List getRow(int y, Int8List? row);

  /// Fetches luminance data for the underlying bitmap. Values should be fetched using:
  /// {@code int luminance = array[y * width + x] & 0xff}
  ///
  /// @return A row-major 2D array of luminance values. Do not use result.length as it may be
  ///         larger than width * height bytes on some platforms. Do not modify the contents
  ///         of the result.
  Int8List get matrix;

  /// Get the width of the bitmap.
  int get width => _width;

  /// Get the height of the bitmap.
  int get height => _height;

  /// Get whether this subclass supports cropping.
  bool get isCropSupported => false;

  /// Returns a new object with cropped image data. Implementations may keep a reference to the
  /// original data rather than a copy. Only callable if isCropSupported() is true.
  ///
  /// @param left The left coordinate, which must be in [0,getWidth())
  /// @param top The top coordinate, which must be in [0,getHeight())
  /// @param width The width of the rectangle to crop.
  /// @param height The height of the rectangle to crop.
  /// @return A cropped version of this object.
  LuminanceSource crop(int left, int top, int width, int height) {
    throw Exception("This luminance source does not support cropping.");
  }

  /// Get whether this subclass supports counter-clockwise rotation.
  bool get isRotateSupported => false;

  /// Get a wrapper of this [LuminanceSource] which inverts the luminances it returns -- black becomes
  ///  white and vice versa, and each value becomes (255-value).
  LuminanceSource invert() {
    return InvertedLuminanceSource(this);
  }

  /// Get a rotated version of this object.
  ///
  /// Returns a new object with rotated image data by 90 degrees counterclockwise.
  /// Only callable if [isRotateSupported] is true.
  LuminanceSource rotateCounterClockwise() {
    throw Exception(
        "This luminance source does not support rotation by 90 degrees.");
  }

  /// Get a rotated version of this object.
  ///
  /// Returns a new object with rotated image data by 45 degrees counterclockwise.
  /// Only callable if [isRotateSupported] is true.
  LuminanceSource rotateCounterClockwise45() {
    throw Exception(
        "This luminance source does not support rotation by 45 degrees.");
  }

  @override
  String toString() {
    late Int8List row = Int8List(_width);
    StringBuffer result = StringBuffer();
    for (int y = 0; y < _height; y++) {
      row = getRow(y, row);
      for (int x = 0; x < _width; x++) {
        int luminance = row[x] & 0xFF;
        String c;
        if (luminance < 0x40) {
          c = '#';
        } else if (luminance < 0x80) {
          c = '+';
        } else if (luminance < 0xC0) {
          c = '.';
        } else {
          c = ' ';
        }
        result.write(c);
      }
      result.write('\n');
    }
    return result.toString();
  }
}
