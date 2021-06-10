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

import 'dart:typed_data';

import '../../common/bit_array.dart';

import 'token.dart';


class SimpleToken extends Token {
  // For normal words, indicates value and bitCount
  final int _value;
  final int _bitCount;

  SimpleToken(Token? previous, this._value, this._bitCount) : super(previous);

  @override
  void appendTo(BitArray bitArray, List<int> text) {
    bitArray.appendBits(_value, _bitCount);
  }

  @override
  String toString() {
    int value = this._value & ((1 << _bitCount) - 1);
    value |= 1 << _bitCount;
    return '<${(value | (1 << _bitCount)).toRadixString(2).substring(1)}>';
  }
}
