import 'dart:typed_data';

import 'package:buffer_image/buffer_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
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

  void openFile() async {
    Uint8List? fileData = await _pickFile();

    if (fileData != null) {
      BufferImage? image = await BufferImage.fromFile(fileData);
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
    } else {
      print('not pick any file');
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
              child: const Text('Scanner'),
              onPressed: () {
                openCamera();
              },
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              child: const Text('Scanner With CameraStream'),
              onPressed: () {
                openCameraStream();
              },
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              child: const Text('Binarizer'),
              onPressed: () {
                openBinarizer();
              },
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              child: SizedBox(
                width: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isReading) const CupertinoActivityIndicator(),
                    const Text('Image discern')
                  ],
                ),
              ),
              onPressed: () {
                openFile();
              },
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
