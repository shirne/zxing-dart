import 'package:flutter/cupertino.dart';
import 'package:zxing_lib/client.dart';

import '../widgets/form_cell.dart';
import '../widgets/list_tile_group.dart';

class WIFIForm extends StatefulWidget {
  final WifiParsedResult result;

  const WIFIForm({super.key, required this.result});

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

  void selectType() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('WIFI Encrypt Type'),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        actions: <CupertinoActionSheetAction>[
          for (String etype in ['WEP', 'WPA', 'WPA/WPA2', 'WPA2'])
            CupertinoActionSheetAction(
              child: Text(etype),
              onPressed: () {
                setState(() {
                  widget.result.networkEncryption = etype;
                });
                Navigator.pop(context);
              },
            ),
          CupertinoActionSheetAction(
            child: const Text('无加密'),
            onPressed: () {
              setState(() {
                widget.result.networkEncryption = '';
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTileGroup(
      labelWidth: 100,
      children: [
        FormCell(
          label: const Text('SSID'),
          field: CupertinoTextField(controller: _ssidController),
        ),
        FormCell(
          label: const Text('Type'),
          field: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: selectType,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0x33000000),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(widget.result.networkEncryption),
                  const Spacer(),
                  const Icon(CupertinoIcons.chevron_down),
                ],
              ),
            ),
          ),
        ),
        if (widget.result.networkEncryption.isNotEmpty)
          FormCell(
            label: const Text('Password'),
            field: CupertinoTextField(controller: _passController),
          ),
      ],
    );
  }
}
