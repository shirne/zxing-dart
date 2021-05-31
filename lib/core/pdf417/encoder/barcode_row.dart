/*
 * Copyright 2011 ZXing authors
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

/**
 * @author Jacob Haynes
 */
class BarcodeRow {
  final Uint8List _row;
  //A tacker for position in the bar
  int _currentLocation = 0;

  /**
   * Creates a Barcode row of the width
   */
  BarcodeRow(int width) : _row = Uint8List(width);

  /**
   * Sets a specific location in the bar
   *
   * @param x The location in the bar
   * @param value Black if true, white if false;
   */
  void set(int x, int value) {
    _row[x] = value;
  }

  void _set(int x, bool black) {
    _row[x] = (black ? 1 : 0);
  }

  /**
   * @param black A bool which is true if the bar black false if it is white
   * @param width How many spots wide the bar is.
   */
  void addBar(bool black, int width) {
    for (int ii = 0; ii < width; ii++) {
      _set(_currentLocation++, black);
    }
  }

  /**
   * This function scales the row
   *
   * @param scale How much you want the image to be scaled, must be greater than or equal to 1.
   * @return the scaled row
   */
  Uint8List getScaledRow(int scale) {
    Uint8List output = Uint8List(_row.length * scale);
    for (int i = 0; i < output.length; i++) {
      output[i] = _row[i ~/ scale];
    }
    return output;
  }
}
