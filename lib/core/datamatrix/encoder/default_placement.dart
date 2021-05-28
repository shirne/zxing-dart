/*
 * Copyright 2006 Jeremias Maerki.
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

import 'dart:typed_data';

/**
 * Symbol Character Placement Program. Adapted from Annex M.1 in ISO/IEC 16022:2000(E).
 */
class DefaultPlacement {
  final String codewords;
  final int numrows;
  final int numcols;
  final Uint8List bits;

  /**
   * Main constructor
   *
   * @param codewords the codewords to place
   * @param numcols   the number of columns
   * @param numrows   the number of rows
   */
  DefaultPlacement(this.codewords, this.numcols, this.numrows)
      : this.bits =
            Uint8List.fromList(List.generate(numcols * numrows, (index) => -1));

  int getNumrows() {
    return numrows;
  }

  int getNumcols() {
    return numcols;
  }

  Uint8List getBits() {
    return bits;
  }

  bool getBit(int col, int row) {
    return bits[row * numcols + col] == 1;
  }

  void setBit(int col, int row, bool bit) {
    bits[row * numcols + col] = (bit ? 1 : 0);
  }

  bool noBit(int col, int row) {
    return bits[row * numcols + col] < 0;
  }

  void place() {
    int pos = 0;
    int row = 4;
    int col = 0;

    do {
      // repeatedly first check for one of the special corner cases, then...
      if ((row == numrows) && (col == 0)) {
        corner1(pos++);
      }
      if ((row == numrows - 2) && (col == 0) && ((numcols % 4) != 0)) {
        corner2(pos++);
      }
      if ((row == numrows - 2) && (col == 0) && (numcols % 8 == 4)) {
        corner3(pos++);
      }
      if ((row == numrows + 4) && (col == 2) && ((numcols % 8) == 0)) {
        corner4(pos++);
      }
      // sweep upward diagonally, inserting successive characters...
      do {
        if ((row < numrows) && (col >= 0) && noBit(col, row)) {
          utah(row, col, pos++);
        }
        row -= 2;
        col += 2;
      } while (row >= 0 && (col < numcols));
      row++;
      col += 3;

      // and then sweep downward diagonally, inserting successive characters, ...
      do {
        if ((row >= 0) && (col < numcols) && noBit(col, row)) {
          utah(row, col, pos++);
        }
        row += 2;
        col -= 2;
      } while ((row < numrows) && (col >= 0));
      row += 3;
      col++;

      // ...until the entire array is scanned
    } while ((row < numrows) || (col < numcols));

    // Lastly, if the lower right-hand corner is untouched, fill in fixed pattern
    if (noBit(numcols - 1, numrows - 1)) {
      setBit(numcols - 1, numrows - 1, true);
      setBit(numcols - 2, numrows - 2, true);
    }
  }

  void module(int row, int col, int pos, int bit) {
    if (row < 0) {
      row += numrows;
      col += 4 - ((numrows + 4) % 8);
    }
    if (col < 0) {
      col += numcols;
      row += 4 - ((numcols + 4) % 8);
    }
    // Note the conversion:
    int v = codewords.codeUnitAt(pos);
    v &= 1 << (8 - bit);
    setBit(col, row, v != 0);
  }

  /**
   * Places the 8 bits of a utah-shaped symbol character in ECC200.
   *
   * @param row the row
   * @param col the column
   * @param pos character position
   */
  void utah(int row, int col, int pos) {
    module(row - 2, col - 2, pos, 1);
    module(row - 2, col - 1, pos, 2);
    module(row - 1, col - 2, pos, 3);
    module(row - 1, col - 1, pos, 4);
    module(row - 1, col, pos, 5);
    module(row, col - 2, pos, 6);
    module(row, col - 1, pos, 7);
    module(row, col, pos, 8);
  }

  void corner1(int pos) {
    module(numrows - 1, 0, pos, 1);
    module(numrows - 1, 1, pos, 2);
    module(numrows - 1, 2, pos, 3);
    module(0, numcols - 2, pos, 4);
    module(0, numcols - 1, pos, 5);
    module(1, numcols - 1, pos, 6);
    module(2, numcols - 1, pos, 7);
    module(3, numcols - 1, pos, 8);
  }

  void corner2(int pos) {
    module(numrows - 3, 0, pos, 1);
    module(numrows - 2, 0, pos, 2);
    module(numrows - 1, 0, pos, 3);
    module(0, numcols - 4, pos, 4);
    module(0, numcols - 3, pos, 5);
    module(0, numcols - 2, pos, 6);
    module(0, numcols - 1, pos, 7);
    module(1, numcols - 1, pos, 8);
  }

  void corner3(int pos) {
    module(numrows - 3, 0, pos, 1);
    module(numrows - 2, 0, pos, 2);
    module(numrows - 1, 0, pos, 3);
    module(0, numcols - 2, pos, 4);
    module(0, numcols - 1, pos, 5);
    module(1, numcols - 1, pos, 6);
    module(2, numcols - 1, pos, 7);
    module(3, numcols - 1, pos, 8);
  }

  void corner4(int pos) {
    module(numrows - 1, 0, pos, 1);
    module(numrows - 1, numcols - 1, pos, 2);
    module(0, numcols - 3, pos, 3);
    module(0, numcols - 2, pos, 4);
    module(0, numcols - 1, pos, 5);
    module(1, numcols - 3, pos, 6);
    module(1, numcols - 2, pos, 7);
    module(1, numcols - 1, pos, 8);
  }
}
