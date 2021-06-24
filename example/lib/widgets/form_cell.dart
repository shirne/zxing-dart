import 'package:flutter/cupertino.dart';

class FormCell extends StatelessWidget {
  const FormCell({
    Key? key,
    required this.label,
    required this.field,
    this.isLink = false,
  }) : super(key: key);

  final Widget label;
  final Widget field;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      width: MediaQuery.of(context).size.width,
      color: CupertinoColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: label,
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
              child: field,
            ),
          ),
          if (isLink)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                CupertinoIcons.right_chevron,
                color: CupertinoColors.inactiveGray,
              ),
            )
        ],
      ),
    );
  }
}
