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

import '../../../barcode_format.dart';
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
import '../../../decode_hint.dart';
import '../../../not_found_exception.dart';
import '../../../result.dart';
import '../../../result_metadata_type.dart';
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
  static const List<int> _symbolWidest = [7, 5, 4, 3, 1];
  static const List<int> _evenTotalSubset = [4, 20, 52, 104, 204];
  static const List<int> _gsum = [0, 348, 1388, 2948, 3988];

  static const List<List<int>> _finderPatterns = [
    [1, 8, 4, 1], // A
    [3, 6, 4, 1], // B
    [3, 4, 6, 1], // C
    [3, 2, 8, 1], // D
    [2, 6, 5, 1], // E
    [2, 2, 9, 1], // F
  ];

  static const List<List<int>> _weights = [
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
    [45, 135, 194, 160, 58, 174, 100, 89], //
  ];

  static const int _finderPatA = 0;
  static const int _finderPatB = 1;
  static const int _finderPatC = 2;
  static const int _finderPatD = 3;
  static const int _finderPatE = 4;
  static const int _finderPatF = 5;

  static final List<List<int>> _finderPatternSequences = [
    [_finderPatA, _finderPatA],
    [_finderPatA, _finderPatB, _finderPatB],
    [_finderPatA, _finderPatC, _finderPatB, _finderPatD],
    [_finderPatA, _finderPatE, _finderPatB, _finderPatD, _finderPatC],
    [
      _finderPatA,
      _finderPatE,
      _finderPatB,
      _finderPatD,
      _finderPatD,
      _finderPatF,
    ], //
    [
      _finderPatA, _finderPatE, _finderPatB, _finderPatD, //
      _finderPatE, _finderPatF, _finderPatF,
    ],
    [
      _finderPatA, _finderPatA, _finderPatB, _finderPatB, //
      _finderPatC, _finderPatC, _finderPatD, _finderPatD,
    ],
    [
      _finderPatA, _finderPatA, _finderPatB, _finderPatB,
      _finderPatC, //
      _finderPatC, _finderPatD, _finderPatE, _finderPatE,
    ],
    [
      _finderPatA, _finderPatA, _finderPatB, _finderPatB, //
      _finderPatC, _finderPatC, _finderPatD, _finderPatE,
      _finderPatF, _finderPatF,
    ],
    [
      _finderPatA, _finderPatA, _finderPatB, _finderPatB, //
      _finderPatC, _finderPatD, _finderPatD, _finderPatE,
      _finderPatE, _finderPatF, _finderPatF,
    ],
  ];

  //static const int _MAX_PAIRS = 11;

  static const finderPatternModules = 15.0;
  static final dataCharacterModules = 17.0;
  static final maxFinderPatternDistanceVariance = 0.1;

  final List<ExpandedPair> _pairs = [];
  final List<ExpandedRow> _rows = [];
  final List<int> _startEnd = [0, 0];
  bool _startFromEven = false;

  @override
  Result decodeRow(
    int rowNumber,
    BitArray row,
    DecodeHint? hints,
  ) {
    // Rows can start with even pattern if previous rows had an odd number
    // of patterns, so we try twice.
    _startFromEven = false;
    try {
      return constructResult(decodeRow2pairs(rowNumber, row));
    } on NotFoundException catch (_) {
      // OK
    }

    _startFromEven = true;
    return constructResult(decodeRow2pairs(rowNumber, row));
  }

  @override
  void reset() {
    _pairs.clear();
    _rows.clear();
  }

  // Not for testing
  List<ExpandedPair> decodeRow2pairs(int rowNumber, BitArray row) {
    _pairs.clear();
    bool done = false;
    while (!done) {
      try {
        _pairs.add(retrieveNextPair(row, _pairs, rowNumber)!);
      } on NotFoundException catch (_) {
        if (_pairs.isEmpty) {
          rethrow;
        }
        // exit this loop when retrieveNextPair() fails and throws
        done = true;
      }
    }

    if (_checkChecksum() && _isValidSequence(_pairs, true)) {
      return _pairs;
    }

    final tryStackedDecode = _rows.isNotEmpty;
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
    if (_rows.length > 25) {
      // We will never have a chance to get result, so clear it
      _rows.clear();
      return null;
    }

    _pairs.clear();
    if (reverse) {
      _rows.setAll(0, _rows.reversed.toList());
    }

    List<ExpandedPair>? ps;
    try {
      ps = _checkRowsCurrent(<ExpandedRow>[], 0);
    } on NotFoundException catch (_) {
      // OK
    }

    if (reverse) {
      _rows.setAll(0, _rows.reversed.toList());
    }

    return ps;
  }

  // Try to construct a valid rows sequence
  // Recursion is used to implement backtracking
  List<ExpandedPair> _checkRowsCurrent(
    List<ExpandedRow> collectedRows,
    int currentRow,
  ) {
    for (int i = currentRow; i < _rows.length; i++) {
      final row = _rows[i];
      _pairs.clear();
      for (ExpandedRow collectedRow in collectedRows) {
        _pairs.addAll(collectedRow.pairs);
      }
      _pairs.addAll(row.pairs);

      if (_isValidSequence(_pairs, false)) {
        if (_checkChecksum()) {
          return _pairs;
        }

        final rs = collectedRows.toList();
        rs.add(row);
        try {
          // Recursion: try to add more rows
          return _checkRowsCurrent(rs, i + 1);
        } on NotFoundException catch (_) {
          // We failed, try the next candidate
        }
      }
    }

    throw NotFoundException.instance;
  }

  // Whether the pairs form a valid find pattern sequence,
  // either complete or a prefix
  static bool _isValidSequence(List<ExpandedPair> pairs, bool complete) {
    for (List<int> sequence in _finderPatternSequences) {
      final sizeOk = (complete
          ? pairs.length == sequence.length
          : pairs.length <= sequence.length);
      if (sizeOk) {
        bool stop = true;
        for (int j = 0; j < pairs.length; j++) {
          if (pairs[j].finderPattern?.value != sequence[j]) {
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

  // Whether the pairs, plus another pair of the specified type, would together
  // form a valid finder pattern sequence, either complete or partial
  static bool _mayFollow(List<ExpandedPair> pairs, int value) {
    if (pairs.isEmpty) {
      return true;
    }

    for (List<int> sequence in _finderPatternSequences) {
      if (pairs.length + 1 <= sequence.length) {
        // the proposed sequence (i.e. pairs + value) would fit in this allowed sequence
        for (int i = pairs.length; i < sequence.length; i++) {
          if (sequence[i] == value) {
            // we found our value in this allowed sequence, check to see if the elements preceding it match our existing
            // pairs; note our existing pairs may not be a full sequence (e.g. if processing a row in a stacked symbol)
            bool matched = true;
            for (int j = 0; j < pairs.length; j++) {
              final allowed = sequence[i - j - 1];
              final actual = pairs[pairs.length - j - 1].finderPattern?.value;
              if (allowed != actual) {
                matched = false;
                break;
              }
            }
            if (matched) {
              return true;
            }
          }
        }
      }
    }

    // the proposed finder pattern sequence is illegal
    return false;
  }

  void _storeRow(int rowNumber) {
    // Discard if duplicate above or below; otherwise insert in order by row number.
    int insertPos = 0;
    bool prevIsSame = false;
    bool nextIsSame = false;
    while (insertPos < _rows.length) {
      final erow = _rows[insertPos];
      if (erow.rowNumber > rowNumber) {
        nextIsSame = erow.isEquivalent(_pairs);
        break;
      }
      prevIsSame = erow.isEquivalent(_pairs);
      insertPos++;
    }
    if (nextIsSame || prevIsSame) {
      return;
    }

    // When the row was partially decoded (e.g. 2 pairs found instead of 3),
    // it will prevent us from detecting the barcode.
    // Try to merge partial rows

    // Check whether the row is part of an already detected row
    if (_isPartialRow(_pairs, _rows)) {
      return;
    }

    _rows.insert(insertPos, ExpandedRow(_pairs, rowNumber));

    _removePartialRows(_pairs, _rows);
  }

  // Remove all the rows that contains only specified pairs
  static void _removePartialRows(
    List<ExpandedPair> pairs,
    List<ExpandedRow> rows,
  ) {
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
    Iterable<ExpandedPair> pairs,
    Iterable<ExpandedRow> rows,
  ) {
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

  // Not private for unit testing
  static Result constructResult(List<ExpandedPair> pairs) {
    final binary = BitArrayBuilder.buildBitArray(pairs);

    final decoder = AbstractExpandedDecoder.createDecoder(binary);
    final resultingString = decoder.parseInformation();

    final firstPoints = pairs[0].finderPattern!.resultPoints;
    final lastPoints = pairs[pairs.length - 1].finderPattern!.resultPoints;

    final result = Result(
      resultingString,
      null,
      [firstPoints[0], firstPoints[1], lastPoints[0], lastPoints[1]],
      BarcodeFormat.rssExpanded,
    );
    result.putMetadata(ResultMetadataType.symbologyIdentifier, ']e0');
    return result;
  }

  bool _checkChecksum() {
    final firstPair = _pairs[0];
    final checkCharacter = firstPair.leftChar;
    final firstCharacter = firstPair.rightChar;

    if (firstCharacter == null) {
      return false;
    }

    int checksum = firstCharacter.checksumPortion;
    int s = 2;

    for (int i = 1; i < _pairs.length; ++i) {
      final currentPair = _pairs[i];
      checksum += currentPair.leftChar!.checksumPortion;
      s++;
      final currentRightChar = currentPair.rightChar;
      if (currentRightChar != null) {
        checksum += currentRightChar.checksumPortion;
        s++;
      }
    }

    checksum %= 211;

    final checkCharacterValue = 211 * (s - 4) + checksum;

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

  // not private for testing
  ExpandedPair? retrieveNextPair(
    BitArray row,
    List<ExpandedPair> previousPairs,
    int rowNumber,
  ) {
    bool isOddPattern = previousPairs.length % 2 == 0;
    if (_startFromEven) {
      isOddPattern = !isOddPattern;
    }

    FinderPattern? pattern;
    DataCharacter? leftChar;

    bool keepFinding = true;
    int forcedOffset = -1;
    do {
      _findNextPair(row, previousPairs, forcedOffset);
      pattern = _parseFoundFinderPattern(
        row,
        rowNumber,
        isOddPattern,
        previousPairs,
      );
      if (pattern == null) {
        // probable false positive, keep looking
        forcedOffset = _getNextSecondBar(row, _startEnd[0]);
      } else {
        try {
          leftChar = this.decodeDataCharacter(row, pattern, isOddPattern, true);
          keepFinding = false;
        } on NotFoundException catch (_) {
          // probable false positive, keep looking
          forcedOffset = _getNextSecondBar(row, _startEnd[0]);
        }
      }
    } while (keepFinding);

    // When stacked symbol is split over multiple rows, there's no way to guess if this pair can be last or not.
    // bool mayBeLast = checkPairSequence(previousPairs, pattern);

    if (previousPairs.isNotEmpty &&
        previousPairs[previousPairs.length - 1].mustBeLast) {
      throw NotFoundException.instance;
    }

    DataCharacter? rightChar;
    try {
      rightChar = decodeDataCharacter(row, pattern!, isOddPattern, false);
    } on NotFoundException catch (_) {
      rightChar = null;
    }
    return ExpandedPair(leftChar, rightChar, pattern);
  }

  void _findNextPair(
    BitArray row,
    List<ExpandedPair> previousPairs,
    int forcedOffset,
  ) {
    final counters = decodeFinderCounters;
    counters.fillRange(0, 4, 0);

    final width = row.size;

    int rowOffset;
    if (forcedOffset >= 0) {
      rowOffset = forcedOffset;
    } else if (previousPairs.isEmpty) {
      rowOffset = 0;
    } else {
      final lastPair = previousPairs[previousPairs.length - 1];
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
            _startEnd[0] = patternStart;
            _startEnd[1] = x;
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
    final length = counters.length;
    for (int i = 0; i < length ~/ 2; ++i) {
      final tmp = counters[i];
      counters[i] = counters[length - i - 1];
      counters[length - i - 1] = tmp;
    }
  }

  FinderPattern? _parseFoundFinderPattern(
    BitArray row,
    int rowNumber,
    bool oddPattern,
    List<ExpandedPair> previousPairs,
  ) {
    // Actually we found elements 2-5.
    int firstCounter;
    int start;
    int end;

    if (oddPattern) {
      // If pattern number is odd, we need to locate element 1 *before* the current block.

      int firstElementStart = _startEnd[0] - 1;
      // Locate element 1
      while (firstElementStart >= 0 && !row.get(firstElementStart)) {
        firstElementStart--;
      }

      firstElementStart++;
      firstCounter = _startEnd[0] - firstElementStart;
      start = firstElementStart;
      end = _startEnd[1];
    } else {
      // If pattern number is even, the pattern is reversed, so we need to locate element 1 *after* the current block.

      start = _startEnd[0];

      end = row.getNextUnset(_startEnd[1] + 1);
      firstCounter = end - _startEnd[1];
    }

    // Make 'counters' hold 1-4
    final counters = decodeFinderCounters;
    List.copyRange(counters, 1, counters, 0, counters.length - 1);

    counters[0] = firstCounter;
    int value;
    try {
      value = AbstractRSSReader.parseFinderValue(counters, _finderPatterns);
    } on NotFoundException catch (_) {
      return null;
    }

    // Check that the pattern type that we *think* we found can exist as part of a valid sequence of finder patterns.
    if (!_mayFollow(previousPairs, value)) {
      return null;
    }

    // Check that the finder pattern that we *think* we found is not too far from where we would expect to find it,
    // given that finder patterns are 15 modules wide and the data characters between them are 17 modules wide.
    if (!previousPairs.isEmpty) {
      final prev = previousPairs[previousPairs.length - 1];
      final prevStart = prev.finderPattern?.startEnd[0] ?? 0;
      final prevEnd = prev.finderPattern?.startEnd[1] ?? 0;
      final prevWidth = prevEnd - prevStart;
      final charWidth =
          (prevWidth / finderPatternModules) * dataCharacterModules;
      final minX =
          prevEnd + (2 * charWidth * (1 - maxFinderPatternDistanceVariance));
      final maxX =
          prevEnd + (2 * charWidth * (1 + maxFinderPatternDistanceVariance));
      if (start < minX || start > maxX) {
        return null;
      }
    }
    return FinderPattern(value, [start, end], start, end, rowNumber);
  }

  DataCharacter decodeDataCharacter(
    BitArray row,
    FinderPattern pattern,
    bool isOddPattern,
    bool leftChar,
  ) {
    final counters = dataCharacterCounters;
    counters.fillRange(0, counters.length, 0);

    if (leftChar) {
      OneDReader.recordPatternInReverse(row, pattern.startEnd[0], counters);
    } else {
      OneDReader.recordPattern(row, pattern.startEnd[1], counters);
      // reverse it
      for (int i = 0, j = counters.length - 1; i < j; i++, j--) {
        final temp = counters[i];
        counters[i] = counters[j];
        counters[j] = temp;
      }
    } //List<counters> has the pixels of the module

    //left and right data characters have all the same length
    final numModules = 17;
    final elementWidth = MathUtils.sum(counters) / numModules;

    // Sanity check: element width for pattern and the character should match
    final expectedElementWidth =
        (pattern.startEnd[1] - pattern.startEnd[0]) / 15.0;
    if ((elementWidth - expectedElementWidth).abs() / expectedElementWidth >
        0.3) {
      throw NotFoundException.instance;
    }

    for (int i = 0; i < counters.length; i++) {
      final value = 1.0 * counters[i] / elementWidth;
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
      final offset = i ~/ 2;
      if ((i & 0x01) == 0) {
        oddCounts[offset] = count;
        oddRoundingErrors[offset] = value - count;
      } else {
        evenCounts[offset] = count;
        evenRoundingErrors[offset] = value - count;
      }
    }

    _adjustOddEvenCounts(numModules);

    final weightRowNumber =
        4 * pattern.value + (isOddPattern ? 0 : 2) + (leftChar ? 0 : 1) - 1;

    int oddSum = 0;
    int oddChecksumPortion = 0;
    for (int i = oddCounts.length - 1; i >= 0; i--) {
      if (_isNotA1left(pattern, isOddPattern, leftChar)) {
        final weight = _weights[weightRowNumber][2 * i];
        oddChecksumPortion += oddCounts[i] * weight;
      }
      oddSum += oddCounts[i];
    }
    int evenChecksumPortion = 0;
    for (int i = evenCounts.length - 1; i >= 0; i--) {
      if (_isNotA1left(pattern, isOddPattern, leftChar)) {
        final weight = _weights[weightRowNumber][2 * i + 1];
        evenChecksumPortion += evenCounts[i] * weight;
      }
    }
    final checksumPortion = oddChecksumPortion + evenChecksumPortion;

    if ((oddSum & 0x01) != 0 || oddSum > 13 || oddSum < 4) {
      throw NotFoundException.instance;
    }

    final group = (13 - oddSum) ~/ 2;
    final oddWidest = _symbolWidest[group];
    final evenWidest = 9 - oddWidest;
    final vOdd = RSSUtils.getRSSvalue(oddCounts, oddWidest, true);
    final vEven = RSSUtils.getRSSvalue(evenCounts, evenWidest, false);
    final tEven = _evenTotalSubset[group];
    final gSum = _gsum[group];
    final value = vOdd * tEven + vEven + gSum;

    return DataCharacter(value, checksumPortion);
  }

  static bool _isNotA1left(
    FinderPattern pattern,
    bool isOddPattern,
    bool leftChar,
  ) {
    // A1: pattern.getValue is 0 (A), and it's an oddPattern, and it is a left char
    return !(pattern.value == 0 && isOddPattern && leftChar);
  }

  void _adjustOddEvenCounts(int numModules) {
    final oddSum = MathUtils.sum(oddCounts);
    final evenSum = MathUtils.sum(evenCounts);

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

    final mismatch = oddSum + evenSum - numModules;
    final oddParityBad = (oddSum & 0x01) == 1;
    final evenParityBad = (evenSum & 0x01) == 0;
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
      AbstractRSSReader.increment(oddCounts, oddRoundingErrors);
    }
    if (decrementOdd) {
      AbstractRSSReader.decrement(oddCounts, oddRoundingErrors);
    }
    if (incrementEven) {
      if (decrementEven) {
        throw NotFoundException.instance;
      }
      AbstractRSSReader.increment(evenCounts, oddRoundingErrors);
    }
    if (decrementEven) {
      AbstractRSSReader.decrement(evenCounts, evenRoundingErrors);
    }
  }
}
