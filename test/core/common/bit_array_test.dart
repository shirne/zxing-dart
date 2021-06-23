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

import 'dart:math';
import 'dart:typed_data';

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';


void main() {


  bool bitSet(Int32List bits, int i) {
    return (bits[i ~/ 32] & (1 << (i & 0x1F))) != 0;
  }

  bool arraysAreEqual(List<int> left, List<int> right, int size) {
    for (int i = 0; i < size; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }

  Int32List reverseOriginal(Int32List oldBits, int size) {
    Int32List newBits = Int32List(oldBits.length);
    for (int i = 0; i < size; i++) {
      if (bitSet(oldBits, size - i - 1)) {
        newBits[i ~/ 32] = (newBits[i ~/ 32] | 1 << (i & 0x1F)).toSigned(32);
      }
    }
    return newBits;
  }


  test('testGetSet', () {
    BitArray array = new BitArray(33);
    for (int i = 0; i < 33; i++) {
      assert(!array[i]);
      array.set(i);
      assert(array[i]);
    }
  });

  test('testGetNextSet1', () {
    BitArray array = new BitArray(32);
    for (int i = 0; i < array.size; i++) {
      expect(32, array.getNextSet(i), reason: i.toString());
    }
    array = new BitArray(33);
    for (int i = 0; i < array.size; i++) {
      expect(33, array.getNextSet(i), reason: i.toString());
    }
  });

  test('testGetNextSet2', () {
    BitArray array = new BitArray(33);    
    array.set(31);
    for (int i = 0; i < array.size; i++) {
      expect( i <= 31 ? 31 : 33, array.getNextSet(i), reason: i.toString());
    }
    array = new BitArray(33);
    array.set(32);
    for (int i = 0; i < array.size; i++) {
      expect( 32, array.getNextSet(i), reason: i.toString());
    }
  });

  test('testGetNextSet3', () {
    BitArray array = new BitArray(63);    
    array.set(31);
    array.set(32);
    for (int i = 0; i < array.size; i++) {
      int expected;
      if (i <= 31) {
        expected = 31;
      } else if (i == 32) {
        expected = 32;
      } else {
        expected = 63;
      }
      expect(expected, array.getNextSet(i), reason: i.toString());
    }
  });

  test('testGetNextSet4', () {
    BitArray array = new BitArray(63);
    array.set(33);
    array.set(40);
    for (int i = 0; i < array.size; i++) {
      int expected;
      if (i <= 33) {
        expected = 33;
      } else if (i <= 40) {
        expected = 40;
      } else {
        expected = 63;
      }
      expect(expected, array.getNextSet(i), reason:i.toString());
    }
  });

  test('testGetNextSet5', () {
    Random r = new Random(0xDEADBEEF);
    for (int i = 0; i < 10; i++) {
      BitArray array = new BitArray(1 + r.nextInt(100));
      int numSet = r.nextInt(20);
      for (int j = 0; j < numSet; j++) {
        array.set(r.nextInt(array.size));
      }
      int numQueries = r.nextInt(20);
      for (int j = 0; j < numQueries; j++) {
        int query = r.nextInt(array.size);
        int expected = query;
        while (expected < array.size && !array[expected]) {
          expected++;
        }
        int actual = array.getNextSet(query);
        expect(expected, actual);
      }
    }
  });


  test('testSetBulk', () {
    BitArray array = new BitArray(64);
    array.setBulk(32, 0xFFFF0000);
    for (int i = 0; i < 48; i++) {
      assert(!array[i]);
    }
    for (int i = 48; i < 64; i++) {
      assert(array[i]);
    }
  });

  test('testSetRange', () {
    BitArray array = new BitArray(64);
    array.setRange(28, 36);
    assert(!array[27]);
    for (int i = 28; i < 36; i++) {
      assert(array[i]);
    }
    assert(!array[36]);
  });

  test('testClear', () {
    BitArray array = new BitArray(32);
    for (int i = 0; i < 32; i++) {
      array.set(i);
    }
    array.clear();
    for (int i = 0; i < 32; i++) {
      assert(!array[i]);
    }
  });

  test('testFlip', () {
    BitArray array = new BitArray(32);
    assert(!array[5]);
    array.flip(5);
    assert(array[5]);
    array.flip(5);
    assert(!array[5]);
  });

  test('testGetArray', () {
    BitArray array = new BitArray(64);
    array.set(0);
    array.set(63);
    List<int> ints = array.getBitArray();
    expect(1, ints[0]);
    expect(MathUtils.MIN_VALUE, ints[1]);
  });

  test('testIsRange', () {
    BitArray array = new BitArray(64);
    assert(array.isRange(0, 64, false));
    assert(!array.isRange(0, 64, true));
    array.set(32);
    assert(array.isRange(32, 33, true));
    array.set(31);
    assert(array.isRange(31, 33, true));
    array.set(34);
    assert(!array.isRange(31, 35, true));
    for (int i = 0; i < 31; i++) {
      array.set(i);
    }
    assert(array.isRange(0, 33, true));
    for (int i = 33; i < 64; i++) {
      array.set(i);
    }
    assert(array.isRange(0, 64, true));
    assert(!array.isRange(0, 64, false));
  });

  test('reverseAlgorithmTest', () {
    Int32List oldBits = Int32List.fromList([128, 256, 512, 6453324, 50934953]);
    for (int size = 1; size < 160; size++) {
      Int32List newBitsOriginal = reverseOriginal(oldBits, size);
      BitArray newBitArray = BitArray.test(Int32List.fromList(oldBits), size);
      newBitArray.reverse();
      Int32List newBitsNew = newBitArray.getBitArray();
      assert(arraysAreEqual(newBitsOriginal, newBitsNew, size ~/ 32 + 1));
    }
  });

  test('testClone', () {
    BitArray array = BitArray(32);
    array.clone().set(0);
    assert(!array[0]);
  });

  test('testEquals', () {
    BitArray a = new BitArray(32);
    BitArray b = new BitArray(32);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    assert(a != new BitArray(31));
    a.set(16);
    assert(a != b);
    assert(a.hashCode != b.hashCode);
    b.set(16);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
