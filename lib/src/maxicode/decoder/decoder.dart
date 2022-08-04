/*
 * Copyright 2011 ZXing authors
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
import '../../decode_hint_type.dart';
import '../../formats_exception.dart';
import 'bit_matrix_parser.dart';
import 'decoded_bit_stream_parser.dart';

/// The main class which implements MaxiCode decoding -- as opposed to locating and extracting
/// the MaxiCode from an image.
///
/// @author Manuel Kasten
class Decoder {
  static const int _ALL = 0;
  static const int _EVEN = 1;
  static const int _ODD = 2;

  final ReedSolomonDecoder _rsDecoder;

  Decoder() : _rsDecoder = ReedSolomonDecoder(GenericGF.maxicodeField64);

  DecoderResult decode(BitMatrix bits, [Map<DecodeHintType, Object>? hints]) {
    final parser = BitMatrixParser(bits);
    final codewords = parser.readCodewords();

    _correctErrors(codewords, 0, 10, 10, _ALL);
    final mode = codewords[0] & 0x0F;
    late Uint8List datawords;
    switch (mode) {
      case 2:
      case 3:
      case 4:
        _correctErrors(codewords, 20, 84, 40, _EVEN);
        _correctErrors(codewords, 20, 84, 40, _ODD);
        datawords = Uint8List(94);
        break;
      case 5:
        _correctErrors(codewords, 20, 68, 56, _EVEN);
        _correctErrors(codewords, 20, 68, 56, _ODD);
        datawords = Uint8List(78);
        break;
      default:
        throw FormatsException.instance;
    }

    List.copyRange(datawords, 0, codewords, 0, 10);
    List.copyRange(datawords, 10, codewords, 20, datawords.length + 10);

    return DecodedBitStreamParser.decode(datawords, mode);
  }

  void _correctErrors(Uint8List codewordBytes, int start, int dataCodewords,
      int ecCodewords, int mode) {
    final codewords = dataCodewords + ecCodewords;

    // in EVEN or ODD mode only half the codewords
    final divisor = mode == _ALL ? 1 : 2;

    // First read into an array of ints
    final codewordsInts = Int32List(codewords ~/ divisor);
    for (int i = 0; i < codewords; i++) {
      if ((mode == _ALL) || (i % 2 == (mode - 1))) {
        codewordsInts[i ~/ divisor] = codewordBytes[i + start] & 0xFF;
      }
    }
    try {
      _rsDecoder.decode(codewordsInts, ecCodewords ~/ divisor);
    } on ReedSolomonException catch (_) {
      throw ChecksumException.getChecksumInstance();
    }
    // Copy back into array of bytes -- only need to worry about the bytes that were data
    // We don't care about errors in the error-correction codewords
    for (int i = 0; i < dataCodewords; i++) {
      if ((mode == _ALL) || (i % 2 == (mode - 1))) {
        codewordBytes[i + start] = codewordsInts[i ~/ divisor];
      }
    }
  }
}
