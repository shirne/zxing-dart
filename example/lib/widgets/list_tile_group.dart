import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ListTileGroup extends StatelessWidget{
  final List<Widget> children;
  final double paddingBottom;
  final double dividerWith;
  final Color dividerColor;
  final double dividerIntent;
  final double dividerEndIntent;

  const ListTileGroup({Key? key,required this.children, this.dividerWith = 0.5, this.paddingBottom = 10, this.dividerIntent = 20, this.dividerEndIntent = 0, this.dividerColor = CupertinoColors.lightBackgroundGray}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget divider = Container(
      height: 0,
      width: MediaQuery.of(context).size.width - dividerIntent - dividerEndIntent,
      margin: EdgeInsets.only(left: dividerIntent, right: dividerEndIntent),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: dividerWith, color: dividerColor)
        )
      ),
    );
    return Padding(
        padding: EdgeInsets.only(bottom: paddingBottom),
      child: Column(
        children: List.generate(
            children.length * 2 - 1,
                (index) => index % 2 == 0 ? children[index ~/2] : divider
        ),
      ),
    );
  }

}