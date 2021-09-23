import 'dart:math' as math;
import 'dart:typed_data';

import 'dispatch.dart';

class OverBrightScale extends Dispatch {
  const OverBrightScale();
  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    final random = math.Random();
    double rand = (random.nextDouble() * 10) + 2;
    for (int i = 0; i < width * height; i++) {
      data[i] = (255 * math.pow((data[i] & 0xff) / 255, rand)).toInt();
    }
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    Uint8List newByte = Uint8List.fromList(data);
    final random = math.Random();
    double rand = (random.nextDouble() * 10) + 2;
    for (int start_h = rect.top; start_h < rect.bottom; start_h++) {
      for (int start_w = rect.left; start_w < rect.right; start_w++) {
        int index = start_h * width + start_w;
        newByte[index] =
            (255 * math.pow((newByte[index] & 0xff) / 255, rand)).toInt();
      }
    }
    return newByte;
  }
}
