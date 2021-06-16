import 'dart:io';
import 'dart:typed_data';

import 'package:buffer_image/buffer_image.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

import '../models/utils.dart';
import '../models/image_source.dart';
import '../widgets/cupertino_icon_button.dart';

class BinarizerPage extends StatefulWidget {
  const BinarizerPage();

  @override
  State<BinarizerPage> createState() => _BinarizerPageState();
}

class _BinarizerPageState extends State<BinarizerPage> {
  BufferImage? bufferImage;
  GrayImage? grayImage;
  GrayImage? deNoiseImage;
  GrayImage? binaryImage;
  GrayImage? HybridBinaryImage;

  takePicture() async {
    XFile? picture =
        await Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
      return TakePhoto();
    }));
    if (picture != null) {
      initImage(await picture.readAsBytes());
    }
  }

  loadFile() async {
    Uint8List? fileData;
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      fileData = await _pickFile();
    } else {
      fileData = await _loadFileDesktop();
    }
    if (fileData != null) {
      initImage(fileData);
    } else {
      print('not pick any file');
    }
  }

  initImage(Uint8List fileData) async {
    bufferImage = await BufferImage.fromFile(fileData);
    if (bufferImage == null) {
      alert(context, 'Can\'t read the image');
      return;
    }
    grayImage = bufferImage?.toGray();

    deNoiseImage = grayImage!.copy()
      ..deNoise()
      ..binaryzation()
      ..deNoise();

    binaryImage =
        bin2Image(GlobalHistogramBinarizer(ImageLuminanceSource(bufferImage!.copy())));
    HybridBinaryImage =
        bin2Image(HybridBinarizer(ImageLuminanceSource(bufferImage!.copy())));

    setState(() {});
  }

  GrayImage bin2Image(Binarizer binarizer) {
    BitMatrix matrix = binarizer.blackMatrix;
    GrayImage image = GrayImage(matrix.width, matrix.height);
    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        image.setChannel(x, y, matrix.get(x, y) ? 0 : 255);
      }
    }
    return image;
  }

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
        middle: Text('Binarizer'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CupertinoButton.filled(
                    onPressed: () {
                      loadFile();
                    },
                    child: Text('file...'),
                  ),
                  CupertinoButton.filled(
                    onPressed: () {
                      takePicture();
                    },
                    child: Text('Camera...'),
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              if (bufferImage != null)
                Image(
                  image: RgbaImage.fromBufferImage(bufferImage!, scale: 1),
                ),
              SizedBox(
                height: 20,
              ),
              if (grayImage != null)
                Image(
                  image: RgbaImage.fromBufferImage(
                      BufferImage.fromGray(grayImage!),
                      scale: 1),
                ),
              SizedBox(
                height: 20,
              ),
              if (deNoiseImage != null)
                Image(
                  image: RgbaImage.fromBufferImage(
                      BufferImage.fromGray(deNoiseImage!),
                      scale: 1),
                ),
              SizedBox(
                height: 20,
              ),
              if (binaryImage != null)
                Image(
                  image: RgbaImage.fromBufferImage(
                      BufferImage.fromGray(binaryImage!),
                      scale: 1),
                ),
              SizedBox(
                height: 20,
              ),
              if (HybridBinaryImage != null)
                Image(
                  image: RgbaImage.fromBufferImage(
                      BufferImage.fromGray(HybridBinaryImage!),
                      scale: 1),
                ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TakePhoto extends StatefulWidget {
  @override
  State<TakePhoto> createState() => _TakePhotoState();
}

class _TakePhotoState extends State<TakePhoto> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool detectedCamera = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  initCamera() async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.max,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);

      _controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          detectedCamera = true;
        });
      });
    } else {
      setState(() {
        detectedCamera = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  takePicture() async {
    XFile picture = await _controller!.takePicture();
    Navigator.of(context).pop(picture);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Camera'),
      ),
      child: Center(
        child: _controller == null
            ? Text(detectedCamera ? 'Not detected cameras' : 'Detecting')
            : CameraPreview(
                _controller!,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment(0, 0.7),
                      child: CupertinoIconButton(
                        icon: Icon(CupertinoIcons.camera),
                        onPressed: takePicture,
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
