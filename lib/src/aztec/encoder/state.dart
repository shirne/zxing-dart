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

import 'dart:convert';
import 'dart:typed_data';

import '../../common/bit_array.dart';
import 'high_level_encoder.dart';
import 'token.dart';

/// State represents all information about a sequence necessary to generate the current output.
/// Note that a state is immutable.
class State {
  static final State initialState =
      State(Token.empty, HighLevelEncoder.MODE_UPPER, 0, 0);

  // The current mode of the encoding (or the mode to which we'll return if
  // we're in Binary Shift mode.
  final int _mode;
  // The list of tokens that we output.  If we are in Binary Shift mode, this
  // token list does *not* yet included the token for those bytes
  final Token _token;
  // If non-zero, the number of most recent bytes that should be output
  // in Binary Shift mode.
  final int _binaryShiftByteCount;
  // The total number of bits generated (including Binary Shift).
  final int _bitCount;
  final int _binaryShiftCost;

  State(
    this._token,
    this._mode,
    this._binaryShiftByteCount,
    this._bitCount, [
    int? binaryShiftCost,
  ]) : _binaryShiftCost =
            binaryShiftCost ?? _calculateBinaryShiftCost(_binaryShiftByteCount);

  int get mode => _mode;

  Token get token => _token;

  int get binaryShiftByteCount => _binaryShiftByteCount;

  int get bitCount => _bitCount;

  State appendFLGn(int eci) {
    State result = shiftAndAppend(HighLevelEncoder.MODE_PUNCT, 0); // 0: FLG(n)
    Token token = result._token;
    int bitsAdded = 3;
    if (eci < 0) {
      token = token.add(0, 3); // 0: FNC1
    } else if (eci > 999999) {
      throw ArgumentError("ECI code must be between 0 and 999999");
    } else {
      Uint8List eciDigits = latin1.encode(eci.toString());
      token = token.add(eciDigits.length, 3); // 1-6: number of ECI digits
      for (int eciDigit in eciDigits) {
        token = token.add(eciDigit - 48 /*'0'*/ + 2, 4);
      }
      bitsAdded += eciDigits.length * 4;
    }
    return State(token, _mode, 0, _bitCount + bitsAdded);
  }

  // Create a new state representing this state with a latch to a (not
  // necessary different) mode, and then a code.
  State latchAndAppend(int mode, int value) {
    //assert binaryShiftByteCount == 0;
    int bitCount = _bitCount;
    Token token = _token;
    if (mode != _mode) {
      int latch = HighLevelEncoder.LATCH_TABLE[_mode][mode];
      token = token.add(latch & 0xFFFF, latch >> 16);
      bitCount += latch >> 16;
    }
    int latchModeBitCount = mode == HighLevelEncoder.MODE_DIGIT ? 4 : 5;
    token = token.add(value, latchModeBitCount);
    return State(token, mode, 0, bitCount + latchModeBitCount);
  }

  // Create a new state representing this state, with a temporary shift
  // to a different mode to output a single value.
  State shiftAndAppend(int mode, int value) {
    //assert binaryShiftByteCount == 0 && this.mode != mode;
    Token token = _token;
    int thisModeBitCount = _mode == HighLevelEncoder.MODE_DIGIT ? 4 : 5;
    // Shifts exist only to UPPER and PUNCT, both with tokens size 5.
    token =
        token.add(HighLevelEncoder.shiftTable[_mode][mode], thisModeBitCount);
    token = token.add(value, 5);
    return State(token, _mode, 0, _bitCount + thisModeBitCount + 5);
  }

  // Create a new state representing this state, but an additional character
  // output in Binary Shift mode.
  State addBinaryShiftChar(int index) {
    Token token = _token;
    int mode = _mode;
    int bitCount = _bitCount;
    if (_mode == HighLevelEncoder.MODE_PUNCT ||
        _mode == HighLevelEncoder.MODE_DIGIT) {
      //assert binaryShiftByteCount == 0;
      int latch =
          HighLevelEncoder.LATCH_TABLE[mode][HighLevelEncoder.MODE_UPPER];
      token = token.add(latch & 0xFFFF, latch >> 16);
      bitCount += latch >> 16;
      mode = HighLevelEncoder.MODE_UPPER;
    }
    int deltaBitCount =
        (_binaryShiftByteCount == 0 || _binaryShiftByteCount == 31)
            ? 18
            : (_binaryShiftByteCount == 62)
                ? 9
                : 8;
    State result =
        State(token, mode, _binaryShiftByteCount + 1, bitCount + deltaBitCount);
    if (result._binaryShiftByteCount == 2047 + 31) {
      // The string is as long as it's allowed to be.  We should end it.
      result = result.endBinaryShift(index + 1);
    }
    return result;
  }

  // Create the state identical to this one, but we are no longer in
  // Binary Shift mode.
  State endBinaryShift(int index) {
    if (_binaryShiftByteCount == 0) {
      return this;
    }
    Token token = _token;
    token = token.addBinaryShift(
        index - _binaryShiftByteCount, _binaryShiftByteCount);
    //assert token.getTotalBitCount() == this.bitCount;
    return State(token, _mode, 0, _bitCount);
  }

  // Returns true if "this" state is better (or equal) to be in than "that"
  // state under all possible circumstances.
  bool isBetterThanOrEqualTo(State other) {
    int newModeBitCount =
        _bitCount + (HighLevelEncoder.LATCH_TABLE[_mode][other._mode] >> 16);
    if (_binaryShiftByteCount < other._binaryShiftByteCount) {
      // add additional B/S encoding cost of other, if any
      newModeBitCount += other._binaryShiftCost - _binaryShiftCost;
    } else if (_binaryShiftByteCount > other._binaryShiftByteCount &&
        other._binaryShiftByteCount > 0) {
      // maximum possible additional cost (we end up exceeding the 31 byte boundary and other state can stay beneath it)
      newModeBitCount += 10;
    }
    return newModeBitCount <= other._bitCount;
  }

  BitArray toBitArray(List<int> text) {
    // Reverse the tokens, so that they are in the order that they should
    // be output
    List<Token> symbols = [];
    for (Token? token = endBinaryShift(text.length)._token;
        token != null;
        token = token.previous) {
      symbols.insert(0, token);
    }
    BitArray bitArray = BitArray();
    // Add each token to the result.
    for (Token symbol in symbols) {
      symbol.appendTo(bitArray, text);
    }
    //assert bitArray.getSize() == this.bitCount;
    return bitArray;
  }

  @override
  String toString() {
    return "${HighLevelEncoder.MODE_NAMES[_mode]} bits=$_bitCount bytes=$_binaryShiftByteCount";
  }

  static int _calculateBinaryShiftCost(int binaryShiftByteCount) {
    if (binaryShiftByteCount > 62) {
      return 21; // B/S with extended length
    }
    if (binaryShiftByteCount > 31) {
      return 20; // two B/S
    }
    if (binaryShiftByteCount > 0) {
      return 10; // one B/S
    }
    return 0;
  }
}
