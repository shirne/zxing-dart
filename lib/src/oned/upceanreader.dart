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

import '../common/bit_array.dart';
import '../common/string_builder.dart';

import '../barcode_format.dart';
import '../checksum_exception.dart';
import '../decode_hint_type.dart';
import '../formats_exception.dart';
import '../not_found_exception.dart';
import '../result.dart';
import '../result_metadata_type.dart';
import '../result_point.dart';
import '../result_point_callback.dart';
import 'eanmanufacturer_org_support.dart';
import 'one_dreader.dart';
import 'upceanextension_support.dart';

/// <p>Encapsulates functionality and implementation that is common to UPC and EAN families
/// of one-dimensional barcodes.</p>
///
/// @author dswitkin@google.com (Daniel Switkin)
/// @author Sean Owen
/// @author alasdair@google.com (Alasdair Mackintosh)
abstract class UPCEANReader extends OneDReader {
  // These two values are critical for determining how permissive the decoding will be.
  // We've arrived at these values through a lot of trial and error. Setting them any higher
  // lets false positives creep in quickly.
  static const double _MAX_AVG_VARIANCE = 0.48;
  static const double _MAX_INDIVIDUAL_VARIANCE = 0.7;

  /// Start/end guard pattern.
  static const List<int> START_END_PATTERN = [ 1, 1, 1,];

  /// Pattern marking the middle of a UPC/EAN pattern, separating the two halves.
  static const List<int> MIDDLE_PATTERN = [1, 1, 1, 1, 1];
  /// end guard pattern.
  static const List<int> END_PATTERN = [1, 1, 1, 1, 1, 1];
  /// "Odd", or "L" patterns used to encode UPC/EAN digits.
  static const List<List<int>> L_PATTERNS = [
    [3, 2, 1, 1], // 0
    [2, 2, 2, 1], // 1
    [2, 1, 2, 2], // 2
    [1, 4, 1, 1], // 3
    [1, 1, 3, 2], // 4
    [1, 2, 3, 1], // 5
    [1, 1, 1, 4], // 6
    [1, 3, 1, 2], // 7
    [1, 2, 1, 3], // 8
    [3, 1, 1, 2] // 9
  ];

  /// As above but also including the "even", or "G" patterns used to encode UPC/EAN digits.
  static final List<List<int>> lAndGPatterns = List.generate(
      20,
      (index) => index < 10
          ? L_PATTERNS[index].toList()
          : List.generate(
              L_PATTERNS[index - 10].length,
              (idx) => L_PATTERNS[index - 10]
                  [L_PATTERNS[index - 10].length - idx - 1]));

  /* static {
    L_AND_G_PATTERNS = new int[20][];
    List.copyRange(L_AND_G_PATTERNS, 0, L_PATTERNS, 0, 10);
    for (int i = 10; i < 20; i++) {
      List<int> widths = L_PATTERNS[i - 10];
      List<int> reversedWidths = new int[widths.length];
      for (int j = 0; j < widths.length; j++) {
        reversedWidths[j] = widths[widths.length - j - 1];
      }
      L_AND_G_PATTERNS[i] = reversedWidths;
    }
  } */

  final StringBuilder _decodeRowStringBuffer = StringBuilder();
  final UPCEANExtensionSupport _extensionReader = UPCEANExtensionSupport();
  final EANManufacturerOrgSupport _eanManSupport = EANManufacturerOrgSupport();

  UPCEANReader();

  static List<int>? findStartGuardPattern(BitArray row) {
    bool foundStart = false;
    List<int>? startRange;
    int nextStart = 0;
    List<int> counters = List.filled(START_END_PATTERN.length, 0);
    while (!foundStart) {
      counters.fillRange(0, counters.length, 0);
      //Arrays.fill(counters, 0, START_END_PATTERN.length, 0);
      startRange =
          _findGuardPattern(row, nextStart, false, START_END_PATTERN, counters);
      int start = startRange[0];
      nextStart = startRange[1];
      // Make sure there is a quiet zone at least as big as the start pattern before the barcode.
      // If this check would run off the left edge of the image, do not accept this barcode,
      // as it is very likely to be a false positive.
      int quietStart = start - (nextStart - start);
      if (quietStart >= 0) {
        foundStart = row.isRange(quietStart, start, false);
      }
    }
    return startRange;
  }

  /// <p>Like {@link #decodeRow(int, BitArray, Map)}, but
  /// allows caller to inform method about where the UPC/EAN start pattern is
  /// found. This allows this to be computed once and reused across many implementations.</p>
  ///
  /// @param rowNumber row index into the image
  /// @param row encoding of the row of the barcode image
  /// @param startGuardRange start/end column where the opening start pattern was found
  /// @param hints optional hints that influence decoding
  /// @return {@link Result} encapsulating the result of decoding a barcode in the row
  /// @throws NotFoundException if no potential barcode is found
  /// @throws ChecksumException if a potential barcode is found but does not pass its checksum
  /// @throws FormatException if a potential barcode is found but format is invalid
  Result decodeRow(
    int rowNumber,
    BitArray row,
    Map<DecodeHintType, Object>? hints, [
    List<int>? startGuardRange,
  ]) {
    if (startGuardRange == null) {
      startGuardRange = findStartGuardPattern(row);
    }
    ResultPointCallback? resultPointCallback = hints == null
        ? null
        : hints[DecodeHintType.NEED_RESULT_POINT_CALLBACK]
            as ResultPointCallback;
    int symbologyIdentifier = 0;

    if (resultPointCallback != null) {
      resultPointCallback.foundPossibleResultPoint(ResultPoint(
          (startGuardRange![0] + startGuardRange[1]) / 2.0,
          rowNumber.toDouble()));
    }

    StringBuilder result = _decodeRowStringBuffer;
    result.clear();
    int endStart = decodeMiddle(row, startGuardRange!, result);

    if (resultPointCallback != null) {
      resultPointCallback.foundPossibleResultPoint(
          ResultPoint(endStart.toDouble(), rowNumber.toDouble()));
    }

    List<int> endRange = decodeEnd(row, endStart);

    if (resultPointCallback != null) {
      resultPointCallback.foundPossibleResultPoint(ResultPoint(
          (endRange[0] + endRange[1]) / 2.0, rowNumber.toDouble()));
    }

    // Make sure there is a quiet zone at least as big as the end pattern after the barcode. The
    // spec might want more whitespace, but in practice this is the maximum we can count on.
    int end = endRange[1];
    int quietEnd = end + (end - endRange[0]);
    if (quietEnd >= row.size || !row.isRange(end, quietEnd, false)) {
      throw NotFoundException.instance;
    }

    String resultString = result.toString();
    // UPC/EAN should never be less than 8 chars anyway
    if (resultString.length < 8) {
      throw FormatsException.instance;
    }
    if (!checkChecksum(resultString)) {
      throw ChecksumException.getChecksumInstance();
    }

    double left = (startGuardRange[1] + startGuardRange[0]) / 2.0;
    double right = (endRange[1] + endRange[0]) / 2.0;
    BarcodeFormat format = barcodeFormat;
    Result decodeResult = Result(
        resultString,
        null, // no natural byte representation for these barcodes
        [
          ResultPoint(left, rowNumber.toDouble()),
          ResultPoint(right, rowNumber.toDouble())
        ],
        format);

    int extensionLength = 0;

    try {
      Result extensionResult =
          _extensionReader.decodeRow(rowNumber, row, endRange[1]);
      decodeResult.putMetadata(
          ResultMetadataType.UPC_EAN_EXTENSION, extensionResult.text);
      decodeResult.putAllMetadata(extensionResult.resultMetadata);
      decodeResult.addResultPoints(extensionResult.resultPoints);
      extensionLength = extensionResult.text.length;
    } catch (re) {
      // ReaderException
      // continue
    }

    List<int>? allowedExtensions = hints == null
        ? null
        : hints[DecodeHintType.ALLOWED_EAN_EXTENSIONS] as List<int>;
    if (allowedExtensions != null) {
      bool valid = false;
      for (int length in allowedExtensions) {
        if (extensionLength == length) {
          valid = true;
          break;
        }
      }
      if (!valid) {
        throw NotFoundException.instance;
      }
    }

    if (format == BarcodeFormat.EAN_13 || format == BarcodeFormat.UPC_A) {
      String? countryID = _eanManSupport.lookupCountryIdentifier(resultString);
      if (countryID != null) {
        decodeResult.putMetadata(
            ResultMetadataType.POSSIBLE_COUNTRY, countryID);
      }
    }
    if (format == BarcodeFormat.EAN_8) {
      symbologyIdentifier = 4;
    }

    decodeResult.putMetadata(
        ResultMetadataType.SYMBOLOGY_IDENTIFIER, "]E$symbologyIdentifier");

    return decodeResult;
  }

  /// @param s string of digits to check
  /// @return {@link #checkStandardUPCEANChecksum(CharSequence)}
  /// @throws FormatException if the string does not contain only digits
  bool checkChecksum(String s) {
    return checkStandardUPCEANChecksum(s);
  }

  /// Computes the UPC/EAN checksum on a string of digits, and reports
  /// whether the checksum is correct or not.
  ///
  /// @param s string of digits to check
  /// @return true iff string of digits passes the UPC/EAN checksum algorithm
  /// @throws FormatException if the string does not contain only digits
  static bool checkStandardUPCEANChecksum(String s) {
    int length = s.length;
    if (length == 0) {
      return false;
    }
    try {
      int check = int.parse(s[length - 1]);
      return getStandardUPCEANChecksum(s.substring(0, length - 1)) == check;
    }catch(_){
      throw FormatsException.instance;
    }
  }

  static int getStandardUPCEANChecksum(String s) {
    int length = s.length;
    int sum = 0;
    for (int i = length - 1; i >= 0; i -= 2) {
      int digit = s.codeUnitAt(i) - 48 /* 0 */;
      if (digit < 0 || digit > 9) {
        throw FormatsException.instance;
      }
      sum += digit;
    }
    sum *= 3;
    for (int i = length - 2; i >= 0; i -= 2) {
      int digit = s.codeUnitAt(i) - 48 /* 0 */;
      if (digit < 0 || digit > 9) {
        throw FormatsException.instance;
      }
      sum += digit;
    }
    return (1000 - sum) % 10;
  }

  List<int> decodeEnd(BitArray row, int endStart) {
    return _findGuardPattern(row, endStart, false, START_END_PATTERN);
  }

  static List<int> findGuardPattern(BitArray row,
      int rowOffset,
    bool whiteFirst,
      List<int> pattern) {
    return _findGuardPattern(row, rowOffset, whiteFirst, pattern, List.filled(pattern.length, 0));
  }

  /// @param row row of black/white values to search
  /// @param rowOffset position to start search
  /// @param whiteFirst if true, indicates that the pattern specifies white/black/white/...
  /// pixel counts, otherwise, it is interpreted as black/white/black/...
  /// @param pattern pattern of counts of number of black and white pixels that are being
  /// searched for as a pattern
  /// @param counters array of counters, as long as pattern, to re-use
  /// @return start/end horizontal offset of guard pattern, as an array of two ints
  /// @throws NotFoundException if pattern is not found
  static List<int> _findGuardPattern(
      BitArray row, int rowOffset, bool whiteFirst, List<int> pattern,
      [List<int>? counters]) {
    if (counters == null) {
      counters = List.filled(pattern.length, 0);
    }
    int width = row.size;
    rowOffset =
        whiteFirst ? row.getNextUnset(rowOffset) : row.getNextSet(rowOffset);
    int counterPosition = 0;
    int patternStart = rowOffset;
    int patternLength = pattern.length;
    bool isWhite = whiteFirst;
    for (int x = rowOffset; x < width; x++) {
      if (row.get(x) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == patternLength - 1) {
          if (OneDReader.patternMatchVariance(
                  counters, pattern, _MAX_INDIVIDUAL_VARIANCE) <
              _MAX_AVG_VARIANCE) {
            return [patternStart, x];
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

  /// Attempts to decode a single UPC/EAN-encoded digit.
  ///
  /// @param row row of black/white values to decode
  /// @param counters the counts of runs of observed black/white/black/... values
  /// @param rowOffset horizontal offset to start decoding from
  /// @param patterns the set of patterns to use to decode -- sometimes different encodings
  /// for the digits 0-9 are used, and this indicates the encodings for 0 to 9 that should
  /// be used
  /// @return horizontal offset of first pixel beyond the decoded digit
  /// @throws NotFoundException if digit cannot be decoded
  static int decodeDigit(BitArray row, List<int> counters, int rowOffset,
      List<List<int>> patterns) {
    OneDReader.recordPattern(row, rowOffset, counters);
    double bestVariance = _MAX_AVG_VARIANCE; // worst variance we'll accept
    int bestMatch = -1;
    int max = patterns.length;
    for (int i = 0; i < max; i++) {
      List<int> pattern = patterns[i];
      double variance = OneDReader.patternMatchVariance(
          counters, pattern, _MAX_INDIVIDUAL_VARIANCE);
      if (variance < bestVariance) {
        bestVariance = variance;
        bestMatch = i;
      }
    }
    if (bestMatch >= 0) {
      return bestMatch;
    } else {
      throw NotFoundException.instance;
    }
  }

  /// Get the format of this decoder.
  ///
  /// @return The 1D format.
  BarcodeFormat get barcodeFormat;

  /// Subclasses override this to decode the portion of a barcode between the start
  /// and end guard patterns.
  ///
  /// @param row row of black/white values to search
  /// @param startRange start/end offset of start guard pattern
  /// @param resultString {@link StringBuffer} to append decoded chars to
  /// @return horizontal offset of first pixel after the "middle" that was decoded
  /// @throws NotFoundException if decoding could not complete successfully
  int decodeMiddle(
      BitArray row, List<int> startRange, StringBuilder resultString);
}