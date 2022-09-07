import 'dart:typed_data';

import 'dispatch.dart';
import 'translation_scale.dart';

class OverlayGrayscale extends Dispatch {
  static const translationScale = TranslationScale(10, 10);

  const OverlayGrayscale();

  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    final newByte = Uint8List.fromList(data);
    final tranByte = translationScale.dispatch(data, width, height, rect);

    final stepX = 2;
    final stepY = 2;

    for (int startH = rect.top; startH < rect.bottom; startH += stepY) {
      for (int startW = rect.left; startW < rect.right; startW += stepX) {
        int oriAverage = 0;
        int tranAverage = 0;
        int min = 256;
        for (int i = startH; i < startH + stepY; i++) {
          for (int j = startW; j < startW + stepX; j++) {
            oriAverage += (newByte[i * width + j] & 0xff);
            tranAverage += (tranByte[i * width + j] & 0xff);
            if ((tranByte[i * width + j] & 0xff) < min) {
              min = tranByte[i * width + j] & 0xff;
            }
          }
        }

        if (oriAverage <= tranAverage) {
          continue;
        }

        for (int i = startH; i < startH + stepY; i++) {
          //System.arraycopy(tranByte, i * width + start_w, newByte,
          //    i * width + start_w, start_w + stepX - start_w);
          List.copyRange(
            newByte,
            i * width + startW,
            tranByte,
            i * width + startW,
            startW + stepX + i * width,
          );
        }
      }
    }
    return newByte;
  }
}
