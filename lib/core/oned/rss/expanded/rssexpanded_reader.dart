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

import 'package:zxing/core/common/bit_array.dart';
import 'package:zxing/core/common/detector/math_utils.dart';

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

/**
 * @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
 * @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
 */
class RSSExpandedReader extends AbstractRSSReader {
  static const List<int> SYMBOL_WIDEST = [7, 5, 4, 3, 1];
  static const List<int> EVEN_TOTAL_SUBSET = [4, 20, 52, 104, 204];
  static const List<int> GSUM = [0, 348, 1388, 2948, 3988];

  static const List<List<int>> FINDER_PATTERNS = [
    [1, 8, 4, 1], // A
    [3, 6, 4, 1], // B
    [3, 4, 6, 1], // C
    [3, 2, 8, 1], // D
    [2, 6, 5, 1], // E
    [2, 2, 9, 1] // F
  ];

  static const List<List<int>> WEIGHTS = [
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

  static const int FINDER_PAT_A = 0;
  static const int FINDER_PAT_B = 1;
  static const int FINDER_PAT_C = 2;
  static const int FINDER_PAT_D = 3;
  static const int FINDER_PAT_E = 4;
  static const int FINDER_PAT_F = 5;

  static final List<List<int>> FINDER_PATTERN_SEQUENCES = [
    [FINDER_PAT_A, FINDER_PAT_A],
    [FINDER_PAT_A, FINDER_PAT_B, FINDER_PAT_B],
    [FINDER_PAT_A, FINDER_PAT_C, FINDER_PAT_B, FINDER_PAT_D],
    [FINDER_PAT_A, FINDER_PAT_E, FINDER_PAT_B, FINDER_PAT_D, FINDER_PAT_C],
    [
      FINDER_PAT_A,
      FINDER_PAT_E,
      FINDER_PAT_B,
      FINDER_PAT_D,
      FINDER_PAT_D,
      FINDER_PAT_F
    ],
    [
      FINDER_PAT_A,
      FINDER_PAT_E,
      FINDER_PAT_B,
      FINDER_PAT_D,
      FINDER_PAT_E,
      FINDER_PAT_F,
      FINDER_PAT_F
    ],
    [
      FINDER_PAT_A,
      FINDER_PAT_A,
      FINDER_PAT_B,
      FINDER_PAT_B,
      FINDER_PAT_C,
      FINDER_PAT_C,
      FINDER_PAT_D,
      FINDER_PAT_D
    ],
    [
      FINDER_PAT_A,
      FINDER_PAT_A,
      FINDER_PAT_B,
      FINDER_PAT_B,
      FINDER_PAT_C,
      FINDER_PAT_C,
      FINDER_PAT_D,
      FINDER_PAT_E,
      FINDER_PAT_E
    ],
    [
      FINDER_PAT_A,
      FINDER_PAT_A,
      FINDER_PAT_B,
      FINDER_PAT_B,
      FINDER_PAT_C,
      FINDER_PAT_C,
      FINDER_PAT_D,
      FINDER_PAT_E,
      FINDER_PAT_F,
      FINDER_PAT_F
    ],
    [
      FINDER_PAT_A,
      FINDER_PAT_A,
      FINDER_PAT_B,
      FINDER_PAT_B,
      FINDER_PAT_C,
      FINDER_PAT_D,
      FINDER_PAT_D,
      FINDER_PAT_E,
      FINDER_PAT_E,
      FINDER_PAT_F,
      FINDER_PAT_F
    ],
  ];

  static const int MAX_PAIRS = 11;

  final List<ExpandedPair> pairs =
      List.generate(MAX_PAIRS, (index) => ExpandedPair(null, null, null));
  final List<ExpandedRow> rows = [];
  final List<int> startEnd = [0, 0];
  late bool startFromEven;

  @override
  Result decodeRow(
      int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints) {
    // Rows can start with even pattern in case in prev rows there where odd number of patters.
    // So lets try twice
    this.pairs.clear();
    this.startFromEven = false;
    try {
      return constructResult(decodeRow2pairs(rowNumber, row));
    } catch (e) {
      // NotFoundException
      // OK
    }

    this.pairs.clear();
    this.startFromEven = true;
    return constructResult(decodeRow2pairs(rowNumber, row));
  }

  @override
  void reset() {
    this.pairs.clear();
    this.rows.clear();
  }

  // Not for testing
  List<ExpandedPair> decodeRow2pairs(int rowNumber, BitArray row) {
    bool done = false;
    while (!done) {
      try {
        this.pairs.add(retrieveNextPair(row, this.pairs, rowNumber)!);
      } catch (nfe) {
        // NotFoundException
        if (this.pairs.isEmpty) {
          throw nfe;
        }
        // exit this loop when retrieveNextPair() fails and throws
        done = true;
      }
    }

    // TODO: verify sequence of finder patterns as in checkPairSequence()
    if (checkChecksum()) {
      return this.pairs;
    }

    bool tryStackedDecode = this.rows.isNotEmpty;
    storeRow(rowNumber); // TODO: deal with reversed rows
    if (tryStackedDecode) {
      // When the image is 180-rotated, then rows are sorted in wrong direction.
      // Try twice with both the directions.
      List<ExpandedPair>? ps = checkRows(false);
      if (ps != null) {
        return ps;
      }
      ps = checkRows(true);
      if (ps != null) {
        return ps;
      }
    }

    throw NotFoundException.getNotFoundInstance();
  }

  List<ExpandedPair>? checkRows(bool reverse) {
    // Limit number of rows we are checking
    // We use recursive algorithm with pure complexity and don't want it to take forever
    // Stacked barcode can have up to 11 rows, so 25 seems reasonable enough
    if (this.rows.length > 25) {
      this
          .rows
          .clear(); // We will never have a chance to get result, so clear it
      return null;
    }

    this.pairs.clear();
    if (reverse) {
      this.rows.setAll(0, this.rows.reversed);
    }

    List<ExpandedPair>? ps;
    try {
      ps = checkRowsCurrent([], 0);
    } catch (e) {
      // NotFoundException
      // OK
    }

    if (reverse) {
      this.rows.setAll(0, this.rows.reversed);
    }

    return ps;
  }

  // Try to construct a valid rows sequence
  // Recursion is used to implement backtracking
  List<ExpandedPair> checkRowsCurrent(
      List<ExpandedRow> collectedRows, int currentRow) {
    for (int i = currentRow; i < rows.length; i++) {
      ExpandedRow row = rows[i];
      this.pairs.clear();
      for (ExpandedRow collectedRow in collectedRows) {
        this.pairs.addAll(collectedRow.getPairs());
      }
      this.pairs.addAll(row.getPairs());

      if (isValidSequence(this.pairs)) {
        if (checkChecksum()) {
          return this.pairs;
        }

        List<ExpandedRow> rs = collectedRows.toList();
        rs.add(row);
        try {
          // Recursion: try to add more rows
          return checkRowsCurrent(rs, i + 1);
        } catch (e) {
          // NotFoundException
          // We failed, try the next candidate
        }
      }
    }

    throw NotFoundException.getNotFoundInstance();
  }

  // Whether the pairs form a valid find pattern sequence,
  // either complete or a prefix
  static bool isValidSequence(List<ExpandedPair> pairs) {
    for (List<int> sequence in FINDER_PATTERN_SEQUENCES) {
      if (pairs.length <= sequence.length) {
        bool stop = true;
        for (int j = 0; j < pairs.length; j++) {
          if (pairs[j].getFinderPattern()!.getValue() != sequence[j]) {
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

  void storeRow(int rowNumber) {
    // Discard if duplicate above or below; otherwise insert in order by row number.
    int insertPos = 0;
    bool prevIsSame = false;
    bool nextIsSame = false;
    while (insertPos < this.rows.length) {
      ExpandedRow erow = this.rows[insertPos];
      if (erow.getRowNumber() > rowNumber) {
        nextIsSame = erow.isEquivalent(this.pairs);
        break;
      }
      prevIsSame = erow.isEquivalent(this.pairs);
      insertPos++;
    }
    if (nextIsSame || prevIsSame) {
      return;
    }

    // When the row was partially decoded (e.g. 2 pairs found instead of 3),
    // it will prevent us from detecting the barcode.
    // Try to merge partial rows

    // Check whether the row is part of an already detected row
    if (isPartialRow(this.pairs, this.rows)) {
      return;
    }

    this.rows[insertPos] = ExpandedRow(this.pairs, rowNumber, false);
    // this.rows.add(insertPos, ExpandedRow(this.pairs, rowNumber, false));

    removePartialRows(this.pairs, this.rows);
  }

  // Remove all the rows that contains only specified pairs
  static void removePartialRows(
      List<ExpandedPair> pairs, List<ExpandedRow> rows) {
    rows.removeWhere((r) {
      if (r.getPairs().length != pairs.length) {
        bool allFound = true;
        for (ExpandedPair p in r.getPairs()) {
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
  static bool isPartialRow(
      Iterable<ExpandedPair> pairs, Iterable<ExpandedRow> rows) {
    for (ExpandedRow r in rows) {
      bool allFound = true;
      for (ExpandedPair p in pairs) {
        bool found = false;
        for (ExpandedPair pp in r.getPairs()) {
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
  List<ExpandedRow> getRows() {
    return this.rows;
  }

  // Not for unit testing
  static Result constructResult(List<ExpandedPair> pairs) {
    BitArray binary = BitArrayBuilder.buildBitArray(pairs);

    AbstractExpandedDecoder decoder =
        AbstractExpandedDecoder.createDecoder(binary);
    String resultingString = decoder.parseInformation();

    List<ResultPoint> firstPoints =
        pairs[0].getFinderPattern()!.getResultPoints();
    List<ResultPoint> lastPoints =
        pairs[pairs.length - 1].getFinderPattern()!.getResultPoints();

    Result result = new Result(
        resultingString,
        null,
        [firstPoints[0], firstPoints[1], lastPoints[0], lastPoints[1]],
        BarcodeFormat.RSS_EXPANDED);
    result.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER, "]e0");
    return result;
  }

  bool checkChecksum() {
    ExpandedPair firstPair = this.pairs[0];
    DataCharacter? checkCharacter = firstPair.getLeftChar();
    DataCharacter? firstCharacter = firstPair.getRightChar();

    if (firstCharacter == null) {
      return false;
    }

    int checksum = firstCharacter.getChecksumPortion();
    int s = 2;

    for (int i = 1; i < this.pairs.length; ++i) {
      ExpandedPair currentPair = this.pairs[i];
      checksum += currentPair.getLeftChar()!.getChecksumPortion();
      s++;
      DataCharacter? currentRightChar = currentPair.getRightChar();
      if (currentRightChar != null) {
        checksum += currentRightChar.getChecksumPortion();
        s++;
      }
    }

    checksum %= 211;

    int checkCharacterValue = 211 * (s - 4) + checksum;

    return checkCharacterValue == checkCharacter!.getValue();
  }

  static int getNextSecondBar(BitArray row, int initialPos) {
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
    if (startFromEven) {
      isOddPattern = !isOddPattern;
    }

    FinderPattern? pattern;

    bool keepFinding = true;
    int forcedOffset = -1;
    do {
      this.findNextPair(row, previousPairs, forcedOffset);
      pattern = parseFoundFinderPattern(row, rowNumber, isOddPattern);
      if (pattern == null) {
        forcedOffset = getNextSecondBar(row, this.startEnd[0]);
      } else {
        keepFinding = false;
      }
    } while (keepFinding);

    // When stacked symbol is split over multiple rows, there's no way to guess if this pair can be last or not.
    // bool mayBeLast = checkPairSequence(previousPairs, pattern);

    DataCharacter leftChar =
        this.decodeDataCharacter(row, pattern!, isOddPattern, true);

    if (previousPairs.isNotEmpty &&
        previousPairs[previousPairs.length - 1].mustBeLast()) {
      throw NotFoundException.getNotFoundInstance();
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

  void findNextPair(
      BitArray row, List<ExpandedPair> previousPairs, int forcedOffset) {
    List<int> counters = this.getDecodeFinderCounters();
    counters[0] = 0;
    counters[1] = 0;
    counters[2] = 0;
    counters[3] = 0;

    int width = row.getSize();

    int rowOffset;
    if (forcedOffset >= 0) {
      rowOffset = forcedOffset;
    } else if (previousPairs.isEmpty) {
      rowOffset = 0;
    } else {
      ExpandedPair lastPair = previousPairs[previousPairs.length - 1];
      rowOffset = lastPair.getFinderPattern()!.getStartEnd()[1];
    }
    bool searchingEvenPair = previousPairs.length % 2 != 0;
    if (startFromEven) {
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
            reverseCounters(counters);
          }

          if (AbstractRSSReader.isFinderPattern(counters)) {
            this.startEnd[0] = patternStart;
            this.startEnd[1] = x;
            return;
          }

          if (searchingEvenPair) {
            reverseCounters(counters);
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
    throw NotFoundException.getNotFoundInstance();
  }

  static void reverseCounters(List<int> counters) {
    int length = counters.length;
    for (int i = 0; i < length / 2; ++i) {
      int tmp = counters[i];
      counters[i] = counters[length - i - 1];
      counters[length - i - 1] = tmp;
    }
  }

  FinderPattern? parseFoundFinderPattern(
      BitArray row, int rowNumber, bool oddPattern) {
    // Actually we found elements 2-5.
    int firstCounter;
    int start;
    int end;

    if (oddPattern) {
      // If pattern number is odd, we need to locate element 1 *before* the current block.

      int firstElementStart = this.startEnd[0] - 1;
      // Locate element 1
      while (firstElementStart >= 0 && !row.get(firstElementStart)) {
        firstElementStart--;
      }

      firstElementStart++;
      firstCounter = this.startEnd[0] - firstElementStart;
      start = firstElementStart;
      end = this.startEnd[1];
    } else {
      // If pattern number is even, the pattern is reversed, so we need to locate element 1 *after* the current block.

      start = this.startEnd[0];

      end = row.getNextUnset(this.startEnd[1] + 1);
      firstCounter = end - this.startEnd[1];
    }

    // Make 'counters' hold 1-4
    List<int> counters = this.getDecodeFinderCounters();
    List.copyRange(counters, 1, counters, 0, counters.length - 1);

    counters[0] = firstCounter;
    int value;
    try {
      value = AbstractRSSReader.parseFinderValue(counters, FINDER_PATTERNS);
    } catch (ignored) {
      // NotFoundException
      return null;
    }
    return new FinderPattern(value, [start, end], start, end, rowNumber);
  }

  DataCharacter decodeDataCharacter(
      BitArray row, FinderPattern pattern, bool isOddPattern, bool leftChar) {
    List<int> counters = this.getDataCharacterCounters();
    // Arrays.fill(counters, 0);

    if (leftChar) {
      OneDReader.recordPatternInReverse(
          row, pattern.getStartEnd()[0], counters);
    } else {
      OneDReader.recordPattern(row, pattern.getStartEnd()[1], counters);
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
        (pattern.getStartEnd()[1] - pattern.getStartEnd()[0]) / 15.0;
    if ((elementWidth - expectedElementWidth).abs() / expectedElementWidth >
        0.3) {
      throw NotFoundException.getNotFoundInstance();
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
          throw NotFoundException.getNotFoundInstance();
        }
        count = 1;
      } else if (count > 8) {
        if (value > 8.7) {
          throw NotFoundException.getNotFoundInstance();
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

    adjustOddEvenCounts(numModules);

    int weightRowNumber = 4 * pattern.getValue() +
        (isOddPattern ? 0 : 2) +
        (leftChar ? 0 : 1) -
        1;

    int oddSum = 0;
    int oddChecksumPortion = 0;
    for (int i = oddCounts.length - 1; i >= 0; i--) {
      if (isNotA1left(pattern, isOddPattern, leftChar)) {
        int weight = WEIGHTS[weightRowNumber][2 * i];
        oddChecksumPortion += oddCounts[i] * weight;
      }
      oddSum += oddCounts[i];
    }
    int evenChecksumPortion = 0;
    for (int i = evenCounts.length - 1; i >= 0; i--) {
      if (isNotA1left(pattern, isOddPattern, leftChar)) {
        int weight = WEIGHTS[weightRowNumber][2 * i + 1];
        evenChecksumPortion += evenCounts[i] * weight;
      }
    }
    int checksumPortion = oddChecksumPortion + evenChecksumPortion;

    if ((oddSum & 0x01) != 0 || oddSum > 13 || oddSum < 4) {
      throw NotFoundException.getNotFoundInstance();
    }

    int group = (13 - oddSum) ~/ 2;
    int oddWidest = SYMBOL_WIDEST[group];
    int evenWidest = 9 - oddWidest;
    int vOdd = RSSUtils.getRSSvalue(oddCounts, oddWidest, true);
    int vEven = RSSUtils.getRSSvalue(evenCounts, evenWidest, false);
    int tEven = EVEN_TOTAL_SUBSET[group];
    int gSum = GSUM[group];
    int value = vOdd * tEven + vEven + gSum;

    return new DataCharacter(value, checksumPortion);
  }

  static bool isNotA1left(
      FinderPattern pattern, bool isOddPattern, bool leftChar) {
    // A1: pattern.getValue is 0 (A), and it's an oddPattern, and it is a left char
    return !(pattern.getValue() == 0 && isOddPattern && leftChar);
  }

  void adjustOddEvenCounts(int numModules) {
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
            throw NotFoundException.getNotFoundInstance();
          }
          decrementOdd = true;
        } else {
          if (!evenParityBad) {
            throw NotFoundException.getNotFoundInstance();
          }
          decrementEven = true;
        }
        break;
      case -1:
        if (oddParityBad) {
          if (evenParityBad) {
            throw NotFoundException.getNotFoundInstance();
          }
          incrementOdd = true;
        } else {
          if (!evenParityBad) {
            throw NotFoundException.getNotFoundInstance();
          }
          incrementEven = true;
        }
        break;
      case 0:
        if (oddParityBad) {
          if (!evenParityBad) {
            throw NotFoundException.getNotFoundInstance();
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
            throw NotFoundException.getNotFoundInstance();
          }
          // Nothing to do!
        }
        break;
      default:
        throw NotFoundException.getNotFoundInstance();
    }

    if (incrementOdd) {
      if (decrementOdd) {
        throw NotFoundException.getNotFoundInstance();
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
        throw NotFoundException.getNotFoundInstance();
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
