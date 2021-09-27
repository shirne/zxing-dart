import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:zxing_lib/common.dart';

void main() {
  /// zxing 以前的实现
  int reverse(int x) {
    x = ((x >> 1) & 0x55555555) | ((x & 0x55555555) << 1);
    x = ((x >> 2) & 0x33333333) | ((x & 0x33333333) << 2);
    x = ((x >> 4) & 0x0f0f0f0f) | ((x & 0x0f0f0f0f) << 4);
    x = ((x >> 8) & 0x00ff00ff) | ((x & 0x00ff00ff) << 8);
    x = ((x >> 16) & 0x0000ffff) | ((x & 0x0000ffff) << 16);
    return x;
  }

  /// java.lang.Integer.inverse 实现
  int reverse2(int i) {
    i = ((i & 0x55555555) << 1).toUnsigned(32) | (i >>> 1) & 0x55555555;
    i = ((i & 0x33333333) << 2).toUnsigned(32) | (i >>> 2) & 0x33333333;
    i = ((i & 0x0f0f0f0f) << 4).toUnsigned(32) | (i >>> 4) & 0x0f0f0f0f;

    return (i << 24).toUnsigned(32) |
        ((i & 0xff00) << 8).toUnsigned(32) |
        ((i >>> 8) & 0xff00) |
        (i >>> 24);
  }

  /// fixnum的Int32运算
  /*int reverseInt32(int i) {
    Int32 x = Int32(i);
    x = ((x >> 1) & 0x55555555) | ((x & 0x55555555) << 1);
    x = ((x >> 2) & 0x33333333) | ((x & 0x33333333) << 2);
    x = ((x >> 4) & 0x0f0f0f0f) | ((x & 0x0f0f0f0f) << 4);
    x = ((x >> 8) & 0x00ff00ff) | ((x & 0x00ff00ff) << 8);
    x = ((x >> 16) & 0x0000ffff) | ((x & 0x0000ffff) << 16);
    return x.toInt();
  }*/

  test('bitOr', () {
    for (List<int> pair in [
      [0, 1],
      [-5, 9],
      [-9, -99],
      [126, 999],
      [0xff19f32, 99],
      [-245888934, -88],
    ]) {
      expect((Int32(pair[0]) ^ Int32(pair[1])).toInt(), pair[0] ^ pair[1]);
    }
  });

  test('testBit', () {
    for (int a in [
      5,
      99,
      654512,
      545482263,
      4294967296,
    ]) {
      int reverseFun = Utils.reverseSign32(a);
      int reverse2Fun = reverse2(a);
      //int reverseI32 = reverseInt32(a);
      expect(reverseFun, reverse2Fun,
          reason:
              '$a reverted error\n${reverseFun.toRadixString(2)}\n${reverse2Fun.toRadixString(2)}');
    }
  });

  test('testInt32List', () {
    Uint32List lists = Uint32List.fromList([
      8,
      6,
      22,
      6523,
      654123,
      545482263,
      2147483647,
      4294967297.toUnsigned(32)
    ]);
    print(lists.toList());
    print(lists.map<String>((item) => item.toRadixString(2)).toList());
    for (int i = 0; i < lists.length; i++) {
      lists[i] = (lists[i] * 2).toUnsigned(32);
    }
    print(lists.toList());
    print(lists.map<String>((item) => item.toRadixString(2)).toList());
  });
}
