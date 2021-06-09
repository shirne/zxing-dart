/*
 * Copyright 2007 ZXing authors
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

import '../not_found_exception.dart';
import 'bit_matrix.dart';
import 'grid_sampler.dart';
import 'perspective_transform.dart';

/// @author Sean Owen
class DefaultGridSampler extends GridSampler {
  @override
  BitMatrix sampleGridBulk(
      BitMatrix image,
      int dimensionX,
      int dimensionY,
      double p1ToX,
      double p1ToY,
      double p2ToX,
      double p2ToY,
      double p3ToX,
      double p3ToY,
      double p4ToX,
      double p4ToY,
      double p1FromX,
      double p1FromY,
      double p2FromX,
      double p2FromY,
      double p3FromX,
      double p3FromY,
      double p4FromX,
      double p4FromY) {
    PerspectiveTransform transform =
        PerspectiveTransform.quadrilateralToQuadrilateral(
            p1ToX,
            p1ToY,
            p2ToX,
            p2ToY,
            p3ToX,
            p3ToY,
            p4ToX,
            p4ToY,
            p1FromX,
            p1FromY,
            p2FromX,
            p2FromY,
            p3FromX,
            p3FromY,
            p4FromX,
            p4FromY);

    return sampleGrid(image, dimensionX, dimensionY, transform);
  }

  @override
  BitMatrix sampleGrid(BitMatrix image, int dimensionX, int dimensionY,
      PerspectiveTransform transform) {
    if (dimensionX <= 0 || dimensionY <= 0) {
      throw NotFoundException.instance;
    }
    BitMatrix bits = BitMatrix(dimensionX, dimensionY);
    List<double> points = List.filled(2 * dimensionX, 0);
    for (int y = 0; y < dimensionY; y++) {
      int max = points.length;
      double iValue = y + 0.5;
      for (int x = 0; x < max; x += 2) {
        points[x] = (x / 2) + 0.5;
        points[x + 1] = iValue;
      }
      transform.transformPoints(points);
      // Quick check to see if points transformed to something inside the image;
      // sufficient to check the endpoints
      GridSampler.checkAndNudgePoints(image, points);
      try {
        for (int x = 0; x < max; x += 2) {
          if (image.get(points[x].toInt(), points[x + 1].toInt())) {
            // Black(-ish) pixel
            bits.set(x ~/ 2, y);
          }
        }
      } catch (aioobe) {
        // on ArrayIndexOutOfBoundsException
        // This feels wrong, but, sometimes if the finder patterns are misidentified, the resulting
        // transform gets "twisted" such that it maps a straight line of points to a set of points
        // whose endpoints are in bounds, but others are not. There is probably some mathematical
        // way to detect this about the transformation that I don't know yet.
        // This results in an ugly runtime exception despite our clever checks above -- can't have
        // that. We could check each point's coordinates but that feels duplicative. We settle for
        // catching and wrapping ArrayIndexOutOfBoundsException.
        throw NotFoundException.instance;
      }
    }
    return bits;
  }
}
