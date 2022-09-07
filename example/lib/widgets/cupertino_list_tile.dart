import 'package:flutter/cupertino.dart';

class CupertinoListTile extends StatelessWidget {
  const CupertinoListTile({
    Key? key,
    required this.title,
    this.trailing,
    this.leading,
    this.subtitle,
    this.onTap,
    this.isLink = false,
  }) : super(key: key);

  final Widget? trailing;
  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final bool isLink;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        width: MediaQuery.of(context).size.width,
        color: CupertinoColors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (leading != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: leading!,
                ),
              ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[title, if (subtitle != null) subtitle!],
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: trailing!,
              ),
            if (isLink)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  CupertinoIcons.right_chevron,
                  color: CupertinoColors.inactiveGray,
                ),
              )
          ],
        ),
      ),
    );
  }
}
