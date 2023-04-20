import 'dart:async';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/multi.dart';
import 'package:zxing_lib/zxing.dart';

enum IsoCommand {
  decode,
  success,
  fail,
}

class IsoMessage {
  IsoMessage(this.cmd, [this.data])
      : result = null,
        assert(cmd != IsoCommand.decode || data != null);

  IsoMessage.result(this.result)
      : cmd = IsoCommand.success,
        data = null,
        assert(result != null);

  IsoMessage.fail()
      : cmd = IsoCommand.success,
        data = null,
        result = null;

  final List<Plane>? data;
  final List<Result>? result;
  final IsoCommand cmd;
}

class IsolateController extends ChangeNotifier {
  Isolate? newIsolate;
  late ReceivePort receivePort;
  late SendPort newIceSP;
  Capability? capability;

  List<Plane> _currentPlanes = <Plane>[];
  final List<List<Result>?> _currentResults = [];
  bool _created = false;
  bool _paused = false;

  List<Plane> get currentMultiplier => _currentPlanes;

  bool get paused => _paused;

  bool get created => _created;

  List<List<Result>?> get currentResults => _currentResults;

  Future<void> createIsolate() async {
    receivePort = ReceivePort();
    newIsolate = await Isolate.spawn(decodeFromCamera, receivePort.sendPort);
  }

  void listen() {
    receivePort.listen((dynamic message) {
      if (message is SendPort) {
        newIceSP = message;
        if (_currentPlanes.isNotEmpty) {
          newIceSP.send(_currentPlanes);
        }
      } else if (message is IsoMessage) {
        if (message.cmd == IsoCommand.success ||
            message.cmd == IsoCommand.fail) {
          setCurrentResults(message.result);
        }
      }
    });
  }

  Future<void> start() async {
    if (_created == false && _paused == false) {
      await createIsolate();
      listen();
      _created = true;
      notifyListeners();
    }
  }

  void terminate() {
    newIsolate?.kill();
    _created = false;
    _currentResults.clear();
    notifyListeners();
  }

  void pausedSwitch() {
    if (_paused && capability != null) {
      newIsolate?.resume(capability!);
    } else {
      capability = newIsolate?.pause();
    }

    _paused = !_paused;
    notifyListeners();
  }

  Completer<List<Result>>? completer;
  Future<List<Result>> setPlanes(List<Plane> planes) {
    _currentPlanes = planes;
    completer = Completer<List<Result>>();
    newIceSP.send(IsoMessage(IsoCommand.decode, _currentPlanes));
    notifyListeners();
    return completer!.future;
  }

  void setCurrentResults(List<Result>? result) {
    _currentResults.insert(0, result);
    notifyListeners();
    if (!(completer?.isCompleted ?? true)) {
      if (result != null) {
        completer?.complete(result);
      } else {
        completer?.completeError('Decode Failed');
      }
    }
  }

  @override
  void dispose() {
    newIsolate?.kill(priority: Isolate.immediate);
    newIsolate = null;
    super.dispose();
  }
}

Future<void> decodeFromCamera(SendPort callerSP) async {
  final newIceRP = ReceivePort();
  callerSP.send(newIceRP.sendPort);

  final reader = GenericMultipleBarcodeReader(MultiFormatReader());

  List<Plane>? planes;

  Completer<bool> goNext = Completer();
  newIceRP.listen((dynamic message) {
    print('Isolate: on message: $message');
    if (message is IsoMessage) {
      if (message.cmd == IsoCommand.decode) {
        if (goNext.isCompleted) {
          print('Is decoding');
          return;
        }
        planes = message.data;

        goNext.complete(true);
      }
    }
  });

  callerSP.send(newIceRP.sendPort);

  while (true) {
    print('Isolate: hold for $goNext');
    await goNext.future;
    print('Isolate: start decode');
    if (planes != null) {
      final e = planes!.first;
      final width = e.bytesPerRow;
      final height = (e.bytes.length / width).round();
      final total = planes!
          .map<double>((p) => p.bytesPerPixel!.toDouble())
          .reduce((value, element) => value + 1 / element)
          .toInt();
      final data = Uint8List(width * height * total);
      int startIndex = 0;
      for (var p in planes!) {
        List.copyRange(data, startIndex, p.bytes);
        startIndex += width * height ~/ p.bytesPerPixel!;
      }

      print('Isolate: ${data.length},$width,$height');
      final imageSource = PlanarYUVLuminanceSource(
        data,
        width,
        height,
      );

      final bitmap = BinaryBitmap(HybridBinarizer(imageSource));
      try {
        final results = reader.decodeMultiple(bitmap, {
          DecodeHintType.tryHarder: false,
          DecodeHintType.alsoInverted: false,
        });
        callerSP.send(IsoMessage.result(results));
        print('Isolate: $results');
      } on NotFoundException catch (_) {
        print(_);
        callerSP.send(IsoMessage.fail());
      }
    }

    goNext = Completer();
  }
}
