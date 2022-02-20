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

class C40Encoder implements Encoder {
  @override
  int get encodingMode => HighLevelEncoder.C40_ENCODATION;

  void encodeMaximal(EncoderContext context) {
    StringBuilder buffer = StringBuilder();
    int lastCharSize = 0;
    int backtrackStartPosition = context.pos;
    int backtrackBufferLength = 0;
    while (context.hasMoreCharacters) {
      int c = context.currentChar;
      context.pos++;
      lastCharSize = encodeChar(c, buffer);
      if (buffer.length % 3 == 0) {
        backtrackStartPosition = context.pos;
        backtrackBufferLength = buffer.length;
      }
    }
    if (backtrackBufferLength != buffer.length) {
      int unwritten = (buffer.length ~/ 3) * 2;

      int curCodewordCount =
          context.codewordCount + unwritten + 1; // +1 for the latch to C40
      context.updateSymbolInfo(curCodewordCount);
      int available = context.symbolInfo!.dataCapacity - curCodewordCount;
      int rest = buffer.length % 3;
      if ((rest == 2 && available != 2) ||
          (rest == 1 && (lastCharSize > 3 || available != 1))) {
        buffer.setLength(backtrackBufferLength);
        context.pos = backtrackStartPosition;
      }
    }
    if (buffer.length > 0) {
      context.writeCodeword(HighLevelEncoder.LATCH_TO_C40);
    }

    handleEOD(context, buffer);
  }

  @override
  void encode(EncoderContext context) {
    //step C
    StringBuilder buffer = StringBuilder();
    while (context.hasMoreCharacters) {
      int c = context.currentChar;
      context.pos++;

      int lastCharSize = encodeChar(c, buffer);

      int unwritten = (buffer.length ~/ 3) * 2;

      int curCodewordCount = context.codewordCount + unwritten;
      context.updateSymbolInfo(curCodewordCount);
      int available = context.symbolInfo!.dataCapacity - curCodewordCount;

      if (!context.hasMoreCharacters) {
        //Avoid having a single C40 value in the last triplet
        StringBuffer removed = StringBuffer();
        if ((buffer.length % 3) == 2 && available != 2) {
          lastCharSize =
              _backtrackOneCharacter(context, buffer, removed, lastCharSize);
        }
        while (
            (buffer.length % 3) == 1 && (lastCharSize > 3 || available != 1)) {
          lastCharSize =
              _backtrackOneCharacter(context, buffer, removed, lastCharSize);
        }
        break;
      }

      int count = buffer.length;
      if ((count % 3) == 0) {
        int newMode = HighLevelEncoder.lookAheadTest(
            context.message, context.pos, encodingMode);
        if (newMode != encodingMode) {
          // Return to ASCII encodation, which will actually handle latch to new mode
          context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
          break;
        }
      }
    }
    handleEOD(context, buffer);
  }

  int _backtrackOneCharacter(EncoderContext context, StringBuilder buffer,
      StringBuffer removed, int lastCharSize) {
    int count = buffer.length;
    buffer.delete(count - lastCharSize, count);
    context.pos--;
    int c = context.currentChar;
    lastCharSize = encodeChar(c, removed);
    context.resetSymbolInfo(); //Deal with possible reduction in symbol size
    return lastCharSize;
  }

  static void writeNextTriplet(EncoderContext context, StringBuilder buffer) {
    context.writeCodewords(_encodeToCodewords(buffer.toString()));
    buffer.delete(0, 3);
  }

  /// Handle "end of data" situations
  ///
  /// @param context the encoder context
  /// @param buffer  the buffer with the remaining encoded characters
  void handleEOD(EncoderContext context, StringBuilder buffer) {
    int unwritten = (buffer.length ~/ 3) * 2;
    int rest = buffer.length % 3;

    int curCodewordCount = context.codewordCount + unwritten;
    context.updateSymbolInfo(curCodewordCount);
    int available = context.symbolInfo!.dataCapacity - curCodewordCount;

    if (rest == 2) {
      buffer.write('\x00'); //Shift 1
      while (buffer.length >= 3) {
        writeNextTriplet(context, buffer);
      }
      if (context.hasMoreCharacters) {
        context.writeCodeword(HighLevelEncoder.C40_UNLATCH);
      }
    } else if (available == 1 && rest == 1) {
      while (buffer.length >= 3) {
        writeNextTriplet(context, buffer);
      }
      if (context.hasMoreCharacters) {
        context.writeCodeword(HighLevelEncoder.C40_UNLATCH);
      }
      // else no unlatch
      context.pos--;
    } else if (rest == 0) {
      while (buffer.length >= 3) {
        writeNextTriplet(context, buffer);
      }
      if (available > 0 || context.hasMoreCharacters) {
        context.writeCodeword(HighLevelEncoder.C40_UNLATCH);
      }
    } else {
      throw StateError("Unexpected case. Please report!");
    }
    context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
  }

  int encodeChar(int chr, StringBuffer sb) {
    if (chr == 32) {
      // ' '
      sb.write('\x03');
      return 1;
    }

    if (chr >= 48 /* 0 */ && chr <= 57 /* 9 */) {
      sb.writeCharCode(chr - 48 + 4);
      return 1;
    }
    if (chr >= 65 /* A */ && chr <= 90 /* Z */) {
      sb.writeCharCode(chr - 65 + 14);
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
    if (chr <= 95 /* _ */) {
      sb.write('\x01'); //Shift 2 Set
      sb.writeCharCode(chr - 91 + 22);
      return 2;
    }
    if (chr <= 127) {
      sb.write('\x02'); //Shift 3 Set
      sb.writeCharCode(chr - 96);
      return 2;
    }
    sb.write("\x01\u001e"); //Shift 2, Upper Shift
    int len = 2;
    len += encodeChar(chr - 128, sb);
    return len;
  }

  static String _encodeToCodewords(String sb) {
    int v = (1600 * sb.codeUnitAt(0)) +
        (40 * sb.codeUnitAt(1)) +
        sb.codeUnitAt(2) +
        1;
    int cw1 = (v ~/ 256);
    int cw2 = (v % 256);
    return String.fromCharCodes([cw1, cw2]);
  }
}
