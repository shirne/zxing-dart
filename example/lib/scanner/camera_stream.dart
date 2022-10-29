import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

import '../models/utils.dart';
import '../widgets/cupertino_icon_button.dart';

class CameraStreamPage extends StatefulWidget {
  const CameraStreamPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CameraStreamPageState();
}

class _CameraStreamPageState extends State<CameraStreamPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  FlashMode _flashMode = FlashMode.off;
  bool detectedCamera = false;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    stop();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> initCamera() async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      _controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          detectedCamera = true;
        });
        if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
          MyDialog.toast('Does not support current platform');
          return;
        }
        Future.delayed(Duration.zero).then((_) => start());
      });
    } else {
      setState(() {
        detectedCamera = true;
      });
    }
  }

  bool _isStart = false;
  void start() {
    if (_isStart) return;
    _isStart = true;
    _controller!.startImageStream(tryDecodeImage);
  }

  void stop() {
    if (!_isStart) return;
    _isStart = false;
    _controller!.stopImageStream();
  }

  Future<void> tryDecodeImage(CameraImage image) async {
    if (isDetecting) return;
    stop();
    setState(() {
      isDetecting = true;
    });
    print(
      image.planes
          .map((p) =>
              '${p.bytes.length} ${p.bytesPerPixel} ${p.bytesPerRow} ${p.width} ${p.height}')
          .toList(),
    );
    final e = image.planes.first;
    final width = e.bytesPerRow;
    final height = (e.bytes.length / width).round();
    final total = image.planes
        .map<double>((p) => p.bytesPerPixel!.toDouble())
        .reduce((value, element) => value + 1 / element)
        .toInt();
    final data = Uint8List(width * height * total);
    int startIndex = 0;
    for (var p in image.planes) {
      List.copyRange(data, startIndex, p.bytes);
      startIndex += width * height ~/ p.bytesPerPixel!;
    }

    var results = await decodeImageInIsolate(data, width, height, isRgb: false);
    if (!mounted) return;
    setState(() {
      isDetecting = false;
    });
    if (results != null) {
      Navigator.of(context).pushNamed('/result', arguments: results);
    } else {
      MyDialog.toast('detected nothing');
      start();
      _controller?.setFocusMode(FocusMode.auto);
    }
  }

  void changeBoltMode() {
    var cIndex = FlashMode.values.indexOf(_flashMode);
    cIndex++;
    if (cIndex >= FlashMode.values.length) {
      cIndex = 0;
    }
    setState(() {
      _flashMode = FlashMode.values[cIndex];
    });
    try {
      _controller?.setFlashMode(_flashMode);
    } catch (_) {}
  }

  Icon getBolt() {
    switch (_flashMode) {
      case FlashMode.off:
        return const Icon(CupertinoIcons.bolt);
      case FlashMode.always:
        return const Icon(CupertinoIcons.bolt_fill);
      case FlashMode.auto:
        return const Icon(CupertinoIcons.bolt_badge_a);
      case FlashMode.torch:
        return const Icon(CupertinoIcons.bolt_circle_fill);
    }
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
                        icon: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (isDetecting) const CupertinoActivityIndicator(),
                            const Icon(CupertinoIcons.qrcode_viewfinder),
                          ],
                        ),
                        //onPressed: onCameraView,
                      ),
                    ),
                    Align(
                      alignment: const Alignment(1, -1),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, top: 80),
                        child: CupertinoIconButton(
                          icon: getBolt(),
                          onPressed: changeBoltMode,
                        ),
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
