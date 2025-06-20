import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/grayscale.dart';
import 'package:zxing_lib/zxing.dart';

import '../common/logger.dart';

class YuvTextCase {}

void main() {
  final Logger logger = Logger.getLogger(YuvTextCase);
  Future<void> decodeFile(File file) async {
    final bytes = file.readAsBytesSync();
    final data = jsonDecode(utf8.decode(bytes));

    final yuvData = data['yuv420Planes'];
    final plane = yuvData[0];
    final width = plane['bytesPerRow'] as int;
    final height = plane['bytes'].length ~/ width as int;

    final reader = MultiFormatReader();

    var byteData =
        Uint8List.fromList(plane['bytes'].map<int>((e) => e as int).toList());

    final dispacter = CropBackground(tolerance: 0.2, cropIn: 6);
    byteData = dispacter.dispatch(byteData, width, height);
    final rect = dispacter.cropRect;
    logger.info('Cropped: $rect ${rect?.width},${rect?.height} ');
    final luminance = PlanarYUVLuminanceSource(
      byteData,
      rect?.width ?? width,
      rect?.height ?? height,
    );

    var bmp = BinaryBitmap(HybridBinarizer(luminance));

    // File(file.path.replaceFirst('.json', '-croped-rotated.txt'))
    //    .writeAsStringSync(luminance.rotateCounterClockwise().toString());

    final metadata =
        File(file.path.replaceFirst('.json', '.txt')).readAsStringSync();

    try {
      final result = reader.decode(
        bmp,
        DecodeHint(
          tryHarder: true,
          //pureBarcode: true,
          possibleFormats: [BarcodeFormat.qrCode],
        ),
      );

      expect(result.text, metadata);
    } catch (err) {
      logger.info('decode faild: $err');
    }
    bmp = bmp.rotateCounterClockwise();
    try {
      final result = reader.decode(
        bmp,
        DecodeHint(
          tryHarder: true,
          //pureBarcode: true,
          possibleFormats: [BarcodeFormat.qrCode],
        ),
      );

      expect(result.text, metadata);
    } catch (err) {
      logger.info('decode faild(90): $err');
    }

    bmp = bmp.rotateCounterClockwise();
    try {
      final result = reader.decode(
        bmp,
        DecodeHint(
          tryHarder: true,
          //pureBarcode: true,
          possibleFormats: [BarcodeFormat.qrCode],
        ),
      );

      expect(result.text, metadata);
    } catch (err) {
      logger.info('decode faild(180): $err');
    }

    bmp = bmp.rotateCounterClockwise();
    try {
      final result = reader.decode(
        bmp,
        DecodeHint(
          tryHarder: true,
          //pureBarcode: true,
          possibleFormats: [BarcodeFormat.qrCode],
        ),
      );

      expect(result.text, metadata);
    } catch (err) {
      logger.info('decode faild(270): $err');
    }
  }

  test('yuv-test', () async {
    final baseDir = 'test/resources/blackbox/yuv';
    final files = Directory(baseDir).listSync();
    for (var file in files) {
      if (file.path.endsWith('.json')) {
        await decodeFile(file as File);
      }
    }
  });
}
