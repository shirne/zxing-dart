import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/cupertino.dart' hide CupertinoListTile;
import 'package:flutter/material.dart';
import 'package:zxing_lib/client.dart';
import 'package:zxing_lib/qrcode.dart';

import '../models/qrcode_style.dart';
import '../models/result_generator.dart';
import '../widgets/cupertino_list_tile.dart';
import '../widgets/list_tile_group.dart';
import '../widgets/type_picker.dart';
import 'geo_form.dart';
import 'sms_form.dart';
import 'text_form.dart';
import 'vcard_form.dart';
import 'wifi_form.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<StatefulWidget> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  ResultGenerator result = ResultGenerator.text;
  Map<ResultGenerator, Widget> forms = {};
  Map<ResultGenerator, ParsedResult> results = {};
  QRCodeStyle style = QRCodeStyle.normal;

  late BufferImage image;
  bool _isCreating = false;

  Future<void> setResult() async {
    ResultGenerator? newResult = await pickerType<ResultGenerator>(
      context,
      ResultGenerator.values,
      result,
    );
    if (newResult != null) {
      setState(() {
        result = newResult;
      });
    }
  }

  Future<void> setStyle() async {
    QRCodeStyle? newStyle =
        await pickerType<QRCodeStyle>(context, QRCodeStyle.values, style);
    if (newStyle != null) {
      setState(() {
        style = newStyle;
      });
    }
  }

  Widget formWidget(ResultGenerator type) {
    switch (type) {
      case ResultGenerator.wifi:
        return WIFIForm(
          result: results.putIfAbsent(type, () => typeResult(type))
              as WifiParsedResult,
        );
      case ResultGenerator.vcard:
        return VCardForm(
          result: results.putIfAbsent(type, () => typeResult(type))
              as AddressBookParsedResult,
        );
      case ResultGenerator.sms:
        return SMSForm(
          result: results.putIfAbsent(type, () => typeResult(type))
              as SMSParsedResult,
        );
      case ResultGenerator.geo:
        return GeoForm(
          result: results.putIfAbsent(type, () => typeResult(type))
              as GeoParsedResult,
        );
      default:
        return TextForm(
          result: results.putIfAbsent(type, () => typeResult(type))
              as TextParsedResult,
        );
    }
  }

  ParsedResult typeResult(ResultGenerator type) {
    switch (type) {
      case ResultGenerator.vcard:
        return AddressBookParsedResult()
          ..addName('')
          ..addPhoneNumber('')
          ..addAddress('');
      case ResultGenerator.sms:
        return SMSParsedResult([''], [''], '', '');
      case ResultGenerator.geo:
        return GeoParsedResult(0, 0);
      case ResultGenerator.wifi:
        return WifiParsedResult('WEP', '', '');
      default:
        return TextParsedResult('');
    }
  }

  Future<BufferImage> createQrcode(
    String content, {
    int pixelSize = 0,
    Color bgColor = Colors.white,
    Color color = Colors.black,
  }) async {
    QRCode code = Encoder.encode(content);
    print(content);
    ByteMatrix matrix = code.matrix!;
    if (pixelSize < 1) {
      pixelSize = 350 ~/ matrix.width;
    }
    BufferImage image = BufferImage(
      matrix.width * pixelSize + pixelSize * 2,
      matrix.height * pixelSize + pixelSize * 2,
    );
    image.drawRect(
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      bgColor,
    );
    BufferImage? blackImage = await style.blackBlock(pixelSize);
    BufferImage? whiteImage = await style.whiteBlock(pixelSize);
    for (int x = 0; x < matrix.width; x++) {
      for (int y = 0; y < matrix.height; y++) {
        if (matrix.get(x, y) == 1) {
          if (blackImage != null) {
            image.drawImage(
              blackImage,
              Offset(
                (pixelSize + x * pixelSize).toDouble(),
                (pixelSize + y * pixelSize).toDouble(),
              ),
            );
          }
        } else if (whiteImage != null) {
          image.drawImage(
            whiteImage,
            Offset(
              (pixelSize + x * pixelSize).toDouble(),
              (pixelSize + y * pixelSize).toDouble(),
            ),
          );
        }
      }
    }
    return image;
  }

  Future<void> createQrCode() async {
    if (_isCreating) return;
    _isCreating = true;
    final rst = results[result];
    if (rst != null) {
      image = await createQrcode(result.generator(rst));
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('qrcode'),
            content: AspectRatio(
              aspectRatio: 1,
              child: Image(
                image: RgbaImage.fromBufferImage(image),
              ),
            ),
          );
        },
      );

      _isCreating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Generator'),
        trailing: CupertinoButton(
          padding: const EdgeInsets.all(0),
          child: const Text('Create'),
          onPressed: () {
            createQrCode();
          },
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              ListTileGroup(
                children: [
                  CupertinoListTile(
                    title: const Text('内容类型'),
                    onTap: () {
                      setResult();
                    },
                    trailing: Text(result.name),
                    isLink: true,
                  ),
                  CupertinoListTile(
                    onTap: setStyle,
                    title: const Text('二维码样式'),
                    trailing: Text(style.name),
                    isLink: true,
                  ),
                ],
              ),
              forms.putIfAbsent(result, () => formWidget(result)),
            ],
          ),
        ),
      ),
    );
  }
}
