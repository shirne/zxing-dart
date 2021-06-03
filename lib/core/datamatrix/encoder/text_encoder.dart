/*
 * Copyright 2006-2007 Jeremias Maerki.
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

import 'c40_encoder.dart';
import 'high_level_encoder.dart';

class TextEncoder extends C40Encoder {
  @override
  int getEncodingMode() {
    return HighLevelEncoder.TEXT_ENCODATION;
  }

  @override
  int encodeChar(String chr, StringBuffer sb) {
    if (chr == ' ') {
      sb.write('\x03');
      return 1;
    }
    int c = chr.codeUnitAt(0);
    if (c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
      sb.write(String.fromCharCode(c - 48 + 4));
      return 1;
    }
    if (c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0)) {
      sb.write(String.fromCharCode(c - 97 + 14));
      return 1;
    }
    if (c < ' '.codeUnitAt(0)) {
      sb.write('\x00'); //Shift 1 Set
      sb.write(c);
      return 2;
    }
    if (c <= '/'.codeUnitAt(0)) {
      sb.write('\x01'); //Shift 2 Set
      sb.write(String.fromCharCode(c - 33));
      return 2;
    }
    if (c <= '@'.codeUnitAt(0)) {
      sb.write('\x01'); //Shift 2 Set
      sb.write(String.fromCharCode(c - 58 + 15));
      return 2;
    }
    if (c >= '['.codeUnitAt(0) && c <= '_'.codeUnitAt(0)) {
      sb.write('\x01'); //Shift 2 Set
      sb.write(String.fromCharCode(c - 91 + 22));
      return 2;
    }
    if (c == '`'.codeUnitAt(0)) {
      sb.write('\x02'); //Shift 3 Set
      sb.write(String.fromCharCode(0)); // '`' - 96 == 0
      return 2;
    }
    if (c <= 'Z'.codeUnitAt(0)) {
      sb.write('\x02'); //Shift 3 Set
      sb.write(String.fromCharCode(c - 65 + 1));
      return 2;
    }
    if (c <= 127) {
      sb.write('\x02'); //Shift 3 Set
      sb.write(String.fromCharCode(c - 123 + 27));
      return 2;
    }
    sb.write("\x01\u001e"); //Shift 2, Upper Shift
    int len = 2;
    len += encodeChar(String.fromCharCode(c - 128), sb);
    return len;
  }
}
