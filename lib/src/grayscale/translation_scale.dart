import 'dart:math' as math;
import 'dart:typed_data';

import 'dispatch.dart';

class TranslationScale extends Dispatch {
  final int maxOffsetXRange;
  final int maxOffsetYRange;

  const TranslationScale(this.maxOffsetXRange, this.maxOffsetYRange);

  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    Uint8List newByte = Uint8List.fromList(data);

    int offsetX, offsetY;
    final random = math.Random();
    if (random.nextDouble() > 0.5) {
      offsetX = (random.nextDouble() * -2 * maxOffsetXRange + maxOffsetXRange)
          .toInt();
      offsetY = 0;
    } else {
      offsetX = 0;
      offsetY = (random.nextDouble() * -2 * maxOffsetYRange + maxOffsetYRange)
          .toInt();
    }

    for (int i = rect.top; i < rect.bottom; i++) {
      for (int j = rect.left; j < rect.right; j++) {
        int offset;
        int current;

        //从右下角开始copy
        if (offsetX >= 0 && offsetY >= 0) {
          offset = (rect.bottom - i + rect.top - offsetY) * width +
              rect.right +
              rect.left -
              j -
              offsetX;
          current =
              (rect.bottom + rect.top - i) * width + rect.right + rect.left - j;

          if ((rect.bottom - i) < offsetY || (rect.right - j) < offsetX) {
            newByte[current] = 255;
          } else
            newByte[current] = newByte[offset];
        }

        //从右上角开始copy
        if (offsetX >= 0 && offsetY <= 0) {
          offset = (i - offsetY) * width + rect.right + rect.left - j - offsetX;
          current = i * width + rect.right + rect.left - j;

          if (i > (rect.bottom + offsetY) || (rect.right - j) < offsetX)
            newByte[current] = 255;
          else
            newByte[current] = newByte[offset];
        }

        //从左下角开始copy
        if (offsetX <= 0 && offsetY >= 0) {
          offset = (rect.bottom + rect.top - i - offsetY) * width + j - offsetX;
          current = (rect.bottom + rect.top - i) * width + j;

          if ((rect.bottom - i) < offsetY || j > (rect.right + offsetX))
            newByte[current] = 255;
          else
            newByte[current] = newByte[offset];
        }

        //从左上角开始copy
        if (offsetX <= 0 && offsetY <= 0) {
          offset = (i - offsetY) * width + j - offsetX;
          current = i * width + j;

          if (i > (rect.bottom + offsetY) || j > (rect.right + offsetX))
            newByte[current] = 255;
          else
            newByte[current] = newByte[offset];
        }
      }
    }
    return newByte;
  }
}
