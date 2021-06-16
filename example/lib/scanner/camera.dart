import 'dart:async';

import 'package:buffer_image/buffer_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/multi.dart';
import 'package:zxing_lib/zxing.dart';

import '../models/image_source.dart';
import '../widgets/cupertino_icon_button.dart';

class CameraPage extends StatefulWidget {
  const CameraPage();
  @override
  State<StatefulWidget> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool detectedCamera = false;
  bool isDetecting = false;
  MultipleBarcodeReader? reader;
  Timer? _detectTimer;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  initCamera() async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.max,
          enableAudio:false,
          imageFormatGroup: ImageFormatGroup.jpeg
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

  onCameraView() async{
    if(isDetecting)return;
    isDetecting = true;
    XFile pic = await _controller!.takePicture();
    BufferImage? image = await BufferImage.fromFile(await pic.readAsBytes());
    if(image != null){
      ImageLuminanceSource imageSource = ImageLuminanceSource(image);
      if(image.width > 1000){
        imageSource = imageSource.scaleDown(imageSource.width ~/ 1000);
      }
      BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(imageSource));

      if(reader == null) {
        reader = GenericMultipleBarcodeReader(MultiFormatReader());
      }
      List<Result>? results;
      try {
        results = reader!.decodeMultiple(bitmap);
      }on NotFoundException catch(_){}

      if(results != null && results.isNotEmpty) {
        if(!mounted)return;
        Navigator.of(context).pushNamed('/result', arguments: results);
      }else{
        print('detected nothing');
      }
    }else{
      print('can\'t take picture from camera');
    }
    isDetecting = false;
    _controller?.setFocusMode(FocusMode.auto);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detectTimer?.cancel();
    super.dispose();
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
                  child: Stack(children: [
                    Align(
                      alignment: Alignment(0, 0.7),
                      child: CupertinoIconButton(icon: Icon(CupertinoIcons.qrcode_viewfinder),onPressed: onCameraView,),
                    )
                  ],),
                ),
      ),
    );
  }
}
