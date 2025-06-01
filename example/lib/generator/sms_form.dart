import 'package:flutter/cupertino.dart';
import 'package:zxing_lib/client.dart';

import '../widgets/form_cell.dart';
import '../widgets/list_tile_group.dart';

class SMSForm extends StatefulWidget {
  final SMSParsedResult result;

  const SMSForm({super.key, required this.result});

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
      labelWidth: 100,
      children: [
        FormCell(
          label: const Text('phone No.'),
          field: CupertinoTextField(controller: _numController),
        ),
        FormCell(
          label: const Text('subject'),
          field: CupertinoTextField(controller: _subController),
        ),
        const FormCell(
          label: Text('body'),
          field: SizedBox(),
        ),
        Container(
          color: CupertinoColors.white,
          padding: const EdgeInsets.all(8.0),
          child: CupertinoTextField(
            maxLines: 5,
            controller: _controller,
          ),
        ),
      ],
    );
  }
}
