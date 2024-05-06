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

import 'dart:core';
import 'dart:math' as math;

import '../../../decode_hint.dart';
import '../../../not_found_exception.dart';
import '../../../qrcode/detector/finder_pattern.dart';
import '../../../qrcode/detector/finder_pattern_finder.dart';
import '../../../qrcode/detector/finder_pattern_info.dart';
import '../../../result_point.dart';

/// This class attempts to find finder patterns in a QR Code. Finder patterns are the square
/// markers at three corners of a QR Code.
///
/// This class is thread-safe but not reentrant. Each thread must allocate its own object.
///
/// In contrast to [FinderPatternFinder], this class will return an array of all possible
/// QR code locations in the image.
///
/// Use the TRY_HARDER hint to ask for a more thorough detection.
///
/// @author Sean Owen
/// @author Hannes Erven
class MultiFinderPatternFinder extends FinderPatternFinder {
  static final List<FinderPatternInfo> _emptyResultArray = [];
  //static final List<FinderPattern> _emptyFpArray = [];
  //static final List<List<FinderPattern>> _emptyFp2dArray = [];

  // TODO MIN_MODULE_COUNT and MAX_MODULE_COUNT would be great hints to ask the user for
  // since it limits the number of regions to decode

  // max. legal count of modules per QR code edge (177)
  static const double _maxModuleCountPerEdge = 180;
  // min. legal count per modules per QR code edge (11)
  static const double _minModuleCountPerEdge = 9;

  /// More or less arbitrary cutoff point for determining if two finder patterns might belong
  /// to the same code if they differ less than DIFF_MODSIZE_CUTOFF_PERCENT percent in their
  /// estimated modules sizes.
  static const double _diffModsizeCutoffPercent = 0.05;

  /// More or less arbitrary cutoff point for determining if two finder patterns might belong
  /// to the same code if they differ less than DIFF_MODSIZE_CUTOFF pixels/module in their
  /// estimated modules sizes.
  static const double _diffModsizeCutoff = 0.5;

  MultiFinderPatternFinder(
    super.image,
    super.resultPointCallback,
  );

  int _compare(FinderPattern? center1, FinderPattern? center2) {
    if (center1 == null) return center2 == null ? 0 : -1;
    if (center2 == null) return 1;
    final value = center2.estimatedModuleSize - center1.estimatedModuleSize;
    return value < 0.0
        ? -1
        : value > 0.0
            ? 1
            : 0;
  }

  /// @return the 3 best [FinderPattern]s from our list of candidates. The "best" are
  ///         those that have been detected at least 2 times, and whose module
  ///         size differs from the average among those patterns the least
  /// @throws NotFoundException if 3 such finder patterns do not exist
  List<List<FinderPattern>> _selectMultipleBestPatterns() {
    final possibleCenters =
        this.possibleCenters.where((fp) => fp.count >= 2).toList();
    final size = possibleCenters.length;

    if (size < 3) {
      // Couldn't find enough finder patterns
      throw NotFoundException.instance;
    }

    /*
     * Begin HE modifications to safely detect multiple codes of equal size
     */
    if (size == 3) {
      return [possibleCenters.toList()];
    }

    // Sort by estimated module size to speed up the upcoming checks
    possibleCenters.sort(_compare);
    //Collections.sort(possibleCenters, ModuleSizeComparator());

    /*
     * Now lets start: build a list of tuples of three finder locations that
     *  - feature similar module sizes
     *  - are placed in a distance so the estimated module count is within the QR specification
     *  - have similar distance between upper left/right and left top/bottom finder patterns
     *  - form a triangle with 90° angle (checked by comparing top right/bottom left distance
     *    with pythagoras)
     *
     * Note: we allow each point to be used for more than one code region: this might seem
     * counterintuitive at first, but the performance penalty is not that big. At this point,
     * we cannot make a good quality decision whether the three finders actually represent
     * a QR code, or are just by chance laid out so it looks like there might be a QR code there.
     * So, if the layout seems right, lets have the decoder try to decode.
     */

    final results = <List<FinderPattern>>[]; // holder for the results

    for (int i1 = 0; i1 < (size - 2); i1++) {
      final p1 = possibleCenters[i1];
      //if (p1 == null) {
      //  continue;
      //}

      for (int i2 = i1 + 1; i2 < (size - 1); i2++) {
        final p2 = possibleCenters[i2];
        //if (p2 == null) {
        //  continue;
        //}

        // Compare the expected module sizes; if they are really off, skip
        final vModSize12 = (p1.estimatedModuleSize - p2.estimatedModuleSize) /
            math.min(p1.estimatedModuleSize, p2.estimatedModuleSize);
        final vModSize12A =
            (p1.estimatedModuleSize - p2.estimatedModuleSize).abs();
        if (vModSize12A > _diffModsizeCutoff &&
            vModSize12 >= _diffModsizeCutoffPercent) {
          // break, since elements are ordered by the module size deviation there cannot be
          // any more interesting elements for the given p1.
          break;
        }

        for (int i3 = i2 + 1; i3 < size; i3++) {
          final p3 = possibleCenters[i3];
          //if (p3 == null) {
          //  continue;
          //}

          // Compare the expected module sizes; if they are really off, skip
          final vModSize23 = (p2.estimatedModuleSize - p3.estimatedModuleSize) /
              math.min(p2.estimatedModuleSize, p3.estimatedModuleSize);
          final vModSize23A =
              (p2.estimatedModuleSize - p3.estimatedModuleSize).abs();
          if (vModSize23A > _diffModsizeCutoff &&
              vModSize23 >= _diffModsizeCutoffPercent) {
            // break, since elements are ordered by the module size deviation there cannot be
            // any more interesting elements for the given p1.
            break;
          }

          final test = [p1, p2, p3];
          ResultPoint.orderBestPatterns(test);

          // Calculate the distances: a = topleft-bottomleft, b=topleft-topright, c = diagonal
          final info = FinderPatternInfo(test);
          final dA = ResultPoint.distance(info.topLeft, info.bottomLeft);
          final dC = ResultPoint.distance(info.topRight, info.bottomLeft);
          final dB = ResultPoint.distance(info.topLeft, info.topRight);

          // Check the sizes
          final estimatedModuleCount =
              (dA + dB) / (p1.estimatedModuleSize * 2.0);
          if (estimatedModuleCount > _maxModuleCountPerEdge ||
              estimatedModuleCount < _minModuleCountPerEdge) {
            continue;
          }

          // Calculate the difference of the edge lengths in percent
          final vABBC = ((dA - dB) / math.min(dA, dB)).abs();
          if (vABBC >= 0.1) {
            continue;
          }

          // Calculate the diagonal length by assuming a 90° angle at topleft
          final dCpy = math.sqrt(dA * dA + dB * dB);
          // Compare to the real distance in %
          final vPyC = ((dC - dCpy) / math.min(dC, dCpy)).abs();

          if (vPyC >= 0.1) {
            continue;
          }

          // All tests passed!
          results.add(test);
        }
      }
    }

    if (results.isNotEmpty) {
      return results;
    }

    // Nothing found!
    throw NotFoundException.instance;
  }

  List<FinderPatternInfo> findMulti(DecodeHint? hints) {
    final tryHarder = hints?.tryHarder ?? false;
    final maxI = image.height;
    final maxJ = image.width;
    // We are looking for black/white/black/white/black modules in
    // 1:1:3:1:1 ratio; this tracks the number of such modules seen so far

    // Let's assume that the maximum version QR Code we support takes up 1/4 the height of the
    // image, and then account for the center being 3 modules in size. This gives the smallest
    // number of pixels the center could be, so skip this often. When trying harder, look for all
    // QR versions regardless of how dense they are.
    int iSkip = (3 * maxI) ~/ (4 * FinderPatternFinder.maxModules);
    if (iSkip < FinderPatternFinder.minSkip || tryHarder) {
      iSkip = FinderPatternFinder.minSkip;
    }

    final stateCount = [0, 0, 0, 0, 0];
    for (int i = iSkip - 1; i < maxI; i += iSkip) {
      // Get a row of black/white values
      FinderPatternFinder.doClearCounts(stateCount);
      int currentState = 0;
      for (int j = 0; j < maxJ; j++) {
        if (image.get(j, i)) {
          // Black pixel
          if ((currentState & 1) == 1) {
            // Counting white pixels
            currentState++;
          }
          stateCount[currentState]++;
        } else {
          // White pixel
          if ((currentState & 1) == 0) {
            // Counting black pixels
            if (currentState == 4) {
              // A winner?
              if (FinderPatternFinder.foundPatternCross(stateCount) &&
                  handlePossibleCenter(stateCount, i, j)) {
                // Yes
                // Clear state to start looking again
                currentState = 0;
                FinderPatternFinder.doClearCounts(stateCount);
              } else {
                // No, shift counts back by two
                FinderPatternFinder.doShiftCounts2(stateCount);
                currentState = 3;
              }
            } else {
              stateCount[++currentState]++;
            }
          } else {
            // Counting white pixels
            stateCount[currentState]++;
          }
        }
      } // for j=...

      if (FinderPatternFinder.foundPatternCross(stateCount)) {
        handlePossibleCenter(stateCount, i, maxJ);
      }
    } // for i=iSkip-1 ...
    final patternInfo = _selectMultipleBestPatterns();
    final result = <FinderPatternInfo>[];
    for (List<FinderPattern> pattern in patternInfo) {
      ResultPoint.orderBestPatterns(pattern);
      result.add(FinderPatternInfo(pattern));
    }

    if (result.isEmpty) {
      return _emptyResultArray;
    } else {
      return result.toList();
    }
  }
}
