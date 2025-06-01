import 'package:flutter/cupertino.dart';

class CupertinoIconButton extends StatelessWidget {
  final Widget? icon;
  final Color color;
  final BoxShape shape;
  final void Function()? onPressed;

  const CupertinoIconButton({
    super.key,
    this.icon,
    this.onPressed,
    this.color = const Color(0x00000000),
    this.shape = BoxShape.circle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(shape: shape, color: color),
        child: icon,
      ),
    );
  }
}
