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
  int _numBits;
  final String _text;
  final List<Uint8List>? _byteSegments;
  final String? _ecLevel;
  int? _errorsCorrected;
  int? _erasures;
  Object? _other;
  final int _structuredAppendParity;
  final int _structuredAppendSequenceNumber;
  final int _symbologyModifier;

  DecoderResult(this._rawBytes, this._text, this._byteSegments, this._ecLevel,
      [this._structuredAppendSequenceNumber = -1,
      this._structuredAppendParity = -1,
      this._symbologyModifier = 0])
      : _numBits = _rawBytes == null ? 0 : 8 * _rawBytes.length;

  /// @return raw bytes representing the result, or {@code null} if not applicable
  Uint8List getRawBytes() {
    return _rawBytes!;
  }

  /// @return how many bits of {@link #getRawBytes()} are valid; typically 8 times its length
  /// @since 3.3.0
  int getNumBits() {
    return _numBits;
  }

  /// @param numBits overrides the number of bits that are valid in {@link #getRawBytes()}
  /// @since 3.3.0
  void setNumBits(int numBits) {
    this._numBits = numBits;
  }

  /// @return text representation of the result
  String getText() {
    return _text;
  }

  /// @return list of byte segments in the result, or {@code null} if not applicable
  List<Uint8List>? getByteSegments() {
    return _byteSegments;
  }

  /// @return name of error correction level used, or {@code null} if not applicable
  String? getECLevel() {
    return _ecLevel;
  }

  /// @return number of errors corrected, or {@code null} if not applicable
  int getErrorsCorrected() {
    return _errorsCorrected!;
  }

  void setErrorsCorrected(int errorsCorrected) {
    this._errorsCorrected = errorsCorrected;
  }

  /// @return number of erasures corrected, or {@code null} if not applicable
  int getErasures() {
    return _erasures!;
  }

  void setErasures(int erasures) {
    this._erasures = erasures;
  }

  /// @return arbitrary additional metadata
  Object? getOther() {
    return _other;
  }

  void setOther(Object other) {
    this._other = other;
  }

  bool hasStructuredAppend() {
    return _structuredAppendParity >= 0 && _structuredAppendSequenceNumber >= 0;
  }

  int getStructuredAppendParity() {
    return _structuredAppendParity;
  }

  int getStructuredAppendSequenceNumber() {
    return _structuredAppendSequenceNumber;
  }

  int getSymbologyModifier() {
    return _symbologyModifier;
  }
}
