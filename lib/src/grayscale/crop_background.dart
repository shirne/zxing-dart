import 'dart:typed_data';

import 'dispatch.dart';

class CropBackground extends Dispatch {
  final double tolerance;
  final double purity;
  final int wrapper;

  CropBackground({
    this.tolerance = 0.05,
    this.purity = 0.99,
    this.wrapper = 255,
  });

  int? lastColor;

  Rect? _cropRect;

  @override
  Rect? get cropRect => _cropRect;

  bool checkLine(List<int> line) {
    final groups = <int, int>{};
    // 统计颜色
    for (var i in line) {
      if (lastColor != null) {
        if (i == lastColor || (i - lastColor!).abs() / 255 < tolerance) {
          groups[lastColor!] = (groups[lastColor] ?? 0) + 1;
        }
      } else {
        if (groups.containsKey(i)) {
          groups[i] = groups[i]! + 1;
        } else {
          groups[i] = 1;
        }
      }
    }

    if (groups.isEmpty) return false;

    // 尝试合并颜色
    if (groups.length > 1) {
      final sorted = groups.entries.toList()
        ..sort((e, e2) => e.value - e2.value);
      final first = sorted.removeAt(0);
      if (first.value < purity * line.length) {
        if (tolerance == 0) {
          return false;
        }
        int count = first.value;
        for (var e in sorted) {
          if ((e.key - first.key).abs() / 255 <= tolerance) {
            count += e.value;
          }
        }
        final passed = count / line.length > purity;
        if (passed && lastColor == null) {
          lastColor = first.key;
        }
        return passed;
      }
    }
    if (lastColor == null) {
      lastColor ??= groups.keys.first;
      return true;
    } else {
      return groups.values.first / line.length > purity;
    }
  }

  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    int cropTop = 0, cropLeft = 0, cropRight = 0, cropBottom = 0;
    final minSize = 10;
    // 垂直裁剪
    for (int i = 0; i < height - minSize; i++) {
      if (checkLine(data.getRange(i * width, (i + 1) * width).toList())) {
        cropTop++;
      } else {
        break;
      }
    }
    for (int i = height - 1; i > cropTop + minSize; i--) {
      if (checkLine(data.getRange(i * width, (i + 1) * width).toList())) {
        cropBottom++;
      } else {
        break;
      }
    }
    final newHeight = height - cropBottom - cropTop;

    // 横向裁剪
    for (int i = 0; i < width - minSize; i++) {
      if (checkLine(
        List.generate(newHeight, (l) => data[(l + cropTop) * width + i]),
      )) {
        cropLeft++;
      } else {
        break;
      }
    }
    for (int i = width - 1; i > cropLeft + minSize; i--) {
      if (checkLine(
        List.generate(newHeight, (l) => data[(l + cropTop) * width + i]),
      )) {
        cropRight++;
      } else {
        break;
      }
    }

    if (cropTop > 0 || cropLeft > 0 || cropRight > 0 || cropBottom > 0) {
      _cropRect =
          Rect(cropLeft, cropTop, width - cropRight, height - cropBottom);

      final newWidth = _cropRect!.width;
      final newHeight = _cropRect!.height;

      // math.max(math.min(newWidth, newHeight) * 0.1, 10).round();
      final padding = 0;
      final newData = Uint8List(
        (newWidth + padding * 2) * (newHeight + padding * 2),
      );
      //newData.fillRange(0, newData.length, wrapper);
      for (int i = 0; i < newHeight; i++) {
        final start = (i + cropTop) * width + cropLeft;
        List.copyRange(
          newData,
          (i + padding) * newWidth + padding,
          data,
          start,
          start + newWidth,
        );
      }
      lastColor = null;
      return newData;
    }
    return data;
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    return data;
  }
}
