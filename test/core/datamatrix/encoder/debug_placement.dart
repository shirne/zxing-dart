/*
 * Copyright 2006 Jeremias Maerki
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

import 'package:zxing/datamatrix.dart';

class DebugPlacement extends DefaultPlacement {

  DebugPlacement(String codewords, int numcols, int numrows):super(codewords, numcols, numrows);

  List<String> toBitFieldStringArray() {
    Uint8List bits = getBits();      
    int numrows = getNumrows();
    int numcols = getNumcols();
    List<String> array = List.filled(numrows, '');
    int startpos = 0;
    for (int row = 0; row < numrows; row++) {
      StringBuffer sb = new StringBuffer(bits.length);
      for (int i = 0; i < numcols; i++) {
        sb.write(bits[startpos + i] == 1 ? '1' : '0');
      }
      array[row] = sb.toString();
      startpos += numcols;
    }
    return array;
  }

}
