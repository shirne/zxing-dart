/*
 * Copyright 2013 ZXing authors
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

import '../../common/bit_array.dart';
import '../../common/bit_matrix.dart';
import '../../common/reedsolomon/generic_gf.dart';
import '../../common/reedsolomon/reed_solomon_encoder.dart';
import 'aztec_code.dart';
import 'high_level_encoder.dart';

/// Generates Aztec 2D barcodes.
///
/// @author Rustam Abdullaev
class Encoder {
  static const int DEFAULT_EC_PERCENT =
      33; // default minimal percentage of error check words
  static const int DEFAULT_AZTEC_LAYERS = 0;
  static const int _MAX_NB_BITS = 32;
  static const int _MAX_NB_BITS_COMPACT = 4;

  static const List<int> _WORD_SIZE = [
    4, 6, 6, 8, 8, 8, 8, 8, 8, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, //
    10, 10, 10, 10, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12
  ];

  Encoder();

  /// Encodes the given string content as an Aztec symbol
  ///
  /// @param data input data string
  /// @param minECCPercent minimal percentage of error check words (According to ISO/IEC 24778:2008,
  ///                      a minimum of 23% + 3 words is recommended)
  /// @param userSpecifiedLayers if non-zero, a user-specified value for the number of layers
  /// @param charset character set in which to encode string using ECI; if null, no ECI code
  ///                will be inserted, and the string must be encodable as ISO/IEC 8859-1
  ///                (Latin-1), the default encoding of the symbol.
  /// @return Aztec symbol matrix with metadata
  static AztecCode encode(String data,
      [int minECCPercent = DEFAULT_AZTEC_LAYERS,
      int userSpecifiedLayers = DEFAULT_AZTEC_LAYERS,
      Encoding? charset]) {
    final List<int> bytes = (charset ?? latin1).encode(data);
    return encodeData(
        Uint8List.fromList(bytes), minECCPercent, userSpecifiedLayers, charset);
  }

  /// Encodes the given binary content as an Aztec symbol
  ///
  /// @param data input data string
  /// @param minECCPercent minimal percentage of error check words (According to ISO/IEC 24778:2008,
  ///                      a minimum of 23% + 3 words is recommended)
  /// @param userSpecifiedLayers if non-zero, a user-specified value for the number of layers
  /// @param charset character set to mark using ECI; if null, no ECI code will be inserted, and the
  ///                default encoding of ISO/IEC 8859-1 will be assuming by readers.
  /// @return Aztec symbol matrix with metadata
  static AztecCode encodeData(Uint8List data,
      [int minECCPercent = DEFAULT_AZTEC_LAYERS,
      int userSpecifiedLayers = DEFAULT_AZTEC_LAYERS,
      Encoding? charset]) {
    // High-level encode
    final BitArray bits = HighLevelEncoder(data, charset).encode();

    // stuff bits and choose symbol size
    final int eccBits = bits.size * minECCPercent ~/ 100 + 11;
    final int totalSizeBits = bits.size + eccBits;
    bool compact;
    int layers;
    int totalBitsLayer;
    int wordSize;
    BitArray? stuffedBits;
    if (userSpecifiedLayers != DEFAULT_AZTEC_LAYERS) {
      compact = userSpecifiedLayers < 0;
      layers = (userSpecifiedLayers).abs();
      if (layers > (compact ? _MAX_NB_BITS_COMPACT : _MAX_NB_BITS)) {
        throw ArgumentError('Illegal value $userSpecifiedLayers for layers');
      }
      totalBitsLayer = _totalBitsInLayer(layers, compact);
      wordSize = _WORD_SIZE[layers];
      final int usableBitsInLayers =
          totalBitsLayer - (totalBitsLayer % wordSize);
      stuffedBits = stuffBits(bits, wordSize);
      if (stuffedBits.size + eccBits > usableBitsInLayers) {
        throw ArgumentError('Data to large for user specified layer');
      }
      if (compact && stuffedBits.size > wordSize * 64) {
        // Compact format only allows 64 data words, though C4 can hold more words than that
        throw ArgumentError('Data to large for user specified layer');
      }
    } else {
      wordSize = 0;
      stuffedBits = null;
      // We look at the possible table sizes in the order Compact1, Compact2, Compact3,
      // Compact4, Normal4,...  Normal(i) for i < 4 isn't typically used since Compact(i+1)
      // is the same size, but has more data.
      for (int i = 0;; i++) {
        if (i > _MAX_NB_BITS) {
          throw ArgumentError('Data too large for an Aztec code');
        }
        compact = i <= 3;
        layers = compact ? i + 1 : i;
        totalBitsLayer = _totalBitsInLayer(layers, compact);
        if (totalSizeBits > totalBitsLayer) {
          continue;
        }
        // [Re]stuff the bits if this is the first opportunity, or if the
        // wordSize has changed
        if (stuffedBits == null || wordSize != _WORD_SIZE[layers]) {
          wordSize = _WORD_SIZE[layers];
          stuffedBits = stuffBits(bits, wordSize);
        }
        final int usableBitsInLayers =
            totalBitsLayer - (totalBitsLayer % wordSize);
        if (compact && stuffedBits.size > wordSize * 64) {
          // Compact format only allows 64 data words, though C4 can hold more words than that
          continue;
        }
        if (stuffedBits.size + eccBits <= usableBitsInLayers) {
          break;
        }
      }
    }
    final BitArray messageBits =
        _generateCheckWords(stuffedBits, totalBitsLayer, wordSize);

    // generate mode message
    final int messageSizeInWords = stuffedBits.size ~/ wordSize;
    final BitArray modeMessage =
        generateModeMessage(compact, layers, messageSizeInWords);

    // allocate symbol
    final int baseMatrixSize =
        (compact ? 11 : 14) + layers * 4; // not including alignment lines
    final List<int> alignmentMap = List.filled(baseMatrixSize, 0);
    int matrixSize;
    if (compact) {
      // no alignment marks in compact mode, alignmentMap is a no-op
      matrixSize = baseMatrixSize;
      for (int i = 0; i < alignmentMap.length; i++) {
        alignmentMap[i] = i;
      }
    } else {
      matrixSize = baseMatrixSize + 1 + 2 * ((baseMatrixSize ~/ 2 - 1) ~/ 15);
      final int origCenter = baseMatrixSize ~/ 2;
      final int center = matrixSize ~/ 2;
      for (int i = 0; i < origCenter; i++) {
        final int newOffset = i + i ~/ 15;
        alignmentMap[origCenter - i - 1] = center - newOffset - 1;
        alignmentMap[origCenter + i] = center + newOffset + 1;
      }
    }
    final BitMatrix matrix = BitMatrix(matrixSize);

    // draw data bits
    for (int i = 0, rowOffset = 0; i < layers; i++) {
      final int rowSize = (layers - i) * 4 + (compact ? 9 : 12);
      for (int j = 0; j < rowSize; j++) {
        final int columnOffset = j * 2;
        for (int k = 0; k < 2; k++) {
          if (messageBits.get(rowOffset + columnOffset + k)) {
            matrix.set(alignmentMap[i * 2 + k], alignmentMap[i * 2 + j]);
          }
          if (messageBits.get(rowOffset + rowSize * 2 + columnOffset + k)) {
            matrix.set(alignmentMap[i * 2 + j],
                alignmentMap[baseMatrixSize - 1 - i * 2 - k]);
          }
          if (messageBits.get(rowOffset + rowSize * 4 + columnOffset + k)) {
            matrix.set(alignmentMap[baseMatrixSize - 1 - i * 2 - k],
                alignmentMap[baseMatrixSize - 1 - i * 2 - j]);
          }
          if (messageBits.get(rowOffset + rowSize * 6 + columnOffset + k)) {
            matrix.set(alignmentMap[baseMatrixSize - 1 - i * 2 - j],
                alignmentMap[i * 2 + k]);
          }
        }
      }
      rowOffset += rowSize * 8;
    }

    // draw mode message
    _drawModeMessage(matrix, compact, matrixSize, modeMessage);

    // draw alignment marks
    if (compact) {
      _drawBullsEye(matrix, matrixSize ~/ 2, 5);
    } else {
      _drawBullsEye(matrix, matrixSize ~/ 2, 7);
      for (int i = 0, j = 0; i < baseMatrixSize / 2 - 1; i += 15, j += 16) {
        for (int k = (matrixSize ~/ 2) & 1; k < matrixSize; k += 2) {
          matrix.set(matrixSize ~/ 2 - j, k);
          matrix.set(matrixSize ~/ 2 + j, k);
          matrix.set(k, matrixSize ~/ 2 - j);
          matrix.set(k, matrixSize ~/ 2 + j);
        }
      }
    }

    return AztecCode(
      isCompact: compact,
      size: matrixSize,
      layers: layers,
      codeWords: messageSizeInWords,
      matrix: matrix,
    );
  }

  static void _drawBullsEye(BitMatrix matrix, int center, int size) {
    for (int i = 0; i < size; i += 2) {
      for (int j = center - i; j <= center + i; j++) {
        matrix.set(j, center - i);
        matrix.set(j, center + i);
        matrix.set(center - i, j);
        matrix.set(center + i, j);
      }
    }
    matrix.set(center - size, center - size);
    matrix.set(center - size + 1, center - size);
    matrix.set(center - size, center - size + 1);
    matrix.set(center + size, center - size);
    matrix.set(center + size, center - size + 1);
    matrix.set(center + size, center + size - 1);
  }

  static BitArray generateModeMessage(
      bool compact, int layers, int messageSizeInWords) {
    BitArray modeMessage = BitArray();
    if (compact) {
      modeMessage.appendBits(layers - 1, 2);
      modeMessage.appendBits(messageSizeInWords - 1, 6);
      modeMessage = _generateCheckWords(modeMessage, 28, 4);
    } else {
      modeMessage.appendBits(layers - 1, 5);
      modeMessage.appendBits(messageSizeInWords - 1, 11);
      modeMessage = _generateCheckWords(modeMessage, 40, 4);
    }
    return modeMessage;
  }

  static void _drawModeMessage(
      BitMatrix matrix, bool compact, int matrixSize, BitArray modeMessage) {
    final int center = matrixSize ~/ 2;
    if (compact) {
      for (int i = 0; i < 7; i++) {
        final int offset = center - 3 + i;
        if (modeMessage.get(i)) {
          matrix.set(offset, center - 5);
        }
        if (modeMessage.get(i + 7)) {
          matrix.set(center + 5, offset);
        }
        if (modeMessage.get(20 - i)) {
          matrix.set(offset, center + 5);
        }
        if (modeMessage.get(27 - i)) {
          matrix.set(center - 5, offset);
        }
      }
    } else {
      for (int i = 0; i < 10; i++) {
        final int offset = center - 5 + i + i ~/ 5;
        if (modeMessage.get(i)) {
          matrix.set(offset, center - 7);
        }
        if (modeMessage.get(i + 10)) {
          matrix.set(center + 7, offset);
        }
        if (modeMessage.get(29 - i)) {
          matrix.set(offset, center + 7);
        }
        if (modeMessage.get(39 - i)) {
          matrix.set(center - 7, offset);
        }
      }
    }
  }

  static BitArray _generateCheckWords(
      BitArray bitArray, int totalBits, int wordSize) {
    // bitArray is guaranteed to be a multiple of the wordSize, so no padding needed
    final int messageSizeInWords = bitArray.size ~/ wordSize;
    final ReedSolomonEncoder rs = ReedSolomonEncoder(_getGF(wordSize));
    final int totalWords = totalBits ~/ wordSize;
    final List<int> messageWords = _bitsToWords(bitArray, wordSize, totalWords);
    rs.encode(messageWords, totalWords - messageSizeInWords);
    final int startPad = totalBits % wordSize;
    final BitArray messageBits = BitArray();
    messageBits.appendBits(0, startPad);
    for (int messageWord in messageWords) {
      messageBits.appendBits(messageWord, wordSize);
    }
    return messageBits;
  }

  static List<int> _bitsToWords(
      BitArray stuffedBits, int wordSize, int totalWords) {
    final List<int> message = List.filled(totalWords, 0);
    int i = 0;
    final int n = stuffedBits.size ~/ wordSize;
    for (; i < n; i++) {
      int value = 0;
      for (int j = 0; j < wordSize; j++) {
        value |=
            stuffedBits.get(i * wordSize + j) ? (1 << wordSize - j - 1) : 0;
      }
      message[i] = value;
    }
    return message;
  }

  static GenericGF _getGF(int wordSize) {
    switch (wordSize) {
      case 4:
        return GenericGF.aztecParam;
      case 6:
        return GenericGF.aztecData6;
      case 8:
        return GenericGF.aztecData8;
      case 10:
        return GenericGF.aztecData10;
      case 12:
        return GenericGF.aztecData12;
      default:
        throw ArgumentError('Unsupported word size $wordSize');
    }
  }

  static BitArray stuffBits(BitArray bits, int wordSize) {
    final BitArray out = BitArray();

    final int n = bits.size;
    final int mask = (1 << wordSize) - 2;
    for (int i = 0; i < n; i += wordSize) {
      int word = 0;
      for (int j = 0; j < wordSize; j++) {
        if (i + j >= n || bits.get(i + j)) {
          word |= 1 << (wordSize - 1 - j);
        }
      }
      if ((word & mask) == mask) {
        out.appendBits(word & mask, wordSize);
        i--;
      } else if ((word & mask) == 0) {
        out.appendBits(word | 1, wordSize);
        i--;
      } else {
        out.appendBits(word, wordSize);
      }
    }
    return out;
  }

  static int _totalBitsInLayer(int layers, bool compact) {
    return ((compact ? 88 : 112) + 16 * layers) * layers;
  }
}
