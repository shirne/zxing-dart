import 'dart:isolate';

import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/foundation.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

import 'image_source.dart';

void binarizerImage(
  Uint8List data,
  int width,
  int height,
  void Function(GrayedData) onData,
  void Function() onEnd,
) {
  final port = ReceivePort();
  final arg = ImageData(port.sendPort, data, width, height);

  port.listen(
    (message) {
      if (message is GrayedData) {
        onData(message);
      } else {
        print(message);
        port.close();
      }
    },
    onDone: () {
      port.close();
      onEnd();
    },
    onError: (e) {
      print(e);
    },
  );

  Isolate.spawn(_binarizerImage, arg);
}

class ImageData {
  ImageData(this.port, this.data, this.width, this.height);

  final Uint8List data;
  final int width;
  final int height;
  final SendPort port;
}

class GrayedData {
  GrayedData(this.type, this.data);

  final Uint8List data;
  final String type;
}

Future<void> _binarizerImage(ImageData data) async {
  final image =
      BufferImage.raw(data.data, width: data.width, height: data.height);

  final grayImage = image.toGray();
  data.port.send(GrayedData('grayImage', grayImage.buffer));
  final deNoiseImage = grayImage.copy()
    ..deNoise()
    ..binaryzation()
    ..deNoise();
  data.port.send(GrayedData('deNoiseImage', deNoiseImage.buffer));
  final binaryImage = bin2Image(
    GlobalHistogramBinarizer(ImageLuminanceSource(image.copy())),
  );
  data.port.send(GrayedData('binaryImage', binaryImage));
  final hybridBinaryImage =
      bin2Image(HybridBinarizer(ImageLuminanceSource(image.copy())));
  data.port.send(GrayedData('hybridBinaryImage', hybridBinaryImage));
  final inverseImage = bin2Image(
    GlobalHistogramBinarizer(
      ImageLuminanceSource(image.copy()..inverse()),
    ),
  );
  data.port.send(GrayedData('inverseImage', inverseImage));

  data.port.send('close');
}

Uint8List bin2Image(Binarizer binarizer) {
  BitMatrix matrix = binarizer.blackMatrix;
  GrayImage image = GrayImage(matrix.width, matrix.height);
  for (int x = 0; x < image.width; x++) {
    for (int y = 0; y < image.height; y++) {
      image.setChannel(x, y, matrix.get(x, y) ? 0 : 255);
    }
  }
  return image.buffer;
}
