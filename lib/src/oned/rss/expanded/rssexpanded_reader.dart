/*
 * Copyright (C) 2010 ZXing authors
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

/*
 * These authors would like to acknowledge the Spanish Ministry of Industry,
 * Tourism and Trade, for the support in the project TSI020301-2008-2
 * "PIRAmIDE: Personalizable Interactions with Resources on AmI-enabled
 * Mobile Dynamic Environments", led by Treelogic
 * ( http://www.treelogic.com/ ):
 *
 *   http://www.piramidepse.com/
 */

import '../../../common/bit_array.dart';
import '../../../common/detector/math_utils.dart';

import '../../../barcode_format.dart';
import '../../../decode_hint_type.dart';
import '../../../not_found_exception.dart';
import '../../../result.dart';
import '../../../result_metadata_type.dart';
import '../../../result_point.dart';
import '../../one_dreader.dart';
import '../abstract_rssreader.dart';
import '../data_character.dart';
import '../finder_pattern.dart';
import '../rssutils.dart';
import 'bit_array_builder.dart';
import 'decoders/abstract_expanded_decoder.dart';
import 'expanded_pair.dart';
import 'expanded_row.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
/// @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
class RSSExpandedReader extends AbstractRSSReader {
  static const List<int> _SYMBOL_WIDEST = [7, 5, 4, 3, 1];
  static const List<int> _EVEN_TOTAL_SUBSET = [4, 20, 52, 104, 204];
  static const List<int> _GSUM = [0, 348, 1388, 2948, 3988];

  static const List<List<int>> _FINDER_PATTERNS = [
    [1, 8, 4, 1], // A
    [3, 6, 4, 1], // B
    [3, 4, 6, 1], // C
    [3, 2, 8, 1], // D
    [2, 6, 5, 1], // E
    [2, 2, 9, 1] // F
  ];

  static const List<List<int>> _WEIGHTS = [
    [1, 3, 9, 27, 81, 32, 96, 77], //
    [20, 60, 180, 118, 143, 7, 21, 63], //
    [189, 145, 13, 39, 117, 140, 209, 205], //
    [193, 157, 49, 147, 19, 57, 171, 91], //
    [62, 186, 136, 197, 169, 85, 44, 132], //
    [185, 133, 188, 142, 4, 12, 36, 108], //
    [113, 128, 173, 97, 80, 29, 87, 50], //
    [150, 28, 84, 41, 123, 158, 52, 156], //
    [46, 138, 203, 187, 139, 206, 196, 166], //
    [76, 17, 51, 153, 37, 111, 122, 155], //
    [43, 129, 176, 106, 107, 110, 119, 146], //
    [16, 48, 144, 10, 30, 90, 59, 177], //
    [109, 116, 137, 200, 178, 112, 125, 164], //
    [70, 210, 208, 202, 184, 130, 179, 115], //
    [134, 191, 151, 31, 93, 68, 204, 190], //
    [148, 22, 66, 198, 172, 94, 71, 2], //
    [6, 18, 54, 162, 64, 192, 154, 40], //
    [120, 149, 25, 75, 14, 42, 126, 167], //
    [79, 26, 78, 23, 69, 207, 199, 175], //
    [103, 98, 83, 38, 114, 131, 182, 124], //
    [161, 61, 183, 127, 170, 88, 53, 159], //
    [55, 165, 73, 8, 24, 72, 5, 15], //
    [45, 135, 194, 160, 58, 174, 100, 89] //
  ];

  static const int _FINDER_PAT_A = 0;
  static const int _FINDER_PAT_B = 1;
  static const int _FINDER_PAT_C = 2;
  static const int _FINDER_PAT_D = 3;
  static const int _FINDER_PAT_E = 4;
  static const int _FINDER_PAT_F = 5;

  static final List<List<int>> _finderPatternSequences = [
    [_FINDER_PAT_A, _FINDER_PAT_A],
    [_FINDER_PAT_A, _FINDER_PAT_B, _FINDER_PAT_B],
    [_FINDER_PAT_A, _FINDER_PAT_C, _FINDER_PAT_B, _FINDER_PAT_D],
    [_FINDER_PAT_A, _FINDER_PAT_E, _FINDER_PAT_B, _FINDER_PAT_D, _FINDER_PAT_C],
    [
      _FINDER_PAT_A,
      _FINDER_PAT_E,
      _FINDER_PAT_B,
      _FINDER_PAT_D,
      _FINDER_PAT_D,
      _FINDER_PAT_F
    ],
    [
      _FINDER_PAT_A,
      _FINDER_PAT_E,
      _FINDER_PAT_B,
      _FINDER_PAT_D,
      _FINDER_PAT_E,
      _FINDER_PAT_F,
      _FINDER_PAT_F
    ],
    [
      _FINDER_PAT_A,
      _FINDER_PAT_A,
      _FINDER_PAT_B,
      _FINDER_PAT_B,
      _FINDER_PAT_C,
      _FINDER_PAT_C,
      _FINDER_PAT_D,
      _FINDER_PAT_D
    ],
    [
      _FINDER_PAT_A,
      _FINDER_PAT_A,
      _FINDER_PAT_B,
      _FINDER_PAT_B,
      _FINDER_PAT_C,
      _FINDER_PAT_C,
      _FINDER_PAT_D,
      _FINDER_PAT_E,
      _FINDER_PAT_E
    ],
    [
      _FINDER_PAT_A,
      _FINDER_PAT_A,
      _FINDER_PAT_B,
      _FINDER_PAT_B,
      _FINDER_PAT_C,
      _FINDER_PAT_C,
      _FINDER_PAT_D,
      _FINDER_PAT_E,
      _FINDER_PAT_F,
      _FINDER_PAT_F
    ],
    [
      _FINDER_PAT_A,
      _FINDER_PAT_A,
      _FINDER_PAT_B,
      _FINDER_PAT_B,
      _FINDER_PAT_C,
      _FINDER_PAT_D,
      _FINDER_PAT_D,
      _FINDER_PAT_E,
      _FINDER_PAT_E,
      _FINDER_PAT_F,
      _FINDER_PAT_F
    ],
  ];

  static const int _MAX_PAIRS = 11;

  final List<ExpandedPair> _pairs = [];
  final List<ExpandedRow> _rows = [];
  final List<int> _startEnd = [0, 0];
  bool _startFromEven = false;

  @override
  Result decodeRow(
      int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints) {
    // Rows can start with even pattern in case in prev rows there where odd number of patters.
    // So lets try twice
    this._pairs.clear();
    this._startFromEven = false;
    try {
      return constructResult(decodeRow2pairs(rowNumber, row));
    } catch (e) {
      // NotFoundException
      // OK
    }

    this._pairs.clear();
    this._startFromEven = true;
    return constructResult(decodeRow2pairs(rowNumber, row));
  }

  @override
  void reset() {
    this._pairs.clear();
    this._rows.clear();
  }

  // Not for testing
  List<ExpandedPair> decodeRow2pairs(int rowNumber, BitArray row) {
    bool done = false;
    while (!done) {
      try {
        this._pairs.add(retrieveNextPair(row, this._pairs, rowNumber)!);
      } catch (nfe) {
        // NotFoundException
        if (this._pairs.isEmpty) {
          throw nfe;
        }
        // exit this loop when retrieveNextPair() fails and throws
        done = true;
      }
    }

    // TODO: verify sequence of finder patterns as in checkPairSequence()
    if (_checkChecksum()) {
      return this._pairs;
    }

    bool tryStackedDecode = this._rows.isNotEmpty;
    _storeRow(rowNumber); // TODO: deal with reversed rows
    if (tryStackedDecode) {
      // When the image is 180-rotated, then rows are sorted in wrong direction.
      // Try twice with both the directions.
      List<ExpandedPair>? ps = _checkRows(false);
      if (ps != null) {
        return ps;
      }
      ps = _checkRows(true);
      if (ps != null) {
        return ps;
      }
    }

    throw NotFoundException.instance;
  }

  List<ExpandedPair>? _checkRows(bool reverse) {
    // Limit number of rows we are checking
    // We use recursive algorithm with pure complexity and don't want it to take forever
    // Stacked barcode can have up to 11 rows, so 25 seems reasonable enough
    if (this._rows.length > 25) {
      // We will never have a chance to get result, so clear it
      this._rows.clear();
      return null;
    }

    this._pairs.clear();
    if (reverse) {
      this._rows.setAll(0, this._rows.reversed.toList());
    }

    List<ExpandedPair>? ps;
    try {
      ps = _checkRowsCurrent([], 0);
    } catch (e) {
      // NotFoundException
      // OK
    }

    if (reverse) {
      this._rows.setAll(0, this._rows.reversed.toList());
    }

    return ps;
  }

  // Try to construct a valid rows sequence
  // Recursion is used to implement backtracking
  List<ExpandedPair> _checkRowsCurrent(
      List<ExpandedRow> collectedRows, int currentRow) {
    for (int i = currentRow; i < _rows.length; i++) {
      ExpandedRow row = _rows[i];
      this._pairs.clear();
      for (ExpandedRow collectedRow in collectedRows) {
        this._pairs.addAll(collectedRow.pairs);
      }
      this._pairs.addAll(row.pairs);

      if (_isValidSequence(this._pairs)) {
        if (_checkChecksum()) {
          return this._pairs;
        }

        List<ExpandedRow> rs = collectedRows.toList();
        rs.add(row);
        try {
          // Recursion: try to add more rows
          return _checkRowsCurrent(rs, i + 1);
        } catch (e) {
          // NotFoundException
          // We failed, try the next candidate
        }
      }
    }

    throw NotFoundException.instance;
  }

  // Whether the pairs form a valid find pattern sequence,
  // either complete or a prefix
  static bool _isValidSequence(List<ExpandedPair> pairs) {
    for (List<int> sequence in _finderPatternSequences) {
      if (pairs.length <= sequence.length) {
        bool stop = true;
        for (int j = 0; j < pairs.length; j++) {
          if (pairs[j].finderPattern!.value != sequence[j]) {
            stop = false;
            break;
          }
        }
        if (stop) {
          return true;
        }
      }
    }

    return false;
  }

  void _storeRow(int rowNumber) {
    // Discard if duplicate above or below; otherwise insert in order by row number.
    int insertPos = 0;
    bool prevIsSame = false;
    bool nextIsSame = false;
    while (insertPos < this._rows.length) {
      ExpandedRow erow = this._rows[insertPos];
      if (erow.rowNumber > rowNumber) {
        nextIsSame = erow.isEquivalent(this._pairs);
        break;
      }
      prevIsSame = erow.isEquivalent(this._pairs);
      insertPos++;
    }
    if (nextIsSame || prevIsSame) {
      return;
    }

    // When the row was partially decoded (e.g. 2 pairs found instead of 3),
    // it will prevent us from detecting the barcode.
    // Try to merge partial rows

    // Check whether the row is part of an already detected row
    if (_isPartialRow(this._pairs, this._rows)) {
      return;
    }

    this._rows.add(ExpandedRow(this._pairs, rowNumber, false));
    // this.rows.add(insertPos, ExpandedRow(this.pairs, rowNumber, false));

    _removePartialRows(this._pairs, this._rows);
  }

  // Remove all the rows that contains only specified pairs
  static void _removePartialRows(
      List<ExpandedPair> pairs, List<ExpandedRow> rows) {
    rows.removeWhere((r) {
      if (r.pairs.length != pairs.length) {
        bool allFound = true;
        for (ExpandedPair p in r.pairs) {
          if (!pairs.contains(p)) {
            allFound = false;
            break;
          }
        }
        if (allFound) {
          // 'pairs' contains all the pairs from the row 'r'
          return true;
        }
      }
      return false;
    });
  }

  // Returns true when one of the rows already contains all the pairs
  static bool _isPartialRow(
      Iterable<ExpandedPair> pairs, Iterable<ExpandedRow> rows) {
    for (ExpandedRow r in rows) {
      bool allFound = true;
      for (ExpandedPair p in pairs) {
        bool found = false;
        for (ExpandedPair pp in r.pairs) {
          if (p == pp) {
            found = true;
            break;
          }
        }
        if (!found) {
          allFound = false;
          break;
        }
      }
      if (allFound) {
        // the row 'r' contain all the pairs from 'pairs'
        return true;
      }
    }
    return false;
  }

  // Only used for unit testing
  List<ExpandedRow> get rows => _rows;

  // Not for unit testing
  static Result constructResult(List<ExpandedPair> pairs) {
    BitArray binary = BitArrayBuilder.buildBitArray(pairs);

    AbstractExpandedDecoder decoder =
        AbstractExpandedDecoder.createDecoder(binary);
    String resultingString = decoder.parseInformation();

    List<ResultPoint> firstPoints =
        pairs[0].finderPattern!.resultPoints;
    List<ResultPoint> lastPoints =
        pairs[pairs.length - 1].finderPattern!.resultPoints;

    Result result = Result(
        resultingString,
        null,
        [firstPoints[0], firstPoints[1], lastPoints[0], lastPoints[1]],
        BarcodeFormat.RSS_EXPANDED);
    result.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER, "]e0");
    return result;
  }

  bool _checkChecksum() {
    ExpandedPair firstPair = this._pairs[0];
    DataCharacter? checkCharacter = firstPair.leftChar;
    DataCharacter? firstCharacter = firstPair.rightChar;

    if (firstCharacter == null) {
      return false;
    }

    int checksum = firstCharacter.checksumPortion;
    int s = 2;

    for (int i = 1; i < this._pairs.length; ++i) {
      ExpandedPair currentPair = this._pairs[i];
      checksum += currentPair.leftChar!.checksumPortion;
      s++;
      DataCharacter? currentRightChar = currentPair.rightChar;
      if (currentRightChar != null) {
        checksum += currentRightChar.checksumPortion;
        s++;
      }
    }

    checksum %= 211;

    int checkCharacterValue = 211 * (s - 4) + checksum;

    return checkCharacterValue == checkCharacter!.value;
  }

  static int _getNextSecondBar(BitArray row, int initialPos) {
    int currentPos;
    if (row.get(initialPos)) {
      currentPos = row.getNextUnset(initialPos);
      currentPos = row.getNextSet(currentPos);
    } else {
      currentPos = row.getNextSet(initialPos);
      currentPos = row.getNextUnset(currentPos);
    }
    return currentPos;
  }

  // not for testing
  ExpandedPair? retrieveNextPair(
      BitArray row, List<ExpandedPair> previousPairs, int rowNumber) {
    bool isOddPattern = previousPairs.length % 2 == 0;
    if (_startFromEven) {
      isOddPattern = !isOddPattern;
    }

    FinderPattern? pattern;

    bool keepFinding = true;
    int forcedOffset = -1;
    do {
      this._findNextPair(row, previousPairs, forcedOffset);
      pattern = _parseFoundFinderPattern(row, rowNumber, isOddPattern);
      if (pattern == null) {
        forcedOffset = _getNextSecondBar(row, this._startEnd[0]);
      } else {
        keepFinding = false;
      }
    } while (keepFinding);

    // When stacked symbol is split over multiple rows, there's no way to guess if this pair can be last or not.
    // bool mayBeLast = checkPairSequence(previousPairs, pattern);

    DataCharacter leftChar =
        this.decodeDataCharacter(row, pattern!, isOddPattern, true);

    if (previousPairs.isNotEmpty &&
        previousPairs[previousPairs.length - 1].mustBeLast) {
      throw NotFoundException.instance;
    }

    DataCharacter? rightChar;
    try {
      rightChar = this.decodeDataCharacter(row, pattern, isOddPattern, false);
    } catch (ignored) {
      // NotFoundException
      rightChar = null;
    }
    return ExpandedPair(leftChar, rightChar, pattern);
  }

  void _findNextPair(
      BitArray row, List<ExpandedPair> previousPairs, int forcedOffset) {
    List<int> counters = this.getDecodeFinderCounters();
    counters.fillRange(0, 4, 0);

    int width = row.size;

    int rowOffset;
    if (forcedOffset >= 0) {
      rowOffset = forcedOffset;
    } else if (previousPairs.isEmpty) {
      rowOffset = 0;
    } else {
      ExpandedPair lastPair = previousPairs[previousPairs.length - 1];
      rowOffset = lastPair.finderPattern!.startEnd[1];
    }
    bool searchingEvenPair = previousPairs.length % 2 != 0;
    if (_startFromEven) {
      searchingEvenPair = !searchingEvenPair;
    }

    bool isWhite = false;
    while (rowOffset < width) {
      isWhite = !row.get(rowOffset);
      if (!isWhite) {
        break;
      }
      rowOffset++;
    }

    int counterPosition = 0;
    int patternStart = rowOffset;
    for (int x = rowOffset; x < width; x++) {
      if (row.get(x) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == 3) {
          if (searchingEvenPair) {
            _reverseCounters(counters);
          }

          if (AbstractRSSReader.isFinderPattern(counters)) {
            this._startEnd[0] = patternStart;
            this._startEnd[1] = x;
            return;
          }

          if (searchingEvenPair) {
            _reverseCounters(counters);
          }

          patternStart += counters[0] + counters[1];
          counters[0] = counters[2];
          counters[1] = counters[3];
          counters[2] = 0;
          counters[3] = 0;
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

  static void _reverseCounters(List<int> counters) {
    int length = counters.length;
    for (int i = 0; i < length ~/ 2; ++i) {
      int tmp = counters[i];
      counters[i] = counters[length - i - 1];
      counters[length - i - 1] = tmp;
    }
  }

  FinderPattern? _parseFoundFinderPattern(
      BitArray row, int rowNumber, bool oddPattern) {
    // Actually we found elements 2-5.
    int firstCounter;
    int start;
    int end;

    if (oddPattern) {
      // If pattern number is odd, we need to locate element 1 *before* the current block.

      int firstElementStart = this._startEnd[0] - 1;
      // Locate element 1
      while (firstElementStart >= 0 && !row.get(firstElementStart)) {
        firstElementStart--;
      }

      firstElementStart++;
      firstCounter = this._startEnd[0] - firstElementStart;
      start = firstElementStart;
      end = this._startEnd[1];
    } else {
      // If pattern number is even, the pattern is reversed, so we need to locate element 1 *after* the current block.

      start = this._startEnd[0];

      end = row.getNextUnset(this._startEnd[1] + 1);
      firstCounter = end - this._startEnd[1];
    }

    // Make 'counters' hold 1-4
    List<int> counters = this.getDecodeFinderCounters();
    List.copyRange(counters, 1, counters, 0, counters.length - 1);

    counters[0] = firstCounter;
    int value;
    try {
      value = AbstractRSSReader.parseFinderValue(counters, _FINDER_PATTERNS);
    } catch (ignored) {
      // NotFoundException
      return null;
    }
    return FinderPattern(value, [start, end], start, end, rowNumber);
  }

  DataCharacter decodeDataCharacter(
      BitArray row, FinderPattern pattern, bool isOddPattern, bool leftChar) {
    List<int> counters = this.getDataCharacterCounters();
    counters.fillRange(0, counters.length, 0);

    if (leftChar) {
      OneDReader.recordPatternInReverse(
          row, pattern.startEnd[0], counters);
    } else {
      OneDReader.recordPattern(row, pattern.startEnd[1], counters);
      // reverse it
      for (int i = 0, j = counters.length - 1; i < j; i++, j--) {
        int temp = counters[i];
        counters[i] = counters[j];
        counters[j] = temp;
      }
    } //List<counters> has the pixels of the module

    int numModules =
        17; //left and right data characters have all the same length
    double elementWidth = MathUtils.sum(counters) / numModules;

    // Sanity check: element width for pattern and the character should match
    double expectedElementWidth =
        (pattern.startEnd[1] - pattern.startEnd[0]) / 15.0;
    if ((elementWidth - expectedElementWidth).abs() / expectedElementWidth >
        0.3) {
      throw NotFoundException.instance;
    }

    List<int> oddCounts = this.getOddCounts();
    List<int> evenCounts = this.getEvenCounts();
    List<double> oddRoundingErrors = this.getOddRoundingErrors();
    List<double> evenRoundingErrors = this.getEvenRoundingErrors();

    for (int i = 0; i < counters.length; i++) {
      double value = 1.0 * counters[i] / elementWidth;
      int count = (value + 0.5).toInt(); // Round
      if (count < 1) {
        if (value < 0.3) {
          throw NotFoundException.instance;
        }
        count = 1;
      } else if (count > 8) {
        if (value > 8.7) {
          throw NotFoundException.instance;
        }
        count = 8;
      }
      int offset = i ~/ 2;
      if ((i & 0x01) == 0) {
        oddCounts[offset] = count;
        oddRoundingErrors[offset] = value - count;
      } else {
        evenCounts[offset] = count;
        evenRoundingErrors[offset] = value - count;
      }
    }

    _adjustOddEvenCounts(numModules);

    int weightRowNumber = 4 * pattern.value +
        (isOddPattern ? 0 : 2) +
        (leftChar ? 0 : 1) -
        1;

    int oddSum = 0;
    int oddChecksumPortion = 0;
    for (int i = oddCounts.length - 1; i >= 0; i--) {
      if (_isNotA1left(pattern, isOddPattern, leftChar)) {
        int weight = _WEIGHTS[weightRowNumber][2 * i];
        oddChecksumPortion += oddCounts[i] * weight;
      }
      oddSum += oddCounts[i];
    }
    int evenChecksumPortion = 0;
    for (int i = evenCounts.length - 1; i >= 0; i--) {
      if (_isNotA1left(pattern, isOddPattern, leftChar)) {
        int weight = _WEIGHTS[weightRowNumber][2 * i + 1];
        evenChecksumPortion += evenCounts[i] * weight;
      }
    }
    int checksumPortion = oddChecksumPortion + evenChecksumPortion;

    if ((oddSum & 0x01) != 0 || oddSum > 13 || oddSum < 4) {
      throw NotFoundException.instance;
    }

    int group = (13 - oddSum) ~/ 2;
    int oddWidest = _SYMBOL_WIDEST[group];
    int evenWidest = 9 - oddWidest;
    int vOdd = RSSUtils.getRSSvalue(oddCounts, oddWidest, true);
    int vEven = RSSUtils.getRSSvalue(evenCounts, evenWidest, false);
    int tEven = _EVEN_TOTAL_SUBSET[group];
    int gSum = _GSUM[group];
    int value = vOdd * tEven + vEven + gSum;

    return DataCharacter(value, checksumPortion);
  }

  static bool _isNotA1left(
      FinderPattern pattern, bool isOddPattern, bool leftChar) {
    // A1: pattern.getValue is 0 (A), and it's an oddPattern, and it is a left char
    return !(pattern.value == 0 && isOddPattern && leftChar);
  }

  void _adjustOddEvenCounts(int numModules) {
    int oddSum = MathUtils.sum(this.getOddCounts());
    int evenSum = MathUtils.sum(this.getEvenCounts());

    bool incrementOdd = false;
    bool decrementOdd = false;

    if (oddSum > 13) {
      decrementOdd = true;
    } else if (oddSum < 4) {
      incrementOdd = true;
    }
    bool incrementEven = false;
    bool decrementEven = false;
    if (evenSum > 13) {
      decrementEven = true;
    } else if (evenSum < 4) {
      incrementEven = true;
    }

    int mismatch = oddSum + evenSum - numModules;
    bool oddParityBad = (oddSum & 0x01) == 1;
    bool evenParityBad = (evenSum & 0x01) == 0;
    switch (mismatch) {
      case 1:
        if (oddParityBad) {
          if (evenParityBad) {
            throw NotFoundException.instance;
          }
          decrementOdd = true;
        } else {
          if (!evenParityBad) {
            throw NotFoundException.instance;
          }
          decrementEven = true;
        }
        break;
      case -1:
        if (oddParityBad) {
          if (evenParityBad) {
            throw NotFoundException.instance;
          }
          incrementOdd = true;
        } else {
          if (!evenParityBad) {
            throw NotFoundException.instance;
          }
          incrementEven = true;
        }
        break;
      case 0:
        if (oddParityBad) {
          if (!evenParityBad) {
            throw NotFoundException.instance;
          }
          // Both bad
          if (oddSum < evenSum) {
            incrementOdd = true;
            decrementEven = true;
          } else {
            decrementOdd = true;
            incrementEven = true;
          }
        } else {
          if (evenParityBad) {
            throw NotFoundException.instance;
          }
          // Nothing to do!
        }
        break;
      default:
        throw NotFoundException.instance;
    }

    if (incrementOdd) {
      if (decrementOdd) {
        throw NotFoundException.instance;
      }
      AbstractRSSReader.increment(
          this.getOddCounts(), this.getOddRoundingErrors());
    }
    if (decrementOdd) {
      AbstractRSSReader.decrement(
          this.getOddCounts(), this.getOddRoundingErrors());
    }
    if (incrementEven) {
      if (decrementEven) {
        throw NotFoundException.instance;
      }
      AbstractRSSReader.increment(
          this.getEvenCounts(), this.getOddRoundingErrors());
    }
    if (decrementEven) {
      AbstractRSSReader.decrement(
          this.getEvenCounts(), this.getEvenRoundingErrors());
    }
  }
}
