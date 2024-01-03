import 'package:flutter/cupertino.dart';

import 'list_tile_group.dart';

class FormCell extends StatelessWidget {
  const FormCell({
    Key? key,
    required this.label,
    required this.field,
    this.labelWidth,
    bool? isLink,
    this.onTap,
  })  : isLink = isLink ?? onTap != null,
        super(key: key);

  final Widget label;
  final Widget field;
  final bool isLink;
  final double? labelWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final group = context.findAncestorWidgetOfExactType<ListTileGroup>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      color: CupertinoColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: labelWidth ?? group?.labelWidth,
            padding: group?.labelPadding ??
                const EdgeInsets.symmetric(horizontal: 10),
            alignment: group?.labelAlign,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                CupertinoIcons.right_chevron,
                color: CupertinoColors.inactiveGray,
              ),
            ),
        ],
      ),
    );
  }
}
