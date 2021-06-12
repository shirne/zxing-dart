

import 'package:flutter/cupertino.dart';
import 'package:zxing_lib/client.dart';

import '../widgets/form_cell.dart';
import '../widgets/list_tile_group.dart';


class GeoForm extends StatefulWidget{
  final GeoParsedResult result;

  const GeoForm({Key? key,required this.result}) : super(key: key);

  @override
  State<GeoForm> createState() => _GeoFormState();
}

class _GeoFormState extends State<GeoForm> {
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(text: widget.result.latitude.toString());
    _latController.addListener(() {
      widget.result.latitude = double.parse( _latController.text);
    });
    _lngController = TextEditingController(text: widget.result.longitude.toString());
    _lngController.addListener(() {
      widget.result.longitude = double.parse( _lngController.text);
    });
  }


  @override
  Widget build(BuildContext context) {
    return ListTileGroup(
      children: [
        FormCell(
            label: Text('latitude'),
            field: CupertinoTextField(controller: _latController)
        ),
        FormCell(
            label: Text('longitude'),
            field: CupertinoTextField(controller: _lngController)
        ),
      ],
    );
  }
}