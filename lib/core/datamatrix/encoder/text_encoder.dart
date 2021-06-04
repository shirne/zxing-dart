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
  int encodeChar(int chr, StringBuffer sb) {
    if (chr == 32) { // ' '
      sb.write('\x03');
      return 1;
    }

    if (chr >= 48 /* 0 */ && chr <= 57 /* 9 */) {
      sb.writeCharCode(chr - 48 + 4);
      return 1;
    }
    if (chr >= 97 /* a */ && chr <= 122 /* z */) {
      sb.writeCharCode(chr - 97 + 14);
      return 1;
    }
    if (chr < 32 /*   */) {
      sb.write('\x00'); //Shift 1 Set
      sb.writeCharCode(chr);
      return 2;
    }
    if (chr <= 47 /* / */) {
      sb.write('\x01'); //Shift 2 Set
      sb.writeCharCode(chr - 33);
      return 2;
    }
    if (chr <= 64 /* @ */) {
      sb.write('\x01'); //Shift 2 Set
      sb.writeCharCode(chr - 58 + 15);
      return 2;
    }
    if (chr >= 91 /* [ */ && chr <= 95 /* _ */) {
      sb.write('\x01'); //Shift 2 Set
      sb.writeCharCode(chr - 91 + 22);
      return 2;
    }
    if (chr == 96 /* ` */) {
      sb.write('\x02'); //Shift 3 Set
      sb.writeCharCode(0); // '`' - 96 == 0
      return 2;
    }
    if (chr <= 90 /* Z */) {
      sb.write('\x02'); //Shift 3 Set
      sb.writeCharCode(chr - 65 + 1);
      return 2;
    }
    if (chr <= 127) {
      sb.write('\x02'); //Shift 3 Set
      sb.writeCharCode(chr - 123 + 27);
      return 2;
    }
    sb.write("\x01\u001e"); //Shift 2, Upper Shift
    int len = 2;
    len += encodeChar(chr - 128, sb);
    return len;
  }
}
