import 'dart:typed_data';

import 'dispatch.dart';

class RevGrayscale extends Dispatch {
  const RevGrayscale();
  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    for (int i = 0; i < width * height; i++) {
      data[i] = (255 - data[i] & 0xff);
    }
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    Uint8List newByte = Uint8List.fromList(data);
    for (int start_h = rect.top; start_h < rect.bottom; start_h++) {
      for (int start_w = rect.left; start_w < rect.right; start_w++) {
        int index = start_h * width + start_w;
        newByte[index] = (255 - newByte[index] & 0xff);
      }
    }
    return newByte;
  }
}
