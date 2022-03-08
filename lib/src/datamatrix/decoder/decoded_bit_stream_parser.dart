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

import 'dart:convert';
import 'dart:typed_data';

import '../../common/bit_source.dart';
import '../../common/decoder_result.dart';
import '../../common/eci_string_builder.dart';
import '../../common/string_builder.dart';
import '../../formats_exception.dart';

enum _Mode {
  PAD_ENCODE, // Not really a mode
  ASCII_ENCODE,
  C40_ENCODE,
  TEXT_ENCODE,
  ANSIX12_ENCODE,
  EDIFACT_ENCODE,
  BASE256_ENCODE,
  ECI_ENCODE
}

/// Data Matrix Codes can encode text as bits in one of several modes, and can use multiple modes
/// in one Data Matrix Code. This class decodes the bits back into text.
///
/// See ISO 16022:2006, 5.2.1 - 5.2.9.2
///
/// @author bbrown@google.com (Brian Brown)
/// @author Sean Owen
class DecodedBitStreamParser {
  /// See ISO 16022:2006, Annex C Table C.1
  /// The C40 Basic Character Set (*'s used for placeholders for the shift values)
  static const List<String> _C40_BASIC_SET_CHARS = [
    '*', '*', '*', ' ', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', //
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', //
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  static const List<String> _C40_SHIFT2_SET_CHARS = [
    '!', '"', '#', r'$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', //
    '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_'
  ];

  /// See ISO 16022:2006, Annex C Table C.2
  /// The Text Basic Character Set (*'s used for placeholders for the shift values)
  static const List<String> _TEXT_BASIC_SET_CHARS = [
    '*', '*', '*', ' ', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', //
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', //
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  ];

  // Shift 2 for Text is the same encoding as C40
  static const List<String> _TEXT_SHIFT2_SET_CHARS = _C40_SHIFT2_SET_CHARS;

  static const List<String> _TEXT_SHIFT3_SET_CHARS = [
    '`', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', //
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '{', '|', '}',
    '~', '\x7f'
  ];

  DecodedBitStreamParser._();

  static DecoderResult decode(Uint8List bytes) {
    BitSource bits = BitSource(bytes);
    ECIStringBuilder result = ECIStringBuilder();
    StringBuilder resultTrailer = StringBuilder();
    List<Uint8List> byteSegments = [];
    _Mode mode = _Mode.ASCII_ENCODE;
    // Could be replaceable by looking directly at 'bytes', if we're sure of not having to account for multi byte values.
    Set<int> fnc1Positions = {};
    int symbologyModifier = 0;
    bool isECIencoded = false;
    do {
      if (mode == _Mode.ASCII_ENCODE) {
        mode = _decodeAsciiSegment(bits, result, resultTrailer, fnc1Positions);
      } else {
        switch (mode) {
          case _Mode.C40_ENCODE:
            _decodeC40Segment(bits, result, fnc1Positions);
            break;
          case _Mode.TEXT_ENCODE:
            _decodeTextSegment(bits, result, fnc1Positions);
            break;
          case _Mode.ANSIX12_ENCODE:
            _decodeAnsiX12Segment(bits, result);
            break;
          case _Mode.EDIFACT_ENCODE:
            _decodeEdifactSegment(bits, result);
            break;
          case _Mode.BASE256_ENCODE:
            _decodeBase256Segment(bits, result, byteSegments);
            break;
          case _Mode.ECI_ENCODE:
            _decodeECISegment(bits, result);
            // ECI detection only, atm continue decoding as ASCII
            isECIencoded = true;
            break;
          default:
            throw FormatsException.instance;
        }
        mode = _Mode.ASCII_ENCODE;
      }
    } while (mode != _Mode.PAD_ENCODE && bits.available() > 0);
    if (resultTrailer.length > 0) {
      result.write(resultTrailer);
    }
    if (isECIencoded) {
      // Examples for this numbers can be found in this documentation of a hardware barcode scanner:
      // https://honeywellaidc.force.com/supportppr/s/article/List-of-barcode-symbology-AIM-Identifiers
      if (fnc1Positions.contains(0) || fnc1Positions.contains(4)) {
        symbologyModifier = 5;
      } else if (fnc1Positions.contains(1) || fnc1Positions.contains(5)) {
        symbologyModifier = 6;
      } else {
        symbologyModifier = 4;
      }
    } else {
      if (fnc1Positions.contains(0) || fnc1Positions.contains(4)) {
        symbologyModifier = 2;
      } else if (fnc1Positions.contains(1) || fnc1Positions.contains(5)) {
        symbologyModifier = 3;
      } else {
        symbologyModifier = 1;
      }
    }

    return DecoderResult(
      bytes,
      result.toString(),
      byteSegments.isEmpty ? null : byteSegments,
      null,
      symbologyModifier: symbologyModifier,
    );
  }

  /// See ISO 16022:2006, 5.2.3 and Annex C, Table C.2
  static _Mode _decodeAsciiSegment(
    BitSource bits,
    ECIStringBuilder result,
    StringBuilder resultTrailer,
    Set<int> fnc1positions,
  ) {
    bool upperShift = false;
    do {
      int oneByte = bits.readBits(8);
      if (oneByte == 0) {
        throw FormatsException.instance;
      } else if (oneByte <= 128) {
        // ASCII data (ASCII value + 1)
        if (upperShift) {
          oneByte += 128;
          //upperShift = false;
        }
        result.writeCharCode(oneByte - 1);
        return _Mode.ASCII_ENCODE;
      } else if (oneByte == 129) {
        // Pad
        return _Mode.PAD_ENCODE;
      } else if (oneByte <= 229) {
        // 2-digit data 00-99 (Numeric Value + 130)
        int value = oneByte - 130;
        if (value < 10) {
          // pad with '0' for single digit values
          result.write('0');
        }
        result.write(value);
      } else {
        switch (oneByte) {
          case 230: // Latch to C40 encodation
            return _Mode.C40_ENCODE;
          case 231: // Latch to Base 256 encodation
            return _Mode.BASE256_ENCODE;
          case 232: // FNC1
            fnc1positions.add(result.length);
            result.writeCharCode(29); // translate as ASCII 29
            break;
          case 233: // Structured Append
          case 234: // Reader Programming
            // Ignore these symbols for now
            //throw ReaderException.getInstance();
            break;
          case 235: // Upper Shift (shift to Extended ASCII)
            upperShift = true;
            break;
          case 236: // 05 Macro
            result.write("[)>\u001E05\u001D");
            resultTrailer.insert(0, "\u001E\u0004");
            break;
          case 237: // 06 Macro
            result.write("[)>\u001E06\u001D");
            resultTrailer.insert(0, "\u001E\u0004");
            break;
          case 238: // Latch to ANSI X12 encodation
            return _Mode.ANSIX12_ENCODE;
          case 239: // Latch to Text encodation
            return _Mode.TEXT_ENCODE;
          case 240: // Latch to EDIFACT encodation
            return _Mode.EDIFACT_ENCODE;
          case 241: // ECI Character
            return _Mode.ECI_ENCODE;
          default:
            // Not to be used in ASCII encodation
            // but work around encoders that end with 254, latch back to ASCII
            if (oneByte != 254 || bits.available() != 0) {
              throw FormatsException.instance;
            }
            break;
        }
      }
    } while (bits.available() > 0);
    return _Mode.ASCII_ENCODE;
  }

  /// See ISO 16022:2006, 5.2.5 and Annex C, Table C.1
  static void _decodeC40Segment(
    BitSource bits,
    ECIStringBuilder result,
    Set<int> fnc1positions,
  ) {
    // Three C40 values are encoded in a 16-bit value as
    // (1600 * C1) + (40 * C2) + C3 + 1
    // TODO(bbrown): The Upper Shift with C40 doesn't work in the 4 value scenario all the time
    bool upperShift = false;

    List<int> cValues = [0, 0, 0];
    int shift = 0;

    do {
      // If there is only one byte left then it will be encoded as ASCII
      if (bits.available() == 8) {
        return;
      }
      int firstByte = bits.readBits(8);
      if (firstByte == 254) {
        // Unlatch codeword
        return;
      }

      _parseTwoBytes(firstByte, bits.readBits(8), cValues);

      for (int i = 0; i < 3; i++) {
        int cValue = cValues[i];
        switch (shift) {
          case 0:
            if (cValue < 3) {
              shift = cValue + 1;
            } else if (cValue < _C40_BASIC_SET_CHARS.length) {
              int c40char = _C40_BASIC_SET_CHARS[cValue].codeUnitAt(0);
              if (upperShift) {
                result.writeCharCode(c40char + 128);
                upperShift = false;
              } else {
                result.writeCharCode(c40char);
              }
            } else {
              throw FormatsException.instance;
            }
            break;
          case 1:
            if (upperShift) {
              result.writeCharCode(cValue + 128);
              upperShift = false;
            } else {
              result.writeCharCode(cValue);
            }
            shift = 0;
            break;
          case 2:
            if (cValue < _C40_SHIFT2_SET_CHARS.length) {
              int c40char = _C40_SHIFT2_SET_CHARS[cValue].codeUnitAt(0);
              if (upperShift) {
                result.writeCharCode(c40char + 128);
                upperShift = false;
              } else {
                result.writeCharCode(c40char);
              }
            } else {
              switch (cValue) {
                case 27: // FNC1
                  fnc1positions.add(result.length);
                  result.writeCharCode(29); // translate as ASCII 29
                  break;
                case 30: // Upper Shift
                  upperShift = true;
                  break;
                default:
                  throw FormatsException.instance;
              }
            }
            shift = 0;
            break;
          case 3:
            if (upperShift) {
              result.writeCharCode(cValue + 224);
              upperShift = false;
            } else {
              result.writeCharCode(cValue + 96);
            }
            shift = 0;
            break;
          default:
            throw FormatsException.instance;
        }
      }
    } while (bits.available() > 0);
  }

  /// See ISO 16022:2006, 5.2.6 and Annex C, Table C.2
  static void _decodeTextSegment(
      BitSource bits, ECIStringBuilder result, Set<int> fnc1positions) {
    // Three Text values are encoded in a 16-bit value as
    // (1600 * C1) + (40 * C2) + C3 + 1
    // TODO(bbrown): The Upper Shift with Text doesn't work in the 4 value scenario all the time
    bool upperShift = false;

    List<int> cValues = [0, 0, 0];
    int shift = 0;
    do {
      // If there is only one byte left then it will be encoded as ASCII
      if (bits.available() == 8) {
        return;
      }
      int firstByte = bits.readBits(8);
      if (firstByte == 254) {
        // Unlatch codeword
        return;
      }

      _parseTwoBytes(firstByte, bits.readBits(8), cValues);

      for (int i = 0; i < 3; i++) {
        int cValue = cValues[i];
        switch (shift) {
          case 0:
            if (cValue < 3) {
              shift = cValue + 1;
            } else if (cValue < _TEXT_BASIC_SET_CHARS.length) {
              int textChar = _TEXT_BASIC_SET_CHARS[cValue].codeUnitAt(0);
              if (upperShift) {
                result.writeCharCode(textChar + 128);
                upperShift = false;
              } else {
                result.writeCharCode(textChar);
              }
            } else {
              throw FormatsException.instance;
            }
            break;
          case 1:
            if (upperShift) {
              result.writeCharCode(cValue + 128);
              upperShift = false;
            } else {
              result.writeCharCode(cValue);
            }
            shift = 0;
            break;
          case 2:
            // Shift 2 for Text is the same encoding as C40
            if (cValue < _TEXT_SHIFT2_SET_CHARS.length) {
              int textChar = _TEXT_SHIFT2_SET_CHARS[cValue].codeUnitAt(0);
              if (upperShift) {
                result.writeCharCode(textChar + 128);
                upperShift = false;
              } else {
                result.writeCharCode(textChar);
              }
            } else {
              switch (cValue) {
                case 27: // FNC1
                  fnc1positions.add(result.length);
                  result.writeCharCode(29); // translate as ASCII 29
                  break;
                case 30: // Upper Shift
                  upperShift = true;
                  break;
                default:
                  throw FormatsException.instance;
              }
            }
            shift = 0;
            break;
          case 3:
            if (cValue < _TEXT_SHIFT3_SET_CHARS.length) {
              int textChar = _TEXT_SHIFT3_SET_CHARS[cValue].codeUnitAt(0);
              if (upperShift) {
                result.writeCharCode(textChar + 128);
                upperShift = false;
              } else {
                result.writeCharCode(textChar);
              }
              shift = 0;
            } else {
              throw FormatsException.instance;
            }
            break;
          default:
            throw FormatsException.instance;
        }
      }
    } while (bits.available() > 0);
  }

  /// See ISO 16022:2006, 5.2.7
  static void _decodeAnsiX12Segment(BitSource bits, ECIStringBuilder result) {
    // Three ANSI X12 values are encoded in a 16-bit value as
    // (1600 * C1) + (40 * C2) + C3 + 1

    List<int> cValues = [0, 0, 0];
    do {
      // If there is only one byte left then it will be encoded as ASCII
      if (bits.available() == 8) {
        return;
      }
      int firstByte = bits.readBits(8);
      if (firstByte == 254) {
        // Unlatch codeword
        return;
      }

      _parseTwoBytes(firstByte, bits.readBits(8), cValues);

      for (int i = 0; i < 3; i++) {
        int cValue = cValues[i];
        switch (cValue) {
          case 0: // X12 segment terminator <CR>
            result.write('\r');
            break;
          case 1: // X12 segment separator *
            result.write('*');
            break;
          case 2: // X12 sub-element separator >
            result.write('>');
            break;
          case 3: // space
            result.write(' ');
            break;
          default:
            if (cValue < 14) {
              // 0 - 9
              result.writeCharCode(cValue + 44);
            } else if (cValue < 40) {
              // A - Z
              result.writeCharCode(cValue + 51);
            } else {
              throw FormatsException.instance;
            }
            break;
        }
      }
    } while (bits.available() > 0);
  }

  static void _parseTwoBytes(int firstByte, int secondByte, List<int> result) {
    int fullBitValue = (firstByte << 8) + secondByte - 1;
    int temp = fullBitValue ~/ 1600;
    result[0] = temp;
    fullBitValue -= temp * 1600;
    temp = fullBitValue ~/ 40;
    result[1] = temp;
    result[2] = fullBitValue - temp * 40;
  }

  /// See ISO 16022:2006, 5.2.8 and Annex C Table C.3
  static void _decodeEdifactSegment(BitSource bits, ECIStringBuilder result) {
    do {
      // If there is only two or less bytes left then it will be encoded as ASCII
      if (bits.available() <= 16) {
        return;
      }

      for (int i = 0; i < 4; i++) {
        int edifactValue = bits.readBits(6);

        // Check for the unlatch character
        if (edifactValue == 0x1F) {
          // 011111
          // Read rest of byte, which should be 0, and stop
          int bitsLeft = 8 - bits.bitOffset;
          if (bitsLeft != 8) {
            bits.readBits(bitsLeft);
          }
          return;
        }

        if ((edifactValue & 0x20) == 0) {
          // no 1 in the leading (6th) bit
          edifactValue |= 0x40; // Add a leading 01 to the 6 bit binary value
        }
        result.writeCharCode(edifactValue);
      }
    } while (bits.available() > 0);
  }

  /// See ISO 16022:2006, 5.2.9 and Annex B, B.2
  static void _decodeBase256Segment(
      BitSource bits, ECIStringBuilder result, List<Uint8List> byteSegments) {
    // Figure out how long the Base 256 Segment is.
    int codewordPosition = 1 + bits.byteOffset; // position is 1-indexed
    int d1 = _unrandomize255State(bits.readBits(8), codewordPosition++);
    int count;
    if (d1 == 0) {
      // Read the remainder of the symbol
      count = bits.available() ~/ 8;
    } else if (d1 < 250) {
      count = d1;
    } else {
      count = 250 * (d1 - 249) +
          _unrandomize255State(
            bits.readBits(8),
            codewordPosition++,
          );
    }

    // We're seeing NegativeArraySizeException errors from users.
    if (count < 0) {
      throw FormatsException.instance;
    }

    Uint8List bytes = Uint8List(count);
    for (int i = 0; i < count; i++) {
      // Have seen this particular error in the wild, such as at
      // http://www.bcgen.com/demo/IDAutomationStreamingDataMatrix.aspx?MODE=3&D=Fred&PFMT=3&PT=F&X=0.3&O=0&LM=0.2
      if (bits.available() < 8) {
        throw FormatsException.instance;
      }
      bytes[i] = _unrandomize255State(bits.readBits(8), codewordPosition++);
    }
    byteSegments.add(bytes);
    result.write(latin1.decode(Uint8List.fromList(bytes)));
  }

  /// See ISO 16022:2007, 5.4.1
  static void _decodeECISegment(BitSource bits, ECIStringBuilder result) {
    if (bits.available() < 8) {
      throw FormatsException.instance;
    }
    int c1 = bits.readBits(8);
    if (c1 <= 127) {
      result.appendECI(c1 - 1);
    }
    //currently we only support character set ECIs
    /*} else {
      if (bits.available() < 8) {
        throw FormatException.getFormatInstance();
      }
      int c2 = bits.readBits(8);
      if (c1 >= 128 && c1 <= 191) {
      } else {
        if (bits.available() < 8) {
          throw FormatException.getFormatInstance();
        }
        int c3 = bits.readBits(8);
      }
    }*/
  }

  /// See ISO 16022:2006, Annex B, B.2
  static int _unrandomize255State(
      int randomizedBase256Codeword, int base256CodewordPosition) {
    int pseudoRandomNumber = ((149 * base256CodewordPosition) % 255) + 1;
    int tempVariable = randomizedBase256Codeword - pseudoRandomNumber;
    return tempVariable >= 0 ? tempVariable : tempVariable + 256;
  }
}
