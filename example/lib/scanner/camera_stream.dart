import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

import '../models/decoder.dart';
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
  final _isoController = IsolateController();
  bool detectedCamera = false;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();

    Future.wait([
      initCamera(),
      _isoController.start(),
      Future.delayed(const Duration(seconds: 1)),
    ]).then((value) => start());
  }

  @override
  void dispose() {
    stop();
    _controller?.dispose();
    _isoController.dispose();
    super.dispose();
  }

  Future<void> initCamera() async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      var camera = _cameras!.first;
      for (var c in _cameras!) {
        if (c.lensDirection == CameraLensDirection.back) {
          camera = c;
        }
      }
      _controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
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
    } else {
      setState(() {
        detectedCamera = true;
      });
    }
  }

  bool _isStart = false;
  Future<void> start() async {
    if (_isStart || !mounted) return;
    await _controller!.startImageStream(tryDecodeImage);
    _isStart = true;
  }

  Future<void> stop() async {
    if (!_isStart) return;
    await _controller!.stopImageStream();
    _isStart = false;
  }

  Future<void> tryDecodeImage(CameraImage image) async {
    if (isDetecting || !mounted) return;
    await stop();
    setState(() {
      isDetecting = true;
    });

    try {
      final results = await _isoController.setPlanes(image.planes);
      if (!mounted) return;
      setState(() {
        isDetecting = false;
      });
      Navigator.of(context).pushNamed('/result', arguments: results);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isDetecting = false;
      });
      MyDialog.toast('detected nothing');
      Future.delayed(Duration.zero).then((_) {
        start();
      });
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
                        color: const Color(0xffffffff),
                        icon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (isDetecting)
                                const CupertinoActivityIndicator()
                              else
                                const Icon(CupertinoIcons.qrcode_viewfinder),
                            ],
                          ),
                        ),
                        onPressed: start,
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
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
