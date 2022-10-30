import 'dart:typed_data';

import 'dispatch.dart';

class RevGrayscale extends Dispatch {
  const RevGrayscale();
  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    for (int i = 0; i < width * height; i++) {
      data[i] = 255 - data[i];
    }
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    final newByte = Uint8List.fromList(data);
    for (int startH = rect.top; startH < rect.bottom; startH++) {
      for (int startW = rect.left; startW < rect.right; startW++) {
        final index = startH * width + startW;
        newByte[index] = 255 - newByte[index];
      }
    }
    return newByte;
  }
}
