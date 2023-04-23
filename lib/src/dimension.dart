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
  const Dimension(this.width, this.height) : assert(width >= 0 || height >= 0);

  /// width of this
  final int width;

  /// height of this
  final int height;

  @override
  bool operator ==(Object other) {
    if (other is Dimension) {
      return width == other.width && height == other.height;
    }
    return false;
  }

  @override
  int get hashCode => width * 32713 + height;

  @override
  String toString() => '$width x $height';
}
