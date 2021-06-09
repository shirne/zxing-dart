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

/// <p>Encapsulates the result of decoding a matrix of bits. This typically
/// applies to 2D barcode formats. For now it contains the raw bytes obtained,
/// as well as a String interpretation of those bytes, if applicable.</p>
///
/// @author Sean Owen
class DecoderResult {
  final Uint8List? _rawBytes;

  /// how many bits of [rawBytes] are valid; typically 8 times its length
  /// you can overrides the number of bits that are valid in
  int numBits;

  final String _text;
  final List<Uint8List>? _byteSegments;
  final String? _ecLevel;

  final int _structuredAppendParity;
  final int _structuredAppendSequenceNumber;
  final int _symbologyModifier;

  /// number of errors corrected, or `null` if not applicable
  int? errorsCorrected;

  /// number of erasures corrected, or `null` if not applicable
  int? erasures;

  /// arbitrary additional metadata
  Object? other;


  DecoderResult(this._rawBytes, this._text, this._byteSegments, this._ecLevel,
      [this._structuredAppendSequenceNumber = -1,
      this._structuredAppendParity = -1,
      this._symbologyModifier = 0])
      : numBits = _rawBytes == null ? 0 : 8 * _rawBytes.length;

  /// @return raw bytes representing the result, or {@code null} if not applicable
  Uint8List get rawBytes => _rawBytes!;

  /// @return text representation of the result
  String get text => _text;

  /// @return list of byte segments in the result, or {@code null} if not applicable
  List<Uint8List>? get byteSegments => _byteSegments;

  /// @return name of error correction level used, or {@code null} if not applicable
  String? get ecLevel => _ecLevel;


  bool get hasStructuredAppend => _structuredAppendParity >= 0 && _structuredAppendSequenceNumber >= 0;

  int get structuredAppendParity => _structuredAppendParity;

  int get structuredAppendSequenceNumber => _structuredAppendSequenceNumber;

  int get symbologyModifier => _symbologyModifier;
}
