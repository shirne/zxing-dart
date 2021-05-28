/*
 * Copyright 2013 ZXing authors
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

import 'bounding_box.dart';
import 'codeword.dart';

/**
 * @author Guenther Grau
 */
class DetectionResultColumn {
  static final int MAX_NEARBY_DISTANCE = 5;

  final BoundingBox boundingBox;
  final List<Codeword?> codewords;

  DetectionResultColumn(BoundingBox boundingBox)
      : this.boundingBox = BoundingBox.copy(boundingBox),
        codewords = List.filled(
            boundingBox.getMaxY() - boundingBox.getMinY() + 1, null);

  Codeword? getCodewordNearby(int imageRow) {
    Codeword? codeword = getCodeword(imageRow);
    if (codeword != null) {
      return codeword;
    }
    for (int i = 1; i < MAX_NEARBY_DISTANCE; i++) {
      int nearImageRow = imageRowToCodewordIndex(imageRow) - i;
      if (nearImageRow >= 0) {
        codeword = codewords[nearImageRow];
        if (codeword != null) {
          return codeword;
        }
      }
      nearImageRow = imageRowToCodewordIndex(imageRow) + i;
      if (nearImageRow < codewords.length) {
        codeword = codewords[nearImageRow];
        if (codeword != null) {
          return codeword;
        }
      }
    }
    return null;
  }

  int imageRowToCodewordIndex(int imageRow) {
    return imageRow - boundingBox.getMinY();
  }

  void setCodeword(int imageRow, Codeword codeword) {
    codewords[imageRowToCodewordIndex(imageRow)] = codeword;
  }

  Codeword? getCodeword(int imageRow) {
    return codewords[imageRowToCodewordIndex(imageRow)];
  }

  BoundingBox getBoundingBox() {
    return boundingBox;
  }

  List<Codeword?> getCodewords() {
    return codewords;
  }

  @override
  String toString() {
    try {
      StringBuffer formatter = StringBuffer();
      int row = 0;
      for (Codeword? codeword in codewords) {
        if (codeword == null) {
          formatter.write("${(row++).toString()}:    |   \n");
          continue;
        }
        formatter.write(
            "${row++}: ${codeword.getRowNumber()}|${codeword.getValue()}\n");
      }
      return formatter.toString();
    } catch (e) {}
    return '';
  }
}
