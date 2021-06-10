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

import 'dart:typed_data';

import 'error_correction_level.dart';
import 'version.dart';

/// Encapsulates a block of data within a QR Code.
///
/// QR Codes may split their data into multiple blocks,
/// each of which is a unit of data and error-correction codewords. Each
/// is represented by an instance of this class.
///
/// @author Sean Owen
class DataBlock {
  final int _numDataCodewords;
  final Uint8List _codewords;

  DataBlock._(this._numDataCodewords, this._codewords);

  /// <p>When QR Codes use multiple data blocks, they are actually interleaved.
  /// That is, the first byte of data block 1 to n is written, then the second bytes, and so on. This
  /// method will separate the data into original blocks.</p>
  ///
  /// @param rawCodewords bytes as read directly from the QR Code
  /// @param version version of the QR Code
  /// @param ecLevel error-correction level of the QR Code
  /// @return DataBlocks containing original bytes, "de-interleaved" from representation in the
  ///         QR Code
  static List<DataBlock> getDataBlocks(
      Uint8List rawCodewords, Version version, ErrorCorrectionLevel ecLevel) {
    if (rawCodewords.length != version.totalCodewords) {
      throw Exception();
    }

    // Figure out the number and size of data blocks used by this version and
    // error correction level
    ECBlocks ecBlocks = version.getECBlocksForLevel(ecLevel);

    // First count the total number of data blocks
    //int totalBlocks = 0;
    List<ECB> ecBlockArray = ecBlocks.ecBlocks;
    //for (ECB ecBlock in ecBlockArray) {
    //  totalBlocks += ecBlock.getCount();
    //}

    // Now establish DataBlocks of the appropriate size and number of data codewords
    List<DataBlock> result = [];
    for (ECB ecBlock in ecBlockArray) {
      for (int i = 0; i < ecBlock.count; i++) {
        int numDataCodewords = ecBlock.dataCodewords;
        int numBlockCodewords =
            ecBlocks.ecCodewordsPerBlock + numDataCodewords;
        result.add(DataBlock._(numDataCodewords, Uint8List(numBlockCodewords)));
      }
    }
    int numResultBlocks = result.length;

    // All blocks have the same amount of data, except that the last n
    // (where n may be 0) have 1 more byte. Figure out where these start.
    int shorterBlocksTotalCodewords = result[0]._codewords.length;
    int longerBlocksStartAt = result.length - 1;
    while (longerBlocksStartAt >= 0) {
      int numCodewords = result[longerBlocksStartAt]._codewords.length;
      if (numCodewords == shorterBlocksTotalCodewords) {
        break;
      }
      longerBlocksStartAt--;
    }
    longerBlocksStartAt++;

    int shorterBlocksNumDataCodewords =
        shorterBlocksTotalCodewords - ecBlocks.ecCodewordsPerBlock;
    // The last elements of result may be 1 element longer;
    // first fill out as many elements as all of them have
    int rawCodewordsOffset = 0;
    for (int i = 0; i < shorterBlocksNumDataCodewords; i++) {
      for (int j = 0; j < numResultBlocks; j++) {
        result[j]._codewords[i] = rawCodewords[rawCodewordsOffset++];
      }
    }
    // Fill out the last data block in the longer ones
    for (int j = longerBlocksStartAt; j < numResultBlocks; j++) {
      result[j]._codewords[shorterBlocksNumDataCodewords] =
          rawCodewords[rawCodewordsOffset++];
    }
    // Now add in error correction blocks
    int max = result[0]._codewords.length;
    for (int i = shorterBlocksNumDataCodewords; i < max; i++) {
      for (int j = 0; j < numResultBlocks; j++) {
        int iOffset = j < longerBlocksStartAt ? i : i + 1;
        result[j]._codewords[iOffset] = rawCodewords[rawCodewordsOffset++];
      }
    }
    return result;
  }

  int get numDataCodewords => _numDataCodewords;

  Uint8List get codewords => _codewords;
}
