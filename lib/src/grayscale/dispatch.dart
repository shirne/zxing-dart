import 'dart:typed_data';

class Rect {
  final int top;
  final int bottom;
  final int left;
  final int right;

  Rect([this.left = 0, this.top = 0, this.right = 0, this.bottom = 0])
      : assert(right >= left && bottom >= top);

  int get width => right - left;
  int get height => bottom - top;

  @override
  String toString() => 'Rect($left, $top, $right, $bottom)';
}

abstract class Dispatch {
  const Dispatch();
  Uint8List dispatch(
    Uint8List data,
    int width,
    int height, [
    Rect? rect,
  ]) {
    if (rect == null) {
      return dispatchFull(data, width, height);
    }
    return dispatchRect(data, width, height, rect);
  }

  Uint8List dispatchFull(Uint8List data, int width, int height);
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect);

  Rect? get cropRect => null;
}
