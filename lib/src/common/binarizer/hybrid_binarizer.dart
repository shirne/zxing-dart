/*
 * Copyright 2009 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:math' as math;
import 'dart:typed_data';

import '../../binarizer.dart';
import '../../luminance_source.dart';
import '../bit_matrix.dart';
import 'global_histogram_binarizer.dart';

/// This class implements a local thresholding algorithm, which while slower than the
/// GlobalHistogramBinarizer, is fairly efficient for what it does.
///
/// It is designed for high frequency images of barcodes with black data on white backgrounds.
/// For this application, it does a much better job than a global blackpoint with severe shadows and gradients.
/// However it tends to produce artifacts on lower frequency images and is therefore not
/// a good general purpose binarizer for uses outside ZXing.
///
/// This class extends GlobalHistogramBinarizer, using the older histogram approach for 1D readers,
/// and the newer local approach for 2D readers. 1D decoding using a per-row histogram is already
/// inherently local, and only fails for horizontal gradients. We can revisit that problem later,
/// but for now it was not a win to use local blocks for 1D.
///
/// This Binarizer is the default for the unit tests and the recommended class for library users.
///
/// @author dswitkin@google.com (Daniel Switkin)
class HybridBinarizer extends GlobalHistogramBinarizer {
  // This class uses 5x5 blocks to compute local luminance, where each block is 8x8 pixels.
  // So this is the smallest dimension in each axis we can accept.
  static const int blockSizePower = 3;
  static const int blockSize = 1 << blockSizePower; // ...0100...00
  static const int blockSizeMask = blockSize - 1; // ...0011...11
  static const int minimumDimension = blockSize * 5;
  static const int minDynamicRange = 24;

  BitMatrix? _matrix;

  HybridBinarizer(super.source);

  /// Calculates the final BitMatrix once for all requests. This could be called once from the
  /// constructor instead, but there are some advantages to doing it lazily, such as making
  /// profiling easier, and not doing heavy lifting when callers don't expect it.
  @override
  BitMatrix get blackMatrix {
    if (_matrix != null) {
      return _matrix!;
    }
    final source = luminanceSource;
    final width = source.width;
    final height = source.height;
    if (width >= minimumDimension && height >= minimumDimension) {
      final luminances = source.matrix;
      int subWidth = width >> blockSizePower;
      if ((width & blockSizeMask) != 0) {
        subWidth++;
      }
      int subHeight = height >> blockSizePower;
      if ((height & blockSizeMask) != 0) {
        subHeight++;
      }
      final blackPoints =
          _calculateBlackPoints(luminances, subWidth, subHeight, width, height);

      final newMatrix = BitMatrix(width, height);
      _calculateThresholdForBlock(
        luminances,
        subWidth,
        subHeight,
        width,
        height,
        blackPoints,
        newMatrix,
      );
      _matrix = newMatrix;
    } else {
      // If the image is too small, fall back to the global histogram approach.
      _matrix = super.blackMatrix;
    }
    return _matrix!;
  }

  @override
  Binarizer createBinarizer(LuminanceSource source) {
    return HybridBinarizer(source);
  }

  /// For each block in the image, calculate the average black point using a 5x5 grid
  /// of the blocks around it. Also handles the corner cases (fractional blocks are computed based
  /// on the last pixels in the row/column which are also used in the previous block).
  static void _calculateThresholdForBlock(
    Uint8List luminances,
    int subWidth,
    int subHeight,
    int width,
    int height,
    List<List<int>> blackPoints,
    BitMatrix matrix,
  ) {
    final maxYOffset = height - blockSize;
    final maxXOffset = width - blockSize;
    for (int y = 0; y < subHeight; y++) {
      int yOffset = y << blockSizePower;
      if (yOffset > maxYOffset) {
        yOffset = maxYOffset;
      }
      final top = _cap(y, subHeight - 3);
      for (int x = 0; x < subWidth; x++) {
        int xOffset = x << blockSizePower;
        if (xOffset > maxXOffset) {
          xOffset = maxXOffset;
        }
        final left = _cap(x, subWidth - 3);
        int sum = 0;
        for (int z = -2; z <= 2; z++) {
          final blackRow = blackPoints[top + z];
          sum += blackRow[left - 2] +
              blackRow[left - 1] +
              blackRow[left] +
              blackRow[left + 1] +
              blackRow[left + 2];
        }
        final average = sum ~/ 25;
        _thresholdBlock(luminances, xOffset, yOffset, average, width, matrix);
      }
    }
  }

  static int _cap(int value, int max) {
    return value < 2 ? 2 : math.min(value, max);
  }

  /// Applies a single threshold to a block of pixels.
  static void _thresholdBlock(
    Uint8List luminances,
    int xoffset,
    int yoffset,
    int threshold,
    int stride,
    BitMatrix matrix,
  ) {
    for (int y = 0, offset = yoffset * stride + xoffset;
        y < blockSize;
        y++, offset += stride) {
      for (int x = 0; x < blockSize; x++) {
        // Comparison needs to be <= so that black == 0 pixels are black even if the threshold is 0.
        if (luminances[offset + x] <= threshold) {
          matrix.set(xoffset + x, yoffset + y);
        }
      }
    }
  }

  /// Calculates a single black point for each block of pixels and saves it away.
  /// See the following thread for a discussion of this algorithm:
  ///  http://groups.google.com/group/zxing/browse_thread/thread/d06efa2c35a7ddc0
  static List<List<int>> _calculateBlackPoints(
    Uint8List luminances,
    int subWidth,
    int subHeight,
    int width,
    int height,
  ) {
    final maxYOffset = height - blockSize;
    final maxXOffset = width - blockSize;
    final blackPoints =
        List.generate(subHeight, (index) => List.filled(subWidth, 0));
    for (int y = 0; y < subHeight; y++) {
      int yOffset = y << blockSizePower;
      if (yOffset > maxYOffset) {
        yOffset = maxYOffset;
      }
      for (int x = 0; x < subWidth; x++) {
        int xOffset = x << blockSizePower;
        if (xOffset > maxXOffset) {
          xOffset = maxXOffset;
        }
        int sum = 0;
        int min = 0xFF;
        int max = 0;
        for (int yy = 0, offset = yOffset * width + xOffset;
            yy < blockSize;
            yy++, offset += width) {
          for (int xx = 0; xx < blockSize; xx++) {
            final pixel = luminances[offset + xx];
            sum += pixel;
            // still looking for good contrast
            if (pixel < min) {
              min = pixel;
            }
            if (pixel > max) {
              max = pixel;
            }
          }
          // short-circuit min/max tests once dynamic range is met
          if (max - min > minDynamicRange) {
            // finish the rest of the rows quickly
            yy++;
            offset += width;
            for (; yy < blockSize; yy++, offset += width) {
              for (int xx = 0; xx < blockSize; xx++) {
                sum += luminances[offset + xx];
              }
            }
          }
        }

        // The default estimate is the average of the values in the block.
        int average = sum >> (blockSizePower * 2);
        if (max - min <= minDynamicRange) {
          // If variation within the block is low, assume this is a block with only light or only
          // dark pixels. In that case we do not want to use the average, as it would divide this
          // low contrast area into black and white pixels, essentially creating data out of noise.
          //
          // The default assumption is that the block is light/background. Since no estimate for
          // the level of dark pixels exists locally, use half the min for the block.
          average = min ~/ 2;

          if (y > 0 && x > 0) {
            // Correct the "white background" assumption for blocks that have neighbors by comparing
            // the pixels in this block to the previously calculated black points. This is based on
            // the fact that dark barcode symbology is always surrounded by some amount of light
            // background for which reasonable black point estimates were made. The bp estimated at
            // the boundaries is used for the interior.

            // The (min < bp) is arbitrary but works better than other heuristics that were tried.
            final averageNeighborBlackPoint = (blackPoints[y - 1][x] +
                    (2 * blackPoints[y][x - 1]) +
                    blackPoints[y - 1][x - 1]) ~/
                4;
            if (min < averageNeighborBlackPoint) {
              average = averageNeighborBlackPoint;
            }
          }
        }
        blackPoints[y][x] = average;
      }
    }
    return blackPoints;
  }
}
