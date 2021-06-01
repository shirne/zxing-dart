/*
 * Copyright 2008 ZXing authors
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

import 'dart:typed_data';

import 'package:zxing/zxing.dart';

/**
 * Class that lets one easily build an array of bytes by appending bits at a time.
 *
 * @author Sean Owen
 */
class BitSourceBuilder {

  final BytesBuilder output = BytesBuilder();
  int nextByte = 0;
  int bitsLeftInNextByte = 8;

  BitSourceBuilder();

  void write(int value, int numBits) {
    if (numBits <= bitsLeftInNextByte) {
      nextByte <<= numBits;
      nextByte |= value;
      bitsLeftInNextByte -= numBits;
      if (bitsLeftInNextByte == 0) {
        output.addByte(nextByte);
        nextByte = 0;
        bitsLeftInNextByte = 8;
      }
    } else {
      int bitsToWriteNow = bitsLeftInNextByte;
      int numRestOfBits = numBits - bitsToWriteNow;
      int mask = 0xFF >> (8 - bitsToWriteNow);
      int valueToWriteNow = (value >> numRestOfBits) & mask;
      write(valueToWriteNow, bitsToWriteNow);
      write(value, numRestOfBits);
    }
  }

  Uint8List toByteArray() {
    if (bitsLeftInNextByte < 8) {
      write(0, bitsLeftInNextByte);
    }
    return output.takeBytes();
  }

}