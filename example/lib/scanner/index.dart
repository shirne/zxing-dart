

import 'package:flutter/cupertino.dart';

class IndexPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _IndexPageState();

}

class _IndexPageState extends State<IndexPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Scanner'),
      ),
      child: Center(
        child: CupertinoButton(
          child: const Text('Scanner'),
          onPressed: () {

          },
        ),
      ),
    );
  }

}