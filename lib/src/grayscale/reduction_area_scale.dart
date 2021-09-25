import 'dart:math' as math;
import 'dart:typed_data';

import 'dispatch.dart';
import 'grayscale_dispatch.dart';

class ReductionAreaScale extends Dispatch {
  final GrayscaleDispatch grayScaleDispatch;
  const ReductionAreaScale(this.grayScaleDispatch);
  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    Uint8List newByte = Uint8List.fromList(data);
    Uint8List emptyByte = Uint8List(rect.width * rect.height);
    final random = math.Random();
    int areaSize = 0;
    double step = random.nextDouble() * 2 + 1;

    int reductWidth, reductHeight = 0;

    for (double startH = rect.top.toDouble();
        startH < rect.bottom;
        startH += step) {
      reductHeight++;
      for (double startW = rect.left.toDouble();
          startW < rect.right;
          startW += step) {
        int index = (startH.toInt()) * width + startW.toInt();
        emptyByte[areaSize] = newByte[index];
        areaSize++;
      }
    }
    reductWidth = areaSize ~/ reductHeight;
    areaSize = 0;
    for (int startH = rect.top; startH < rect.bottom; startH++) {
      for (int startW = rect.left; startW < rect.right; startW++) {
        int index = startH * width + startW;
        int lefW = (rect.width - reductWidth) ~/ 2 + rect.left;
        int rigW = lefW + reductWidth;
        int topH = (rect.height - reductHeight) ~/ 2 + rect.top;
        int botH = topH + reductHeight;

        if (startH >= topH &&
            startH < botH &&
            startW >= lefW &&
            startW < rigW) {
          newByte[index] = emptyByte[areaSize++];
        } else {
          newByte[index] = 255;
        }
      }
    }
    return grayScaleDispatch.dispatch(newByte, width, height, rect);
  }
}
