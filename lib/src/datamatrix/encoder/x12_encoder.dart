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
  int get encodingMode => HighLevelEncoder.X12_ENCODATION;

  @override
  void encode(EncoderContext context) {
    //step C
    final buffer = StringBuilder();
    while (context.hasMoreCharacters) {
      final c = context.currentChar;
      context.pos++;

      encodeChar(c, buffer);

      final count = buffer.length;
      if ((count % 3) == 0) {
        C40Encoder.writeNextTriplet(context, buffer);

        final newMode = HighLevelEncoder.lookAheadTest(
          context.message,
          context.pos,
          encodingMode,
        );
        if (newMode != encodingMode) {
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
        if (chr >= 48 /* 0 */ && chr <= 57 /* 9 */) {
          sb.writeCharCode(chr - 48 + 4);
        } else if (chr >= 65 /* A */ && chr <= 90 /* Z */) {
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
    final available = context.symbolInfo!.dataCapacity - context.codewordCount;
    final count = buffer.length;
    context.pos -= count;
    if (context.remainingCharacters > 1 ||
        available > 1 ||
        context.remainingCharacters != available) {
      context.writeCodeword(HighLevelEncoder.X12_UNLATCH);
    }
    if (context.newEncoding < 0) {
      context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
    }
  }
}
