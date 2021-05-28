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

import 'package:zxing/core/common/detector/math_utils.dart';

import '../pdf417_common.dart';

/**
 * @author Guenther Grau
 * @author creatale GmbH (christoph.schulz@creatale.de)
 */
class PDF417CodewordDecoder {
  static final List<List<double>> RATIOS_TABLE = List.generate(
      PDF417Common.SYMBOL_TABLE.length,
      (index) => List.filled(PDF417Common.BARS_IN_MODULE, 0));

  static init() {
    // Pre-computes the symbol ratio table.
    for (int i = 0; i < PDF417Common.SYMBOL_TABLE.length; i++) {
      int currentSymbol = PDF417Common.SYMBOL_TABLE[i];
      int currentBit = currentSymbol & 0x1;
      for (int j = 0; j < PDF417Common.BARS_IN_MODULE; j++) {
        double size = 0.0;
        while ((currentSymbol & 0x1) == currentBit) {
          size += 1.0;
          currentSymbol >>= 1;
        }
        currentBit = currentSymbol & 0x1;
        RATIOS_TABLE[i][PDF417Common.BARS_IN_MODULE - j - 1] =
            size / PDF417Common.MODULES_IN_CODEWORD;
      }
    }
  }

  PDF417CodewordDecoder() {}

  static int getDecodedValue(List<int> moduleBitCount) {
    int decodedValue = getDecodedCodewordValue(sampleBitCounts(moduleBitCount));
    if (decodedValue != -1) {
      return decodedValue;
    }
    return getClosestDecodedValue(moduleBitCount);
  }

  static List<int> sampleBitCounts(List<int> moduleBitCount) {
    double bitCountSum = MathUtils.sum(moduleBitCount).toDouble();
    List<int> result = List.filled(PDF417Common.BARS_IN_MODULE, 0);
    int bitCountIndex = 0;
    int sumPreviousBits = 0;
    for (int i = 0; i < PDF417Common.MODULES_IN_CODEWORD; i++) {
      double sampleIndex =
          bitCountSum / (2 * PDF417Common.MODULES_IN_CODEWORD) +
              (i * bitCountSum) / PDF417Common.MODULES_IN_CODEWORD;
      if (sumPreviousBits + moduleBitCount[bitCountIndex] <= sampleIndex) {
        sumPreviousBits += moduleBitCount[bitCountIndex];
        bitCountIndex++;
      }
      result[bitCountIndex]++;
    }
    return result;
  }

  static int getDecodedCodewordValue(List<int> moduleBitCount) {
    int decodedValue = getBitValue(moduleBitCount);
    return PDF417Common.getCodeword(decodedValue) == -1 ? -1 : decodedValue;
  }

  static int getBitValue(List<int> moduleBitCount) {
    int result = 0;
    for (int i = 0; i < moduleBitCount.length; i++) {
      for (int bit = 0; bit < moduleBitCount[i]; bit++) {
        result = (result << 1) | (i % 2 == 0 ? 1 : 0);
      }
    }
    return result;
  }

  static int getClosestDecodedValue(List<int> moduleBitCount) {
    int bitCountSum = MathUtils.sum(moduleBitCount);
    List<double> bitCountRatios = List.filled(PDF417Common.BARS_IN_MODULE, 0);
    if (bitCountSum > 1) {
      for (int i = 0; i < bitCountRatios.length; i++) {
        bitCountRatios[i] = moduleBitCount[i] / bitCountSum;
      }
    }
    double bestMatchError = double.maxFinite;
    int bestMatch = -1;
    for (int j = 0; j < RATIOS_TABLE.length; j++) {
      double error = 0.0;
      List<double> ratioTableRow = RATIOS_TABLE[j];
      for (int k = 0; k < PDF417Common.BARS_IN_MODULE; k++) {
        double diff = ratioTableRow[k] - bitCountRatios[k];
        error += diff * diff;
        if (error >= bestMatchError) {
          break;
        }
      }
      if (error < bestMatchError) {
        bestMatchError = error;
        bestMatch = PDF417Common.SYMBOL_TABLE[j];
      }
    }
    return bestMatch;
  }
}
