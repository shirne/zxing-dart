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

    for (double start_h = rect.top.toDouble();
        start_h < rect.bottom;
        start_h += step) {
      reductHeight++;
      for (double start_w = rect.left.toDouble();
          start_w < rect.right;
          start_w += step) {
        int index = (start_h.toInt()) * width + start_w.toInt();
        emptyByte[areaSize] = newByte[index];
        areaSize++;
      }
    }
    reductWidth = areaSize ~/ reductHeight;
    areaSize = 0;
    for (int start_h = rect.top; start_h < rect.bottom; start_h++) {
      for (int start_w = rect.left; start_w < rect.right; start_w++) {
        int index = start_h * width + start_w;
        int lef_w = (rect.width - reductWidth) ~/ 2 + rect.left;
        int rig_w = lef_w + reductWidth;
        int top_h = (rect.height - reductHeight) ~/ 2 + rect.top;
        int bot_h = top_h + reductHeight;

        if (start_h >= top_h &&
            start_h < bot_h &&
            start_w >= lef_w &&
            start_w < rig_w) {
          newByte[index] = emptyByte[areaSize++];
        } else
          newByte[index] = 255;
      }
    }
    return grayScaleDispatch.dispatch(newByte, width, height, rect);
  }
}
