/*
 * Copyright (C) 2010 ZXing authors
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

/*
 * These authors would like to acknowledge the Spanish Ministry of Industry,
 * Tourism and Trade, for the support in the project TSI020301-2008-2
 * "PIRAmIDE: Personalizable Interactions with Resources on AmI-enabled
 * Mobile Dynamic Environments", led by Treelogic
 * ( http://www.treelogic.com/ ):
 *
 *   http://www.piramidepse.com/
 */







import 'package:zxing/common.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
class BinaryUtil {

  static final Pattern ONE = "1";
  static final Pattern ZERO = "0";
  static final Pattern SPACE = " ";

  BinaryUtil();

  /*
  * Constructs a BitArray from a String like the one returned from BitArray.toString()
  */
  static BitArray buildBitArrayFromString(String data) {
    String dotsAndXs = data.replaceAll(ONE,"X").replaceAll(ZERO, ".");
    BitArray binary = new BitArray(dotsAndXs.replaceAll(SPACE,"").length);
    int counter = 0;

    for (int i = 0; i < dotsAndXs.length; ++i) {
      if (i % 9 == 0) { // spaces
        if (dotsAndXs[i] != ' ') {
          throw Exception("space expected");
        }
        continue;
      }

      String currentChar = dotsAndXs[i];
      if (currentChar == 'X' || currentChar == 'x') {
        binary.set(counter);
      }
      counter++;
    }
    return binary;
  }

  static BitArray buildBitArrayFromStringWithoutSpaces(String data) {
    StringBuilder sb = new StringBuilder();
    String dotsAndXs = data.replaceAll(ONE,"X").replaceAll(ZERO,".");
    int current = 0;
    while (current < dotsAndXs.length) {
      sb.write(' ');
      for (int i = 0; i < 8 && current < dotsAndXs.length; ++i) {
        sb.write(dotsAndXs[current]);
        current++;
      }
    }
    return buildBitArrayFromString(sb.toString());
  }

}
