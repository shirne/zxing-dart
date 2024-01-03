import 'dart:typed_data';

import 'package:buffer_image/buffer_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:zxing_lib/zxing.dart';

import '../models/utils.dart';
import 'binarizer.dart';
import 'camera.dart';
import 'camera_stream.dart';
import 'result.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/camera':
            builder = (BuildContext context) => const CameraPage();
            break;
          case '/camera-stream':
            builder = (BuildContext context) => const CameraStreamPage();
            break;
          case '/result':
            builder = (BuildContext context) =>
                ResultPage(settings.arguments as List<Result>);
            break;
          case '/binarizer':
            builder = (BuildContext context) => const BinarizerPage();
            break;
          default:
            builder = (BuildContext context) => const _IndexPage();
        }
        return CupertinoPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

class _IndexPage extends StatefulWidget {
  const _IndexPage();
  @override
  State<StatefulWidget> createState() => _IndexPageState();
}

class _IndexPageState extends State<_IndexPage> {
  bool isReading = false;
  void openCamera() {
    Navigator.of(context).pushNamed('/camera');
  }

  void openCameraStream() {
    Navigator.of(context).pushNamed('/camera-stream');
  }

  void openBinarizer() {
    Navigator.of(context).pushNamed('/binarizer');
  }

  void fromClipBoard() async {
    final reader = await ClipboardReader.readClipboard();

    if (reader.canProvide(Formats.jpeg)) {
      reader.getFile(Formats.jpeg, (file) async {
        discernFile(await file.readAll());
      });
    } else if (reader.canProvide(Formats.png)) {
      reader.getFile(Formats.png, (file) async {
        discernFile(await file.readAll());
      });
    }
  }

  void openFile() async {
    Uint8List? fileData = await _pickFile();

    if (fileData != null) {
      discernFile(fileData);
    } else {
      print('not pick any file');
    }
  }

  void discernFile(Uint8List data) async {
    BufferImage? image = await BufferImage.fromFile(data);
    if (image == null) {
      alert(context, 'Can\'t read the image');
      return;
    }
    setState(() {
      isReading = true;
    });
    var results =
        await decodeImageInIsolate(image.buffer, image.width, image.height);
    setState(() {
      isReading = false;
    });
    if (results != null) {
      Navigator.of(context).pushNamed('/result', arguments: results);
    } else {
      alert(context, 'Can\'t detect barcodes or qrcodes');
    }
  }

  void isoEntry(BufferImage image) {}

  Future<Uint8List?> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);

    if (result != null && result.count > 0) {
      return result.files.first.bytes;
    } else {
      // User canceled the picker
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scanner'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: openCamera,
              child: const Text('Scanner'),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: openCameraStream,
              child: const Text('Scanner With CameraStream'),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: openBinarizer,
              child: const Text('Binarizer'),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: fromClipBoard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isReading) const CupertinoActivityIndicator(),
                  const Text('Image discern from clipboard'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: openFile,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isReading) const CupertinoActivityIndicator(),
                  const Text('Image discern'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('Multi decode mode'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
