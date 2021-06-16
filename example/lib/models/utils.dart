
import 'package:flutter/cupertino.dart';

Future<bool?> alert<bool>(BuildContext context, String message, {String? title, List<Widget>? actions}){
  return showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Align(
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 200, horizontal: 50),
          child: CupertinoAlertDialog(
            title: title == null ? null : Text(title),
            content: Column(
              children: message.split(RegExp("[\r\n]+")).map<Widget>((row)=>Text(row)).toList(),
            ),
              actions:actions ?? [
                CupertinoButton(child: Text('OK'), onPressed: (){
                  Navigator.pop(context, true);
                })
              ]
          ),
        ),
      );
    },
  );
}