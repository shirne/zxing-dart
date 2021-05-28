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

import 'encoder.dart';

import 'encoder_context.dart';
import 'high_level_encoder.dart';

class EdifactEncoder implements Encoder {
  @override
  int getEncodingMode() {
    return HighLevelEncoder.EDIFACT_ENCODATION;
  }

  @override
  void encode(EncoderContext context) {
    //step F
    StringBuilder buffer = new StringBuilder();
    while (context.hasMoreCharacters()) {
      String c = context.getCurrentChar();
      encodeChar(c, buffer);
      context.pos++;

      int count = buffer.length;
      if (count >= 4) {
        context.writeCodewords(encodeToCodewords(buffer));
        buffer.delete(0, 4);

        int newMode = HighLevelEncoder.lookAheadTest(
            context.getMessage(), context.pos, getEncodingMode());
        if (newMode != getEncodingMode()) {
          // Return to ASCII encodation, which will actually handle latch to new mode
          context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
          break;
        }
      }
    }
    buffer.write(String.fromCharCode(31)); //Unlatch
    handleEOD(context, buffer);
  }

  /**
   * Handle "end of data" situations
   *
   * @param context the encoder context
   * @param buffer  the buffer with the remaining encoded characters
   */
  static void handleEOD(EncoderContext context, StringBuilder buffer) {
    try {
      int count = buffer.length;
      if (count == 0) {
        return; //Already finished
      }
      if (count == 1) {
        //Only an unlatch at the end
        context.updateSymbolInfo();
        int available = context.getSymbolInfo()!.getDataCapacity() -
            context.getCodewordCount();
        int remaining = context.getRemainingCharacters();
        // The following two lines are a hack inspired by the 'fix' from https://sourceforge.net/p/barcode4j/svn/221/
        if (remaining > available) {
          context.updateSymbolInfo(context.getCodewordCount() + 1);
          available = context.getSymbolInfo()!.getDataCapacity() -
              context.getCodewordCount();
        }
        if (remaining <= available && available <= 2) {
          return; //No unlatch
        }
      }

      if (count > 4) {
        throw Exception("Count must not exceed 4");
      }
      int restChars = count - 1;
      String encoded = encodeToCodewords(buffer);
      bool endOfSymbolReached = !context.hasMoreCharacters();
      bool restInAscii = endOfSymbolReached && restChars <= 2;

      if (restChars <= 2) {
        context.updateSymbolInfo(context.getCodewordCount() + restChars);
        int available = context.getSymbolInfo()!.getDataCapacity() -
            context.getCodewordCount();
        if (available >= 3) {
          restInAscii = false;
          context.updateSymbolInfo(context.getCodewordCount() + encoded.length);
          //available = context.symbolInfo.dataCapacity - context.getCodewordCount();
        }
      }

      if (restInAscii) {
        context.resetSymbolInfo();
        context.pos -= restChars;
      } else {
        context.writeCodewords(encoded);
      }
    } finally {
      context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
    }
  }

  static void encodeChar(String chr, StringBuffer sb) {
    int c = chr.codeUnitAt(0);
    if (c >= ' '.codeUnitAt(0) && c <= '?'.codeUnitAt(0)) {
      sb.write(c);
    } else if (c >= '@'.codeUnitAt(0) && c <= '^'.codeUnitAt(0)) {
      sb.write(String.fromCharCode(c - 64));
    } else {
      HighLevelEncoder.illegalCharacter(c);
    }
  }

  static String encodeToCodewords(StringBuilder sb) {
    int len = sb.length;
    if (len == 0) {
      throw Exception("StringBuffer must not be empty");
    }
    int c1 = sb.codePointAt(0);
    int c2 = len >= 2 ? sb.codePointAt(1) : 0;
    int c3 = len >= 3 ? sb.codePointAt(2) : 0;
    int c4 = len >= 4 ? sb.codePointAt(3) : 0;

    int v = (c1 << 18) + (c2 << 12) + (c3 << 6) + c4;
    String cw1 = String.fromCharCode((v >> 16) & 255);
    String cw2 = String.fromCharCode((v >> 8) & 255);
    String cw3 = String.fromCharCode(v & 255);
    StringBuffer res = new StringBuffer(3);
    res.write(cw1);
    if (len >= 2) {
      res.write(cw2);
    }
    if (len >= 3) {
      res.write(cw3);
    }
    return res.toString();
  }
}
