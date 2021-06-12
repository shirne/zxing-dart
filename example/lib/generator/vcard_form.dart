

import 'package:flutter/cupertino.dart';
import 'package:zxing_lib/client.dart';

import '../widgets/form_cell.dart';
import '../widgets/cupertino_list_tile.dart';
import '../widgets/list_tile_group.dart';


class VCardForm extends StatefulWidget{
  final AddressBookParsedResult result;

  const VCardForm({Key? key,required this.result}) : super(key: key);

  @override
  State<VCardForm> createState() => _TextFormState();
}

class _TextFormState extends State<VCardForm> {
  late TextEditingController _controller;
  late TextEditingController _nameController;
  late TextEditingController _telController;
  late TextEditingController _addController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.result.names![0]);
    _nameController.addListener(() {
      widget.result.names![0] = _nameController.text;
    });
    _telController = TextEditingController(text: widget.result.phoneNumbers![0]);
    _telController.addListener(() {
      widget.result.phoneNumbers![0] = _telController.text;
    });
    _addController = TextEditingController(text: widget.result.addresses![0]);
    _addController.addListener(() {
      widget.result.addresses![0] = _addController.text;
    });
    _controller = TextEditingController(text: widget.result.note);
    _controller.addListener(() {
      widget.result.note = _controller.text;
    });
  }


  @override
  Widget build(BuildContext context) {
    return ListTileGroup(
      children: [
        FormCell(
            label: Text('name'),
            field: CupertinoTextField(controller: _nameController)
        ),
        FormCell(
            label: Text('tel'),
            field: CupertinoTextField(controller: _telController)
        ),
        FormCell(
            label: Text('add'),
            field: CupertinoTextField(controller: _addController)
        ),
        CupertinoListTile(
          title: Text('note'),
        ),
        CupertinoTextField(
          maxLines: 5,
          controller: _controller,
        )
      ],
    );
  }
}