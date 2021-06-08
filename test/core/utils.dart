

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zxing_lib/common.dart';

void assertListEquals(List<int> expected, int expectedFrom,
    Uint8List actual, int actualFrom, int length) {
  for (int i = 0; i < length; i++) {
    expect(actual[actualFrom + i], expected[expectedFrom + i]);
  }
}

void assertArrayEquals(List<dynamic>? a, List<dynamic>? b){
  if(a == null || b == null){
    assert(a == null && b == null);
    return;
  }
  expect(a.runtimeType.toString().replaceAll('?', ''), b.runtimeType.toString().replaceAll('?', ''), reason:'runtime not match');
  expect(a.length, b.length, reason:'length not match \n $a \n $b');

  for(int i = 0; i < a.length; i++){
    if(a[i] is List){
      assertArrayEquals(a[i], b[i]);
    }else{
      expect(a[i], b[i], reason: "at $i");
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

String matrixToString(BitMatrix result) {
  expect(result.getHeight(), 1);
  StringBuilder builder = new StringBuilder();
  for (int i = 0; i < result.getWidth(); i++) {
    builder.write(result.get(i, 0) ? '1' : '0');
  }
  return builder.toString();
}

/// Convert a string of char codewords into a different string which lists each character
/// using its decimal value.
///
/// @param codewords the codewords
/// @return the visualized codewords
String visualize(String codewords) {
  return codewords.codeUnits.join(' ');
}

final Pattern _space = " ";
String unVisualize(String visualized) {
  StringBuffer sb = new StringBuffer();
  for (String token in visualized.split(_space)) {
    sb.writeCharCode(int.parse(token));
  }
  return sb.toString();
}