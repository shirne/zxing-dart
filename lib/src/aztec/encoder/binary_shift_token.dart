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

import 'dart:math' as Math;

import '../../common/bit_array.dart';

import 'token.dart';


class BinaryShiftToken extends Token {
  final int _binaryShiftStart;
  final int _binaryShiftByteCount;

  BinaryShiftToken(
      Token previous, this._binaryShiftStart, this._binaryShiftByteCount)
      : super(previous);

  @override
  void appendTo(BitArray bitArray, List<int> text) {
    for (int i = 0; i < _binaryShiftByteCount; i++) {
      if (i == 0 || (i == 31 && _binaryShiftByteCount <= 62)) {
        // We need a header before the first character, and before
        // character 31 when the total byte code is <= 62
        bitArray.appendBits(31, 5); // BINARY_SHIFT
        if (_binaryShiftByteCount > 62) {
          bitArray.appendBits(_binaryShiftByteCount - 31, 16);
        } else if (i == 0) {
          // 1 <= binaryShiftByteCode <= 62
          bitArray.appendBits(Math.min(_binaryShiftByteCount, 31), 5);
        } else {
          // 32 <= binaryShiftCount <= 62 and i == 31
          bitArray.appendBits(_binaryShiftByteCount - 31, 5);
        }
      }
      bitArray.appendBits(text[_binaryShiftStart + i], 8);
    }
  }

  @override
  String toString() {
    return "<$_binaryShiftStart::${_binaryShiftStart + _binaryShiftByteCount - 1}>";
  }
}
