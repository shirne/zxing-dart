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

import '../../common/bit_matrix.dart';
import '../../common/character_set_eci.dart';
import '../../common/decoder_result.dart';
import '../../common/reedsolomon/generic_gf.dart';
import '../../common/reedsolomon/reed_solomon_decoder.dart';
import '../../common/reedsolomon/reed_solomon_exception.dart';
import '../../formats_exception.dart';
import '../aztec_detector_result.dart';

final _tableMap = Map<String, _Table>.fromEntries(
  _Table.values.map((e) => MapEntry(e.label, e)),
);

enum _Table {
  upper('U', [
    'CTRL_PS', ' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', //
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', //
    'X', 'Y', 'Z', 'CTRL_LL', 'CTRL_ML', 'CTRL_DL', 'CTRL_BS',
  ]),
  lower('L', [
    'CTRL_PS', ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', //
    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', //
    'x', 'y', 'z', 'CTRL_US', 'CTRL_ML', 'CTRL_DL', 'CTRL_BS',
  ]),
  mixed('M', [
    'CTRL_PS', ' ', '\x01', '\x02', '\x03', '\x04', '\x05', '\x06', '\x07',
    '\b', '\t', '\n', //
    '\x0e', '\f', '\r', '\x1b', '\x1c', '\x1d', '\x1e', '\x1f', '@', '\\', '^',
    '_',
    '`', '|', '~', '\x7f', 'CTRL_LL', 'CTRL_UL', 'CTRL_PL', 'CTRL_BS',
  ]),
  digit('D', [
    'CTRL_PS', ' ', '0', '1', '2', '3', '4', '5', '6', '7', '8', //
    '9', ',', '.', 'CTRL_UL', 'CTRL_US',
  ]),
  punct('P', [
    'FLG(n)', '\r', '\r\n', '. ', ', ', ': ', '!', '"', '#', r'$', '%', '&',
    "'", '(', ')', //
    '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '[', ']', '{',
    '}', 'CTRL_UL',
  ]),
  binary('B', []);

  final String label;

  final List<String> table;

  const _Table(this.label, this.table);

  /// gets the table corresponding to the char passed
  factory _Table.fromLabel(String t) {
    if (t.isNotEmpty) {
      return _tableMap[t]!;
    }
    return upper;
  }
}

class CorrectedBitsResult {
  final List<bool> correctBits;
  final int errorsCorrected;
  final int ecLevel;

  CorrectedBitsResult(this.correctBits, this.errorsCorrected, this.ecLevel);
}

/// The main class which implements Aztec Code decoding -- as opposed to locating and extracting
/// the Aztec Code from an image.
///
/// @author David Olivier
class Decoder {
  static const Encoding _defaultEncoding = latin1;

  late final AztecDetectorResult _dData;

  DecoderResult decode(AztecDetectorResult detectorResult) {
    _dData = detectorResult;
    final BitMatrix matrix = _dData.bits;
    final List<bool> rawBits = _extractBits(matrix);
    final CorrectedBitsResult correctedBits = _correctBits(rawBits);
    final Uint8List rawBytes = convertBoolArrayToByteArray(
      correctedBits.correctBits,
    );
    final String result = _getEncodedData(correctedBits.correctBits);
    final DecoderResult decoderResult = DecoderResult(
      rawBytes,
      result,
      null,
      '${correctedBits.ecLevel}%',
    );
    decoderResult.numBits = correctedBits.correctBits.length;
    decoderResult.errorsCorrected = correctedBits.errorsCorrected;
    return decoderResult;
  }

  // This method is used for testing the high-level encoder
  static String highLevelDecode(List<bool> correctedBits) {
    return _getEncodedData(correctedBits);
  }

  /// Gets the string encoded in the aztec code bits
  ///
  /// @return the decoded string
  static String _getEncodedData(List<bool> correctedBits) {
    final int endIndex = correctedBits.length;
    _Table latchTable = _Table.upper; // table most recently latched to
    _Table shiftTable = _Table.upper; // table to use for the next read

    // Final decoded string result
    // (correctedBits-5) / 4 is an upper bound on the size (all-digit result)
    final StringBuffer result = StringBuffer();

    // Intermediary buffer of decoded bytes, which is decoded into a string and flushed
    // when character encoding changes (ECI) or input ends.
    final BytesBuilder decodedBytes = BytesBuilder();
    Encoding encoding = _defaultEncoding;

    int index = 0;
    while (index < endIndex) {
      if (shiftTable == _Table.binary) {
        if (endIndex - index < 5) {
          break;
        }
        int length = _readCode(correctedBits, index, 5);
        index += 5;
        if (length == 0) {
          if (endIndex - index < 11) {
            break;
          }
          length = _readCode(correctedBits, index, 11) + 31;
          index += 11;
        }
        for (int charCount = 0; charCount < length; charCount++) {
          if (endIndex - index < 8) {
            index = endIndex; // Force outer loop to exit
            break;
          }
          final int code = _readCode(correctedBits, index, 8);
          decodedBytes.addByte(code);
          index += 8;
        }
        // Go back to whatever mode we had been in
        shiftTable = latchTable;
      } else {
        final int size = shiftTable == _Table.digit ? 4 : 5;
        if (endIndex - index < size) {
          break;
        }
        final int code = _readCode(correctedBits, index, size);
        index += size;
        final String str = shiftTable.table[code];
        if ('FLG(n)' == str) {
          if (endIndex - index < 3) {
            break;
          }
          int n = _readCode(correctedBits, index, 3);
          index += 3;
          // flush bytes before changing character set
          try {
            result.write(encoding.decode(decodedBytes.takeBytes()));
          } catch (_) {
            // UnsupportedEncodingException
            // can't happen
            rethrow;
          }
          decodedBytes.clear();
          switch (n) {
            case 0:
              result.writeCharCode(29); // translate FNC1 as ASCII 29
              break;
            case 7:
              throw FormatsException.instance; // FLG(7) is reserved and illegal
            default:
              // ECI is decimal integer encoded as 1-6 codes in DIGIT mode
              int eci = 0;
              if (endIndex - index < 4 * n) {
                break;
              }
              while (n-- > 0) {
                final int nextDigit = _readCode(correctedBits, index, 4);
                index += 4;
                if (nextDigit < 2 || nextDigit > 11) {
                  throw FormatsException.instance; // Not a decimal digit
                }
                eci = eci * 10 + (nextDigit - 2);
              }
              final CharacterSetECI? charsetECI =
                  CharacterSetECI.getCharacterSetECIByValue(eci);
              if (charsetECI == null) {
                throw FormatsException.instance;
              }
              encoding = charsetECI.charset!;
          }
          // Go back to whatever mode we had been in
          shiftTable = latchTable;
        } else if (str.startsWith('CTRL_')) {
          // Table changes
          // ISO/IEC 24778:2008 prescribes ending a shift sequence in the mode from which it was invoked.
          // That's including when that mode is a shift.
          // Our test case dlusbs.png for issue #642 exercises that.
          latchTable =
              shiftTable; // Latch the current mode, so as to return to Upper after U/S B/S
          shiftTable = _Table.fromLabel(str[5]);
          if (str[6] == 'L') {
            latchTable = shiftTable;
          }
        } else {
          // Though stored as a table of strings for convenience, codes actually represent 1 or 2 *bytes*.
          final Uint8List b = ascii.encode(str);
          decodedBytes.add(b);
          // Go back to whatever mode we had been in
          shiftTable = latchTable;
        }
      }
    }
    try {
      result.write(encoding.decode(decodedBytes.takeBytes()));
    } catch (_) {
      // UnsupportedEncodingException
      // can't happen
      rethrow;
    }
    return result.toString();
  }

  /// <p>Performs RS error correction on an array of bits.</p>
  ///
  /// @return the corrected array
  /// @throws FormatException if the input contains too many errors
  CorrectedBitsResult _correctBits(List<bool> rawbits) {
    GenericGF gf;
    int codewordSize;

    if (_dData.nbLayers <= 2) {
      codewordSize = 6;
      gf = GenericGF.aztecData6;
    } else if (_dData.nbLayers <= 8) {
      codewordSize = 8;
      gf = GenericGF.aztecData8;
    } else if (_dData.nbLayers <= 22) {
      codewordSize = 10;
      gf = GenericGF.aztecData10;
    } else {
      codewordSize = 12;
      gf = GenericGF.aztecData12;
    }

    final int numDataCodewords = _dData.nbDataBlocks;
    final int numCodewords = rawbits.length ~/ codewordSize;
    if (numCodewords < numDataCodewords) {
      throw FormatsException.instance;
    }
    int offset = rawbits.length % codewordSize;

    final Int32List dataWords = Int32List(numCodewords);
    for (int i = 0; i < numCodewords; i++, offset += codewordSize) {
      dataWords[i] = _readCode(rawbits, offset, codewordSize);
    }

    int errorsCorrected = 0;
    try {
      final ReedSolomonDecoder rsDecoder = ReedSolomonDecoder(gf);
      errorsCorrected = rsDecoder.decodeWithECCount(
        dataWords,
        numCodewords - numDataCodewords,
      );
    } on ReedSolomonException catch (ex) {
      throw FormatsException(ex.toString());
    }

    // Now perform the unstuffing operation.
    // First, count how many bits are going to be thrown out as stuffing
    final int mask = (1 << codewordSize) - 1;
    int stuffedBits = 0;
    for (int i = 0; i < numDataCodewords; i++) {
      final int dataWord = dataWords[i];
      if (dataWord == 0 || dataWord == mask) {
        throw FormatsException.instance;
      } else if (dataWord == 1 || dataWord == mask - 1) {
        stuffedBits++;
      }
    }
    // Now, actually unpack the bits and remove the stuffing
    final List<bool> correctedBits =
        List.filled(numDataCodewords * codewordSize - stuffedBits, false);
    int index = 0;
    for (int i = 0; i < numDataCodewords; i++) {
      final int dataWord = dataWords[i];
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

    final ecLevel = 100 * (numCodewords - numDataCodewords) ~/ numCodewords;
    return CorrectedBitsResult(correctedBits, errorsCorrected, ecLevel);
  }

  /// Gets the array of bits from an Aztec Code matrix
  ///
  /// @return the array of bits
  List<bool> _extractBits(BitMatrix matrix) {
    final bool compact = _dData.isCompact;
    final int layers = _dData.nbLayers;
    final int baseMatrixSize =
        (compact ? 11 : 14) + layers * 4; // not including alignment lines
    final List<int> alignmentMap = List.filled(baseMatrixSize, 0);
    final List<bool> rawbits =
        List.filled(_totalBitsInLayer(layers, compact), false);

    if (compact) {
      for (int i = 0; i < alignmentMap.length; i++) {
        alignmentMap[i] = i;
      }
    } else {
      final int matrixSize =
          baseMatrixSize + 1 + 2 * ((baseMatrixSize ~/ 2 - 1) ~/ 15);
      final int origCenter = baseMatrixSize ~/ 2;
      final int center = matrixSize ~/ 2;
      for (int i = 0; i < origCenter; i++) {
        final int newOffset = i + i ~/ 15;
        alignmentMap[origCenter - i - 1] = center - newOffset - 1;
        alignmentMap[origCenter + i] = center + newOffset + 1;
      }
    }
    for (int i = 0, rowOffset = 0; i < layers; i++) {
      final int rowSize = (layers - i) * 4 + (compact ? 9 : 12);
      // The top-left most point of this layer is <low, low> (not including alignment lines)
      final int low = i * 2;
      // The bottom-right most point of this layer is <high, high> (not including alignment lines)
      final int high = baseMatrixSize - 1 - low;
      // We pull bits from the two 2 x rowSize columns and two rowSize x 2 rows
      for (int j = 0; j < rowSize; j++) {
        final int columnOffset = j * 2;
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

  /// Reads a code of given length and at given index in an array of bits
  static int _readCode(List<bool> rawBits, int startIndex, int length) {
    int res = 0;
    for (int i = startIndex; i < startIndex + length; i++) {
      res <<= 1;
      if (rawBits[i]) {
        res |= 0x01;
      }
    }
    return res.toSigned(32);
  }

  /// Reads a code of length 8 in an array of bits, padding with zeros
  static int _readByte(List<bool> rawBits, int startIndex) {
    final int n = rawBits.length - startIndex;
    if (n >= 8) {
      return _readCode(rawBits, startIndex, 8);
    }
    return (_readCode(rawBits, startIndex, n) << (8 - n));
  }

  /// Packs a bit array into bytes, most significant bit first
  static Uint8List convertBoolArrayToByteArray(List<bool> boolArr) {
    final Uint8List byteArr = Uint8List((boolArr.length + 7) ~/ 8);
    for (int i = 0; i < byteArr.length; i++) {
      byteArr[i] = _readByte(boolArr, 8 * i);
    }
    return byteArr;
  }

  static int _totalBitsInLayer(int layers, bool compact) {
    return ((compact ? 88 : 112) + 16 * layers) * layers;
  }
}
