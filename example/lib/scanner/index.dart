import 'package:flutter/cupertino.dart';
import 'camera.dart';
import 'webview.dart';

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
          case '/webview':
            builder = (BuildContext context) => const WebviewPage();
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
  void openCamera() {
    Navigator.of(context).pushNamed('/camera');
  }

  void openWebview() {
    Navigator.of(context).pushNamed('/webview');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Scanner'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CupertinoButton(
              child: const Text('Scanner'),
              onPressed: () {
                openCamera();
              },
            ),
            CupertinoButton(
              child: const Text('Webview discern'),
              onPressed: () {
                openWebview();
              },
            )
          ],
        ),
      ),
    );
  }
}
