import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/painting.dart';

abstract class QRCodeStyle {
  static const normal = NormalQRCodeStyle();
  static const rRect = RRectQRCodeStyle();
  static const rRectOut = RRectOutQRCodeStyle();
  static const dot = DotQRCodeStyle();
  static const dotOut = DotOutQRCodeStyle();

  static const values = <QRCodeStyle>[normal, rRect, rRectOut, dot, dotOut];

  final String type;
  final String name;

  const QRCodeStyle(this.type, this.name);

  Future<BufferImage?> blackBlock(int size,
      {Color blackColor = const Color(0xff000000),
      Color whiteColor = const Color(0xffffffff)});

  Future<BufferImage?> whiteBlock(int size,
          {Color blackColor = const Color(0xff000000),
          Color whiteColor = const Color(0xffffffff)}) async =>
      null;

  @override
  String toString() {
    return name;
  }
}

class NormalQRCodeStyle extends QRCodeStyle {
  const NormalQRCodeStyle() : super('normal', 'Normal');

  @override
  Future<BufferImage?> blackBlock(int size,
      {Color blackColor = const Color(0xff000000),
      Color whiteColor = const Color(0xffffffff)}) async {
    BufferImage image = BufferImage(size, size);
    image.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), blackColor);

    return image;
  }
}

class RRectQRCodeStyle extends QRCodeStyle {
  const RRectQRCodeStyle() : super('rRect', 'RRect');

  @override
  Future<BufferImage?> blackBlock(int size,
      {Color blackColor = const Color(0xff000000),
      Color whiteColor = const Color(0xffffffff)}) async {
    BufferImage image = BufferImage(size, size);
    await image.drawPath(
      Path()
        ..addRRect(RRect.fromLTRBR(0, 0, size.toDouble(), size.toDouble(),
            Radius.circular(size * 0.2))),
      blackColor,
    );

    return image;
  }
}

class RRectOutQRCodeStyle extends QRCodeStyle {
  const RRectOutQRCodeStyle() : super('rRectOut', 'RRectOut');

  @override
  Future<BufferImage?> blackBlock(int size,
      {Color blackColor = const Color(0xff000000),
      Color whiteColor = const Color(0xffffffff)}) async {
    BufferImage image = BufferImage(size, size);
    image.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), blackColor);

    return image;
  }

  @override
  Future<BufferImage?> whiteBlock(int size,
      {Color blackColor = const Color(0xff000000),
      Color whiteColor = const Color(0xffffffff)}) async {
    BufferImage image = BufferImage(size, size);
    image.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), blackColor);
    await image.drawPath(
      Path()
        ..addRRect(RRect.fromLTRBR(0, 0, size.toDouble(), size.toDouble(),
            Radius.circular(size * 0.2))),
      whiteColor,
    );

    return image;
  }
}

class DotQRCodeStyle extends QRCodeStyle {
  const DotQRCodeStyle() : super('dot', 'Dot');

  @override
  Future<BufferImage?> blackBlock(int size,
      {Color blackColor = const Color(0xff000000),
      Color whiteColor = const Color(0xffffffff)}) async {
    BufferImage image = BufferImage(size, size);
    await image.drawPath(
      Path()
        ..addRRect(RRect.fromLTRBR(
            0,
            0,
            size.toDouble(),
            size.toDouble(),
            Radius.circular(
              size * .5,
            ))),
      blackColor,
    );

    return image;
  }
}

class DotOutQRCodeStyle extends QRCodeStyle {
  const DotOutQRCodeStyle() : super('dotOut', 'DotOut');

  @override
  Future<BufferImage?> blackBlock(int size,
      {Color blackColor = const Color(0xff000000),
      Color whiteColor = const Color(0xffffffff)}) async {
    BufferImage image = BufferImage(size, size);
    image.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), blackColor);

    return image;
  }

  @override
  Future<BufferImage?> whiteBlock(int size,
      {Color blackColor = const Color(0xff000000),
      Color whiteColor = const Color(0xffffffff)}) async {
    BufferImage image = BufferImage(size, size);
    image.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), blackColor);
    await image.drawPath(
      Path()
        ..addRRect(RRect.fromLTRBR(
            0,
            0,
            size.toDouble(),
            size.toDouble(),
            Radius.circular(
              size * .5,
            ))),
      whiteColor,
    );

    return image;
  }
}
