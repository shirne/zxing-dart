
import 'package:flutter/cupertino.dart';
import 'package:zxing_lib/client.dart';

import '../widgets/list_tile_group.dart';
import '../widgets/form_cell.dart';

class WIFIForm extends StatefulWidget {
  final WifiParsedResult result;

  const WIFIForm({Key? key, required this.result}) : super(key: key);

  @override
  State<WIFIForm> createState() => _TextFormState();
}

class _TextFormState extends State<WIFIForm> {
  late TextEditingController _passController;
  late TextEditingController _ssidController;

  @override
  void initState() {
    super.initState();
    _ssidController = TextEditingController(text: widget.result.ssid);
    _passController = TextEditingController(text: widget.result.password);
    _ssidController.addListener(() {
      widget.result.ssid = _ssidController.text;
    });
    _passController.addListener(() {
      widget.result.password = _passController.text;
    });
  }

  selectType(){
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('WIFI Encrypt Type'),
        message: const Text('Message'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('WPA'),
            onPressed: () {
              setState(() {
                widget.result.networkEncryption = 'WPA';
              });
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('WEP'),
            onPressed: () {
              setState(() {
                widget.result.networkEncryption = 'WEP';
              });
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTileGroup(
        children: [
          FormCell(
            label: Text('SSID'),
            field: CupertinoTextField(controller: _ssidController)
          ),
          FormCell(
            label: Text('Password'),
            field: CupertinoTextField(controller: _passController),
          ),
          FormCell(
            label: Text('Type'),
            field: GestureDetector(
              onTap: selectType,
              child:  Text(widget.result.networkEncryption),
            ),
          ),
        ],
    );
  }
}
