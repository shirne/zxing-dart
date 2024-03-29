/*
 * Copyright 2012 ZXing authors
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

import 'dart:math' as math;
import 'dart:typed_data';

import '../../common.dart';
import '../barcode_format.dart';
import '../encode_hint.dart';
import '../writer.dart';
import 'encoder/pdf417.dart';

/// @author Jacob Haynes
/// @author qwandor@google.com (Andrew Walbran)
class PDF417Writer implements Writer {
  /// default white space (margin) around the code
  static const int _whiteSpace = 30;

  /// default error correction level
  static const int _defaultErrorCorrectionLevel = 2;

  @override
  BitMatrix encode(
    String contents,
    BarcodeFormat format,
    int width,
    int height, [
    EncodeHint? hints,
  ]) {
    if (format != BarcodeFormat.pdf417) {
      throw ArgumentError('Can only encode PDF_417, but got $format');
    }

    final encoder = PDF417();
    int margin = _whiteSpace;
    int errorCorrectionLevel = _defaultErrorCorrectionLevel;
    bool autoECI = false;

    if (hints != null) {
      if (hints.pdf417Compact == true) {
        encoder.setCompact(hints.pdf417Compact);
      }
      if (hints.pdf417Compaction != null) {
        encoder.setCompaction(hints.pdf417Compaction!);
      }
      if (hints.pdf417Dimensions != null) {
        final dimensions = hints.pdf417Dimensions!;
        encoder.setDimensions(
          dimensions.maxCols,
          dimensions.minCols,
          dimensions.maxRows,
          dimensions.minRows,
        );
      }
      if (hints.margin != null) {
        margin = hints.margin!;
      }
      if (hints.errorCorrection != null) {
        errorCorrectionLevel = hints.errorCorrection!;
      }
      if (hints.characterSet != null) {
        final encoding = CharacterSetECI.getCharacterSetECIByName(
          hints.characterSet!,
        )?.charset;
        if (encoding != null) encoder.setEncoding(encoding);
      }
      autoECI = hints.pdf417AutoEci;
    }

    return _bitMatrixFromEncoder(
      encoder,
      contents,
      errorCorrectionLevel,
      width,
      height,
      margin,
      autoECI,
    );
  }

  /// Takes encoder, accounts for width/height, and retrieves bit matrix
  static BitMatrix _bitMatrixFromEncoder(
    PDF417 encoder,
    String contents,
    int errorCorrectionLevel,
    int width,
    int height,
    int margin,
    bool autoECI,
  ) {
    encoder.generateBarcodeLogic(contents, errorCorrectionLevel, autoECI);

    final aspectRatio = 4;
    List<Uint8List> originalScale =
        encoder.barcodeMatrix!.getScaledMatrix(1, aspectRatio);
    bool rotated = false;
    if ((height > width) != (originalScale[0].length < originalScale.length)) {
      originalScale = _rotateArray(originalScale);
      rotated = true;
    }

    final scaleX = width ~/ originalScale[0].length;
    final scaleY = height ~/ originalScale.length;
    final scale = math.min(scaleX, scaleY);

    if (scale > 1) {
      List<Uint8List> scaledMatrix =
          encoder.barcodeMatrix!.getScaledMatrix(scale, scale * aspectRatio);
      if (rotated) {
        scaledMatrix = _rotateArray(scaledMatrix);
      }
      return _bitMatrixFromBitArray(scaledMatrix, margin);
    }
    return _bitMatrixFromBitArray(originalScale, margin);
  }

  /// This takes an array holding the values of the PDF 417
  ///
  /// @param input a byte array of information with 0 is black, and 1 is white
  /// @param margin border around the barcode
  /// @return BitMatrix of the input
  static BitMatrix _bitMatrixFromBitArray(List<Uint8List> input, int margin) {
    // Creates the bit matrix with extra space for whitespace
    final output =
        BitMatrix(input[0].length + 2 * margin, input.length + 2 * margin);
    output.clear();
    for (int y = 0, yOutput = output.height - margin - 1;
        y < input.length;
        y++, yOutput--) {
      final inputY = input[y];
      for (int x = 0; x < input[0].length; x++) {
        // Zero is white in the byte matrix
        if (inputY[x] == 1) {
          output.set(x + margin, yOutput);
        }
      }
    }
    return output;
  }

  /// Takes and rotates the it 90 degrees
  static List<Uint8List> _rotateArray(List<Uint8List> bitarray) {
    final temp = List.generate(
      bitarray[0].length,
      (index) => Uint8List(bitarray.length),
    );
    for (int ii = 0; ii < bitarray.length; ii++) {
      // This makes the direction consistent on screen when rotating the
      // screen;
      final inverseii = bitarray.length - ii - 1;
      for (int jj = 0; jj < bitarray[0].length; jj++) {
        temp[jj][inverseii] = bitarray[ii][jj];
      }
    }
    return temp;
  }
}
