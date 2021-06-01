/*
 * Copyright (C) 2010 ZXing authors
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

/*
 * These authors would like to acknowledge the Spanish Ministry of Industry,
 * Tourism and Trade, for the support in the project TSI020301-2008-2
 * "PIRAmIDE: Personalizable Interactions with Resources on AmI-enabled
 * Mobile Dynamic Environments", led by Treelogic
 * ( http://www.treelogic.com/ ):
 *
 *   http://www.piramidepse.com/
 */

import '../../../../common/bit_array.dart';
import '../../../../common/string_builder.dart';

import 'block_parsed_result.dart';
import 'current_parsing_state.dart';
import 'decoded_char.dart';
import 'decoded_information.dart';
import 'decoded_numeric.dart';
import 'field_parser.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
/// @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
class GeneralAppIdDecoder {
  final BitArray _information;
  final CurrentParsingState _current = CurrentParsingState();
  final StringBuilder _buffer = StringBuilder();

  GeneralAppIdDecoder(this._information);

  String decodeAllCodes(StringBuffer buff, int initialPosition) {
    int currentPosition = initialPosition;
    String? remaining;
    do {
      DecodedInformation info =
          this.decodeGeneralPurposeField(currentPosition, remaining!);
      String? parsedFields =
          FieldParser.parseFieldsInGeneralPurpose(info.getNewString());
      if (parsedFields != null) {
        buff.write(parsedFields);
      }
      if (info.isRemaining()) {
        remaining = info.getRemainingValue().toString();
      } else {
        remaining = null;
      }

      if (currentPosition == info.getNewPosition()) {
        // No step forward!
        break;
      }
      currentPosition = info.getNewPosition();
    } while (true);

    return buff.toString();
  }

  bool _isStillNumeric(int pos) {
    // It's numeric if it still has 7 positions
    // and one of the first 4 bits is "1".
    if (pos + 7 > this._information.getSize()) {
      return pos + 4 <= this._information.getSize();
    }

    for (int i = pos; i < pos + 3; ++i) {
      if (this._information.get(i)) {
        return true;
      }
    }

    return this._information.get(pos + 3);
  }

  DecodedNumeric _decodeNumeric(int pos) {
    if (pos + 7 > this._information.getSize()) {
      int numeric = extractNumericValueFromBitArray(pos, 4);
      if (numeric == 0) {
        return DecodedNumeric(this._information.getSize(),
            DecodedNumeric.FNC1, DecodedNumeric.FNC1);
      }
      return DecodedNumeric(
          this._information.getSize(), numeric - 1, DecodedNumeric.FNC1);
    }
    int numeric = extractNumericValueFromBitArray(pos, 7);

    int digit1 = (numeric - 8) ~/ 11;
    int digit2 = (numeric - 8) % 11;

    return DecodedNumeric(pos + 7, digit1, digit2);
  }

  int extractNumericValueFromBitArray(int pos, int bits) {
    return extractNumericFromBitArray(this._information, pos, bits);
  }

  static int extractNumericFromBitArray(
      BitArray information, int pos, int bits) {
    int value = 0;
    for (int i = 0; i < bits; ++i) {
      if (information.get(pos + i)) {
        value |= 1 << (bits - i - 1);
      }
    }

    return value;
  }

  DecodedInformation decodeGeneralPurposeField(int pos, String? remaining) {
    this._buffer.setLength(0);

    if (remaining != null) {
      this._buffer.write(remaining);
    }

    this._current.setPosition(pos);

    DecodedInformation? lastDecoded = _parseBlocks();
    if (lastDecoded != null && lastDecoded.isRemaining()) {
      return DecodedInformation(this._current.getPosition(),
          this._buffer.toString(), lastDecoded.getRemainingValue());
    }
    return DecodedInformation(
        this._current.getPosition(), this._buffer.toString());
  }

  DecodedInformation? _parseBlocks() {
    bool isFinished;
    BlockParsedResult result;
    do {
      int initialPosition = _current.getPosition();

      if (_current.isAlpha()) {
        result = _parseAlphaBlock();
        isFinished = result.isFinished();
      } else if (_current.isIsoIec646()) {
        result = _parseIsoIec646Block();
        isFinished = result.isFinished();
      } else {
        // it must be numeric
        result = _parseNumericBlock();
        isFinished = result.isFinished();
      }

      bool positionChanged = initialPosition != _current.getPosition();
      if (!positionChanged && !isFinished) {
        break;
      }
    } while (!isFinished);

    return result.getDecodedInformation();
  }

  BlockParsedResult _parseNumericBlock() {
    while (_isStillNumeric(_current.getPosition())) {
      DecodedNumeric numeric = _decodeNumeric(_current.getPosition());
      _current.setPosition(numeric.getNewPosition());

      if (numeric.isFirstDigitFNC1()) {
        DecodedInformation information;
        if (numeric.isSecondDigitFNC1()) {
          information =
              DecodedInformation(_current.getPosition(), _buffer.toString());
        } else {
          information = DecodedInformation(_current.getPosition(),
              _buffer.toString(), numeric.getSecondDigit());
        }
        return BlockParsedResult(information, true);
      }
      _buffer.write(numeric.getFirstDigit());

      if (numeric.isSecondDigitFNC1()) {
        DecodedInformation information =
            DecodedInformation(_current.getPosition(), _buffer.toString());
        return BlockParsedResult(information, true);
      }
      _buffer.write(numeric.getSecondDigit());
    }

    if (_isNumericToAlphaNumericLatch(_current.getPosition())) {
      _current.setAlpha();
      _current.incrementPosition(4);
    }
    return BlockParsedResult();
  }

  BlockParsedResult _parseIsoIec646Block() {
    while (_isStillIsoIec646(_current.getPosition())) {
      DecodedChar iso = _decodeIsoIec646(_current.getPosition());
      _current.setPosition(iso.getNewPosition());

      if (iso.isFNC1()) {
        DecodedInformation information =
            DecodedInformation(_current.getPosition(), _buffer.toString());
        return BlockParsedResult(information, true);
      }
      _buffer.write(iso.getValue());
    }

    if (_isAlphaOr646ToNumericLatch(_current.getPosition())) {
      _current.incrementPosition(3);
      _current.setNumeric();
    } else if (_isAlphaTo646ToAlphaLatch(_current.getPosition())) {
      if (_current.getPosition() + 5 < this._information.getSize()) {
        _current.incrementPosition(5);
      } else {
        _current.setPosition(this._information.getSize());
      }

      _current.setAlpha();
    }
    return BlockParsedResult();
  }

  BlockParsedResult _parseAlphaBlock() {
    while (_isStillAlpha(_current.getPosition())) {
      DecodedChar alpha = _decodeAlphanumeric(_current.getPosition());
      _current.setPosition(alpha.getNewPosition());

      if (alpha.isFNC1()) {
        DecodedInformation information =
            DecodedInformation(_current.getPosition(), _buffer.toString());
        return BlockParsedResult(information, true); //end of the char block
      }

      _buffer.write(alpha.getValue());
    }

    if (_isAlphaOr646ToNumericLatch(_current.getPosition())) {
      _current.incrementPosition(3);
      _current.setNumeric();
    } else if (_isAlphaTo646ToAlphaLatch(_current.getPosition())) {
      if (_current.getPosition() + 5 < this._information.getSize()) {
        _current.incrementPosition(5);
      } else {
        _current.setPosition(this._information.getSize());
      }

      _current.setIsoIec646();
    }
    return BlockParsedResult();
  }

  bool _isStillIsoIec646(int pos) {
    if (pos + 5 > this._information.getSize()) {
      return false;
    }

    int fiveBitValue = extractNumericValueFromBitArray(pos, 5);
    if (fiveBitValue >= 5 && fiveBitValue < 16) {
      return true;
    }

    if (pos + 7 > this._information.getSize()) {
      return false;
    }

    int sevenBitValue = extractNumericValueFromBitArray(pos, 7);
    if (sevenBitValue >= 64 && sevenBitValue < 116) {
      return true;
    }

    if (pos + 8 > this._information.getSize()) {
      return false;
    }

    int eightBitValue = extractNumericValueFromBitArray(pos, 8);
    return eightBitValue >= 232 && eightBitValue < 253;
  }

  DecodedChar _decodeIsoIec646(int pos) {
    int fiveBitValue = extractNumericValueFromBitArray(pos, 5);
    if (fiveBitValue == 15) {
      return DecodedChar(pos + 5, DecodedChar.FNC1);
    }

    if (fiveBitValue >= 5 && fiveBitValue < 15) {
      return DecodedChar(pos + 5, ('0'.codeUnitAt(0) + fiveBitValue - 5));
    }

    int sevenBitValue = extractNumericValueFromBitArray(pos, 7);

    if (sevenBitValue >= 64 && sevenBitValue < 90) {
      return DecodedChar(pos + 7, (sevenBitValue + 1));
    }

    if (sevenBitValue >= 90 && sevenBitValue < 116) {
      return DecodedChar(pos + 7, (sevenBitValue + 7));
    }

    int eightBitValue = extractNumericValueFromBitArray(pos, 8);
    String c;
    switch (eightBitValue) {
      case 232:
        c = '!';
        break;
      case 233:
        c = '"';
        break;
      case 234:
        c = '%';
        break;
      case 235:
        c = '&';
        break;
      case 236:
        c = '\'';
        break;
      case 237:
        c = '(';
        break;
      case 238:
        c = ')';
        break;
      case 239:
        c = '*';
        break;
      case 240:
        c = '+';
        break;
      case 241:
        c = ',';
        break;
      case 242:
        c = '-';
        break;
      case 243:
        c = '.';
        break;
      case 244:
        c = '/';
        break;
      case 245:
        c = ':';
        break;
      case 246:
        c = ';';
        break;
      case 247:
        c = '<';
        break;
      case 248:
        c = '=';
        break;
      case 249:
        c = '>';
        break;
      case 250:
        c = '?';
        break;
      case 251:
        c = '_';
        break;
      case 252:
        c = ' ';
        break;
      default:
        throw FormatException();
    }
    return DecodedChar(pos + 8, c.codeUnitAt(0));
  }

  bool _isStillAlpha(int pos) {
    if (pos + 5 > this._information.getSize()) {
      return false;
    }

    // We now check if it's a valid 5-bit value (0..9 and FNC1)
    int fiveBitValue = extractNumericValueFromBitArray(pos, 5);
    if (fiveBitValue >= 5 && fiveBitValue < 16) {
      return true;
    }

    if (pos + 6 > this._information.getSize()) {
      return false;
    }

    int sixBitValue = extractNumericValueFromBitArray(pos, 6);
    return sixBitValue >= 16 && sixBitValue < 63; // 63 not included
  }

  DecodedChar _decodeAlphanumeric(int pos) {
    int fiveBitValue = extractNumericValueFromBitArray(pos, 5);
    if (fiveBitValue == 15) {
      return DecodedChar(pos + 5, DecodedChar.FNC1);
    }

    if (fiveBitValue >= 5 && fiveBitValue < 15) {
      return DecodedChar(pos + 5, ('0'.codeUnitAt(0) + fiveBitValue - 5));
    }

    int sixBitValue = extractNumericValueFromBitArray(pos, 6);

    if (sixBitValue >= 32 && sixBitValue < 58) {
      return DecodedChar(pos + 6, (sixBitValue + 33));
    }

    String c;
    switch (sixBitValue) {
      case 58:
        c = '*';
        break;
      case 59:
        c = ',';
        break;
      case 60:
        c = '-';
        break;
      case 61:
        c = '.';
        break;
      case 62:
        c = '/';
        break;
      default:
        throw Exception("Decoding invalid alphanumeric value: $sixBitValue");
    }
    return DecodedChar(pos + 6, c.codeUnitAt(0));
  }

  bool _isAlphaTo646ToAlphaLatch(int pos) {
    if (pos + 1 > this._information.getSize()) {
      return false;
    }

    for (int i = 0; i < 5 && i + pos < this._information.getSize(); ++i) {
      if (i == 2) {
        if (!this._information.get(pos + 2)) {
          return false;
        }
      } else if (this._information.get(pos + i)) {
        return false;
      }
    }

    return true;
  }

  bool _isAlphaOr646ToNumericLatch(int pos) {
    // Next is alphanumeric if there are 3 positions and they are all zeros
    if (pos + 3 > this._information.getSize()) {
      return false;
    }

    for (int i = pos; i < pos + 3; ++i) {
      if (this._information.get(i)) {
        return false;
      }
    }
    return true;
  }

  bool _isNumericToAlphaNumericLatch(int pos) {
    // Next is alphanumeric if there are 4 positions and they are all zeros, or
    // if there is a subset of this just before the end of the symbol
    if (pos + 1 > this._information.getSize()) {
      return false;
    }

    for (int i = 0; i < 4 && i + pos < this._information.getSize(); ++i) {
      if (this._information.get(pos + i)) {
        return false;
      }
    }
    return true;
  }
}
