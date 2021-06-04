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

/// Symbol Character Placement Program. Adapted from Annex M.1 in ISO/IEC 16022:2000(E).
class DefaultPlacement {
  final String _codewords;
  final int _numrows;
  final int _numcols;
  final Int8List _bits;

  /// Main constructor
  ///
  /// @param codewords the codewords to place
  /// @param numcols   the number of columns
  /// @param numrows   the number of rows
  DefaultPlacement(this._codewords, this._numcols, this._numrows)
      : this._bits =
  Int8List.fromList(List.filled(_numcols * _numrows, -1));

  int getNumrows() {
    return _numrows;
  }

  int getNumcols() {
    return _numcols;
  }

  Int8List getBits() {
    return _bits;
  }

  bool getBit(int col, int row) {
    return _bits[row * _numcols + col] == 1;
  }

  void _setBit(int col, int row, bool bit) {
    _bits[row * _numcols + col] = (bit ? 1 : 0);
  }

  bool _noBit(int col, int row) {
    return _bits[row * _numcols + col] < 0;
  }

  void place() {
    int pos = 0;
    int row = 4;
    int col = 0;

    do {
      // repeatedly first check for one of the special corner cases, then...
      if ((row == _numrows) && (col == 0)) {
        _corner1(pos++);
      }
      if ((row == _numrows - 2) && (col == 0) && ((_numcols % 4) != 0)) {
        _corner2(pos++);
      }
      if ((row == _numrows - 2) && (col == 0) && (_numcols % 8 == 4)) {
        _corner3(pos++);
      }
      if ((row == _numrows + 4) && (col == 2) && ((_numcols % 8) == 0)) {
        _corner4(pos++);
      }
      // sweep upward diagonally, inserting successive characters...
      do {
        if ((row < _numrows) && (col >= 0) && _noBit(col, row)) {
          _utah(row, col, pos++);
        }
        row -= 2;
        col += 2;
      } while (row >= 0 && (col < _numcols));
      row++;
      col += 3;

      // and then sweep downward diagonally, inserting successive characters, ...
      do {
        if ((row >= 0) && (col < _numcols) && _noBit(col, row)) {
          _utah(row, col, pos++);
        }
        row += 2;
        col -= 2;
      } while ((row < _numrows) && (col >= 0));
      row += 3;
      col++;

      // ...until the entire array is scanned
    } while ((row < _numrows) || (col < _numcols));

    // Lastly, if the lower right-hand corner is untouched, fill in fixed pattern
    if (_noBit(_numcols - 1, _numrows - 1)) {
      _setBit(_numcols - 1, _numrows - 1, true);
      _setBit(_numcols - 2, _numrows - 2, true);
    }
  }

  void _module(int row, int col, int pos, int bit) {
    if (row < 0) {
      row += _numrows;
      col += 4 - ((_numrows + 4) % 8);
    }
    if (col < 0) {
      col += _numcols;
      row += 4 - ((_numcols + 4) % 8);
    }
    // Note the conversion:
    int v = _codewords.codeUnitAt(pos);
    v &= 1 << (8 - bit);
    _setBit(col, row, v != 0);
  }

  /// Places the 8 bits of a utah-shaped symbol character in ECC200.
  ///
  /// @param row the row
  /// @param col the column
  /// @param pos character position
  void _utah(int row, int col, int pos) {
    _module(row - 2, col - 2, pos, 1);
    _module(row - 2, col - 1, pos, 2);
    _module(row - 1, col - 2, pos, 3);
    _module(row - 1, col - 1, pos, 4);
    _module(row - 1, col, pos, 5);
    _module(row, col - 2, pos, 6);
    _module(row, col - 1, pos, 7);
    _module(row, col, pos, 8);
  }

  void _corner1(int pos) {
    _module(_numrows - 1, 0, pos, 1);
    _module(_numrows - 1, 1, pos, 2);
    _module(_numrows - 1, 2, pos, 3);
    _module(0, _numcols - 2, pos, 4);
    _module(0, _numcols - 1, pos, 5);
    _module(1, _numcols - 1, pos, 6);
    _module(2, _numcols - 1, pos, 7);
    _module(3, _numcols - 1, pos, 8);
  }

  void _corner2(int pos) {
    _module(_numrows - 3, 0, pos, 1);
    _module(_numrows - 2, 0, pos, 2);
    _module(_numrows - 1, 0, pos, 3);
    _module(0, _numcols - 4, pos, 4);
    _module(0, _numcols - 3, pos, 5);
    _module(0, _numcols - 2, pos, 6);
    _module(0, _numcols - 1, pos, 7);
    _module(1, _numcols - 1, pos, 8);
  }

  void _corner3(int pos) {
    _module(_numrows - 3, 0, pos, 1);
    _module(_numrows - 2, 0, pos, 2);
    _module(_numrows - 1, 0, pos, 3);
    _module(0, _numcols - 2, pos, 4);
    _module(0, _numcols - 1, pos, 5);
    _module(1, _numcols - 1, pos, 6);
    _module(2, _numcols - 1, pos, 7);
    _module(3, _numcols - 1, pos, 8);
  }

  void _corner4(int pos) {
    _module(_numrows - 1, 0, pos, 1);
    _module(_numrows - 1, _numcols - 1, pos, 2);
    _module(0, _numcols - 3, pos, 3);
    _module(0, _numcols - 2, pos, 4);
    _module(0, _numcols - 1, pos, 5);
    _module(1, _numcols - 3, pos, 6);
    _module(1, _numcols - 2, pos, 7);
    _module(1, _numcols - 1, pos, 8);
  }
}
