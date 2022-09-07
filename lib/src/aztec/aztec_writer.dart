/*
 * Copyright 2013 ZXing authors
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
import 'dart:math' as math;

import '../common/bit_matrix.dart';
import '../common/character_set_eci.dart';
import '../barcode_format.dart';
import '../encode_hint_type.dart';
import '../writer.dart';
import 'encoder/aztec_code.dart';
import 'encoder/encoder.dart';

/// Renders an Aztec code as a [BitMatrix].
class AztecWriter implements Writer {
  @override
  BitMatrix encode(
    String contents,
    BarcodeFormat format,
    int width,
    int height, [
    Map<EncodeHintType, Object>? hints,
  ]) {
    Encoding? charset; // Do not add any ECI code by default
    int eccPercent = Encoder.DEFAULT_EC_PERCENT;
    int layers = Encoder.DEFAULT_AZTEC_LAYERS;
    if (hints != null) {
      if (hints.containsKey(EncodeHintType.CHARACTER_SET)) {
        charset = CharacterSetECI.getCharacterSetECIByName(
          hints[EncodeHintType.CHARACTER_SET] as String,
        )?.charset;
      }
      if (hints.containsKey(EncodeHintType.ERROR_CORRECTION)) {
        eccPercent =
            int.parse(hints[EncodeHintType.ERROR_CORRECTION].toString());
      }
      if (hints.containsKey(EncodeHintType.AZTEC_LAYERS)) {
        layers = int.parse(hints[EncodeHintType.AZTEC_LAYERS].toString());
      }
    }
    return _encodeStatic(
      contents,
      format,
      width,
      height,
      charset,
      eccPercent,
      layers,
    );
  }

  static BitMatrix _encodeStatic(
    String contents,
    BarcodeFormat format,
    int width,
    int height,
    Encoding? charset,
    int eccPercent,
    int layers,
  ) {
    if (format != BarcodeFormat.AZTEC) {
      throw ArgumentError('Can only encode AZTEC, but got $format');
    }
    final AztecCode aztec =
        Encoder.encode(contents, eccPercent, layers, charset);
    return _renderResult(aztec, width, height);
  }

  static BitMatrix _renderResult(AztecCode code, int width, int height) {
    final BitMatrix? input = code.matrix;
    if (input == null) {
      throw ArgumentError();
    }
    final int inputWidth = input.width;
    final int inputHeight = input.height;
    final int outputWidth = math.max(width, inputWidth);
    final int outputHeight = math.max(height, inputHeight);

    final int multiple =
        math.min(outputWidth ~/ inputWidth, outputHeight ~/ inputHeight);
    final int leftPadding = (outputWidth - (inputWidth * multiple)) ~/ 2;
    final int topPadding = (outputHeight - (inputHeight * multiple)) ~/ 2;

    final BitMatrix output = BitMatrix(outputWidth, outputHeight);

    for (int inputY = 0, outputY = topPadding;
        inputY < inputHeight;
        inputY++, outputY += multiple) {
      // Write the contents of this row of the barcode
      for (int inputX = 0, outputX = leftPadding;
          inputX < inputWidth;
          inputX++, outputX += multiple) {
        if (input.get(inputX, inputY)) {
          output.setRegion(outputX, outputY, multiple, multiple);
        }
      }
    }
    return output;
  }
}
