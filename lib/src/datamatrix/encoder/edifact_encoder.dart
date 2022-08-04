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
import 'encoder.dart';
import 'encoder_context.dart';
import 'high_level_encoder.dart';

class EdifactEncoder implements Encoder {
  @override
  int get encodingMode => HighLevelEncoder.EDIFACT_ENCODATION;

  @override
  void encode(EncoderContext context) {
    //step F
    final buffer = StringBuilder();
    while (context.hasMoreCharacters) {
      final c = context.currentChar;
      _encodeChar(c, buffer);
      context.pos++;

      final count = buffer.length;
      if (count >= 4) {
        context.writeCodewords(_encodeToCodewords(buffer));
        buffer.delete(0, 4);

        final newMode = HighLevelEncoder.lookAheadTest(
            context.message, context.pos, encodingMode);
        if (newMode != encodingMode) {
          // Return to ASCII encodation, which will actually handle latch to new mode
          context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
          break;
        }
      }
    }
    buffer.writeCharCode(31); //Unlatch
    _handleEOD(context, buffer);
  }

  /// Handle "end of data" situations
  ///
  /// @param context the encoder context
  /// @param buffer  the buffer with the remaining encoded characters
  static void _handleEOD(EncoderContext context, StringBuilder buffer) {
    try {
      final count = buffer.length;
      if (count == 0) {
        return; //Already finished
      }
      if (count == 1) {
        //Only an unlatch at the end
        context.updateSymbolInfo();
        int available =
            context.symbolInfo!.dataCapacity - context.codewordCount;
        final remaining = context.remainingCharacters;
        // The following two lines are a hack inspired by the 'fix' from https://sourceforge.net/p/barcode4j/svn/221/
        if (remaining > available) {
          context.updateSymbolInfo(context.codewordCount + 1);
          available = context.symbolInfo!.dataCapacity - context.codewordCount;
        }
        if (remaining <= available && available <= 2) {
          return; //No unlatch
        }
      }

      if (count > 4) {
        throw StateError('Count must not exceed 4');
      }
      final restChars = count - 1;
      final encoded = _encodeToCodewords(buffer);
      final endOfSymbolReached = !context.hasMoreCharacters;
      bool restInAscii = endOfSymbolReached && restChars <= 2;

      if (restChars <= 2) {
        context.updateSymbolInfo(context.codewordCount + restChars);
        final available =
            context.symbolInfo!.dataCapacity - context.codewordCount;
        if (available >= 3) {
          restInAscii = false;
          context.updateSymbolInfo(context.codewordCount + encoded.length);
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

  static void _encodeChar(int chr, StringBuffer sb) {
    if (chr >= 32 /*   */ && chr <= 63 /* ? */) {
      sb.writeCharCode(chr);
    } else if (chr >= 64 /* @ */ && chr <= 94 /* ^ */) {
      sb.writeCharCode(chr - 64);
    } else {
      HighLevelEncoder.illegalCharacter(chr);
    }
  }

  static String _encodeToCodewords(StringBuilder sb) {
    final len = sb.length;
    if (len == 0) {
      throw StateError('StringBuffer must not be empty');
    }
    final c1 = sb.codePointAt(0);
    final c2 = len >= 2 ? sb.codePointAt(1) : 0;
    final c3 = len >= 3 ? sb.codePointAt(2) : 0;
    final c4 = len >= 4 ? sb.codePointAt(3) : 0;

    final v = (c1 << 18) + (c2 << 12) + (c3 << 6) + c4;
    final cw1 = (v >> 16) & 255;
    final cw2 = (v >> 8) & 255;
    final cw3 = v & 255;
    final res = StringBuffer();
    res.writeCharCode(cw1);
    if (len >= 2) {
      res.writeCharCode(cw2);
    }
    if (len >= 3) {
      res.writeCharCode(cw3);
    }
    return res.toString();
  }
}
