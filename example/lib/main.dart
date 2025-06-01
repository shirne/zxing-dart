import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

import 'generator/index.dart' as generator;
import 'home/index.dart' as home;
import 'scanner/index.dart' as scanner;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'ZXing Demo',
      navigatorKey: MyDialog.navigatorKey,
      localizationsDelegates: const [
        ShirneDialogLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      theme: const CupertinoThemeData(
        scaffoldBackgroundColor: CupertinoColors.lightBackgroundGray,
      ),
      home: const MyHomePage(title: 'ZXing Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.qrcode),
            activeIcon: Icon(CupertinoIcons.qrcode_viewfinder),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.app_badge),
            activeIcon: Icon(CupertinoIcons.app_badge_fill),
            label: 'Generator',
          ),
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
