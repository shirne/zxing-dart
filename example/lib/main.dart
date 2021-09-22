import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'generator/index.dart' as generator;
import 'home/index.dart' as home;
import 'scanner/index.dart' as scanner;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'ZXing Demo',
      theme: CupertinoThemeData(primaryColor: Colors.red),
      home: MyHomePage(title: 'ZXing Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house),
              activeIcon: Icon(CupertinoIcons.house_fill),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.qrcode),
              activeIcon: Icon(CupertinoIcons.qrcode_viewfinder),
              label: 'Scanner'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.app_badge),
              activeIcon: Icon(CupertinoIcons.app_badge_fill),
              label: 'Generator'),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            switch (index) {
              case 1:
                return const scanner.IndexPage();
              case 2:
                return const generator.IndexPage();
              default:
                return const home.IndexPage();
            }
          },
        );
      },
      backgroundColor: Colors.white,
    );
  }
}
