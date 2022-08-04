import 'dart:math' as math;
import 'dart:typed_data';

import 'dispatch.dart';

class LightGrayscale extends Dispatch {
  const LightGrayscale();
  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    final random = math.Random();
    final rand = random.nextInt(5) + 2;
    for (int i = 0; i < width * height; i++) {
      data[i] = (data[i] * rand);
    }
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    final newByte = Uint8List.fromList(data);
    final random = math.Random();
    final rand = random.nextInt(4) + 3;
    for (int startH = rect.top; startH < rect.bottom; startH++) {
      for (int startW = rect.left; startW < rect.right; startW++) {
        final index = startH * width + startW;
        newByte[index] = (newByte[index] * rand);
      }
    }
    return newByte;
  }
}
