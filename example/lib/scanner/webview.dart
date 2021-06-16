import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewPage extends StatefulWidget {
  const WebviewPage();
  @override
  State<StatefulWidget> createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage> {

  @override
  void initState() {
    super.initState();
    if(!kIsWeb) {
      if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Webview'),
      ),
      child: WebView(
        initialUrl: 'https://flutter.cn',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated:(webview){
          print(webview);
            webview.evaluateJavascript("""
            alert('aaa');
            """);
          }
      ),
    );
  }
}
