import 'dart:math' as math;
import 'dart:typed_data';

import 'dispatch.dart';

class OverBrightScale extends Dispatch {
  const OverBrightScale();
  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    final random = math.Random();
    final rand = (random.nextDouble() * 10) + 2;
    for (int i = 0; i < width * height; i++) {
      data[i] = (255 * math.pow((data[i] & 0xff) / 255, rand)).toInt();
    }
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    final newByte = Uint8List.fromList(data);
    final random = math.Random();
    final rand = (random.nextDouble() * 10) + 2;
    for (int startH = rect.top; startH < rect.bottom; startH++) {
      for (int startW = rect.left; startW < rect.right; startW++) {
        final index = startH * width + startW;
        newByte[index] =
            (255 * math.pow((newByte[index] & 0xff) / 255, rand)).toInt();
      }
    }
    return newByte;
  }
}
