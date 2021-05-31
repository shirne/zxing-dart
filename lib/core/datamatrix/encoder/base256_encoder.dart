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

class Base256Encoder implements Encoder {
  @override
  int getEncodingMode() {
    return HighLevelEncoder.BASE256_ENCODATION;
  }

  @override
  void encode(EncoderContext context) {
    StringBuilder buffer = StringBuilder();
    buffer.write('\0'); //Initialize length field
    while (context.hasMoreCharacters()) {
      String c = context.getCurrentChar();
      buffer.write(c);

      context.pos++;

      int newMode = HighLevelEncoder.lookAheadTest(
          context.getMessage(), context.pos, getEncodingMode());
      if (newMode != getEncodingMode()) {
        // Return to ASCII encodation, which will actually handle latch to new mode
        context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
        break;
      }
    }
    int dataCount = buffer.length - 1;
    int lengthFieldSize = 1;
    int currentSize = context.getCodewordCount() + dataCount + lengthFieldSize;
    context.updateSymbolInfo(currentSize);
    bool mustPad =
        (context.getSymbolInfo()!.getDataCapacity() - currentSize) > 0;
    if (context.hasMoreCharacters() || mustPad) {
      if (dataCount <= 249) {
        buffer.setCharAt(0, String.fromCharCode(dataCount));
      } else if (dataCount <= 1555) {
        buffer.setCharAt(0, String.fromCharCode((dataCount ~/ 250) + 249));
        buffer.insert(1, String.fromCharCode(dataCount % 250));
      } else {
        throw Exception("Message length not in valid ranges: $dataCount");
      }
    }
    for (int i = 0, c = buffer.length; i < c; i++) {
      context.writeCodeword(
          _randomize255State(buffer.charAt(i), context.getCodewordCount() + 1));
    }
  }

  static String _randomize255State(String ch, int codewordPosition) {
    int pseudoRandom = ((149 * codewordPosition) % 255) + 1;
    int tempVariable = ch.codeUnitAt(0) + pseudoRandom;
    if (tempVariable <= 255) {
      return String.fromCharCode(tempVariable);
    } else {
      return String.fromCharCode(tempVariable - 256);
    }
  }
}
