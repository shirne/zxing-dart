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

import 'dart:math' as Math;
import 'dart:typed_data';

import '../common/bit_array.dart';
import '../common/string_builder.dart';
import '../barcode_format.dart';
import '../checksum_exception.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'one_dreader.dart';

/// <p>Decodes Code 128 barcodes.</p>
///
/// @author Sean Owen
class Code128Reader extends OneDReader {
  static const List<List<int>> CODE_PATTERNS = [
    [2, 1, 2, 2, 2, 2], // 0
    [2, 2, 2, 1, 2, 2],
    [2, 2, 2, 2, 2, 1],
    [1, 2, 1, 2, 2, 3],
    [1, 2, 1, 3, 2, 2],
    [1, 3, 1, 2, 2, 2], // 5
    [1, 2, 2, 2, 1, 3],
    [1, 2, 2, 3, 1, 2],
    [1, 3, 2, 2, 1, 2],
    [2, 2, 1, 2, 1, 3],
    [2, 2, 1, 3, 1, 2], // 10
    [2, 3, 1, 2, 1, 2],
    [1, 1, 2, 2, 3, 2],
    [1, 2, 2, 1, 3, 2],
    [1, 2, 2, 2, 3, 1],
    [1, 1, 3, 2, 2, 2], // 15
    [1, 2, 3, 1, 2, 2],
    [1, 2, 3, 2, 2, 1],
    [2, 2, 3, 2, 1, 1],
    [2, 2, 1, 1, 3, 2],
    [2, 2, 1, 2, 3, 1], // 20
    [2, 1, 3, 2, 1, 2],
    [2, 2, 3, 1, 1, 2],
    [3, 1, 2, 1, 3, 1],
    [3, 1, 1, 2, 2, 2],
    [3, 2, 1, 1, 2, 2], // 25
    [3, 2, 1, 2, 2, 1],
    [3, 1, 2, 2, 1, 2],
    [3, 2, 2, 1, 1, 2],
    [3, 2, 2, 2, 1, 1],
    [2, 1, 2, 1, 2, 3], // 30
    [2, 1, 2, 3, 2, 1],
    [2, 3, 2, 1, 2, 1],
    [1, 1, 1, 3, 2, 3],
    [1, 3, 1, 1, 2, 3],
    [1, 3, 1, 3, 2, 1], // 35
    [1, 1, 2, 3, 1, 3],
    [1, 3, 2, 1, 1, 3],
    [1, 3, 2, 3, 1, 1],
    [2, 1, 1, 3, 1, 3],
    [2, 3, 1, 1, 1, 3], // 40
    [2, 3, 1, 3, 1, 1],
    [1, 1, 2, 1, 3, 3],
    [1, 1, 2, 3, 3, 1],
    [1, 3, 2, 1, 3, 1],
    [1, 1, 3, 1, 2, 3], // 45
    [1, 1, 3, 3, 2, 1],
    [1, 3, 3, 1, 2, 1],
    [3, 1, 3, 1, 2, 1],
    [2, 1, 1, 3, 3, 1],
    [2, 3, 1, 1, 3, 1], // 50
    [2, 1, 3, 1, 1, 3],
    [2, 1, 3, 3, 1, 1],
    [2, 1, 3, 1, 3, 1],
    [3, 1, 1, 1, 2, 3],
    [3, 1, 1, 3, 2, 1], // 55
    [3, 3, 1, 1, 2, 1],
    [3, 1, 2, 1, 1, 3],
    [3, 1, 2, 3, 1, 1],
    [3, 3, 2, 1, 1, 1],
    [3, 1, 4, 1, 1, 1], // 60
    [2, 2, 1, 4, 1, 1],
    [4, 3, 1, 1, 1, 1],
    [1, 1, 1, 2, 2, 4],
    [1, 1, 1, 4, 2, 2],
    [1, 2, 1, 1, 2, 4], // 65
    [1, 2, 1, 4, 2, 1],
    [1, 4, 1, 1, 2, 2],
    [1, 4, 1, 2, 2, 1],
    [1, 1, 2, 2, 1, 4],
    [1, 1, 2, 4, 1, 2], // 70
    [1, 2, 2, 1, 1, 4],
    [1, 2, 2, 4, 1, 1],
    [1, 4, 2, 1, 1, 2],
    [1, 4, 2, 2, 1, 1],
    [2, 4, 1, 2, 1, 1], // 75
    [2, 2, 1, 1, 1, 4],
    [4, 1, 3, 1, 1, 1],
    [2, 4, 1, 1, 1, 2],
    [1, 3, 4, 1, 1, 1],
    [1, 1, 1, 2, 4, 2], // 80
    [1, 2, 1, 1, 4, 2],
    [1, 2, 1, 2, 4, 1],
    [1, 1, 4, 2, 1, 2],
    [1, 2, 4, 1, 1, 2],
    [1, 2, 4, 2, 1, 1], // 85
    [4, 1, 1, 2, 1, 2],
    [4, 2, 1, 1, 1, 2],
    [4, 2, 1, 2, 1, 1],
    [2, 1, 2, 1, 4, 1],
    [2, 1, 4, 1, 2, 1], // 90
    [4, 1, 2, 1, 2, 1],
    [1, 1, 1, 1, 4, 3],
    [1, 1, 1, 3, 4, 1],
    [1, 3, 1, 1, 4, 1],
    [1, 1, 4, 1, 1, 3], // 95
    [1, 1, 4, 3, 1, 1],
    [4, 1, 1, 1, 1, 3],
    [4, 1, 1, 3, 1, 1],
    [1, 1, 3, 1, 4, 1],
    [1, 1, 4, 1, 3, 1], // 100
    [3, 1, 1, 1, 4, 1],
    [4, 1, 1, 1, 3, 1],
    [2, 1, 1, 4, 1, 2],
    [2, 1, 1, 2, 1, 4],
    [2, 1, 1, 2, 3, 2], // 105
    [2, 3, 3, 1, 1, 1, 2]
  ];

  static const double _MAX_AVG_VARIANCE = 0.25;
  static const double _MAX_INDIVIDUAL_VARIANCE = 0.7;

  static const int _CODE_SHIFT = 98;

  static const int _CODE_CODE_C = 99;
  static const int _CODE_CODE_B = 100;
  static const int _CODE_CODE_A = 101;

  static const int _CODE_FNC_1 = 102;
  static const int _CODE_FNC_2 = 97;
  static const int _CODE_FNC_3 = 96;
  static const int _CODE_FNC_4_A = 101;
  static const int _CODE_FNC_4_B = 100;

  static const int _CODE_START_A = 103;
  static const int _CODE_START_B = 104;
  static const int _CODE_START_C = 105;
  static const int _CODE_STOP = 106;

  static List<int> _findStartPattern(BitArray row) {
    int width = row.getSize();
    int rowOffset = row.getNextSet(0);

    int counterPosition = 0;
    List<int> counters = List.filled(6, 0);
    int patternStart = rowOffset;
    bool isWhite = false;
    int patternLength = counters.length;

    for (int i = rowOffset; i < width; i++) {
      if (row.get(i) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == patternLength - 1) {
          double bestVariance = _MAX_AVG_VARIANCE;
          int bestMatch = -1;
          for (int startCode = _CODE_START_A;
              startCode <= _CODE_START_C;
              startCode++) {
            double variance = OneDReader.patternMatchVariance(
                counters, CODE_PATTERNS[startCode], _MAX_INDIVIDUAL_VARIANCE);
            if (variance < bestVariance) {
              bestVariance = variance;
              bestMatch = startCode;
            }
          }
          // Look for whitespace before start pattern, >= 50% of width of start pattern
          if (bestMatch >= 0 &&
              row.isRange(Math.max(0, patternStart - (i - patternStart) ~/ 2),
                  patternStart, false)) {
            return [patternStart, i, bestMatch];
          }
          patternStart += counters[0] + counters[1];
          List.copyRange(counters, 0, counters, 2, counterPosition + 1);
          counters[counterPosition - 1] = 0;
          counters[counterPosition] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    throw NotFoundException.getNotFoundInstance();
  }

  static int _decodeCode(BitArray row, List<int> counters, int rowOffset) {
    OneDReader.recordPattern(row, rowOffset, counters);
    double bestVariance = _MAX_AVG_VARIANCE; // worst variance we'll accept
    int bestMatch = -1;
    for (int d = 0; d < CODE_PATTERNS.length; d++) {
      List<int> pattern = CODE_PATTERNS[d];
      double variance = OneDReader.patternMatchVariance(
          counters, pattern, _MAX_INDIVIDUAL_VARIANCE);
      if (variance < bestVariance) {
        bestVariance = variance;
        bestMatch = d;
      }
    }
    // TODO We're overlooking the fact that the STOP pattern has 7 values, not 6.
    if (bestMatch >= 0) {
      return bestMatch;
    } else {
      throw NotFoundException.getNotFoundInstance();
    }
  }

  @override
  Result decodeRow(
      int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints) {
    bool convertFNC1 =
        hints != null && hints.containsKey(DecodeHintType.ASSUME_GS1);

    int symbologyModifier = 0;

    List<int> startPatternInfo = _findStartPattern(row);
    int startCode = startPatternInfo[2];

    List<int> rawCodes = [];
    rawCodes.add(startCode);

    int codeSet;
    switch (startCode) {
      case _CODE_START_A:
        codeSet = _CODE_CODE_A;
        break;
      case _CODE_START_B:
        codeSet = _CODE_CODE_B;
        break;
      case _CODE_START_C:
        codeSet = _CODE_CODE_C;
        break;
      default:
        throw FormatException();
    }

    bool done = false;
    bool isNextShifted = false;

    StringBuilder result = StringBuilder();

    int lastStart = startPatternInfo[0];
    int nextStart = startPatternInfo[1];
    List<int> counters = List.filled(6, 0);

    int lastCode = 0;
    int code = 0;
    int checksumTotal = startCode;
    int multiplier = 0;
    bool lastCharacterWasPrintable = true;
    bool upperMode = false;
    bool shiftUpperMode = false;

    while (!done) {
      bool unshift = isNextShifted;
      isNextShifted = false;

      // Save off last code
      lastCode = code;

      // Decode another code from image
      code = _decodeCode(row, counters, nextStart);

      rawCodes.add(code);

      // Remember whether the last code was printable or not (excluding CODE_STOP)
      if (code != _CODE_STOP) {
        lastCharacterWasPrintable = true;
      }

      // Add to checksum computation (if not CODE_STOP of course)
      if (code != _CODE_STOP) {
        multiplier++;
        checksumTotal += multiplier * code;
      }

      // Advance to where the next code will to start
      lastStart = nextStart;
      for (int counter in counters) {
        nextStart += counter;
      }

      // Take care of illegal start codes
      switch (code) {
        case _CODE_START_A:
        case _CODE_START_B:
        case _CODE_START_C:
          throw FormatException();
      }

      switch (codeSet) {
        case _CODE_CODE_A:
          if (code < 64) {
            if (shiftUpperMode == upperMode) {
              result.writeCharCode(32 /*   */ + code);
            } else {
              result.writeCharCode(32 /*   */ + code + 128);
            }
            shiftUpperMode = false;
          } else if (code < 96) {
            if (shiftUpperMode == upperMode) {
              result.writeCharCode(code - 64);
            } else {
              result.writeCharCode(code + 64);
            }
            shiftUpperMode = false;
          } else {
            // Don't let CODE_STOP, which always appears, affect whether whether we think the last
            // code was printable or not.
            if (code != _CODE_STOP) {
              lastCharacterWasPrintable = false;
            }
            switch (code) {
              case _CODE_FNC_1:
                if (result.length == 0) {
                  // FNC1 at first or second character determines the symbology
                  symbologyModifier = 1;
                } else if (result.length == 1) {
                  symbologyModifier = 2;
                }
                if (convertFNC1) {
                  if (result.length == 0) {
                    // GS1 specification 5.4.3.7. and 5.4.6.4. If the first char after the start code
                    // is FNC1 then this is GS1-128. We add the symbology identifier.
                    result.write("]C1");
                  } else {
                    // GS1 specification 5.4.7.5. Every subsequent FNC1 is returned as ASCII 29 (GS)
                    result.writeCharCode(29);
                  }
                }
                break;
              case _CODE_FNC_2:
                symbologyModifier = 4;
                break;
              case _CODE_FNC_3:
                // do nothing?
                break;
              case _CODE_FNC_4_A:
                if (!upperMode && shiftUpperMode) {
                  upperMode = true;
                  shiftUpperMode = false;
                } else if (upperMode && shiftUpperMode) {
                  upperMode = false;
                  shiftUpperMode = false;
                } else {
                  shiftUpperMode = true;
                }
                break;
              case _CODE_SHIFT:
                isNextShifted = true;
                codeSet = _CODE_CODE_B;
                break;
              case _CODE_CODE_B:
                codeSet = _CODE_CODE_B;
                break;
              case _CODE_CODE_C:
                codeSet = _CODE_CODE_C;
                break;
              case _CODE_STOP:
                done = true;
                break;
            }
          }
          break;
        case _CODE_CODE_B:
          if (code < 96) {
            if (shiftUpperMode == upperMode) {
              result.writeCharCode(32 /*   */ + code);
            } else {
              result.writeCharCode(32 /*   */ + code + 128);
            }
            shiftUpperMode = false;
          } else {
            if (code != _CODE_STOP) {
              lastCharacterWasPrintable = false;
            }
            switch (code) {
              case _CODE_FNC_1:
                if (result.length == 0) {
                  // FNC1 at first or second character determines the symbology
                  symbologyModifier = 1;
                } else if (result.length == 1) {
                  symbologyModifier = 2;
                }
                if (convertFNC1) {
                  if (result.length == 0) {
                    // GS1 specification 5.4.3.7. and 5.4.6.4. If the first char after the start code
                    // is FNC1 then this is GS1-128. We add the symbology identifier.
                    result.write("]C1");
                  } else {
                    // GS1 specification 5.4.7.5. Every subsequent FNC1 is returned as ASCII 29 (GS)
                    result.writeCharCode(29);
                  }
                }
                break;
              case _CODE_FNC_2:
                symbologyModifier = 4;
                break;
              case _CODE_FNC_3:
                // do nothing?
                break;
              case _CODE_FNC_4_B:
                if (!upperMode && shiftUpperMode) {
                  upperMode = true;
                  shiftUpperMode = false;
                } else if (upperMode && shiftUpperMode) {
                  upperMode = false;
                  shiftUpperMode = false;
                } else {
                  shiftUpperMode = true;
                }
                break;
              case _CODE_SHIFT:
                isNextShifted = true;
                codeSet = _CODE_CODE_A;
                break;
              case _CODE_CODE_A:
                codeSet = _CODE_CODE_A;
                break;
              case _CODE_CODE_C:
                codeSet = _CODE_CODE_C;
                break;
              case _CODE_STOP:
                done = true;
                break;
            }
          }
          break;
        case _CODE_CODE_C:
          if (code < 100) {
            if (code < 10) {
              result.write('0');
            }
            result.write(code);
          } else {
            if (code != _CODE_STOP) {
              lastCharacterWasPrintable = false;
            }
            switch (code) {
              case _CODE_FNC_1:
                if (result.length == 0) {
                  // FNC1 at first or second character determines the symbology
                  symbologyModifier = 1;
                } else if (result.length == 1) {
                  symbologyModifier = 2;
                }
                if (convertFNC1) {
                  if (result.length == 0) {
                    // GS1 specification 5.4.3.7. and 5.4.6.4. If the first char after the start code
                    // is FNC1 then this is GS1-128. We add the symbology identifier.
                    result.write("]C1");
                  } else {
                    // GS1 specification 5.4.7.5. Every subsequent FNC1 is returned as ASCII 29 (GS)
                    result.writeCharCode(29);
                  }
                }
                break;
              case _CODE_FNC_2:
                symbologyModifier = 4;
                break;
              case _CODE_CODE_A:
                codeSet = _CODE_CODE_A;
                break;
              case _CODE_CODE_B:
                codeSet = _CODE_CODE_B;
                break;
              case _CODE_STOP:
                done = true;
                break;
            }
          }
          break;
      }

      // Unshift back to another code set if we were shifted
      if (unshift) {
        codeSet = codeSet == _CODE_CODE_A ? _CODE_CODE_B : _CODE_CODE_A;
      }
    }

    int lastPatternSize = nextStart - lastStart;

    // Check for ample whitespace following pattern, but, to do this we first need to remember that
    // we fudged decoding CODE_STOP since it actually has 7 bars, not 6. There is a black bar left
    // to read off. Would be slightly better to properly read. Here we just skip it:
    nextStart = row.getNextUnset(nextStart);
    if (!row.isRange(
        nextStart,
        Math.min(row.getSize(), nextStart + (nextStart - lastStart) ~/ 2),
        false)) {
      throw NotFoundException.getNotFoundInstance();
    }

    // Pull out from sum the value of the penultimate check code
    checksumTotal -= multiplier * lastCode;
    // lastCode is the checksum then:
    if (checksumTotal % 103 != lastCode) {
      throw ChecksumException.getChecksumInstance();
    }

    // Need to pull out the check digits from string
    int resultLength = result.length;
    if (resultLength == 0) {
      // false positive
      throw NotFoundException.getNotFoundInstance();
    }

    // Only bother if the result had at least one character, and if the checksum digit happened to
    // be a printable character. If it was just interpreted as a control code, nothing to remove.
    if (resultLength > 0 && lastCharacterWasPrintable) {
      if (codeSet == _CODE_CODE_C) {
        result.delete(resultLength - 2, resultLength);
      } else {
        result.delete(resultLength - 1, resultLength);
      }
    }

    double left = (startPatternInfo[1] + startPatternInfo[0]) / 2.0;
    double right = lastStart + lastPatternSize / 2.0;

    int rawCodesSize = rawCodes.length;
    Uint8List rawBytes = Uint8List(rawCodesSize);
    for (int i = 0; i < rawCodesSize; i++) {
      rawBytes[i] = rawCodes[i];
    }
    Result resultObject = Result(
        result.toString(),
        rawBytes,
        [
          ResultPoint(left, rowNumber.toDouble()),
          ResultPoint(right, rowNumber.toDouble())
        ],
        BarcodeFormat.CODE_128);
    resultObject.putMetadata(
        ResultMetadataType.SYMBOLOGY_IDENTIFIER, "]C$symbologyModifier");
    return resultObject;
  }
}
