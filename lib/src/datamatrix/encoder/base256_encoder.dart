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
  int get encodingMode => HighLevelEncoder.BASE256_ENCODATION;

  @override
  void encode(EncoderContext context) {
    final buffer = StringBuilder();
    buffer.write('\x00'); //Initialize length field
    while (context.hasMoreCharacters) {
      final c = context.currentChar;
      buffer.writeCharCode(c);

      context.pos++;

      final newMode = HighLevelEncoder.lookAheadTest(
          context.message, context.pos, encodingMode);
      if (newMode != encodingMode) {
        // Return to ASCII encodation, which will actually handle latch to new mode
        context.signalEncoderChange(HighLevelEncoder.ASCII_ENCODATION);
        break;
      }
    }
    final dataCount = buffer.length - 1;
    final lengthFieldSize = 1;
    final currentSize = context.codewordCount + dataCount + lengthFieldSize;
    context.updateSymbolInfo(currentSize);
    final mustPad = (context.symbolInfo!.dataCapacity - currentSize) > 0;
    if (context.hasMoreCharacters || mustPad) {
      if (dataCount <= 249) {
        buffer.setCharAt(0, dataCount);
      } else if (dataCount <= 1555) {
        buffer.setCharAt(0, (dataCount ~/ 250) + 249);
        buffer.insert(1, dataCount % 250);
      } else {
        throw StateError('Message length not in valid ranges: $dataCount');
      }
    }
    final l = buffer.length;
    for (int i = 0; i < l; i++) {
      context.writeCodeword(
          _randomize255State(buffer.charAt(i), context.codewordCount + 1));
    }
  }

  static int _randomize255State(String ch, int codewordPosition) {
    final pseudoRandom = ((149 * codewordPosition) % 255) + 1;
    final tempVariable = ch.codeUnitAt(0) + pseudoRandom;
    if (tempVariable <= 255) {
      return tempVariable;
    } else {
      return tempVariable - 256;
    }
  }
}
