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

/// Simply encapsulates a width and height.
class Dimension {
  final int _width;
  final int _height;

  Dimension(this._width, this._height)
      : assert(_width > 0, 'Argument width must greater then zero'),
        assert(_height > 0, 'Argument height must greater then zero');

  /// width of this
  int get width => _width;

  /// height of this
  int get height => _height;

  @override
  operator ==(Object other) {
    if (other is Dimension) {
      Dimension d = other;
      return _width == d._width && _height == d._height;
    }
    return false;
  }

  @override
  int get hashCode {
    return _width * 32713 + _height;
  }

  @override
  String toString() {
    return "$_width x $_height";
  }
}
