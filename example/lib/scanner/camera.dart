import 'package:flutter/cupertino.dart';

class CameraPage extends StatefulWidget {
  const CameraPage();
  @override
  State<StatefulWidget> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Camera'),
      ),
      child: Center(
        child: Text('camera'),
      ),
    );
  }
}
