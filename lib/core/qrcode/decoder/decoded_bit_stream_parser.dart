/*
 * Copyright 2007 ZXing authors
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
import '../../common/character_set_eci.dart';
import '../../common/decoder_result.dart';
import '../../common/string_builder.dart';
import '../../common/string_utils.dart';

import '../../decode_hint_type.dart';
import 'error_correction_level.dart';
import 'mode.dart';
import 'version.dart';

/// <p>QR Codes can encode text as bits in one of several modes, and can use multiple modes
/// in one QR Code. This class decodes the bits back into text.</p>
///
/// <p>See ISO 18004:2006, 6.4.3 - 6.4.7</p>
///
/// @author Sean Owen
class DecodedBitStreamParser {
  /// See ISO 18004:2006, 6.4.4 Table 5
  static final List<String> _alphaNumericChars =
      r"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:".split('');
  static final int _gbkSubset = 1;

  DecodedBitStreamParser._();

  static DecoderResult decode(Uint8List bytes, Version version,
      ErrorCorrectionLevel? ecLevel, Map<DecodeHintType, Object>? hints) {
    BitSource bits = BitSource(bytes);
    StringBuilder result = StringBuilder();
    List<Uint8List> byteSegments = []; //new ArrayList<>(1);
    int symbolSequence = -1;
    int parityData = -1;
    int symbologyModifier;

    try {
      CharacterSetECI? currentCharacterSetECI;
      bool fc1InEffect = false;
      bool hasFNC1first = false;
      bool hasFNC1second = false;
      Mode mode;
      do {
        // While still another segment to read...
        if (bits.available() < 4) {
          // OK, assume we're done. Really, a TERMINATOR mode should have been recorded here
          mode = Mode.TERMINATOR;
        } else {
          mode = Mode.values[bits.readBits(4)]!; // mode is encoded by 4 bits
        }
        switch (mode) {
          case Mode.TERMINATOR:
            break;
          case Mode.FNC1_FIRST_POSITION:
            hasFNC1first = true; // symbology detection
            // We do little with FNC1 except alter the parsed result a bit according to the spec
            fc1InEffect = true;
            break;
          case Mode.FNC1_SECOND_POSITION:
            hasFNC1second = true; // symbology detection
            // We do little with FNC1 except alter the parsed result a bit according to the spec
            fc1InEffect = true;
            break;
          case Mode.STRUCTURED_APPEND:
            if (bits.available() < 16) {
              throw FormatException();
            }
            // sequence number and parity is added later to the result metadata
            // Read next 8 bits (symbol sequence #) and 8 bits (parity data), then continue
            symbolSequence = bits.readBits(8);
            parityData = bits.readBits(8);
            break;
          case Mode.ECI:
            // Count doesn't apply to ECI
            int value = _parseECIValue(bits);
            currentCharacterSetECI =
                CharacterSetECI.getCharacterSetECIByValue(value);
            if (currentCharacterSetECI == null) {
              throw FormatException();
            }
            break;
          case Mode.HANZI:
            // First handle Hanzi mode which does not start with character count
            // Chinese mode contains a sub set indicator right after mode indicator
            int subset = bits.readBits(4);
            int countHanzi = bits.readBits(mode.getCharacterCountBits(version));
            if (subset == _gbkSubset) {
              _decodeHanziSegment(bits, result, countHanzi);
            }
            break;
          default:
            // "Normal" QR code modes:
            // How many characters will follow, encoded in this mode?
            int count = bits.readBits(mode.getCharacterCountBits(version));
            switch (mode) {
              case Mode.NUMERIC:
                _decodeNumericSegment(bits, result, count);
                break;
              case Mode.ALPHANUMERIC:
                _decodeAlphanumericSegment(bits, result, count, fc1InEffect);
                break;
              case Mode.BYTE:
                _decodeByteSegment(bits, result, count, currentCharacterSetECI!,
                    byteSegments, hints);
                break;
              case Mode.KANJI:
                _decodeKanjiSegment(bits, result, count);
                break;
              default:
                throw FormatException();
            }
            break;
        }
      } while (mode != Mode.TERMINATOR);

      if (currentCharacterSetECI != null) {
        if (hasFNC1first) {
          symbologyModifier = 4;
        } else if (hasFNC1second) {
          symbologyModifier = 6;
        } else {
          symbologyModifier = 2;
        }
      } else {
        if (hasFNC1first) {
          symbologyModifier = 3;
        } else if (hasFNC1second) {
          symbologyModifier = 5;
        } else {
          symbologyModifier = 1;
        }
      }
    } catch (iae) {
      // on IllegalArgumentException
      // from readBits() calls
      throw FormatException();
    }

    return DecoderResult(
        bytes,
        result.toString(),
        byteSegments.isEmpty ? null : byteSegments,
        ecLevel == null ? null : ecLevel.toString(),
        symbolSequence,
        parityData,
        symbologyModifier);
  }

  /// See specification GBT 18284-2000
  static void _decodeHanziSegment(
      BitSource bits, StringBuffer result, int count) {
    // Don't crash trying to read more bits than we have available.
    if (count * 13 > bits.available()) {
      throw FormatException();
    }

    // Each character will require 2 bytes. Read the characters as 2-byte pairs
    // and decode as GB2312 afterwards
    Uint8List buffer = Uint8List(2 * count);
    int offset = 0;
    while (count > 0) {
      // Each 13 bits encodes a 2-byte character
      int twoBytes = bits.readBits(13);
      int assembledTwoBytes = (((twoBytes ~/ 0x060) << 8) & 0xFFFFFFFF) | (twoBytes % 0x060);
      if (assembledTwoBytes < 0x00A00) {
        // In the 0xA1A1 to 0xAAFE range
        assembledTwoBytes += 0x0A1A1;
      } else {
        // In the 0xB0A1 to 0xFAFE range
        assembledTwoBytes += 0x0A6A1;
      }
      buffer[offset] = ((assembledTwoBytes >> 8) & 0xFF);
      buffer[offset + 1] = (assembledTwoBytes & 0xFF);
      offset += 2;
      count--;
    }

    result.write(StringUtils.gbkCharset!.decode(buffer));
  }

  static void _decodeKanjiSegment(
      BitSource bits, StringBuffer result, int count) {
    // Don't crash trying to read more bits than we have available.
    if (count * 13 > bits.available()) {
      throw FormatException();
    }

    // Each character will require 2 bytes. Read the characters as 2-byte pairs
    // and decode as Shift_JIS afterwards
    Uint8List buffer = Uint8List(2 * count);
    int offset = 0;
    while (count > 0) {
      // Each 13 bits encodes a 2-byte character
      int twoBytes = bits.readBits(13);
      int assembledTwoBytes = (((twoBytes ~/ 0x0C0) << 8) & 0xFFFFFFFF) | (twoBytes % 0x0C0);
      if (assembledTwoBytes < 0x01F00) {
        // In the 0x8140 to 0x9FFC range
        assembledTwoBytes += 0x08140;
      } else {
        // In the 0xE040 to 0xEBBF range
        assembledTwoBytes += 0x0C140;
      }
      buffer[offset] = (assembledTwoBytes >> 8);
      buffer[offset + 1] = assembledTwoBytes;
      offset += 2;
      count--;
    }
    result.write(StringUtils.shiftJisCharset!.decode(buffer));
  }

  static void _decodeByteSegment(BitSource bits, StringBuffer result, int count,
      CharacterSetECI? currentCharacterSetECI, List<Uint8List> byteSegments,
      [Map<DecodeHintType, Object>? hints]) {
    // Don't crash trying to read more bits than we have available.
    if (8 * count > bits.available()) {
      throw FormatException();
    }

    Uint8List readBytes = Uint8List(count);
    for (int i = 0; i < count; i++) {
      readBytes[i] = bits.readBits(8);
    }
    Encoding? encoding;
    if (currentCharacterSetECI == null) {
      // The spec isn't clear on this mode; see
      // section 6.4.5: t does not say which encoding to assuming
      // upon decoding. I have seen ISO-8859-1 used as well as
      // Shift_JIS -- without anything like an ECI designator to
      // give a hint.
      encoding = StringUtils.guessCharset(readBytes, hints);
    } else {
      encoding = currentCharacterSetECI.getCharset();
    }

    result.write(encoding!.decode(readBytes));
    byteSegments.add(readBytes);
  }

  static String _toAlphaNumericChar(int value) {
    if (value >= _alphaNumericChars.length) {
      throw FormatException();
    }
    return _alphaNumericChars[value];
  }

  static void _decodeAlphanumericSegment(
      BitSource bits, StringBuilder result, int count, bool fc1InEffect) {
    // Read two characters at a time
    int start = result.length;
    while (count > 1) {
      if (bits.available() < 11) {
        throw FormatException();
      }
      int nextTwoCharsBits = bits.readBits(11);
      result.write(_toAlphaNumericChar(nextTwoCharsBits ~/ 45));
      result.write(_toAlphaNumericChar(nextTwoCharsBits % 45));
      count -= 2;
    }
    if (count == 1) {
      // special case: one character left
      if (bits.available() < 6) {
        throw FormatException();
      }
      result.write(_toAlphaNumericChar(bits.readBits(6)));
    }
    // See section 6.4.8.1, 6.4.8.2
    if (fc1InEffect) {
      // We need to massage the result a bit if in an FNC1 mode:
      for (int i = start; i < result.length; i++) {
        if (result.charAt(i) == '%') {
          if (i < result.length - 1 && result[i + 1] == '%') {
            // %% is rendered as %
            result.deleteCharAt(i + 1);
          } else {
            // In alpha mode, % should be converted to FNC1 separator 0x1D
            result.setCharAt(i, 0x1D);
          }
        }
      }
    }
  }

  static void _decodeNumericSegment(
      BitSource bits, StringBuffer result, int count) {
    // Read three digits at a time
    while (count >= 3) {
      // Each 10 bits encodes three digits
      if (bits.available() < 10) {
        throw FormatException();
      }
      int threeDigitsBits = bits.readBits(10);
      if (threeDigitsBits >= 1000) {
        throw FormatException();
      }
      result.write(_toAlphaNumericChar(threeDigitsBits ~/ 100));
      result.write(_toAlphaNumericChar((threeDigitsBits ~/ 10) % 10));
      result.write(_toAlphaNumericChar(threeDigitsBits % 10));
      count -= 3;
    }
    if (count == 2) {
      // Two digits left over to read, encoded in 7 bits
      if (bits.available() < 7) {
        throw FormatException();
      }
      int twoDigitsBits = bits.readBits(7);
      if (twoDigitsBits >= 100) {
        throw FormatException();
      }
      result.write(_toAlphaNumericChar(twoDigitsBits ~/ 10));
      result.write(_toAlphaNumericChar(twoDigitsBits % 10));
    } else if (count == 1) {
      // One digit left over to read
      if (bits.available() < 4) {
        throw FormatException();
      }
      int digitBits = bits.readBits(4);
      if (digitBits >= 10) {
        throw FormatException();
      }
      result.write(_toAlphaNumericChar(digitBits));
    }
  }

  static int _parseECIValue(BitSource bits) {
    int firstByte = bits.readBits(8);
    if ((firstByte & 0x80) == 0) {
      // just one byte
      return firstByte & 0x7F;
    }
    if ((firstByte & 0xC0) == 0x80) {
      // two bytes
      int secondByte = bits.readBits(8);
      return (((firstByte & 0x3F) << 8) & 0xFFFFFFFF) | secondByte;
    }
    if ((firstByte & 0xE0) == 0xC0) {
      // three bytes
      int secondThirdBytes = bits.readBits(16);
      return (((firstByte & 0x1F) << 16) & 0xFFFFFFFF) | secondThirdBytes;
    }
    throw FormatException();
  }
}
