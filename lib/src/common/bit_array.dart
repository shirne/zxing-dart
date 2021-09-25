/*
 * Copyright 2007 ZXing authors
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

import 'dart:math' as math;
import 'dart:typed_data';

import 'detector/math_utils.dart';
import 'utils.dart';

/// A simple, fast array of bits, represented compactly by an array of ints internally.
///
/// @author Sean Owen
class BitArray {
  late Int32List _bits;
  int _size;

  BitArray([this._size = 0]) {
    if (_size == 0) {
      _bits = Int32List(1);
    } else {
      _bits = _makeArray(_size);
    }
  }

  BitArray.test(this._bits, this._size);

  // for tests
  Int32List get bits => _bits;

  int get size => _size;

  int get sizeInBytes => (_size + 7) ~/ 8;

  void _ensureCapacity(int size) {
    if (size > _bits.length * 32) {
      Int32List newBits = _makeArray(size);
      List.copyRange(newBits, 0, _bits, 0, _bits.length);
      _bits = newBits;
    }
  }

  bool operator [](int i) {
    return get(i);
  }

  /// @param i bit to get
  /// @return true iff bit i is set
  bool get(int i) {
    return (_bits[i ~/ 32] & (1 << (i & 0x1F))) != 0;
  }

  /// Sets bit i.
  ///
  /// @param i bit to set
  void set(int i) {
    _bits[i ~/ 32] |= 1 << (i & 0x1F);
  }

  /// Flips bit i.
  ///
  /// @param i bit to set
  void flip(int i) {
    _bits[i ~/ 32] ^= 1 << (i & 0x1F);
  }

  /// @param from first bit to check
  /// @return index of first bit that is set, starting from the given index, or size if none are set
  ///  at or beyond this given index
  /// @see #getNextUnset(int)
  int getNextSet(int from) {
    if (from >= _size) {
      return _size;
    }
    int bitsOffset = from ~/ 32;
    int currentBits = _bits[bitsOffset];
    // mask off lesser bits first
    currentBits &= ~((1 << (from & 0x1F)) - 1);
    while (currentBits == 0) {
      if (++bitsOffset == _bits.length) {
        return _size;
      }
      currentBits = _bits[bitsOffset];
    }
    int result =
        (bitsOffset * 32) + MathUtils.numberOfTrailingZeros(currentBits);
    return math.min(result, _size);
  }

  /// @param from index to start looking for unset bit
  /// @return index of next unset bit, or `size` if none are unset until the end
  /// @see #getNextSet(int)
  int getNextUnset(int from) {
    if (from >= _size) {
      return _size;
    }
    int bitsOffset = from ~/ 32;
    int currentBits = ~_bits[bitsOffset];
    // mask off lesser bits first
    currentBits &= ~((1 << (from & 0x1F)) - 1);
    while (currentBits == 0) {
      if (++bitsOffset == _bits.length) {
        return _size;
      }
      currentBits = ~_bits[bitsOffset];
    }
    int result =
        (bitsOffset * 32) + MathUtils.numberOfTrailingZeros(currentBits);
    return math.min(result, _size);
  }

  /// Sets a block of 32 bits, starting at bit i.
  ///
  /// @param i first bit to set
  /// @param newBits the new value of the next 32 bits. Note again that the least-significant bit
  /// corresponds to bit i, the next-least-significant to i+1, and so on.
  void setBulk(int i, int newBits) {
    _bits[i ~/ 32] = newBits;
  }

  /// Sets a range of bits.
  ///
  /// @param start start of range, inclusive.
  /// @param end end of range, exclusive
  void setRange(int start, int end) {
    if (end < start || start < 0 || end > _size) {
      throw ArgumentError(r'Illegal Argument');
    }
    if (end == start) {
      return;
    }
    end--; // will be easier to treat this as the last actually set bit -- inclusive
    int firstInt = start ~/ 32;
    int lastInt = end ~/ 32;
    for (int i = firstInt; i <= lastInt; i++) {
      int firstBit = i > firstInt ? 0 : start & 0x1F;
      int lastBit = i < lastInt ? 31 : end & 0x1F;
      // Ones from firstBit to lastBit, inclusive
      int mask = (2 << lastBit) - (1 << firstBit);
      _bits[i] |= mask;
    }
  }

  /// Clears all bits (sets to false).
  void clear() {
    _bits.fillRange(0, _bits.length, 0);
    /*int max = _bits.length;
    for (int i = 0; i < max; i++) {
      _bits[i] = 0;
    }*/
  }

  /// Efficient method to check if a range of bits is set, or not set.
  ///
  /// @param start start of range, inclusive.
  /// @param end end of range, exclusive
  /// @param value if true, checks that bits in range are set, otherwise checks that they are not set
  /// @return true iff all bits are set or not set in range, according to value argument
  /// @throws IllegalArgumentException if end is less than start or the range is not contained in the array
  bool isRange(int start, int end, bool value) {
    if (end < start || start < 0 || end > _size) {
      throw ArgumentError(r'Illegal Argument');
    }
    if (end == start) {
      return true; // empty range matches
    }
    end--; // will be easier to treat this as the last actually set bit -- inclusive
    int firstInt = start ~/ 32;
    int lastInt = end ~/ 32;
    for (int i = firstInt; i <= lastInt; i++) {
      int firstBit = i > firstInt ? 0 : start & 0x1F;
      int lastBit = i < lastInt ? 31 : end & 0x1F;
      // Ones from firstBit to lastBit, inclusive
      int mask = (2 << lastBit) - (1 << firstBit);

      // Return false if we're looking for 1s and the masked bits[i] isn't all 1s (that is,
      // equals the mask, or we're looking for 0s and the masked portion is not all 0s
      if ((_bits[i] & mask) != (value ? mask : 0)) {
        return false;
      }
    }
    return true;
  }

  void appendBit(bool bit) {
    _ensureCapacity(_size + 1);
    if (bit) {
      _bits[_size ~/ 32] |= 1 << (_size & 0x1F);
    }
    _size++;
  }

  /// Appends the least-significant bits, from value, in order from most-significant to
  /// least-significant. For example, appending 6 bits from 0x000001E will append the bits
  /// 0, 1, 1, 1, 1, 0 in that order.
  ///
  /// @param value `int` containing bits to append
  /// @param numBits bits from value to append
  void appendBits(int value, int numBits) {
    if (numBits < 0 || numBits > 32) {
      throw ArgumentError(r'Num bits must be between 0 and 32');
    }

    int nextSize = _size;
    _ensureCapacity(nextSize + numBits);
    for (int numBitsLeft = numBits - 1; numBitsLeft >= 0; numBitsLeft--) {
      if ((value & (1 << numBitsLeft)) != 0) {
        bits[nextSize ~/ 32] |= 1 << (nextSize & 0x1F);
      }
      nextSize++;
    }
    _size = nextSize;
  }

  void appendBitArray(BitArray other) {
    int otherSize = other._size;
    _ensureCapacity(_size + otherSize);
    for (int i = 0; i < otherSize; i++) {
      appendBit(other.get(i));
    }
  }

  void xor(BitArray other) {
    if (_size != other._size) {
      throw ArgumentError("Sizes don't match");
    }
    for (int i = 0; i < _bits.length; i++) {
      // The last int could be incomplete (i.e. not have 32 bits in
      // it) but there is no problem since 0 XOR 0 == 0.
      _bits[i] ^= other._bits[i];
    }
  }

  ///
  /// @param bitOffset first bit to start writing
  /// @param array array to write into. Bytes are written most-significant byte first. This is the opposite
  ///  of the internal representation, which is exposed by {@link #getBitArray()}
  /// @param offset position in array to start writing
  /// @param numBytes how many bytes to write
  void toBytes(int bitOffset, Uint8List array, int offset, int numBytes) {
    for (int i = 0; i < numBytes; i++) {
      int theByte = 0;
      for (int j = 0; j < 8; j++) {
        if (get(bitOffset)) {
          theByte |= 1 << (7 - j);
        }
        bitOffset++;
      }
      array[offset + i] = theByte;
    }
  }

  /// @return underlying array of ints. The first element holds the first 32 bits, and the least
  ///         significant bit is bit 0.
  Int32List getBitArray() {
    return _bits;
  }

  /// Reverses all bits in the array.
  void reverse() {
    Int32List newBits = Int32List(_bits.length);
    // reverse all int's first
    int len = (_size - 1) ~/ 32;
    int oldBitsLen = len + 1;
    for (int i = 0; i < oldBitsLen; i++) {
      newBits[len - i] = Utils.reverseSign32(_bits[i]);
    }
    // now correct the int's if the bit size isn't a multiple of 32
    if (_size != oldBitsLen * 32) {
      int leftOffset = oldBitsLen * 32 - _size;
      var currentInt = newBits[0] >>> leftOffset;
      for (int i = 1; i < oldBitsLen; i++) {
        var nextInt = newBits[i];
        currentInt |= (nextInt << (32 - leftOffset)).toSigned(32);
        newBits[i - 1] = currentInt.toInt();
        currentInt = nextInt >>> leftOffset;
      }
      newBits[oldBitsLen - 1] = currentInt.toInt();
    }
    _bits = newBits;
  }

  static Int32List _makeArray(int size) {
    return Int32List((size + 31) ~/ 32);
  }

  @override
  operator ==(Object other) {
    if (other is! BitArray) {
      return false;
    }
    return _size == other._size && Utils.arrayEquals(_bits, other._bits);
  }

  @override
  int get hashCode {
    return 31 * _size + Utils.arrayHashCode(_bits);
  }

  @override
  String toString() {
    StringBuffer result = StringBuffer();
    for (int i = 0; i < _size; i++) {
      if ((i & 0x07) == 0) {
        result.write(' ');
      }
      result.write(get(i) ? 'X' : '.');
    }
    return result.toString();
  }

  BitArray clone() {
    return BitArray.test(Int32List.fromList(_bits.toList()), _size);
  }
}
