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

import 'encoder.dart';
import 'encoder_context.dart';
import 'high_level_encoder.dart';

class ASCIIEncoder implements Encoder {
  @override
  int get encodingMode => HighLevelEncoder.asciiEncodation;

  @override
  void encode(EncoderContext context) {
    //step B
    final n = HighLevelEncoder.determineConsecutiveDigitCount(
      context.message,
      context.pos,
    );
    if (n >= 2) {
      context.writeCodeword(
        _encodeASCIIDigits(
          context.message.codeUnitAt(context.pos),
          context.message.codeUnitAt(context.pos + 1),
        ),
      );
      context.pos += 2;
    } else {
      final c = context.currentChar;
      final newMode = HighLevelEncoder.lookAheadTest(
        context.message,
        context.pos,
        encodingMode,
      );
      if (newMode != encodingMode) {
        switch (newMode) {
          case HighLevelEncoder.base256Encodation:
            context.writeCodeword(HighLevelEncoder.latchToBase256);
            context.signalEncoderChange(HighLevelEncoder.base256Encodation);
            return;
          case HighLevelEncoder.c40Encodation:
            context.writeCodeword(HighLevelEncoder.latchToC40);
            context.signalEncoderChange(HighLevelEncoder.c40Encodation);
            return;
          case HighLevelEncoder.x12Encodation:
            context.writeCodeword(HighLevelEncoder.latchToAnsix12);
            context.signalEncoderChange(HighLevelEncoder.x12Encodation);
            break;
          case HighLevelEncoder.textEncodation:
            context.writeCodeword(HighLevelEncoder.latchToText);
            context.signalEncoderChange(HighLevelEncoder.textEncodation);
            break;
          case HighLevelEncoder.edifactEncodation:
            context.writeCodeword(HighLevelEncoder.latchToEdifact);
            context.signalEncoderChange(HighLevelEncoder.edifactEncodation);
            break;
          default:
            throw StateError('Illegal mode: $newMode');
        }
      } else if (HighLevelEncoder.isExtendedASCII(c)) {
        context.writeCodeword(HighLevelEncoder.upperShift);
        context.writeCodeword(c - 128 + 1);
        context.pos++;
      } else {
        context.writeCodeword(c + 1);
        context.pos++;
      }
    }
  }

  static int _encodeASCIIDigits(int digit1, int digit2) {
    if (HighLevelEncoder.isDigit(digit1) && HighLevelEncoder.isDigit(digit2)) {
      final num = (digit1 - 48) * 10 + (digit2 - 48);
      return num + 130;
    }
    throw ArgumentError('not digits: $digit1 $digit2');
  }
}
