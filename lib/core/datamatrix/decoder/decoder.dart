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

import '../../common/bit_matrix.dart';
import '../../common/decoder_result.dart';
import '../../common/reedsolomon/generic_gf.dart';
import '../../common/reedsolomon/reed_solomon_decoder.dart';
import '../../common/reedsolomon/reed_solomon_exception.dart';

import '../../checksum_exception.dart';
import 'version.dart';
import 'bit_matrix_parser.dart';
import 'data_block.dart';
import 'decoded_bit_stream_parser.dart';

/// <p>The main class which implements Data Matrix Code decoding -- as opposed to locating and extracting
/// the Data Matrix Code from an image.</p>
///
/// @author bbrown@google.com (Brian Brown)
class Decoder {
  final ReedSolomonDecoder _rsDecoder;

  Decoder():_rsDecoder = ReedSolomonDecoder(GenericGF.DATA_MATRIX_FIELD_256);

  /// <p>Convenience method that can decode a Data Matrix Code represented as a 2D array of booleans.
  /// "true" is taken to mean a black module.</p>
  ///
  /// @param image booleans representing white/black Data Matrix Code modules
  /// @return text and bytes encoded within the Data Matrix Code
  /// @throws FormatException if the Data Matrix Code cannot be decoded
  /// @throws ChecksumException if error correction fails
  DecoderResult decode(List<List<bool>> image) {
    return decodeMatrix(BitMatrix.parse(image));
  }

  /// <p>Decodes a Data Matrix Code represented as a {@link BitMatrix}. A 1 or "true" is taken
  /// to mean a black module.</p>
  ///
  /// @param bits booleans representing white/black Data Matrix Code modules
  /// @return text and bytes encoded within the Data Matrix Code
  /// @throws FormatException if the Data Matrix Code cannot be decoded
  /// @throws ChecksumException if error correction fails
  DecoderResult decodeMatrix(BitMatrix bits) {
    // Construct a parser and read version, error-correction level
    BitMatrixParser parser = BitMatrixParser(bits);
    Version version = parser.getVersion();

    // Read codewords
    Uint8List codewords = parser.readCodewords();
    // Separate into data blocks
    List<DataBlock> dataBlocks = DataBlock.getDataBlocks(codewords, version);

    // Count total number of data bytes
    int totalBytes = 0;
    for (DataBlock db in dataBlocks) {
      totalBytes += db.getNumDataCodewords();
    }
    Uint8List resultBytes = Uint8List(totalBytes);

    int dataBlocksCount = dataBlocks.length;
    // Error-correct and copy data blocks together into a stream of bytes
    for (int j = 0; j < dataBlocksCount; j++) {
      DataBlock dataBlock = dataBlocks[j];
      Uint8List codewordBytes = dataBlock.getCodewords();
      int numDataCodewords = dataBlock.getNumDataCodewords();
      _correctErrors(codewordBytes, numDataCodewords);
      for (int i = 0; i < numDataCodewords; i++) {
        // De-interlace data blocks.
        resultBytes[i * dataBlocksCount + j] = codewordBytes[i];
      }
    }

    // Decode the contents of that stream of bytes
    return DecodedBitStreamParser.decode(resultBytes);
  }

  /// <p>Given data and error-correction codewords received, possibly corrupted by errors, attempts to
  /// correct the errors in-place using Reed-Solomon error correction.</p>
  ///
  /// @param codewordBytes data and error correction codewords
  /// @param numDataCodewords number of codewords that are data bytes
  /// @throws ChecksumException if error correction fails
  void _correctErrors(Uint8List codewordBytes, int numDataCodewords) {
    int numCodewords = codewordBytes.length;
    // First read into an array of ints
    List<int> codewordsInts =
        List.generate(numCodewords, (index) => codewordBytes[index] & 0xFF);

    try {
      _rsDecoder.decode(codewordsInts, codewordBytes.length - numDataCodewords);
    } on ReedSolomonException catch (_) {
      throw ChecksumException.getChecksumInstance();
    }
    // Copy back into array of bytes -- only need to worry about the bytes that were data
    // We don't care about errors in the error-correction codewords
    for (int i = 0; i < numDataCodewords; i++) {
      codewordBytes[i] = codewordsInts[i];
    }
  }
}
