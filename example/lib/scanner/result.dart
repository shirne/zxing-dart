import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zxing_lib/zxing.dart';

class ResultPage extends StatefulWidget {
  final List<Result> results;

  const ResultPage(this.results, {super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Results'),
      ),
      resizeToAvoidBottomInset: true,
      child: Material(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.results
                  .map<Widget>(
                    (result) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 20,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: CupertinoColors.lightBackgroundGray,
                              ),
                            ),
                            color: CupertinoColors.white,
                          ),
                          child: SelectableText(
                            "Detected ${result.barcodeFormat.toString().replaceFirst('BarcodeFormat.', '')} at ${result.resultPoints}",
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: CupertinoColors.inactiveGray,
                            ),
                            color: CupertinoColors.lightBackgroundGray,
                          ),
                          child: SelectableText(result.toString()),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
