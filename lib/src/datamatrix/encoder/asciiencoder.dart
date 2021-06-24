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
import 'high_level_encoder.dart';
import 'encoder_context.dart';

class ASCIIEncoder implements Encoder {
  @override
  int get encodingMode => HighLevelEncoder.ASCII_ENCODATION;

  @override
  void encode(EncoderContext context) {
    //step B
    int n = HighLevelEncoder.determineConsecutiveDigitCount(
        context.message, context.pos);
    if (n >= 2) {
      context.writeCodeword(_encodeASCIIDigits(
          context.message.codeUnitAt(context.pos),
          context.message.codeUnitAt(context.pos + 1)));
      context.pos += 2;
    } else {
      int c = context.currentChar;
      int newMode = HighLevelEncoder.lookAheadTest(
          context.message, context.pos, encodingMode);
      if (newMode != encodingMode) {
        switch (newMode) {
          case HighLevelEncoder.BASE256_ENCODATION:
            context.writeCodeword(HighLevelEncoder.LATCH_TO_BASE256);
            context.signalEncoderChange(HighLevelEncoder.BASE256_ENCODATION);
            return;
          case HighLevelEncoder.C40_ENCODATION:
            context.writeCodeword(HighLevelEncoder.LATCH_TO_C40);
            context.signalEncoderChange(HighLevelEncoder.C40_ENCODATION);
            return;
          case HighLevelEncoder.X12_ENCODATION:
            context.writeCodeword(HighLevelEncoder.LATCH_TO_ANSIX12);
            context.signalEncoderChange(HighLevelEncoder.X12_ENCODATION);
            break;
          case HighLevelEncoder.TEXT_ENCODATION:
            context.writeCodeword(HighLevelEncoder.LATCH_TO_TEXT);
            context.signalEncoderChange(HighLevelEncoder.TEXT_ENCODATION);
            break;
          case HighLevelEncoder.EDIFACT_ENCODATION:
            context.writeCodeword(HighLevelEncoder.LATCH_TO_EDIFACT);
            context.signalEncoderChange(HighLevelEncoder.EDIFACT_ENCODATION);
            break;
          default:
            throw Exception("Illegal mode: $newMode");
        }
      } else if (HighLevelEncoder.isExtendedASCII(c)) {
        context.writeCodeword(HighLevelEncoder.UPPER_SHIFT);
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
      int num = (digit1 - 48) * 10 + (digit2 - 48);
      return num + 130;
    }
    throw Exception("not digits: $digit1 $digit2");
  }
}
