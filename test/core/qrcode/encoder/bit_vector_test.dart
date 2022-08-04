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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';

void main() {
  int getUnsignedInt(BitArray v) {
    int result = 0;
    final offset = 0;
    for (int i = 0; i < 32; i++) {
      if (v[offset + i]) {
        result |= 1 << (31 - i);
      }
    }
    return result;
  }

  test('testAppendBit', () {
    final v = BitArray();
    expect(0, v.sizeInBytes);
    // 1
    v.appendBit(true);
    expect(1, v.size);
    expect(0x80000000, getUnsignedInt(v));
    // 10
    v.appendBit(false);
    expect(2, v.size);
    expect(0x80000000, getUnsignedInt(v));
    // 101
    v.appendBit(true);
    expect(3, v.size);
    expect(0xa0000000, getUnsignedInt(v));
    // 1010
    v.appendBit(false);
    expect(4, v.size);
    expect(0xa0000000, getUnsignedInt(v));
    // 10101
    v.appendBit(true);
    expect(5, v.size);
    expect(0xa8000000, getUnsignedInt(v));
    // 101010
    v.appendBit(false);
    expect(6, v.size);
    expect(0xa8000000, getUnsignedInt(v));
    // 1010101
    v.appendBit(true);
    expect(7, v.size);
    expect(0xaa000000, getUnsignedInt(v));
    // 10101010
    v.appendBit(false);
    expect(8, v.size);
    expect(0xaa000000, getUnsignedInt(v));
    // 10101010 1
    v.appendBit(true);
    expect(9, v.size);
    expect(0xaa800000, getUnsignedInt(v));
    // 10101010 10
    v.appendBit(false);
    expect(10, v.size);
    expect(0xaa800000, getUnsignedInt(v));
  });

  test('testAppendBits', () {
    BitArray v = BitArray();
    v.appendBits(0x1, 1);
    expect(1, v.size);
    expect(0x80000000, getUnsignedInt(v));
    v = BitArray();
    v.appendBits(0xff, 8);
    expect(8, v.size);
    expect(0xff000000, getUnsignedInt(v));
    v = BitArray();
    v.appendBits(0xff7, 12);
    expect(12, v.size);
    expect(0xff700000, getUnsignedInt(v));
  });

  test('testNumBytes', () {
    final v = BitArray();
    expect(0, v.sizeInBytes);
    v.appendBit(false);
    // 1 bit was added in the vector, so 1 byte should be consumed.
    expect(1, v.sizeInBytes);
    v.appendBits(0, 7);
    expect(1, v.sizeInBytes);
    v.appendBits(0, 8);
    expect(2, v.sizeInBytes);
    v.appendBits(0, 1);
    // We now have 17 bits, so 3 bytes should be consumed.
    expect(3, v.sizeInBytes);
  });

  test('testAppendBitVector', () {
    final v1 = BitArray();
    v1.appendBits(0xbe, 8);
    final v2 = BitArray();
    v2.appendBits(0xef, 8);
    v1.appendBitArray(v2);
    // beef = 1011 1110 1110 1111
    expect(' X.XXXXX. XXX.XXXX', v1.toString());
  });

  test('testXOR', () {
    final v1 = BitArray();
    v1.appendBits(0x5555aaaa, 32);
    final v2 = BitArray();
    v2.appendBits(0xaaaa5555, 32);
    v1.xor(v2);
    expect(0xffffffff, getUnsignedInt(v1));
  });

  test('testXOR2', () {
    final v1 = BitArray();
    v1.appendBits(0x2a, 7); // 010 1010
    final v2 = BitArray();
    v2.appendBits(0x55, 7); // 101 0101
    v1.xor(v2);
    expect(0xfe000000, getUnsignedInt(v1)); // 1111 1110
  });

  test('testAt', () {
    final v = BitArray();
    v.appendBits(0xdead, 16); // 1101 1110 1010 1101
    assert(v[0]);
    assert(v[1]);
    assert(!v[2]);
    assert(v[3]);

    assert(v[4]);
    assert(v[5]);
    assert(v[6]);
    assert(!v[7]);

    assert(v[8]);
    assert(!v[9]);
    assert(v[10]);
    assert(!v[11]);

    assert(v[12]);
    assert(v[13]);
    assert(!v[14]);
    assert(v[15]);
  });

  test('testToString', () {
    final v = BitArray();
    v.appendBits(0xdead, 16); // 1101 1110 1010 1101
    expect(' XX.XXXX. X.X.XX.X', v.toString());
  });
}
