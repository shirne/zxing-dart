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

import 'dart:convert';
import 'dart:math' as math;

import '../barcode_format.dart';
import '../common/bit_matrix.dart';
import '../dimension.dart';
import '../encode_hint_type.dart';
import '../qrcode/encoder/byte_matrix.dart';
import '../writer.dart';
import 'encoder/default_placement.dart';
import 'encoder/error_correction.dart';
import 'encoder/high_level_encoder.dart';
import 'encoder/minimal_encoder.dart';
import 'encoder/symbol_info.dart';
import 'encoder/symbol_shape_hint.dart';

/// This object renders a Data Matrix code as a BitMatrix 2D array of greyscale values.
///
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Guillaume Le Biller Added to zxing lib.
class DataMatrixWriter implements Writer {
  @override
  BitMatrix encode(String contents, BarcodeFormat format, int width, int height,
      [Map<EncodeHintType, Object>? hints]) {
    if (contents.isEmpty) {
      throw ArgumentError("Found empty contents");
    }

    if (format != BarcodeFormat.DATA_MATRIX) {
      throw ArgumentError("Can only encode DATA_MATRIX, but got $format");
    }

    if (width < 0 || height < 0) {
      throw ArgumentError(
          "Requested dimensions can't be negative: $width" 'x$height');
    }

    // Try to get force shape & min / max size
    SymbolShapeHint shape = SymbolShapeHint.FORCE_NONE;
    Dimension? minSize;
    Dimension? maxSize;
    if (hints != null) {
      SymbolShapeHint? requestedShape =
          hints[EncodeHintType.DATA_MATRIX_SHAPE] as SymbolShapeHint?;
      if (requestedShape != null) {
        shape = requestedShape;
      }
      // ignore: deprecated_consistency
      Dimension? requestedMinSize =
          hints[EncodeHintType.MIN_SIZE] as Dimension?;
      if (requestedMinSize != null) {
        minSize = requestedMinSize;
      }
      // ignore: deprecated_consistency
      Dimension? requestedMaxSize =
          hints[EncodeHintType.MAX_SIZE] as Dimension?;
      if (requestedMaxSize != null) {
        maxSize = requestedMaxSize;
      }
    }

    //1. step: Data encodation
    String encoded;

    bool hasCompactionHint = hints != null &&
        hints.containsKey(EncodeHintType.DATA_MATRIX_COMPACT) &&
        (hints[EncodeHintType.DATA_MATRIX_COMPACT] as bool);
    if (hasCompactionHint) {
      bool hasGS1FormatHint = hints.containsKey(EncodeHintType.GS1_FORMAT) &&
          (hints[EncodeHintType.GS1_FORMAT] as bool);

      Encoding? charset;
      bool hasEncodingHint = hints.containsKey(EncodeHintType.CHARACTER_SET);
      if (hasEncodingHint) {
        charset = (hints[EncodeHintType.CHARACTER_SET] as Encoding?);
      }
      encoded = MinimalEncoder.encodeHighLevel(
          contents, charset, hasGS1FormatHint ? 0x1D : -1, shape);
    } else {
      encoded =
          HighLevelEncoder.encodeHighLevel(contents, shape, minSize, maxSize);
    }

    SymbolInfo? symbolInfo =
        SymbolInfo.lookup(encoded.length, shape, minSize, maxSize, true);

    //2. step: ECC generation
    String codewords = ErrorCorrection.encodeECC200(encoded, symbolInfo!);

    //3. step: Module placement in Matrix
    DefaultPlacement placement = DefaultPlacement(
        codewords, symbolInfo.symbolDataWidth, symbolInfo.symbolDataHeight);
    placement.place();

    //4. step: low-level encoding
    return _encodeLowLevel(placement, symbolInfo, width, height);
  }

  /// Encode the given symbol info to a bit matrix.
  ///
  /// @param placement  The DataMatrix placement.
  /// @param symbolInfo The symbol info to encode.
  /// @return The bit matrix generated.
  static BitMatrix _encodeLowLevel(DefaultPlacement placement,
      SymbolInfo symbolInfo, int width, int height) {
    int symbolWidth = symbolInfo.symbolDataWidth;
    int symbolHeight = symbolInfo.symbolDataHeight;

    ByteMatrix matrix =
        ByteMatrix(symbolInfo.symbolWidth, symbolInfo.symbolHeight);

    int matrixY = 0;

    for (int y = 0; y < symbolHeight; y++) {
      // Fill the top edge with alternate 0 / 1
      int matrixX;
      if ((y % symbolInfo.matrixHeight) == 0) {
        matrixX = 0;
        for (int x = 0; x < symbolInfo.symbolWidth; x++) {
          matrix.set(matrixX, matrixY, (x % 2) == 0 ? 1 : 0);
          matrixX++;
        }
        matrixY++;
      }
      matrixX = 0;
      for (int x = 0; x < symbolWidth; x++) {
        // Fill the right edge with full 1
        if ((x % symbolInfo.matrixWidth) == 0) {
          matrix.set(matrixX, matrixY, 1);
          matrixX++;
        }
        matrix.set(matrixX, matrixY, placement.getBit(x, y) ? 1 : 0);
        matrixX++;
        // Fill the right edge with alternate 0 / 1
        if ((x % symbolInfo.matrixWidth) == symbolInfo.matrixWidth - 1) {
          matrix.set(matrixX, matrixY, (y % 2) == 0 ? 1 : 0);
          matrixX++;
        }
      }
      matrixY++;
      // Fill the bottom edge with full 1
      if ((y % symbolInfo.matrixHeight) == symbolInfo.matrixHeight - 1) {
        matrixX = 0;
        for (int x = 0; x < symbolInfo.symbolWidth; x++) {
          matrix.set(matrixX, matrixY, 1);
          matrixX++;
        }
        matrixY++;
      }
    }

    return _convertByteMatrixToBitMatrix(matrix, width, height);
  }

  /// Convert the ByteMatrix to BitMatrix.
  ///
  /// @param reqHeight The requested height of the image (in pixels) with the Datamatrix code
  /// @param reqWidth The requested width of the image (in pixels) with the Datamatrix code
  /// @param matrix The input matrix.
  /// @return The output matrix.
  static BitMatrix _convertByteMatrixToBitMatrix(
      ByteMatrix matrix, int reqWidth, int reqHeight) {
    int matrixWidth = matrix.width;
    int matrixHeight = matrix.height;
    int outputWidth = math.max(reqWidth, matrixWidth);
    int outputHeight = math.max(reqHeight, matrixHeight);

    int multiple =
        math.min(outputWidth ~/ matrixWidth, outputHeight ~/ matrixHeight);

    int leftPadding = (outputWidth - (matrixWidth * multiple)) ~/ 2;
    int topPadding = (outputHeight - (matrixHeight * multiple)) ~/ 2;

    BitMatrix output;

    // remove padding if requested width and height are too small
    if (reqHeight < matrixHeight || reqWidth < matrixWidth) {
      leftPadding = 0;
      topPadding = 0;
      output = BitMatrix(matrixWidth, matrixHeight);
    } else {
      output = BitMatrix(reqWidth, reqHeight);
    }

    output.clear();
    for (int inputY = 0, outputY = topPadding;
        inputY < matrixHeight;
        inputY++, outputY += multiple) {
      // Write the contents of this row of the bytematrix
      for (int inputX = 0, outputX = leftPadding;
          inputX < matrixWidth;
          inputX++, outputX += multiple) {
        if (matrix.get(inputX, inputY) == 1) {
          output.setRegion(outputX, outputY, multiple, multiple);
        }
      }
    }

    return output;
  }
}
