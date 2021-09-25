import 'dart:math' as math;
import 'dart:typed_data';

import 'dispatch.dart';

class InterruptGrayscale extends Dispatch {
  //结构元素步长
  static const stepX = 2;
  static const stepY = 2;

  const InterruptGrayscale();
  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    final random = math.Random();
    int offset = random.nextInt(3) + 1;
    Rect rect = Rect(0, 0, width, height);
    for (int i = 0; i < offset; i++) {
      openOp(data, width, rect, i);
      closeOp(data, width, rect, i);
    }
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    Uint8List newByte = Uint8List.fromList(data);
    final random = math.Random();
    int offset = random.nextInt(5) + 1;
    for (int i = 0; i < offset; i++) {
      openOp(newByte, width, rect, i);
      closeOp(newByte, width, rect, i);
    }
    return newByte;
  }

  void openOp(Uint8List newByte, int width, Rect rect, int offset) {
    for (int stepH = rect.top + offset;
        stepH + stepY < rect.bottom;
        stepH += stepY) {
      for (int stepW = rect.left + offset;
          stepW + stepX < rect.right;
          stepW += stepX) {
        int count = 0;
        int avage = 0;
        int min = 256;
        for (int y_ = stepH; y_ < stepH + stepY; y_++) {
          for (int x_ = stepW; x_ < stepW + stepX; x_++) {
            if ((newByte[y_ * width + x_] & 0xff) < 150) count++;
            avage += newByte[y_ * width + x_] & 0xff;
            if ((newByte[y_ * width + x_] & 0xff) < min) {
              min = newByte[y_ * width + x_] & 0xff;
            }
          }
        }
        if (count == 0) {
          continue;
        }
        avage ~/= stepY * stepX;
        for (int y_ = stepH; y_ < stepH + stepY; y_++) {
          for (int x_ = stepW; x_ < stepW + stepX; x_++) {
            newByte[y_ * width + x_] = (min ~/ 5 * 4);
          }
        }
      }
    }
  }

  void closeOp(Uint8List newByte, int width, Rect rect, int offset) {
    for (int stepH = rect.top + offset;
        stepH + stepY < rect.bottom;
        stepH += stepY) {
      for (int stepW = rect.left + offset;
          stepW + stepX < rect.right;
          stepW += stepX) {
        int count = 0;
        int max = 0;
        for (int y_ = stepH; y_ < stepH + stepY; y_++) {
          for (int x_ = stepW; x_ < stepW + stepX; x_++) {
            if ((newByte[y_ * width + x_] & 0xff) < 150) count++;
            if ((newByte[y_ * width + x_] & 0xff) > max) {
              max = newByte[y_ * width + x_] & 0xff;
            }
          }
        }
        if (count > stepX * stepY / 2) {
          continue;
        }
        for (int y_ = stepH; y_ < stepH + stepY; y_++) {
          for (int x_ = stepW; x_ < stepW + stepX; x_++) {
            newByte[y_ * width + x_] = max;
          }
        }
      }
    }
  }
}
