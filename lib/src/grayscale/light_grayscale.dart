import 'dart:math' as math;
import 'dart:typed_data';

import 'dispatch.dart';

class LightGrayscale extends Dispatch {
  const LightGrayscale();
  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    final random = math.Random();
    int rand = random.nextInt(5) + 2;
    for (int i = 0; i < width * height; i++) {
      data[i] = (data[i] * rand);
    }
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    Uint8List newByte = Uint8List.fromList(data);
    final random = math.Random();
    int rand = random.nextInt(4) + 3;
    for (int start_h = rect.top; start_h < rect.bottom; start_h++) {
      for (int start_w = rect.left; start_w < rect.right; start_w++) {
        int index = start_h * width + start_w;
        newByte[index] = (newByte[index] * rand);
      }
    }
    return newByte;
  }
}
