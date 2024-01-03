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

import 'dart:math' as math;
import 'dart:typed_data';

import '../barcode_format.dart';
import '../checksum_exception.dart';
import '../common/bit_array.dart';
import '../common/string_builder.dart';
import '../decode_hint.dart';
import '../formats_exception.dart';
import '../not_found_exception.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import 'one_dreader.dart';

/// Decodes Code 128 barcodes.
///
/// @author Sean Owen
class Code128Reader extends OneDReader {
  static const List<List<int>> codePatterns = [
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
    [2, 3, 3, 1, 1, 1, 2],
  ];

  static const double _maxAvgVariance = 0.25;
  static const double _maxIndividualVariance = 0.7;

  static const int _codeShift = 98;

  static const int _codeCodeC = 99;
  static const int _codeCodeB = 100;
  static const int _codeCodeA = 101;

  static const int _codeFnc1 = 102;
  static const int _codeFnc2 = 97;
  static const int _codeFnc3 = 96;
  static const int _codeFnc4A = 101;
  static const int _codeFnc4B = 100;

  static const int _codeStartA = 103;
  static const int _codeStartB = 104;
  static const int _codeStartC = 105;
  static const int _codeStop = 106;

  static List<int> _findStartPattern(BitArray row) {
    final width = row.size;
    final rowOffset = row.getNextSet(0);

    int counterPosition = 0;
    final counters = List.filled(6, 0);
    int patternStart = rowOffset;
    bool isWhite = false;
    final patternLength = counters.length;

    for (int i = rowOffset; i < width; i++) {
      if (row.get(i) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == patternLength - 1) {
          double bestVariance = _maxAvgVariance;
          int bestMatch = -1;
          for (int startCode = _codeStartA;
              startCode <= _codeStartC;
              startCode++) {
            final variance = OneDReader.patternMatchVariance(
              counters,
              codePatterns[startCode],
              _maxIndividualVariance,
            );
            if (variance < bestVariance) {
              bestVariance = variance;
              bestMatch = startCode;
            }
          }
          // Look for whitespace before start pattern, >= 50% of width of start pattern
          if (bestMatch >= 0 &&
              row.isRange(
                math.max(0, patternStart - (i - patternStart) ~/ 2),
                patternStart,
                false,
              )) {
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
    throw NotFoundException.instance;
  }

  static int _decodeCode(BitArray row, List<int> counters, int rowOffset) {
    OneDReader.recordPattern(row, rowOffset, counters);
    double bestVariance = _maxAvgVariance; // worst variance we'll accept
    int bestMatch = -1;
    for (int d = 0; d < codePatterns.length; d++) {
      final pattern = codePatterns[d];
      final variance = OneDReader.patternMatchVariance(
        counters,
        pattern,
        _maxIndividualVariance,
      );
      if (variance < bestVariance) {
        bestVariance = variance;
        bestMatch = d;
      }
    }
    // TODO We're overlooking the fact that the STOP pattern has 7 values, not 6.
    if (bestMatch >= 0) {
      return bestMatch;
    } else {
      throw NotFoundException.instance;
    }
  }

  @override
  Result decodeRow(
    int rowNumber,
    BitArray row,
    DecodeHint? hints,
  ) {
    final convertFNC1 = hints?.assumeGs1 ?? false;

    int symbologyModifier = 0;

    final startPatternInfo = _findStartPattern(row);
    final startCode = startPatternInfo[2];

    final rawCodes = <int>[];
    rawCodes.add(startCode);

    int codeSet;
    switch (startCode) {
      case _codeStartA:
        codeSet = _codeCodeA;
        break;
      case _codeStartB:
        codeSet = _codeCodeB;
        break;
      case _codeStartC:
        codeSet = _codeCodeC;
        break;
      default:
        throw FormatsException.instance;
    }

    bool done = false;
    bool isNextShifted = false;

    final result = StringBuilder();

    int lastStart = startPatternInfo[0];
    int nextStart = startPatternInfo[1];
    final counters = List.filled(6, 0);

    int lastCode = 0;
    int code = 0;
    int checksumTotal = startCode;
    int multiplier = 0;
    bool lastCharacterWasPrintable = true;
    bool upperMode = false;
    bool shiftUpperMode = false;

    while (!done) {
      final unshift = isNextShifted;
      isNextShifted = false;

      // Save off last code
      lastCode = code;

      // Decode another code from image
      code = _decodeCode(row, counters, nextStart);

      rawCodes.add(code);

      // Remember whether the last code was printable or not (excluding CODE_STOP)
      if (code != _codeStop) {
        lastCharacterWasPrintable = true;
      }

      // Add to checksum computation (if not CODE_STOP of course)
      if (code != _codeStop) {
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
        case _codeStartA:
        case _codeStartB:
        case _codeStartC:
          throw FormatsException.instance;
      }

      switch (codeSet) {
        case _codeCodeA:
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
            if (code != _codeStop) {
              lastCharacterWasPrintable = false;
            }
            switch (code) {
              case _codeFnc1:
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
                    result.write(']C1');
                  } else {
                    // GS1 specification 5.4.7.5. Every subsequent FNC1 is returned as ASCII 29 (GS)
                    result.writeCharCode(29);
                  }
                }
                break;
              case _codeFnc2:
                symbologyModifier = 4;
                break;
              case _codeFnc3:
                // do nothing?
                break;
              case _codeFnc4A:
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
              case _codeShift:
                isNextShifted = true;
                codeSet = _codeCodeB;
                break;
              case _codeCodeB:
                codeSet = _codeCodeB;
                break;
              case _codeCodeC:
                codeSet = _codeCodeC;
                break;
              case _codeStop:
                done = true;
                break;
            }
          }
          break;
        case _codeCodeB:
          if (code < 96) {
            if (shiftUpperMode == upperMode) {
              result.writeCharCode(32 /*   */ + code);
            } else {
              result.writeCharCode(32 /*   */ + code + 128);
            }
            shiftUpperMode = false;
          } else {
            if (code != _codeStop) {
              lastCharacterWasPrintable = false;
            }
            switch (code) {
              case _codeFnc1:
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
                    result.write(']C1');
                  } else {
                    // GS1 specification 5.4.7.5. Every subsequent FNC1 is returned as ASCII 29 (GS)
                    result.writeCharCode(29);
                  }
                }
                break;
              case _codeFnc2:
                symbologyModifier = 4;
                break;
              case _codeFnc3:
                // do nothing?
                break;
              case _codeFnc4B:
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
              case _codeShift:
                isNextShifted = true;
                codeSet = _codeCodeA;
                break;
              case _codeCodeA:
                codeSet = _codeCodeA;
                break;
              case _codeCodeC:
                codeSet = _codeCodeC;
                break;
              case _codeStop:
                done = true;
                break;
            }
          }
          break;
        case _codeCodeC:
          if (code < 100) {
            if (code < 10) {
              result.write('0');
            }
            // This is not char
            result.write(code);
          } else {
            if (code != _codeStop) {
              lastCharacterWasPrintable = false;
            }
            switch (code) {
              case _codeFnc1:
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
                    result.write(']C1');
                  } else {
                    // GS1 specification 5.4.7.5. Every subsequent FNC1 is returned as ASCII 29 (GS)
                    result.writeCharCode(29);
                  }
                }
                break;
              case _codeCodeA:
                codeSet = _codeCodeA;
                break;
              case _codeCodeB:
                codeSet = _codeCodeB;
                break;
              case _codeStop:
                done = true;
                break;
            }
          }
          break;
      }

      // Unshift back to another code set if we were shifted
      if (unshift) {
        codeSet = (codeSet == _codeCodeA) ? _codeCodeB : _codeCodeA;
      }
    }

    final lastPatternSize = nextStart - lastStart;

    // Check for ample whitespace following pattern, but, to do this we first need to remember that
    // we fudged decoding CODE_STOP since it actually has 7 bars, not 6. There is a black bar left
    // to read off. Would be slightly better to properly read. Here we just skip it:
    nextStart = row.getNextUnset(nextStart);
    if (!row.isRange(
      nextStart,
      math.min(row.size, nextStart + (nextStart - lastStart) ~/ 2),
      false,
    )) {
      throw NotFoundException.instance;
    }

    // Pull out from sum the value of the penultimate check code
    checksumTotal -= multiplier * lastCode;
    // lastCode is the checksum then:
    if (checksumTotal % 103 != lastCode) {
      throw ChecksumException.getChecksumInstance();
    }

    // Need to pull out the check digits from string
    final resultLength = result.length;
    if (resultLength == 0) {
      // false positive
      throw NotFoundException.instance;
    }

    // Only bother if the result had at least one character, and if the checksum digit happened to
    // be a printable character. If it was just interpreted as a control code, nothing to remove.
    if (resultLength > 0 && lastCharacterWasPrintable) {
      if (codeSet == _codeCodeC) {
        result.delete(resultLength - 2, resultLength);
      } else {
        result.delete(resultLength - 1, resultLength);
      }
    }

    final left = (startPatternInfo[1] + startPatternInfo[0]) / 2.0;
    final right = lastStart + lastPatternSize / 2.0;

    final rawCodesSize = rawCodes.length;
    final rawBytes = Uint8List(rawCodesSize);
    for (int i = 0; i < rawCodesSize; i++) {
      rawBytes[i] = rawCodes[i];
    }
    final resultObject = Result(
      result.toString(),
      rawBytes,
      [
        ResultPoint(left, rowNumber.toDouble()),
        ResultPoint(right, rowNumber.toDouble()),
      ],
      BarcodeFormat.code128,
    );
    resultObject.putMetadata(
      ResultMetadataType.symbologyIdentifier,
      ']C$symbologyModifier',
    );
    return resultObject;
  }
}
