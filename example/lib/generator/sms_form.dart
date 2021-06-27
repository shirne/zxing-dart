
import 'package:flutter/cupertino.dart';
import 'package:zxing_lib/client.dart';

import '../widgets/form_cell.dart';
import '../widgets/cupertino_list_tile.dart';
import '../widgets/list_tile_group.dart';

class SMSForm extends StatefulWidget {
  final SMSParsedResult result;

  const SMSForm({Key? key, required this.result}) : super(key: key);

  @override
  State<SMSForm> createState() => _SMSFormState();
}

class _SMSFormState extends State<SMSForm> {
  late TextEditingController _controller;
  late TextEditingController _numController;
  late TextEditingController _subController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.result.body);
    _controller.addListener(() {
      widget.result.body = _controller.text;
    });
    _subController = TextEditingController(text: widget.result.subject);
    _subController.addListener(() {
      widget.result.subject = _subController.text;
    });
    _numController = TextEditingController(text: widget.result.numbers[0]);
    _numController.addListener(() {
      widget.result.numbers[0] = _numController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTileGroup(
      children: [
        FormCell(
          label: Text('phone No.'),
          field: CupertinoTextField(controller: _numController),
        ),
        FormCell(
          label: Text('subject'),
          field: CupertinoTextField(controller: _subController),
        ),
        CupertinoListTile(
          title: Text('body'),
        ),
        CupertinoTextField(
          maxLines: 5,
          controller: _controller,
        )
      ],
    );
  }
}
