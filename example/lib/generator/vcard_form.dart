import 'package:flutter/cupertino.dart';
import 'package:zxing_lib/client.dart';

import '../widgets/form_cell.dart';
import '../widgets/list_tile_group.dart';

class VCardForm extends StatefulWidget {
  final AddressBookParsedResult result;

  const VCardForm({Key? key, required this.result}) : super(key: key);

  @override
  State<VCardForm> createState() => _TextFormState();
}

class _TextFormState extends State<VCardForm> {
  late TextEditingController _controller;
  late TextEditingController _nameController;
  late TextEditingController _telController;
  late TextEditingController _addController;
  late TextEditingController _orgController;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.result.names![0]);
    _nameController.addListener(() {
      widget.result.names![0] = _nameController.text;
    });
    _telController =
        TextEditingController(text: widget.result.phoneNumbers![0]);
    _telController.addListener(() {
      widget.result.phoneNumbers![0] = _telController.text;
    });
    _addController = TextEditingController(text: widget.result.addresses![0]);
    _addController.addListener(() {
      widget.result.addresses![0] = _addController.text;
    });

    _orgController = TextEditingController(text: widget.result.org);
    _orgController.addListener(() {
      widget.result.org = _orgController.text;
    });

    _titleController = TextEditingController(text: widget.result.title);
    _titleController.addListener(() {
      widget.result.title = _titleController.text;
    });
    _controller = TextEditingController(text: widget.result.note);
    _controller.addListener(() {
      widget.result.note = _controller.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTileGroup(
      labelWidth: 80,
      children: [
        FormCell(
          label: const Text('Name.'),
          field: CupertinoTextField(controller: _nameController),
        ),
        FormCell(
          label: const Text('Tel.'),
          field: CupertinoTextField(controller: _telController),
        ),
        FormCell(
          label: const Text('Org.'),
          field: CupertinoTextField(controller: _orgController),
        ),
        FormCell(
          label: const Text('Title'),
          field: CupertinoTextField(controller: _titleController),
        ),
        FormCell(
          label: const Text('Add'),
          field: CupertinoTextField(controller: _addController),
        ),
        const FormCell(
          label: Text('Note'),
          field: SizedBox(),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          color: CupertinoColors.white,
          child: CupertinoTextField(
            maxLines: 5,
            controller: _controller,
          ),
        ),
      ],
    );
  }
}
