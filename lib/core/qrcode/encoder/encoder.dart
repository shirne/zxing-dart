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

import 'dart:math' as Math;
import 'dart:convert';
import 'dart:typed_data';

import '../../common/character_set_eci.dart';
import '../../common/detector/math_utils.dart';
import '../../common/reedsolomon/generic_gf.dart';
import '../../common/reedsolomon/reed_solomon_encoder.dart';
import '../../common/string_utils.dart';
import '../../qrcode/decoder/mode.dart';
import '../../qrcode/decoder/version.dart';

import '../../common/bit_array.dart';

import '../../writer_exception.dart';
import '../decoder/error_correction_level.dart';

import '../../encode_hint_type.dart';
import 'block_pair.dart';
import 'byte_matrix.dart';
import 'mask_util.dart';
import 'matrix_util.dart';
import 'qrcode.dart';

/**
 * @author satorux@google.com (Satoru Takabayashi) - creator
 * @author dswitkin@google.com (Daniel Switkin) - ported from C++
 */
class Encoder {
  // The original table is defined in the table 5 of JISX0510:2004 (p.19).
  static final List<int> ALPHANUMERIC_TABLE = [
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 0x00-0x0f
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 0x10-0x1f
    36, -1, -1, -1, 37, 38, -1, -1, -1, -1, 39, 40, -1, 41, 42, 43, // 0x20-0x2f
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 44, -1, -1, -1, -1, -1, // 0x30-0x3f
    -1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, // 0x40-0x4f
    25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1, // 0x50-0x5f
  ];

  static final Encoding DEFAULT_BYTE_MODE_ENCODING = latin1;

  Encoder();

  // The mask penalty calculation is complicated.  See Table 21 of JISX0510:2004 (p.45) for details.
  // Basically it applies four rules and summate all penalties.
  static int calculateMaskPenalty(ByteMatrix matrix) {
    return MaskUtil.applyMaskPenaltyRule1(matrix) +
        MaskUtil.applyMaskPenaltyRule2(matrix) +
        MaskUtil.applyMaskPenaltyRule3(matrix) +
        MaskUtil.applyMaskPenaltyRule4(matrix);
  }

  static QRCode encode(String content,
      [ErrorCorrectionLevel? ecLevel, Map<EncodeHintType, Object>? hints]) {
    // Determine what character encoding has been specified by the caller, if any
    Encoding? encoding = DEFAULT_BYTE_MODE_ENCODING;
    bool hasEncodingHint =
        hints != null && hints.containsKey(EncodeHintType.CHARACTER_SET);
    if (hasEncodingHint) {
      encoding =
          Encoding.getByName(hints[EncodeHintType.CHARACTER_SET].toString());
    }

    // Pick an encoding mode appropriate for the content. Note that this will not attempt to use
    // multiple modes / segments even if that were more efficient. Twould be nice.
    Mode mode = chooseMode(content, encoding);

    // This will store the header information, like mode and
    // length, as well as "header" segments like an ECI segment.
    BitArray headerBits = BitArray();

    // Append ECI segment if applicable
    if (mode == Mode.BYTE && hasEncodingHint) {
      CharacterSetECI? eci = CharacterSetECI.getCharacterSetECI(encoding!);
      if (eci != null) {
        appendECI(eci, headerBits);
      }
    }

    // Append the FNC1 mode header for GS1 formatted data if applicable
    bool hasGS1FormatHint =
        hints != null && hints.containsKey(EncodeHintType.GS1_FORMAT);
    if (hasGS1FormatHint && hints.containsKey(EncodeHintType.GS1_FORMAT)) {
      // GS1 formatted codes are prefixed with a FNC1 in first position mode header
      appendModeInfo(Mode.FNC1_FIRST_POSITION, headerBits);
    }

    // (With ECI in place,) Write the mode marker
    appendModeInfo(mode, headerBits);

    // Collect data within the main segment, separately, to count its size if needed. Don't add it to
    // main payload yet.
    BitArray dataBits = BitArray();
    appendBytes(content, mode, dataBits, encoding!);

    Version version;
    if (hints != null && hints.containsKey(EncodeHintType.QR_VERSION)) {
      int versionNumber =
          int.parse(hints[EncodeHintType.QR_VERSION].toString());
      version = Version.getVersionForNumber(versionNumber);
      int bitsNeeded = calculateBitsNeeded(mode, headerBits, dataBits, version);
      if (!willFit(bitsNeeded, version, ecLevel!)) {
        throw WriterException("Data too big for requested version");
      }
    } else {
      version = recommendVersion(ecLevel!, mode, headerBits, dataBits);
    }

    BitArray headerAndDataBits = BitArray();
    headerAndDataBits.appendBitArray(headerBits);
    // Find "length" of main segment and write it
    int numLetters =
        mode == Mode.BYTE ? dataBits.getSizeInBytes() : content.length;
    appendLengthInfo(numLetters, version, mode, headerAndDataBits);
    // Put data together into the overall payload
    headerAndDataBits.appendBitArray(dataBits);

    ECBlocks ecBlocks = version.getECBlocksForLevel(ecLevel);
    int numDataBytes =
        version.getTotalCodewords() - ecBlocks.getTotalECCodewords();

    // Terminate the bits properly.
    terminateBits(numDataBytes, headerAndDataBits);

    // Interleave data bits with error correction code.
    BitArray finalBits = interleaveWithECBytes(headerAndDataBits,
        version.getTotalCodewords(), numDataBytes, ecBlocks.getNumBlocks());

    QRCode qrCode = QRCode();

    qrCode.setECLevel(ecLevel);
    qrCode.setMode(mode);
    qrCode.setVersion(version);

    //  Choose the mask pattern and set to "qrCode".
    int dimension = version.getDimensionForVersion();
    ByteMatrix matrix = ByteMatrix(dimension, dimension);

    // Enable manual selection of the pattern to be used via hint
    int maskPattern = -1;
    if (hints != null && hints.containsKey(EncodeHintType.QR_MASK_PATTERN)) {
      int hintMaskPattern =
          int.parse(hints[EncodeHintType.QR_MASK_PATTERN].toString());
      maskPattern =
          QRCode.isValidMaskPattern(hintMaskPattern) ? hintMaskPattern : -1;
    }

    if (maskPattern == -1) {
      maskPattern = chooseMaskPattern(finalBits, ecLevel, version, matrix);
    }
    qrCode.setMaskPattern(maskPattern);

    // Build the matrix and set it to "qrCode".
    MatrixUtil.buildMatrix(finalBits, ecLevel, version, maskPattern, matrix);
    qrCode.setMatrix(matrix);

    return qrCode;
  }

  /**
   * Decides the smallest version of QR code that will contain all of the provided data.
   *
   * @throws WriterException if the data cannot fit in any version
   */
  static Version recommendVersion(ErrorCorrectionLevel ecLevel, Mode mode,
      BitArray headerBits, BitArray dataBits) {
    // Hard part: need to know version to know how many bits length takes. But need to know how many
    // bits it takes to know version. First we take a guess at version by assuming version will be
    // the minimum, 1:
    int provisionalBitsNeeded = calculateBitsNeeded(
        mode, headerBits, dataBits, Version.getVersionForNumber(1));
    Version provisionalVersion = chooseVersion(provisionalBitsNeeded, ecLevel);

    // Use that guess to calculate the right version. I am still not sure this works in 100% of cases.
    int bitsNeeded =
        calculateBitsNeeded(mode, headerBits, dataBits, provisionalVersion);
    return chooseVersion(bitsNeeded, ecLevel);
  }

  static int calculateBitsNeeded(
      Mode mode, BitArray headerBits, BitArray dataBits, Version version) {
    return headerBits.getSize() +
        mode.getCharacterCountBits(version) +
        dataBits.getSize();
  }

  /**
   * @return the code point of the table used in alphanumeric mode or
   *  -1 if there is no corresponding code in the table.
   */
  static int getAlphanumericCode(int code) {
    if (code < ALPHANUMERIC_TABLE.length) {
      return ALPHANUMERIC_TABLE[code];
    }
    return -1;
  }

  /**
   * Choose the best mode by examining the content. Note that 'encoding' is used as a hint;
   * if it is Shift_JIS, and the input is only double-byte Kanji, then we return {@link Mode#KANJI}.
   */
  static Mode chooseMode(String content, [Encoding? encoding]) {
    if (StringUtils.SHIFT_JIS_CHARSET == encoding &&
        isOnlyDoubleByteKanji(content)) {
      // Choose Kanji mode if all input are double-byte characters
      return Mode.KANJI;
    }
    bool hasNumeric = false;
    bool hasAlphanumeric = false;
    for (int i = 0; i < content.length; ++i) {
      int c = content.codeUnitAt(i);
      if (c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
        hasNumeric = true;
      } else if (getAlphanumericCode(c) != -1) {
        hasAlphanumeric = true;
      } else {
        return Mode.BYTE;
      }
    }
    if (hasAlphanumeric) {
      return Mode.ALPHANUMERIC;
    }
    if (hasNumeric) {
      return Mode.NUMERIC;
    }
    return Mode.BYTE;
  }

  static bool isOnlyDoubleByteKanji(String content) {
    List<int> bytes = StringUtils.SHIFT_JIS_CHARSET!.encode(content);
    int length = bytes.length;
    if (length % 2 != 0) {
      return false;
    }
    for (int i = 0; i < length; i += 2) {
      int byte1 = bytes[i] & 0xFF;
      if ((byte1 < 0x81 || byte1 > 0x9F) && (byte1 < 0xE0 || byte1 > 0xEB)) {
        return false;
      }
    }
    return true;
  }

  static int chooseMaskPattern(BitArray bits, ErrorCorrectionLevel ecLevel,
      Version version, ByteMatrix matrix) {
    int minPenalty = MathUtils.MAX_VALUE; //Integer.MAX_VALUE;  // Lower penalty is better.
    int bestMaskPattern = -1;
    // We try all mask patterns to choose the best one.
    for (int maskPattern = 0;
        maskPattern < QRCode.NUM_MASK_PATTERNS;
        maskPattern++) {
      MatrixUtil.buildMatrix(bits, ecLevel, version, maskPattern, matrix);
      int penalty = calculateMaskPenalty(matrix);
      if (penalty < minPenalty) {
        minPenalty = penalty;
        bestMaskPattern = maskPattern;
      }
    }
    return bestMaskPattern;
  }

  static Version chooseVersion(int numInputBits, ErrorCorrectionLevel ecLevel) {
    for (int versionNum = 1; versionNum <= 40; versionNum++) {
      Version version = Version.getVersionForNumber(versionNum);
      if (willFit(numInputBits, version, ecLevel)) {
        return version;
      }
    }
    throw WriterException("Data too big");
  }

  /**
   * @return true if the number of input bits will fit in a code with the specified version and
   * error correction level.
   */
  static bool willFit(
      int numInputBits, Version version, ErrorCorrectionLevel ecLevel) {
    // In the following comments, we use numbers of Version 7-H.
    // numBytes = 196
    int numBytes = version.getTotalCodewords();
    // getNumECBytes = 130
    ECBlocks ecBlocks = version.getECBlocksForLevel(ecLevel);
    int numEcBytes = ecBlocks.getTotalECCodewords();
    // getNumDataBytes = 196 - 130 = 66
    int numDataBytes = numBytes - numEcBytes;
    int totalInputBytes = (numInputBits + 7) ~/ 8;
    return numDataBytes >= totalInputBytes;
  }

  /**
   * Terminate bits as described in 8.4.8 and 8.4.9 of JISX0510:2004 (p.24).
   */
  static void terminateBits(int numDataBytes, BitArray bits) {
    int capacity = numDataBytes * 8;
    if (bits.getSize() > capacity) {
      throw WriterException(
          "data bits cannot fit in the QR Code ${bits.getSize()} > $capacity");
    }
    for (int i = 0; i < 4 && bits.getSize() < capacity; ++i) {
      bits.appendBit(false);
    }
    // Append termination bits. See 8.4.8 of JISX0510:2004 (p.24) for details.
    // If the last byte isn't 8-bit aligned, we'll add padding bits.
    int numBitsInLastByte = bits.getSize() & 0x07;
    if (numBitsInLastByte > 0) {
      for (int i = numBitsInLastByte; i < 8; i++) {
        bits.appendBit(false);
      }
    }
    // If we have more space, we'll fill the space with padding patterns defined in 8.4.9 (p.24).
    int numPaddingBytes = numDataBytes - bits.getSizeInBytes();
    for (int i = 0; i < numPaddingBytes; ++i) {
      bits.appendBits((i & 0x01) == 0 ? 0xEC : 0x11, 8);
    }
    if (bits.getSize() != capacity) {
      throw WriterException("Bits size does not equal capacity");
    }
  }

  /**
   * Get number of data bytes and number of error correction bytes for block id "blockID". Store
   * the result in "numDataBytesInBlock", and "numECBytesInBlock". See table 12 in 8.5.1 of
   * JISX0510:2004 (p.30)
   */
  static void getNumDataBytesAndNumECBytesForBlockID(
      int numTotalBytes,
      int numDataBytes,
      int numRSBlocks,
      int blockID,
      List<int> numDataBytesInBlock,
      List<int> numECBytesInBlock) {
    if (blockID >= numRSBlocks) {
      throw WriterException("Block ID too large");
    }
    // numRsBlocksInGroup2 = 196 % 5 = 1
    int numRsBlocksInGroup2 = numTotalBytes % numRSBlocks;
    // numRsBlocksInGroup1 = 5 - 1 = 4
    int numRsBlocksInGroup1 = numRSBlocks - numRsBlocksInGroup2;
    // numTotalBytesInGroup1 = 196 / 5 = 39
    int numTotalBytesInGroup1 = numTotalBytes ~/ numRSBlocks;
    // numTotalBytesInGroup2 = 39 + 1 = 40
    int numTotalBytesInGroup2 = numTotalBytesInGroup1 + 1;
    // numDataBytesInGroup1 = 66 / 5 = 13
    int numDataBytesInGroup1 = numDataBytes ~/ numRSBlocks;
    // numDataBytesInGroup2 = 13 + 1 = 14
    int numDataBytesInGroup2 = numDataBytesInGroup1 + 1;
    // numEcBytesInGroup1 = 39 - 13 = 26
    int numEcBytesInGroup1 = numTotalBytesInGroup1 - numDataBytesInGroup1;
    // numEcBytesInGroup2 = 40 - 14 = 26
    int numEcBytesInGroup2 = numTotalBytesInGroup2 - numDataBytesInGroup2;
    // Sanity checks.
    // 26 = 26
    if (numEcBytesInGroup1 != numEcBytesInGroup2) {
      throw WriterException("EC bytes mismatch");
    }
    // 5 = 4 + 1.
    if (numRSBlocks != numRsBlocksInGroup1 + numRsBlocksInGroup2) {
      throw WriterException("RS blocks mismatch");
    }
    // 196 = (13 + 26) * 4 + (14 + 26) * 1
    if (numTotalBytes !=
        ((numDataBytesInGroup1 + numEcBytesInGroup1) * numRsBlocksInGroup1) +
            ((numDataBytesInGroup2 + numEcBytesInGroup2) *
                numRsBlocksInGroup2)) {
      throw WriterException("Total bytes mismatch");
    }

    if (blockID < numRsBlocksInGroup1) {
      numDataBytesInBlock[0] = numDataBytesInGroup1;
      numECBytesInBlock[0] = numEcBytesInGroup1;
    } else {
      numDataBytesInBlock[0] = numDataBytesInGroup2;
      numECBytesInBlock[0] = numEcBytesInGroup2;
    }
  }

  /**
   * Interleave "bits" with corresponding error correction bytes. On success, store the result in
   * "result". The interleave rule is complicated. See 8.6 of JISX0510:2004 (p.37) for details.
   */
  static BitArray interleaveWithECBytes(
      BitArray bits, int numTotalBytes, int numDataBytes, int numRSBlocks) {
    // "bits" must have "getNumDataBytes" bytes of data.
    if (bits.getSizeInBytes() != numDataBytes) {
      throw WriterException("Number of bits and data bytes does not match");
    }

    // Step 1.  Divide data bytes into blocks and generate error correction bytes for them. We'll
    // store the divided data bytes blocks and error correction bytes blocks into "blocks".
    int dataBytesOffset = 0;
    int maxNumDataBytes = 0;
    int maxNumEcBytes = 0;

    // Since, we know the number of reedsolmon blocks, we can initialize the vector with the number.
    List<BlockPair> blocks = []; //numRSBlocks

    for (int i = 0; i < numRSBlocks; ++i) {
      List<int> numDataBytesInBlock = [0];
      List<int> numEcBytesInBlock = [0];
      getNumDataBytesAndNumECBytesForBlockID(numTotalBytes, numDataBytes,
          numRSBlocks, i, numDataBytesInBlock, numEcBytesInBlock);

      int size = numDataBytesInBlock[0];
      Uint8List dataBytes = Uint8List(size);
      bits.toBytes(8 * dataBytesOffset, dataBytes, 0, size);
      Uint8List ecBytes = generateECBytes(dataBytes, numEcBytesInBlock[0]);
      blocks.add(BlockPair(dataBytes, ecBytes));

      maxNumDataBytes = Math.max(maxNumDataBytes, size);
      maxNumEcBytes = Math.max(maxNumEcBytes, ecBytes.length);
      dataBytesOffset += numDataBytesInBlock[0];
    }
    if (numDataBytes != dataBytesOffset) {
      throw WriterException("Data bytes does not match offset");
    }

    BitArray result = BitArray();

    // First, place data blocks.
    for (int i = 0; i < maxNumDataBytes; ++i) {
      for (BlockPair block in blocks) {
        Uint8List dataBytes = block.getDataBytes();
        if (i < dataBytes.length) {
          result.appendBits(dataBytes[i], 8);
        }
      }
    }
    // Then, place error correction blocks.
    for (int i = 0; i < maxNumEcBytes; ++i) {
      for (BlockPair block in blocks) {
        Uint8List ecBytes = block.getErrorCorrectionBytes();
        if (i < ecBytes.length) {
          result.appendBits(ecBytes[i], 8);
        }
      }
    }
    if (numTotalBytes != result.getSizeInBytes()) {
      // Should be same.
      throw WriterException(
          "Interleaving error: $numTotalBytes and ${result.getSizeInBytes()} differ.");
    }

    return result;
  }

  static Uint8List generateECBytes(Uint8List dataBytes, int numEcBytesInBlock) {
    int numDataBytes = dataBytes.length;
    List<int> toEncode = [];
    for (int i = 0; i < numDataBytes; i++) {
      toEncode.add(dataBytes[i] & 0xFF);
    }
    toEncode.addAll(List.filled(numEcBytesInBlock, 0));
    ReedSolomonEncoder(GenericGF.QR_CODE_FIELD_256)
        .encode(toEncode, numEcBytesInBlock);

    Uint8List ecBytes = Uint8List(numEcBytesInBlock);
    for (int i = 0; i < numEcBytesInBlock; i++) {
      ecBytes[i] = toEncode[numDataBytes + i];
    }
    return ecBytes;
  }

  /**
   * Append mode info. On success, store the result in "bits".
   */
  static void appendModeInfo(Mode mode, BitArray bits) {
    bits.appendBits(mode.getBits(), 4);
  }

  /**
   * Append length info. On success, store the result in "bits".
   */
  static void appendLengthInfo(
      int numLetters, Version version, Mode mode, BitArray bits) {
    int numBits = mode.getCharacterCountBits(version);
    if (numLetters >= (1 << numBits)) {
      throw WriterException(
          "$numLetters is bigger than ${((1 << numBits) - 1)}");
    }
    bits.appendBits(numLetters, numBits);
  }

  /**
   * Append "bytes" in "mode" mode (encoding) into "bits". On success, store the result in "bits".
   */
  static void appendBytes(
      String content, Mode mode, BitArray bits, Encoding encoding) {
    switch (mode) {
      case Mode.NUMERIC:
        appendNumericBytes(content, bits);
        break;
      case Mode.ALPHANUMERIC:
        appendAlphanumericBytes(content, bits);
        break;
      case Mode.BYTE:
        append8BitBytes(content, bits, encoding);
        break;
      case Mode.KANJI:
        appendKanjiBytes(content, bits);
        break;
      default:
        throw WriterException("Invalid mode: $mode");
    }
  }

  static void appendNumericBytes(String content, BitArray bits) {
    int length = content.length;
    int i = 0;
    while (i < length) {
      int num1 = content.codeUnitAt(i) - '0'.codeUnitAt(0);
      if (i + 2 < length) {
        // Encode three numeric letters in ten bits.
        int num2 = content.codeUnitAt(i + 1) - '0'.codeUnitAt(0);
        int num3 = content.codeUnitAt(i + 2) - '0'.codeUnitAt(0);
        bits.appendBits(num1 * 100 + num2 * 10 + num3, 10);
        i += 3;
      } else if (i + 1 < length) {
        // Encode two numeric letters in seven bits.
        int num2 = content.codeUnitAt(i + 1) - '0'.codeUnitAt(0);
        bits.appendBits(num1 * 10 + num2, 7);
        i += 2;
      } else {
        // Encode one numeric letter in four bits.
        bits.appendBits(num1, 4);
        i++;
      }
    }
  }

  static void appendAlphanumericBytes(String content, BitArray bits) {
    int length = content.length;
    int i = 0;
    while (i < length) {
      int code1 = getAlphanumericCode(content.codeUnitAt(i));
      if (code1 == -1) {
        throw WriterException();
      }
      if (i + 1 < length) {
        int code2 = getAlphanumericCode(content.codeUnitAt(i + 1));
        if (code2 == -1) {
          throw WriterException();
        }
        // Encode two alphanumeric letters in 11 bits.
        bits.appendBits(code1 * 45 + code2, 11);
        i += 2;
      } else {
        // Encode one alphanumeric letter in six bits.
        bits.appendBits(code1, 6);
        i++;
      }
    }
  }

  static void append8BitBytes(
      String content, BitArray bits, Encoding encoding) {
    List<int> bytes = encoding.encode(content);
    for (int b in bytes) {
      bits.appendBits(b, 8);
    }
  }

  static void appendKanjiBytes(String content, BitArray bits) {
    List<int> bytes = StringUtils.SHIFT_JIS_CHARSET!.encode(content);
    if (bytes.length % 2 != 0) {
      throw WriterException("Kanji byte size not even");
    }
    int maxI = bytes.length - 1; // bytes.length must be even
    for (int i = 0; i < maxI; i += 2) {
      int byte1 = bytes[i] & 0xFF;
      int byte2 = bytes[i + 1] & 0xFF;
      int code = (byte1 << 8) | byte2;
      int subtracted = -1;
      if (code >= 0x8140 && code <= 0x9ffc) {
        subtracted = code - 0x8140;
      } else if (code >= 0xe040 && code <= 0xebbf) {
        subtracted = code - 0xc140;
      }
      if (subtracted == -1) {
        throw WriterException("Invalid byte sequence");
      }
      int encoded = ((subtracted >> 8) * 0xc0) + (subtracted & 0xff);
      bits.appendBits(encoded, 13);
    }
  }

  static void appendECI(CharacterSetECI eci, BitArray bits) {
    bits.appendBits(Mode.ECI.getBits(), 4);
    // This is correct for values up to 127, which is all we need now.
    bits.appendBits(eci.getValue(), 8);
  }
}
