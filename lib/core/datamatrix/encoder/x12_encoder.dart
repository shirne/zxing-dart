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

import 'package:zxing/core/common/string_builder.dart';

import 'c40_encoder.dart';
import 'encoder_context.dart';
import 'high_level_encoder.dart';

class X12Encoder extends C40Encoder {
  @override
  int getEncodingMode() {
    return HighLevelEncoder.X12_ENCODATION;
  }

  @override
  void encode(EncoderContext context) {
    //step C
    StringBuilder buffer = new StringBuilder();
    while (context.hasMoreCharacters()) {
      String c = context.getCurrentChar();
      context.pos++;

      encodeChar(c, buffer);

      int count = buffer.length;
      if ((count % 3) == 0) {
        C40Encoder.writeNextTriplet(context, buffer);

        int newMode = HighLevelEncoder.lookAheadTest(
            context.getMessage(), context.pos, getEncodingMode());
        if (newMode != getEncodingMode()) {
          // Return to ASCII encodation, which will actually handle latch to new mode
          context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
          break;
        }
      }
    }
    handleEOD(context, buffer);
  }

  @override
  int encodeChar(String c, StringBuffer sb) {
    switch (c) {
      case '\r':
        sb.write('\0');
        break;
      case '*':
        sb.write('\1');
        break;
      case '>':
        sb.write('\2');
        break;
      case ' ':
        sb.write('\3');
        break;
      default:
        int code = c.codeUnitAt(0);
        if (code >= '0'.codeUnitAt(0) && code <= '9'.codeUnitAt(0)) {
          sb.write(String.fromCharCode(code - 48 + 4));
        } else if (code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0)) {
          sb.write(String.fromCharCode(code - 65 + 14));
        } else {
          HighLevelEncoder.illegalCharacter(code);
        }
        break;
    }
    return 1;
  }

  @override
  void handleEOD(EncoderContext context, StringBuffer buffer) {
    context.updateSymbolInfo();
    int available =
        context.getSymbolInfo()!.getDataCapacity() - context.getCodewordCount();
    int count = buffer.length;
    context.pos -= count;
    if (context.getRemainingCharacters() > 1 ||
        available > 1 ||
        context.getRemainingCharacters() != available) {
      context.writeCodeword(String.fromCharCode(HighLevelEncoder.X12_UNLATCH));
    }
    if (context.getNewEncoding() < 0) {
      context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
    }
  }
}
