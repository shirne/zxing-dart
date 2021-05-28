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

/**
 * <p>Encapsulates the result of decoding a matrix of bits. This typically
 * applies to 2D barcode formats. For now it contains the raw bytes obtained,
 * as well as a String interpretation of those bytes, if applicable.</p>
 *
 * @author Sean Owen
 */
class DecoderResult {
  final Uint8List? rawBytes;
  int numBits;
  final String text;
  final List<Uint8List>? byteSegments;
  final String? ecLevel;
  int? errorsCorrected;
  int? erasures;
  Object? other;
  final int structuredAppendParity;
  final int structuredAppendSequenceNumber;
  final int symbologyModifier;

  DecoderResult(this.rawBytes, this.text, this.byteSegments, this.ecLevel,
      [this.structuredAppendSequenceNumber = -1,
      this.structuredAppendParity = -1,
      this.symbologyModifier = 0])
      : numBits = rawBytes == null ? 0 : 8 * rawBytes.length;

  /**
   * @return raw bytes representing the result, or {@code null} if not applicable
   */
  Uint8List getRawBytes() {
    return rawBytes!;
  }

  /**
   * @return how many bits of {@link #getRawBytes()} are valid; typically 8 times its length
   * @since 3.3.0
   */
  int getNumBits() {
    return numBits;
  }

  /**
   * @param numBits overrides the number of bits that are valid in {@link #getRawBytes()}
   * @since 3.3.0
   */
  void setNumBits(int numBits) {
    this.numBits = numBits;
  }

  /**
   * @return text representation of the result
   */
  String getText() {
    return text;
  }

  /**
   * @return list of byte segments in the result, or {@code null} if not applicable
   */
  List<Uint8List>? getByteSegments() {
    return byteSegments;
  }

  /**
   * @return name of error correction level used, or {@code null} if not applicable
   */
  String? getECLevel() {
    return ecLevel;
  }

  /**
   * @return number of errors corrected, or {@code null} if not applicable
   */
  int getErrorsCorrected() {
    return errorsCorrected!;
  }

  void setErrorsCorrected(int errorsCorrected) {
    this.errorsCorrected = errorsCorrected;
  }

  /**
   * @return number of erasures corrected, or {@code null} if not applicable
   */
  int getErasures() {
    return erasures!;
  }

  void setErasures(int erasures) {
    this.erasures = erasures;
  }

  /**
   * @return arbitrary additional metadata
   */
  Object? getOther() {
    return other;
  }

  void setOther(Object other) {
    this.other = other;
  }

  bool hasStructuredAppend() {
    return structuredAppendParity >= 0 && structuredAppendSequenceNumber >= 0;
  }

  int getStructuredAppendParity() {
    return structuredAppendParity;
  }

  int getStructuredAppendSequenceNumber() {
    return structuredAppendSequenceNumber;
  }

  int getSymbologyModifier() {
    return symbologyModifier;
  }
}
