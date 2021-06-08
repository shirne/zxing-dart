import 'package:flutter/cupertino.dart';

class WebviewPage extends StatefulWidget {
  const WebviewPage();
  @override
  State<StatefulWidget> createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Webview'),
      ),
      child: Center(
        child: Text('webview'),
      ),
    );
  }
}
