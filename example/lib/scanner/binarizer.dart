import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:buffer_image/buffer_image.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/binarizer.dart';
import '../models/utils.dart';
import '../widgets/cupertino_icon_button.dart';

class BinarizerPage extends StatefulWidget {
  const BinarizerPage({super.key});

  @override
  State<BinarizerPage> createState() => _BinarizerPageState();
}

class _BinarizerPageState extends State<BinarizerPage> {
  BufferImage? bufferImage;
  ui.Image? origImage;
  ui.Image? grayImage;
  ui.Image? deNoiseImage;
  ui.Image? binaryImage;
  ui.Image? hybridBinaryImage;
  ui.Image? inverseImage;

  int imageLoadStatus = 0;

  Future<void> takePicture() async {
    XFile? picture = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          return const TakePhoto();
        },
      ),
    );
    if (picture != null) {
      setState(() {
        imageLoadStatus = 1;
      });
      initImage(await picture.readAsBytes());
    }
  }

  Future<void> loadFile() async {
    Uint8List? fileData = await _pickFile();

    if (fileData != null) {
      setState(() {
        imageLoadStatus = 1;
      });
      initImage(fileData);
    } else {
      print('not pick any file');
    }
  }

  Future<void> initImage(Uint8List fileData) async {
    bufferImage = await BufferImage.fromFile(fileData);
    if (bufferImage == null) {
      alert(context, 'Can\'t read the image');
      setState(() {
        imageLoadStatus = 0;
      });
      return;
    }
    final width = bufferImage!.width;
    final height = bufferImage!.height;
    origImage = await bufferImage!.getImage();
    setState(() {});
    binarizerImage(bufferImage!.buffer, bufferImage!.width, bufferImage!.height,
        (data) async {
      switch (data.type) {
        case 'grayImage':
          grayImage =
              await GrayImage.raw(data.data, width: width, height: height)
                  .getImage();
          break;
        case 'deNoiseImage':
          deNoiseImage =
              await GrayImage.raw(data.data, width: width, height: height)
                  .getImage();
          break;
        case 'binaryImage':
          binaryImage =
              await GrayImage.raw(data.data, width: width, height: height)
                  .getImage();
          break;
        case 'hybridBinaryImage':
          hybridBinaryImage =
              await GrayImage.raw(data.data, width: width, height: height)
                  .getImage();
          break;
        case 'inverseImage':
          inverseImage =
              await GrayImage.raw(data.data, width: width, height: height)
                  .getImage();
          break;
      }
      setState(() {});
    }, () {
      setState(() {
        imageLoadStatus = 2;
      });
    });
  }

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
        middle: Text('Binarizer'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        loadFile();
                      },
                      padding: EdgeInsets.zero,
                      child: const Center(child: Text('file...')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        takePicture();
                      },
                      padding: EdgeInsets.zero,
                      child: const Center(child: Text('Camera...')),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const SizedBox(height: 16),
              if (bufferImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image(
                    image: RgbaImage.fromBufferImage(bufferImage!, scale: 1),
                  ),
                ),
              if (grayImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RawImage(
                    image: grayImage,
                  ),
                ),
              if (deNoiseImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RawImage(
                    image: deNoiseImage,
                  ),
                ),
              if (binaryImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RawImage(
                    image: binaryImage,
                  ),
                ),
              if (hybridBinaryImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RawImage(
                    image: hybridBinaryImage,
                  ),
                ),
              if (inverseImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RawImage(
                    image: inverseImage,
                  ),
                ),
              if (imageLoadStatus == 1) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class TakePhoto extends StatefulWidget {
  const TakePhoto({super.key});

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

  Future<void> initCamera() async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

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

  Future<void> takePicture() async {
    XFile picture = await _controller!.takePicture();
    Navigator.of(context).pop(picture);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
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
                      alignment: const Alignment(0, 0.7),
                      child: CupertinoIconButton(
                        icon: const Icon(CupertinoIcons.camera),
                        onPressed: takePicture,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
