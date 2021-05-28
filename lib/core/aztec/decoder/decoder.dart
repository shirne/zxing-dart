/*
 * Copyright 2010 ZXing authors
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

import 'package:zxing/core/common/bit_matrix.dart';
import 'package:zxing/core/common/character_set_eci.dart';
import 'package:zxing/core/common/decoder_result.dart';
import 'package:zxing/core/common/reedsolomon/generic_gf.dart';
import 'package:zxing/core/common/reedsolomon/reed_solomon_decoder.dart';

import '../aztec_detector_result.dart';

enum Table { UPPER, LOWER, MIXED, DIGIT, PUNCT, BINARY }

class CorrectedBitsResult {
  final List<bool> correctBits;
  final int ecLevel;

  CorrectedBitsResult(this.correctBits, this.ecLevel);
}

/**
 * <p>The main class which implements Aztec Code decoding -- as opposed to locating and extracting
 * the Aztec Code from an image.</p>
 *
 * @author David Olivier
 */
class Decoder {
  static final List<String> UPPER_TABLE = [
    "CTRL_PS", " ", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", //
    "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", //
    "X", "Y", "Z", "CTRL_LL", "CTRL_ML", "CTRL_DL", "CTRL_BS"
  ];

  static final List<String> LOWER_TABLE = [
    "CTRL_PS", " ", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", //
    "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", //
    "x", "y", "z", "CTRL_US", "CTRL_ML", "CTRL_DL", "CTRL_BS"
  ];

  static final List<String> MIXED_TABLE = [
    "CTRL_PS", " ", "\1", "\2", "\3", "\4", "\5", "\6", "\7", "\b", "\t",
    "\n", //
    "\13", "\f", "\r", "\33", "\34", "\35", "\36", "\37", "@", "\\", "^", "_",
    "`", "|", "~", "\177", "CTRL_LL", "CTRL_UL", "CTRL_PL", "CTRL_BS"
  ];

  static final List<String> PUNCT_TABLE = [
    "FLG(n)", "\r", "\r\n", ". ", ", ", ": ", "!", "\"", "#", r"$", "%", "&",
    "'", "(", ")", //
    "*", "+", ",", "-", ".", "/", ":", ";", "<", "=", ">", "?", "[", "]", "{",
    "}", "CTRL_UL"
  ];

  static final List<String> DIGIT_TABLE = [
    "CTRL_PS", " ", "0", "1", "2", "3", "4", "5", "6", "7", "8", //
    "9", ",", ".", "CTRL_UL", "CTRL_US"
  ];

  static final Encoding DEFAULT_ENCODING = latin1;

  late AztecDetectorResult ddata;

  DecoderResult decode(AztecDetectorResult detectorResult) {
    ddata = detectorResult;
    BitMatrix matrix = detectorResult.getBits();
    List<bool> rawbits = extractBits(matrix);
    CorrectedBitsResult correctedBits = correctBits(rawbits);
    Uint8List rawBytes = convertBoolArrayToByteArray(correctedBits.correctBits);
    String result = getEncodedData(correctedBits.correctBits);
    DecoderResult decoderResult =
        new DecoderResult(rawBytes, result, null, "${correctedBits.ecLevel}%");
    decoderResult.setNumBits(correctedBits.correctBits.length);
    return decoderResult;
  }

  // This method is used for testing the high-level encoder
  static String highLevelDecode(List<bool> correctedBits) {
    return getEncodedData(correctedBits);
  }

  /**
   * Gets the string encoded in the aztec code bits
   *
   * @return the decoded string
   */
  static String getEncodedData(List<bool> correctedBits) {
    int endIndex = correctedBits.length;
    Table latchTable = Table.UPPER; // table most recently latched to
    Table shiftTable = Table.UPPER; // table to use for the next read

    // Final decoded string result
    // (correctedBits-5) / 4 is an upper bound on the size (all-digit result)
    StringBuffer result = StringBuffer();

    // Intermediary buffer of decoded bytes, which is decoded into a string and flushed
    // when character encoding changes (ECI) or input ends.
    BytesBuilder decodedBytes = BytesBuilder();
    Encoding encoding = DEFAULT_ENCODING;

    int index = 0;
    while (index < endIndex) {
      if (shiftTable == Table.BINARY) {
        if (endIndex - index < 5) {
          break;
        }
        int length = readCode(correctedBits, index, 5);
        index += 5;
        if (length == 0) {
          if (endIndex - index < 11) {
            break;
          }
          length = readCode(correctedBits, index, 11) + 31;
          index += 11;
        }
        for (int charCount = 0; charCount < length; charCount++) {
          if (endIndex - index < 8) {
            index = endIndex; // Force outer loop to exit
            break;
          }
          int code = readCode(correctedBits, index, 8);
          decodedBytes.addByte(code);
          index += 8;
        }
        // Go back to whatever mode we had been in
        shiftTable = latchTable;
      } else {
        int size = shiftTable == Table.DIGIT ? 4 : 5;
        if (endIndex - index < size) {
          break;
        }
        int code = readCode(correctedBits, index, size);
        index += size;
        String str = getCharacter(shiftTable, code);
        if ("FLG(n)" == str) {
          if (endIndex - index < 3) {
            break;
          }
          int n = readCode(correctedBits, index, 3);
          index += 3;
          switch (n) {
            case 0:
              result.writeCharCode(29); // translate FNC1 as ASCII 29
              break;
            case 7:
              throw FormatException(); // FLG(7) is reserved and illegal
            default:
              // flush bytes before changing character set
              try {
                result.write(decodedBytes.toString());
              } catch (uee) {
                // UnsupportedEncodingException
                // can't happen
                throw Exception(uee);
              }
              decodedBytes.clear();

              // ECI is decimal integer encoded as 1-6 codes in DIGIT mode
              int eci = 0;
              if (endIndex - index < 4 * n) {
                break;
              }
              while (n-- > 0) {
                int nextDigit = readCode(correctedBits, index, 4);
                index += 4;
                if (nextDigit < 2 || nextDigit > 11) {
                  throw FormatException(); // Not a decimal digit
                }
                eci = eci * 10 + (nextDigit - 2);
              }
              CharacterSetECI charsetECI =
                  CharacterSetECI.getCharacterSetECIByValue(eci)!;
              encoding = charsetECI.getCharset()!;
          }
          // Go back to whatever mode we had been in
          shiftTable = latchTable;
        } else if (str.startsWith("CTRL_")) {
          // Table changes
          // ISO/IEC 24778:2008 prescribes ending a shift sequence in the mode from which it was invoked.
          // That's including when that mode is a shift.
          // Our test case dlusbs.png for issue #642 exercises that.
          latchTable =
              shiftTable; // Latch the current mode, so as to return to Upper after U/S B/S
          shiftTable = getTable(str[5]);
          if (str[6] == 'L') {
            latchTable = shiftTable;
          }
        } else {
          // Though stored as a table of strings for convenience, codes actually represent 1 or 2 *bytes*.
          Uint8List b = ascii.encode(str);
          decodedBytes.add(b);
          // Go back to whatever mode we had been in
          shiftTable = latchTable;
        }
      }
    }
    try {
      result.write(encoding.decode(decodedBytes.takeBytes()));
    } catch (uee) {
      // UnsupportedEncodingException
      // can't happen
      throw Exception(uee);
    }
    return result.toString();
  }

  /**
   * gets the table corresponding to the char passed
   */
  static Table getTable(String t) {
    switch (t) {
      case 'L':
        return Table.LOWER;
      case 'P':
        return Table.PUNCT;
      case 'M':
        return Table.MIXED;
      case 'D':
        return Table.DIGIT;
      case 'B':
        return Table.BINARY;
      case 'U':
      default:
        return Table.UPPER;
    }
  }

  /**
   * Gets the character (or string) corresponding to the passed code in the given table
   *
   * @param table the table used
   * @param code the code of the character
   */
  static String getCharacter(Table table, int code) {
    switch (table) {
      case Table.UPPER:
        return UPPER_TABLE[code];
      case Table.LOWER:
        return LOWER_TABLE[code];
      case Table.MIXED:
        return MIXED_TABLE[code];
      case Table.PUNCT:
        return PUNCT_TABLE[code];
      case Table.DIGIT:
        return DIGIT_TABLE[code];
      default:
        // Should not reach here.
        throw Exception("Bad table");
    }
  }

  /**
   * <p>Performs RS error correction on an array of bits.</p>
   *
   * @return the corrected array
   * @throws FormatException if the input contains too many errors
   */
  CorrectedBitsResult correctBits(List<bool> rawbits) {
    GenericGF gf;
    int codewordSize;

    if (ddata.getNbLayers() <= 2) {
      codewordSize = 6;
      gf = GenericGF.AZTEC_DATA_6;
    } else if (ddata.getNbLayers() <= 8) {
      codewordSize = 8;
      gf = GenericGF.AZTEC_DATA_8;
    } else if (ddata.getNbLayers() <= 22) {
      codewordSize = 10;
      gf = GenericGF.AZTEC_DATA_10;
    } else {
      codewordSize = 12;
      gf = GenericGF.AZTEC_DATA_12;
    }

    int numDataCodewords = ddata.getNbDatablocks();
    int numCodewords = rawbits.length ~/ codewordSize;
    if (numCodewords < numDataCodewords) {
      throw FormatException();
    }
    int offset = rawbits.length % codewordSize;

    List<int> dataWords = List.filled(numCodewords, 0);
    for (int i = 0; i < numCodewords; i++, offset += codewordSize) {
      dataWords[i] = readCode(rawbits, offset, codewordSize);
    }

    try {
      ReedSolomonDecoder rsDecoder = new ReedSolomonDecoder(gf);
      rsDecoder.decode(dataWords, numCodewords - numDataCodewords);
    } catch (ex) {
      // ReedSolomonException
      throw FormatException(ex.toString());
    }

    // Now perform the unstuffing operation.
    // First, count how many bits are going to be thrown out as stuffing
    int mask = (1 << codewordSize) - 1;
    int stuffedBits = 0;
    for (int i = 0; i < numDataCodewords; i++) {
      int dataWord = dataWords[i];
      if (dataWord == 0 || dataWord == mask) {
        throw FormatException();
      } else if (dataWord == 1 || dataWord == mask - 1) {
        stuffedBits++;
      }
    }
    // Now, actually unpack the bits and remove the stuffing
    List<bool> correctedBits =
        List.filled(numDataCodewords * codewordSize - stuffedBits, false);
    int index = 0;
    for (int i = 0; i < numDataCodewords; i++) {
      int dataWord = dataWords[i];
      if (dataWord == 1 || dataWord == mask - 1) {
        // next codewordSize-1 bits are all zeros or all ones
        correctedBits.fillRange(index, index + codewordSize - 1, dataWord > 1);
        //Arrays.fill(correctedBits, index, index + codewordSize - 1, dataWord > 1);
        index += codewordSize - 1;
      } else {
        for (int bit = codewordSize - 1; bit >= 0; --bit) {
          correctedBits[index++] = (dataWord & (1 << bit)) != 0;
        }
      }
    }

    return new CorrectedBitsResult(
        correctedBits, 100 * (numCodewords - numDataCodewords) ~/ numCodewords);
  }

  /**
   * Gets the array of bits from an Aztec Code matrix
   *
   * @return the array of bits
   */
  List<bool> extractBits(BitMatrix matrix) {
    bool compact = ddata.isCompact();
    int layers = ddata.getNbLayers();
    int baseMatrixSize =
        (compact ? 11 : 14) + layers * 4; // not including alignment lines
    List<int> alignmentMap = List.filled(baseMatrixSize, 0);
    List<bool> rawbits = List.filled(totalBitsInLayer(layers, compact), false);

    if (compact) {
      for (int i = 0; i < alignmentMap.length; i++) {
        alignmentMap[i] = i;
      }
    } else {
      int matrixSize =
          baseMatrixSize + 1 + 2 * ((baseMatrixSize ~/ 2 - 1) ~/ 15);
      int origCenter = baseMatrixSize ~/ 2;
      int center = matrixSize ~/ 2;
      for (int i = 0; i < origCenter; i++) {
        int newOffset = i + i ~/ 15;
        alignmentMap[origCenter - i - 1] = center - newOffset - 1;
        alignmentMap[origCenter + i] = center + newOffset + 1;
      }
    }
    for (int i = 0, rowOffset = 0; i < layers; i++) {
      int rowSize = (layers - i) * 4 + (compact ? 9 : 12);
      // The top-left most point of this layer is <low, low> (not including alignment lines)
      int low = i * 2;
      // The bottom-right most point of this layer is <high, high> (not including alignment lines)
      int high = baseMatrixSize - 1 - low;
      // We pull bits from the two 2 x rowSize columns and two rowSize x 2 rows
      for (int j = 0; j < rowSize; j++) {
        int columnOffset = j * 2;
        for (int k = 0; k < 2; k++) {
          // left column
          rawbits[rowOffset + columnOffset + k] =
              matrix.get(alignmentMap[low + k], alignmentMap[low + j]);
          // bottom row
          rawbits[rowOffset + 2 * rowSize + columnOffset + k] =
              matrix.get(alignmentMap[low + j], alignmentMap[high - k]);
          // right column
          rawbits[rowOffset + 4 * rowSize + columnOffset + k] =
              matrix.get(alignmentMap[high - k], alignmentMap[high - j]);
          // top row
          rawbits[rowOffset + 6 * rowSize + columnOffset + k] =
              matrix.get(alignmentMap[high - j], alignmentMap[low + k]);
        }
      }
      rowOffset += rowSize * 8;
    }
    return rawbits;
  }

  /**
   * Reads a code of given length and at given index in an array of bits
   */
  static int readCode(List<bool> rawbits, int startIndex, int length) {
    int res = 0;
    for (int i = startIndex; i < startIndex + length; i++) {
      res <<= 1;
      if (rawbits[i]) {
        res |= 0x01;
      }
    }
    return res;
  }

  /**
   * Reads a code of length 8 in an array of bits, padding with zeros
   */
  static int readByte(List<bool> rawbits, int startIndex) {
    int n = rawbits.length - startIndex;
    if (n >= 8) {
      return readCode(rawbits, startIndex, 8);
    }
    return (readCode(rawbits, startIndex, n) << (8 - n));
  }

  /**
   * Packs a bit array into bytes, most significant bit first
   */
  static Uint8List convertBoolArrayToByteArray(List<bool> boolArr) {
    Uint8List byteArr = Uint8List((boolArr.length + 7) ~/ 8);
    for (int i = 0; i < byteArr.length; i++) {
      byteArr[i] = readByte(boolArr, 8 * i);
    }
    return byteArr;
  }

  static int totalBitsInLayer(int layers, bool compact) {
    return ((compact ? 88 : 112) + 16 * layers) * layers;
  }
}
