import 'dart:math';
import 'dart:typed_data';

import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxing_lib/common.dart';

void assertListEquals(List<int> expected, int expectedFrom, Uint8List actual,
    int actualFrom, int length) {
  for (int i = 0; i < length; i++) {
    expect(actual[actualFrom + i], expected[expectedFrom + i]);
  }
}

void assertArrayEquals(List<dynamic>? a, List<dynamic>? b) {
  if (a == null || b == null) {
    assert(a == null && b == null);
    return;
  }
  expect(a.runtimeType.toString().replaceAll('?', ''),
      b.runtimeType.toString().replaceAll('?', ''),
      reason: 'runtime not match');
  expect(a.length, b.length, reason: 'length not match \n $a \n $b');

  for (int i = 0; i < a.length; i++) {
    if (a[i] is List) {
      assertArrayEquals(a[i], b[i]);
    } else {
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
  expect(result.height, 1);
  StringBuilder builder = new StringBuilder();
  for (int i = 0; i < result.width; i++) {
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

/// 根据Bitmap的ARGB值生成YUV420SP数据。
/// @param inputWidth  image width
/// @param inputHeight image height
/// @param scaled      bmp
/// @return YUV420SP数组
Int8List getYUV420sp(AbstractImage image, int inputWidth, int inputHeight) {
  // 需要转换成偶数的像素点，否则编码YUV420的时候有可能导致分配的空间大小不够而溢出。
  int requiredWidth = inputWidth % 2 == 0 ? inputWidth : inputWidth + 1;
  int requiredHeight = inputHeight % 2 == 0 ? inputHeight : inputHeight + 1;
  int byteLength = requiredWidth * requiredHeight * 3 ~/ 2;
  Int8List yuvs = Int8List(byteLength);
  encodeYUV420SP(yuvs, image, inputWidth, inputHeight);

  return yuvs;
}

/// RGB转YUV420sp
void encodeYUV420SP(Int8List yuv420sp, AbstractImage image, int width, int height) {
  // 帧图片的像素大小
  final int frameSize = width * height;
  // ---YUV数据---
  int Y, U, V;
  // Y的index从0开始
  int yIndex = 0;
  // UV的index从frameSize开始
  int uvIndex = frameSize;
  // ---颜色数据---
  int R, G, B;

  // ---循环所有像素点，RGB转YUV---
  for (int j = 0; j < height; j++) {
    for (int i = 0; i < width; i++) {
      Color color = image.getColor(i, j);

      // well known RGB to YUV algorithm
      Y = ((66 * color.red + 129 * color.green + 25 * color.blue + 128) >> 8) + 16;
      U = ((-38 * color.red - 74 * color.green + 112 * color.blue + 128) >> 8) + 128;
      V = ((112 * color.red - 94 * color.green - 18 * color.blue + 128) >> 8) + 128;
      Y = max(0, min(Y, 255));
      U = max(0, min(U, 255));
      V = max(0, min(V, 255));
      // NV21 has a plane of Y and interleaved planes of VU each sampled by a factor of 2
      // meaning for every 4 Y pixels there are 1 V and 1 U. Note the sampling is every other
      // pixel AND every other scan line.
      // ---Y---
      yuv420sp[yIndex++] = Y;
      // ---UV---
      if ((j % 2 == 0) && (i % 2 == 0)) {
        yuv420sp[uvIndex++] = V;
        yuv420sp[uvIndex++] = U;
      }
    }
  }
}
