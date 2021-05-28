/*
 * Copyright 2006 Jeremias Maerki
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

import '../../dimension.dart';
import 'data_matrix_symbol_info144.dart';
import 'symbol_shape_hint.dart';

/**
 * Symbol info table for DataMatrix.
 *
 * @version $Id$
 */
class SymbolInfo {
  static final List<SymbolInfo> PROD_SYMBOLS = [
    SymbolInfo(false, 3, 5, 8, 8, 1),
    SymbolInfo(false, 5, 7, 10, 10, 1),
    /*rect*/ SymbolInfo(true, 5, 7, 16, 6, 1),
    SymbolInfo(false, 8, 10, 12, 12, 1),
    /*rect*/ SymbolInfo(true, 10, 11, 14, 6, 2),
    SymbolInfo(false, 12, 12, 14, 14, 1),
    /*rect*/ SymbolInfo(true, 16, 14, 24, 10, 1),
    SymbolInfo(false, 18, 14, 16, 16, 1),
    SymbolInfo(false, 22, 18, 18, 18, 1),
    /*rect*/ SymbolInfo(true, 22, 18, 16, 10, 2),
    SymbolInfo(false, 30, 20, 20, 20, 1),
    /*rect*/ SymbolInfo(true, 32, 24, 16, 14, 2),
    SymbolInfo(false, 36, 24, 22, 22, 1),
    SymbolInfo(false, 44, 28, 24, 24, 1),
    /*rect*/ SymbolInfo(true, 49, 28, 22, 14, 2),
    SymbolInfo(false, 62, 36, 14, 14, 4),
    SymbolInfo(false, 86, 42, 16, 16, 4),
    SymbolInfo(false, 114, 48, 18, 18, 4),
    SymbolInfo(false, 144, 56, 20, 20, 4),
    SymbolInfo(false, 174, 68, 22, 22, 4),
    SymbolInfo(false, 204, 84, 24, 24, 4, 102, 42),
    SymbolInfo(false, 280, 112, 14, 14, 16, 140, 56),
    SymbolInfo(false, 368, 144, 16, 16, 16, 92, 36),
    SymbolInfo(false, 456, 192, 18, 18, 16, 114, 48),
    SymbolInfo(false, 576, 224, 20, 20, 16, 144, 56),
    SymbolInfo(false, 696, 272, 22, 22, 16, 174, 68),
    SymbolInfo(false, 816, 336, 24, 24, 16, 136, 56),
    SymbolInfo(false, 1050, 408, 18, 18, 36, 175, 68),
    SymbolInfo(false, 1304, 496, 20, 20, 36, 163, 62),
    DataMatrixSymbolInfo144(),
  ];

  static List<SymbolInfo> symbols = PROD_SYMBOLS;

  final bool rectangular;
  final int dataCapacity;
  final int errorCodewords;
  final int matrixWidth;
  final int matrixHeight;
  final int dataRegions;
  final int rsBlockData;
  final int rsBlockError;

  /**
   * Overrides the symbol info set used by this class. Used for testing purposes.
   *
   * @param override the symbol info set to use
   */
  static void overrideSymbolSet(List<SymbolInfo> override) {
    symbols = override;
  }

  SymbolInfo(this.rectangular, this.dataCapacity, this.errorCodewords,
      this.matrixWidth, this.matrixHeight, this.dataRegions,
      [int? rsBlockData, int? rsBlockError])
      : rsBlockData = rsBlockData ?? dataCapacity,
        rsBlockError = rsBlockError ?? errorCodewords;

  static SymbolInfo? lookupRect(
      int dataCodewords, bool allowRectangular, bool fail) {
    SymbolShapeHint shape = allowRectangular
        ? SymbolShapeHint.FORCE_NONE
        : SymbolShapeHint.FORCE_SQUARE;
    return lookup(dataCodewords, shape, fail);
  }

  static SymbolInfo? lookup(int dataCodewords,
      [SymbolShapeHint shape = SymbolShapeHint.FORCE_NONE, bool fail = true]) {
    return lookupDm(dataCodewords, shape, null, null, fail);
  }

  static SymbolInfo? lookupDm(int dataCodewords, SymbolShapeHint? shape,
      Dimension? minSize, Dimension? maxSize, bool fail) {
    for (SymbolInfo symbol in symbols) {
      if (shape == SymbolShapeHint.FORCE_SQUARE && symbol.rectangular) {
        continue;
      }
      if (shape == SymbolShapeHint.FORCE_RECTANGLE && !symbol.rectangular) {
        continue;
      }
      if (minSize != null &&
          (symbol.getSymbolWidth() < minSize.getWidth() ||
              symbol.getSymbolHeight() < minSize.getHeight())) {
        continue;
      }
      if (maxSize != null &&
          (symbol.getSymbolWidth() > maxSize.getWidth() ||
              symbol.getSymbolHeight() > maxSize.getHeight())) {
        continue;
      }
      if (dataCodewords <= symbol.dataCapacity) {
        return symbol;
      }
    }
    if (fail) {
      throw Exception(
          "Can't find a symbol arrangement that matches the message. Data codewords: $dataCodewords");
    }
    return null;
  }

  int getHorizontalDataRegions() {
    switch (dataRegions) {
      case 1:
        return 1;
      case 2:
      case 4:
        return 2;
      case 16:
        return 4;
      case 36:
        return 6;
      default:
        throw Exception("Cannot handle this number of data regions");
    }
  }

  int getVerticalDataRegions() {
    switch (dataRegions) {
      case 1:
      case 2:
        return 1;
      case 4:
        return 2;
      case 16:
        return 4;
      case 36:
        return 6;
      default:
        throw Exception("Cannot handle this number of data regions");
    }
  }

  int getSymbolDataWidth() {
    return getHorizontalDataRegions() * matrixWidth;
  }

  int getSymbolDataHeight() {
    return getVerticalDataRegions() * matrixHeight;
  }

  int getSymbolWidth() {
    return getSymbolDataWidth() + (getHorizontalDataRegions() * 2);
  }

  int getSymbolHeight() {
    return getSymbolDataHeight() + (getVerticalDataRegions() * 2);
  }

  int getCodewordCount() {
    return dataCapacity + errorCodewords;
  }

  int getInterleavedBlockCount() {
    return dataCapacity ~/ rsBlockData;
  }

  int getDataCapacity() {
    return dataCapacity;
  }

  int getErrorCodewords() {
    return errorCodewords;
  }

  int getDataLengthForInterleavedBlock(int index) {
    return rsBlockData;
  }

  int getErrorLengthForInterleavedBlock(int index) {
    return rsBlockError;
  }

  @override
  String toString() {
    return (rectangular ? "Rectangular Symbol:" : "Square Symbol:") +
        " data region $matrixWidth"
            'x$matrixHeight'
            ", symbol size ${getSymbolWidth()}"
            'x${getSymbolHeight()}'
            ", symbol data size ${getSymbolDataWidth()}"
            'x${getSymbolDataHeight()}'
            ", codewords $dataCapacity"
            '+$errorCodewords';
  }
}
