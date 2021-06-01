

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void assertListEquals(List<int> expected, int expectedFrom,
    Uint8List actual, int actualFrom, int length) {
  for (int i = 0; i < length; i++) {
    expect(actual[actualFrom + i], expected[expectedFrom + i]);
  }
}

void assertArrayEquals(List<dynamic>? a, List<dynamic>? b){
  if(a == null || b == null){
    assert(a == null && b == null);
  }
  assert(a.runtimeType == b.runtimeType);
  assert(a!.length == b!.length);

  for(int i = 0; i < a!.length; i++){
    if(a[i] is List){
      assertArrayEquals(a[i], b![i]);
    }else{
      assert(a[i] == b![i]);
    }
  }
}

void assertEqualOrNaN(double expected, double actual, [int eps = 1000]) {
  if (expected.isNaN) {
    assert(actual.isNaN);
  } else {
    expect((expected * pow(10, eps)).round(), (actual * pow(10, eps)).round());
  }
}