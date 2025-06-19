import 'dart:typed_data';

import 'dispatch.dart';

class CropBackground extends Dispatch {
  final double tolerance;
  final double purity;
  final int cropIn;

  CropBackground({
    this.tolerance = 0.05,
    this.purity = 0.99,
    this.cropIn = 5,
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

  void cropData(Uint8List data, int width, int height) {
    // 顶
    for (int i = 0; i < width; i++) {
      final deepInColor = data[cropIn * width + i];
      if ((deepInColor - lastColor!).abs() / 255 > tolerance) {
        for (int j = 0; j < cropIn; j++) {
          data[j * width + i] = deepInColor;
        }
      }
    }

    // 底
    for (int i = 0; i < width; i++) {
      final deepInColor = data[(height - cropIn - 1) * width + i];
      if ((deepInColor - lastColor!).abs() / 255 > tolerance) {
        for (int j = 1; j <= cropIn; j++) {
          data[(height - j) * width + i] = deepInColor;
        }
      }
    }

    // 左
    for (int i = 0; i < height; i++) {
      final deepInColor = data[i * width + cropIn];
      if ((deepInColor - lastColor!).abs() / 255 > tolerance) {
        for (int j = 0; j < cropIn; j++) {
          data[i * width + j] = deepInColor;
        }
      }
    }

    // 右
    for (int i = 0; i < height; i++) {
      final deepInColor = data[i * width + (width - cropIn - 1)];
      if ((deepInColor - lastColor!).abs() / 255 > tolerance) {
        for (int j = 1; j <= cropIn; j++) {
          data[i * width + (width - j)] = deepInColor;
        }
      }
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
      final newWidth = width - cropRight - cropLeft;
      final newHeight = height - cropBottom - cropTop;

      _cropRect = Rect(
        cropLeft,
        cropTop,
        width - cropRight,
        height - cropBottom,
      );

      final newData = Uint8List(newWidth * newHeight);
      //newData.fillRange(0, newData.length, wrapper);

      for (int i = 0; i < newHeight; i++) {
        final start = (i + cropTop) * width + cropLeft;
        List.copyRange(
          newData,
          i * newWidth,
          data,
          start,
          start + newWidth,
        );
      }
      if (cropIn > 0 && lastColor != null) {
        cropData(newData, newWidth, newHeight);
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
