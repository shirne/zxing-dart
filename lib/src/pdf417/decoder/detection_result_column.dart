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

/// @author Guenther Grau
class DetectionResultColumn {
  static const int _maxNearbyDistance = 5;

  final BoundingBox _boundingBox;
  final List<Codeword?> _codewords;

  DetectionResultColumn(BoundingBox boundingBox)
      : _boundingBox = BoundingBox.copy(boundingBox),
        _codewords = List.filled(boundingBox.maxY - boundingBox.minY + 1, null);

  Codeword? getCodewordNearby(int imageRow) {
    Codeword? codeword = getCodeword(imageRow);
    if (codeword != null) {
      return codeword;
    }
    for (int i = 1; i < _maxNearbyDistance; i++) {
      int nearImageRow = imageRowToCodewordIndex(imageRow) - i;
      if (nearImageRow >= 0) {
        codeword = _codewords[nearImageRow];
        if (codeword != null) {
          return codeword;
        }
      }
      nearImageRow = imageRowToCodewordIndex(imageRow) + i;
      if (nearImageRow < _codewords.length) {
        codeword = _codewords[nearImageRow];
        if (codeword != null) {
          return codeword;
        }
      }
    }
    return null;
  }

  int imageRowToCodewordIndex(int imageRow) {
    return imageRow - _boundingBox.minY;
  }

  void setCodeword(int imageRow, Codeword codeword) {
    _codewords[imageRowToCodewordIndex(imageRow)] = codeword;
  }

  Codeword? getCodeword(int imageRow) {
    return _codewords[imageRowToCodewordIndex(imageRow)];
  }

  BoundingBox get boundingBox => _boundingBox;

  List<Codeword?> get codewords => _codewords;

  @override
  String toString() {
    final formatter = StringBuffer();
    int row = 0;
    for (Codeword? codeword in _codewords) {
      if (codeword == null) {
        formatter.write('${(row++).toString().padLeft(3)}:    |   \n');
        continue;
      }
      formatter.write(
        '${(row++).toString().padLeft(3)}: '
        '${codeword.rowNumber.toString().padLeft(3)}|'
        '${codeword.value.toString().padLeft(3)}\n',
      );
    }
    return formatter.toString();
  }
}
