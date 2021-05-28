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

import 'dart:math' as Math;

import 'package:zxing/core/common/bit_matrix.dart';

import '../barcode_format.dart';
import '../encode_hint_type.dart';
import '../writer.dart';

/**
 * <p>Encapsulates functionality and implementation that is common to one-dimensional barcodes.</p>
 *
 * @author dsbnatut@gmail.com (Kazuki Nishiura)
 */
abstract class OneDimensionalCodeWriter implements Writer {
  static final RegExp NUMERIC = RegExp(r"[0-9]+");

  /**
   * Encode the contents following specified format.
   * {@code width} and {@code height} are required size. This method may return bigger size
   * {@code BitMatrix} when specified size is too small. The user can set both {@code width} and
   * {@code height} to zero to get minimum size barcode. If negative value is set to {@code width}
   * or {@code height}, {@code IllegalArgumentException} is thrown.
   */
  @override
  BitMatrix encode(String contents, BarcodeFormat format, int width, int height,
      [Map<EncodeHintType, Object>? hints]) {
    if (contents.isEmpty) {
      throw Exception("Found empty contents");
    }

    if (width < 0 || height < 0) {
      throw Exception(
          "Negative size is not allowed. Input: $width" + 'x$height');
    }
    List<BarcodeFormat> supportedFormats = getSupportedWriteFormats()!;
    if (supportedFormats != null && !supportedFormats.contains(format)) {
      throw Exception(
          "Can only encode $supportedFormats" + ", but got $format");
    }

    int sidesMargin = getDefaultMargin();
    if (hints != null && hints.containsKey(EncodeHintType.MARGIN)) {
      sidesMargin = int.parse(hints[EncodeHintType.MARGIN].toString());
    }

    List<bool> code = encodeContent(contents);
    return renderResult(code, width, height, sidesMargin);
  }

  List<BarcodeFormat>? getSupportedWriteFormats() {
    return null;
  }

  /**
   * @return a byte array of horizontal pixels (0 = white, 1 = black)
   */
  static BitMatrix renderResult(
      List<bool> code, int width, int height, int sidesMargin) {
    int inputWidth = code.length;
    // Add quiet zone on both sides.
    int fullWidth = inputWidth + sidesMargin;
    int outputWidth = Math.max(width, fullWidth);
    int outputHeight = Math.max(1, height);

    int multiple = outputWidth ~/ fullWidth;
    int leftPadding = (outputWidth - (inputWidth * multiple)) ~/ 2;

    BitMatrix output = new BitMatrix(outputWidth, outputHeight);
    for (int inputX = 0, outputX = leftPadding;
        inputX < inputWidth;
        inputX++, outputX += multiple) {
      if (code[inputX]) {
        output.setRegion(outputX, 0, multiple, outputHeight);
      }
    }
    return output;
  }

  /**
   * @param contents string to check for numeric characters
   * @throws IllegalArgumentException if input contains characters other than digits 0-9.
   */
  static void checkNumeric(String contents) {
    if (!NUMERIC.hasMatch(contents)) {
      throw Exception("Input should only contain digits 0-9");
    }
  }

  /**
   * @param target encode black/white pattern into this array
   * @param pos position to start encoding at in {@code target}
   * @param pattern lengths of black/white runs to encode
   * @param startColor starting color - false for white, true for black
   * @return the number of elements added to target.
   */
  static int appendPattern(
      List<bool> target, int pos, List<int> pattern, bool startColor) {
    bool color = startColor;
    int numAdded = 0;
    for (int len in pattern) {
      for (int j = 0; j < len; j++) {
        target[pos++] = color;
      }
      numAdded += len;
      color = !color; // flip color after each segment
    }
    return numAdded;
  }

  int getDefaultMargin() {
    // CodaBar spec requires a side margin to be more than ten times wider than narrow space.
    // This seems like a decent idea for a default for all formats.
    return 10;
  }

  /**
   * Encode the contents to bool array expression of one-dimensional barcode.
   * Start code and end code should be included in result, and side margins should not be included.
   *
   * @param contents barcode contents to encode
   * @return a {@code List<bool>} of horizontal pixels (false = white, true = black)
   */
  List<bool> encodeContent(String contents);
}
