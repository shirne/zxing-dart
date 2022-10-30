import 'dart:async';

import 'package:buffer_image/buffer_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

import '../models/utils.dart';
import '../widgets/cupertino_icon_button.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  FlashMode _flashMode = FlashMode.off;
  bool detectedCamera = false;
  bool isDetecting = false;
  Timer? _detectTimer;

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
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      //_controller!.addListener(onCameraView);
      //_detectTimer = Timer.periodic(Duration(seconds: 2), onCameraView);
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

  Future<void> onCameraView() async {
    if (isDetecting) return;
    setState(() {
      isDetecting = true;
    });
    XFile pic = await _controller!.takePicture();

    Uint8List data = await pic.readAsBytes();
    BufferImage? image = await BufferImage.fromFile(data);
    if (image != null) {
      if (image.width > 1000) {
        image.scaleDown(image.width / 800);
      }

      var results =
          await decodeImageInIsolate(image.buffer, image.width, image.height);
      if (!mounted) return;
      setState(() {
        isDetecting = false;
      });
      if (results != null) {
        Navigator.of(context).pushNamed('/result', arguments: results);
      } else {
        MyDialog.toast('detected nothing');
        if (!kIsWeb) {
          onCameraView();
        }
      }
    } else {
      setState(() {
        isDetecting = false;
      });
      print('can\'t take picture from camera');
    }
    _controller?.setFocusMode(FocusMode.auto);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detectTimer?.cancel();
    super.dispose();
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
                        onPressed: onCameraView,
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
