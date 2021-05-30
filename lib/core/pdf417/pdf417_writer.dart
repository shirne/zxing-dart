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

import 'dart:convert';
import 'dart:math' as Math;
import 'dart:typed_data';

import '../common/bit_matrix.dart';

import '../barcode_format.dart';
import '../encode_hint_type.dart';
import '../writer.dart';
import 'encoder/compaction.dart';
import 'encoder/dimensions.dart';
import 'encoder/pdf417.dart';

/**
 * @author Jacob Haynes
 * @author qwandor@google.com (Andrew Walbran)
 */
class PDF417Writer implements Writer {
  /**
   * default white space (margin) around the code
   */
  static final int WHITE_SPACE = 30;

  /**
   * default error correction level
   */
  static final int DEFAULT_ERROR_CORRECTION_LEVEL = 2;

  @override
  BitMatrix encode(String contents, BarcodeFormat format, int width, int height,
      [Map<EncodeHintType, Object>? hints]) {
    if (format != BarcodeFormat.PDF_417) {
      throw Exception("Can only encode PDF_417, but got $format");
    }

    PDF417 encoder = PDF417();
    int margin = WHITE_SPACE;
    int errorCorrectionLevel = DEFAULT_ERROR_CORRECTION_LEVEL;

    if (hints != null) {
      if (hints.containsKey(EncodeHintType.PDF417_COMPACT)) {
        encoder.setCompact(hints[EncodeHintType.PDF417_COMPACT] as bool);
      }
      if (hints.containsKey(EncodeHintType.PDF417_COMPACTION)) {
        encoder.setCompaction(
            hints[EncodeHintType.PDF417_COMPACTION] as Compaction);
      }
      if (hints.containsKey(EncodeHintType.PDF417_DIMENSIONS)) {
        Dimensions dimensions =
            hints[EncodeHintType.PDF417_DIMENSIONS] as Dimensions;
        encoder.setDimensions(dimensions.getMaxCols(), dimensions.getMinCols(),
            dimensions.getMaxRows(), dimensions.getMinRows());
      }
      if (hints.containsKey(EncodeHintType.MARGIN)) {
        margin = int.parse(hints[EncodeHintType.MARGIN].toString());
      }
      if (hints.containsKey(EncodeHintType.ERROR_CORRECTION)) {
        errorCorrectionLevel =
            int.parse(hints[EncodeHintType.ERROR_CORRECTION].toString());
      }
      if (hints.containsKey(EncodeHintType.CHARACTER_SET)) {
        Encoding encoding =
            Encoding.getByName(hints[EncodeHintType.CHARACTER_SET].toString())!;
        encoder.setEncoding(encoding);
      }
    }

    return bitMatrixFromEncoder(
        encoder, contents, errorCorrectionLevel, width, height, margin);
  }

  /**
   * Takes encoder, accounts for width/height, and retrieves bit matrix
   */
  static BitMatrix bitMatrixFromEncoder(PDF417 encoder, String contents,
      int errorCorrectionLevel, int width, int height, int margin) {
    encoder.generateBarcodeLogic(contents, errorCorrectionLevel);

    int aspectRatio = 4;
    List<Uint8List> originalScale =
        encoder.getBarcodeMatrix()!.getScaledMatrix(1, aspectRatio);
    bool rotated = false;
    if ((height > width) != (originalScale[0].length < originalScale.length)) {
      originalScale = rotateArray(originalScale);
      rotated = true;
    }

    int scaleX = width ~/ originalScale[0].length;
    int scaleY = height ~/ originalScale.length;
    int scale = Math.min(scaleX, scaleY);

    if (scale > 1) {
      List<Uint8List> scaledMatrix = encoder
          .getBarcodeMatrix()!
          .getScaledMatrix(scale, scale * aspectRatio);
      if (rotated) {
        scaledMatrix = rotateArray(scaledMatrix);
      }
      return bitMatrixFromBitArray(scaledMatrix, margin);
    }
    return bitMatrixFromBitArray(originalScale, margin);
  }

  /**
   * This takes an array holding the values of the PDF 417
   *
   * @param input a byte array of information with 0 is black, and 1 is white
   * @param margin border around the barcode
   * @return BitMatrix of the input
   */
  static BitMatrix bitMatrixFromBitArray(List<Uint8List> input, int margin) {
    // Creates the bit matrix with extra space for whitespace
    BitMatrix output =
        BitMatrix(input[0].length + 2 * margin, input.length + 2 * margin);
    output.clear();
    for (int y = 0, yOutput = output.getHeight() - margin - 1;
        y < input.length;
        y++, yOutput--) {
      Uint8List inputY = input[y];
      for (int x = 0; x < input[0].length; x++) {
        // Zero is white in the byte matrix
        if (inputY[x] == 1) {
          output.set(x + margin, yOutput);
        }
      }
    }
    return output;
  }

  /**
   * Takes and rotates the it 90 degrees
   */
  static List<Uint8List> rotateArray(List<Uint8List> bitarray) {
    List<Uint8List> temp = List.generate(
        bitarray[0].length, (index) => Uint8List(bitarray.length));
    for (int ii = 0; ii < bitarray.length; ii++) {
      // This makes the direction consistent on screen when rotating the
      // screen;
      int inverseii = bitarray.length - ii - 1;
      for (int jj = 0; jj < bitarray[0].length; jj++) {
        temp[jj][inverseii] = bitarray[ii][jj];
      }
    }
    return temp;
  }
}
