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

import '../../common/bit_array.dart';

import 'binary_shift_token.dart';
import 'simple_token.dart';

abstract class Token {
  static final Token empty = SimpleToken(null, 0, 0);

  final Token? _previous;

  Token(this._previous);

  Token? get previous => _previous;

  Token add(int value, int bitCount) {
    return SimpleToken(this, value, bitCount);
  }

  Token addBinaryShift(int start, int byteCount) {
    //int bitCount = (byteCount * 8) + (byteCount <= 31 ? 10 : byteCount <= 62 ? 20 : 21);
    return BinaryShiftToken(this, start, byteCount);
  }

  void appendTo(BitArray bitArray, List<int> text);
}
