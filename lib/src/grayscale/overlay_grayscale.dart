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
    Uint8List newByte = Uint8List.fromList(data);
    Uint8List tranByte = translationScale.dispatch(data, width, height, rect);

    int stepX = 2;
    int stepY = 2;

    for (int start_h = rect.top; start_h < rect.bottom; start_h += stepY) {
      for (int start_w = rect.left; start_w < rect.right; start_w += stepX) {
        int oriAvage = 0;
        int tranAvage = 0;
        int min = 256;
        for (int i = start_h; i < start_h + stepY; i++) {
          for (int j = start_w; j < start_w + stepX; j++) {
            oriAvage += (newByte[i * width + j] & 0xff);
            tranAvage += (tranByte[i * width + j] & 0xff);
            if ((tranByte[i * width + j] & 0xff) < min) {
              min = tranByte[i * width + j] & 0xff;
            }
          }
        }

        if (oriAvage <= tranAvage) {
          continue;
        }

        for (int i = start_h; i < start_h + stepY; i++) {
          //System.arraycopy(tranByte, i * width + start_w, newByte,
          //    i * width + start_w, start_w + stepX - start_w);
          List.copyRange(newByte, i * width + start_w, tranByte,
              i * width + start_w, start_w + stepX + i * width);
        }
      }
    }
    return newByte;
  }
}
