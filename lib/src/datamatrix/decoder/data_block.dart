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

import 'version.dart';

/// Encapsulates a block of data within a Data Matrix Code.
///
/// Data Matrix Codes may split their data into
/// multiple blocks, each of which is a unit of data and error-correction codewords.
/// Each is represented by an instance of this class.
///
/// @author bbrown@google.com (Brian Brown)
class DataBlock {
  final int _numDataCodewords;
  final Uint8List _codewords;

  DataBlock._(this._numDataCodewords, this._codewords);

  /// <p>When Data Matrix Codes use multiple data blocks, they actually interleave the bytes of each of them.
  /// That is, the first byte of data block 1 to n is written, then the second bytes, and so on. This
  /// method will separate the data into original blocks.</p>
  ///
  /// @param rawCodewords bytes as read directly from the Data Matrix Code
  /// @param version version of the Data Matrix Code
  /// @return DataBlocks containing original bytes, "de-interleaved" from representation in the
  ///         Data Matrix Code
  static List<DataBlock> getDataBlocks(
    Uint8List rawCodewords,
    Version version,
  ) {
    // Figure out the number and size of data blocks used by this version
    final ecBlocks = version.ecBlocks;

    // First count the total number of data blocks
    //int totalBlocks = 0;
    final ecBlockArray = ecBlocks.ecBlocks;
    //for (ECB ecBlock in ecBlockArray) {
    //  totalBlocks += ecBlock.getCount();
    //}

    // Now establish DataBlocks of the appropriate size and number of data codewords
    final result = <DataBlock>[];
    //int numResultBlocks = 0;
    for (ECB ecBlock in ecBlockArray) {
      for (int i = 0; i < ecBlock.count; i++) {
        final numDataCodewords = ecBlock.dataCodewords;
        final numBlockCodewords = ecBlocks.ecCodewords + numDataCodewords;
        result.add(DataBlock._(numDataCodewords, Uint8List(numBlockCodewords)));
      }
    }
    final numResultBlocks = result.length;

    // All blocks have the same amount of data, except that the last n
    // (where n may be 0) have 1 less byte. Figure out where these start.
    // TODO(bbrown): There is only one case where there is a difference for Data Matrix for size 144
    final longerBlocksTotalCodewords = result[0]._codewords.length;
    //int shorterBlocksTotalCodewords = longerBlocksTotalCodewords - 1;

    final longerBlocksNumDataCodewords =
        longerBlocksTotalCodewords - ecBlocks.ecCodewords;
    final shorterBlocksNumDataCodewords = longerBlocksNumDataCodewords - 1;
    // The last elements of result may be 1 element shorter for 144 matrix
    // first fill out as many elements as all of them have minus 1
    int rawCodewordsOffset = 0;
    for (int i = 0; i < shorterBlocksNumDataCodewords; i++) {
      for (int j = 0; j < numResultBlocks; j++) {
        result[j]._codewords[i] = rawCodewords[rawCodewordsOffset++];
      }
    }

    // Fill out the last data block in the longer ones
    final specialVersion = version.versionNumber == 24;
    final numLongerBlocks = specialVersion ? 8 : numResultBlocks;
    for (int j = 0; j < numLongerBlocks; j++) {
      result[j]._codewords[longerBlocksNumDataCodewords - 1] =
          rawCodewords[rawCodewordsOffset++];
    }

    // Now add in error correction blocks
    final max = result[0]._codewords.length;
    for (int i = longerBlocksNumDataCodewords; i < max; i++) {
      for (int j = 0; j < numResultBlocks; j++) {
        final jOffset = specialVersion ? (j + 8) % numResultBlocks : j;
        final iOffset = specialVersion && jOffset > 7 ? i - 1 : i;
        result[jOffset]._codewords[iOffset] =
            rawCodewords[rawCodewordsOffset++];
      }
    }

    if (rawCodewordsOffset != rawCodewords.length) {
      throw ArgumentError();
    }

    return result;
  }

  int get numDataCodewords => _numDataCodewords;

  Uint8List get codewords => _codewords;
}
