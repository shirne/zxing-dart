import 'dart:math' as math;
import 'dart:typed_data';

import 'dispatch.dart';
import 'interrupt_grayscale.dart';
import 'light_grayscale.dart';
import 'over_bright_scale.dart';
import 'over_dark_scale.dart';
import 'rev_grayscale.dart';

class GrayscaleDispatch extends Dispatch {
  static const grayScaleProcess = <Dispatch>[
    LightGrayscale(),
    OverBrightScale(),
    OverDarkScale(),
    RevGrayscale(),
    //OverlyGrayScale(),
    InterruptGrayscale(),
    //ReductionAreaScale(this),
  ];

  static final random = math.Random();

  @override
  Uint8List dispatchFull(Uint8List data, int width, int height) {
    return grayScaleProcess[random.nextInt(grayScaleProcess.length)]
        .dispatch(data, width, height);
  }

  @override
  Uint8List dispatchRect(Uint8List data, int width, int height, Rect rect) {
    if ((rect.left == 0 && rect.right == 0) ||
        (rect.top == 0 && rect.bottom == 0)) {
      return dispatch(data, width, height);
    }
    return grayScaleProcess[random.nextInt(grayScaleProcess.length)]
        .dispatch(data, width, height, rect);
  }
}
