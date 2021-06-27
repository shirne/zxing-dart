import 'dart:io';
import 'dart:typed_data';

import 'package:buffer_image/buffer_image.dart';
import 'package:zxing_lib/zxing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../models/utils.dart';
import 'result.dart';
import 'binarizer.dart';
import 'camera.dart';

class IndexPage extends StatelessWidget {
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

  void openBinarizer() {
    Navigator.of(context).pushNamed('/binarizer');
  }

  void openFile() async {
    Uint8List? fileData;
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      fileData = await _pickFile();
    } else {
      fileData = await _loadFileDesktop();
    }
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

  isoEntry(BufferImage image) {}

  Future<Uint8List?> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.count > 0) {
      if (result.files.single.path != null) {
        return File(result.files.single.path!).readAsBytesSync();
      }
      return result.files.single.bytes;
    } else {
      // User canceled the picker
      return null;
    }
  }

  Future<Uint8List?> _loadFileDesktop() async {
    final typeGroup = XTypeGroup(
      label: 'Image files',
      extensions: ['jpg', 'jpeg', 'png'],
    );
    final files = await FileSelectorPlatform.instance
        .openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.length > 0) {
      return await files.first.readAsBytes();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Scanner'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
            ),
            CupertinoButton.filled(
              child: const Text('Scanner'),
              onPressed: () {
                openCamera();
              },
            ),
            SizedBox(
              height: 20,
            ),
            CupertinoButton.filled(
              child: const Text('Binarizer'),
              onPressed: () {
                openBinarizer();
              },
            ),
            SizedBox(
              height: 20,
            ),
            CupertinoButton.filled(
              child: SizedBox(
                width: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isReading) CupertinoActivityIndicator(),
                    const Text('Image discern')
                  ],
                ),
              ),
              onPressed: () {
                openFile();
              },
            ),
            SizedBox(
              height: 10,
            ),
            Text('Multi decode mode'),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
