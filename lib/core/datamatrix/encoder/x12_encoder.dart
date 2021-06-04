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

import '../../common/string_builder.dart';

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
    StringBuilder buffer = StringBuilder();
    while (context.hasMoreCharacters()) {
      int c = context.getCurrentChar();
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
  int encodeChar(int chr, StringBuffer sb) {
    switch (chr) {
      case 13: // '\r':
        sb.write('\x00');
        break;
      case 42: // '*':
        sb.write('\x01');
        break;
      case 62: // '>':
        sb.write('\x02');
        break;
      case 32: // ' ':
        sb.write('\x03');
        break;
      default:

        if (chr >= '0'.codeUnitAt(0) && chr <= '9'.codeUnitAt(0)) {
          sb.writeCharCode(chr - 48 + 4);
        } else if (chr >= 'A'.codeUnitAt(0) && chr <= 'Z'.codeUnitAt(0)) {
          sb.writeCharCode(chr - 65 + 14);
        } else {
          HighLevelEncoder.illegalCharacter(chr);
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
      context.writeCodeword(HighLevelEncoder.X12_UNLATCH);
    }
    if (context.getNewEncoding() < 0) {
      context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
    }
  }
}
