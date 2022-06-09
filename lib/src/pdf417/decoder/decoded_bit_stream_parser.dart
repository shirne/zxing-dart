/*
 * Copyright 2009 ZXing authors
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

import '../../common/decoder_result.dart';
import '../../common/eci_string_builder.dart';
import '../../formats_exception.dart';
import '../pdf417_result_metadata.dart';

enum _Mode { ALPHA, LOWER, MIXED, PUNCT, ALPHA_SHIFT, PUNCT_SHIFT }

/// This class contains the methods for decoding the PDF417 codewords.
///
/// @author SITA Lab (kevin.osullivan@sita.aero)
/// @author Guenther Grau
class DecodedBitStreamParser {
  static const int _TEXT_COMPACTION_MODE_LATCH = 900;
  static const int _BYTE_COMPACTION_MODE_LATCH = 901;
  static const int _NUMERIC_COMPACTION_MODE_LATCH = 902;
  static const int _BYTE_COMPACTION_MODE_LATCH_6 = 924;
  static const int _ECI_USER_DEFINED = 925;
  static const int _ECI_GENERAL_PURPOSE = 926;
  static const int _ECI_CHARSET = 927;
  static const int _BEGIN_MACRO_PDF417_CONTROL_BLOCK = 928;
  static const int _BEGIN_MACRO_PDF417_OPTIONAL_FIELD = 923;
  static const int _MACRO_PDF417_TERMINATOR = 922;
  static const int _MODE_SHIFT_TO_BYTE_COMPACTION_MODE = 913;
  static const int _MAX_NUMERIC_CODEWORDS = 15;

  static const int _MACRO_PDF417_OPTIONAL_FIELD_FILE_NAME = 0;
  static const int _MACRO_PDF417_OPTIONAL_FIELD_SEGMENT_COUNT = 1;
  static const int _MACRO_PDF417_OPTIONAL_FIELD_TIME_STAMP = 2;
  static const int _MACRO_PDF417_OPTIONAL_FIELD_SENDER = 3;
  static const int _MACRO_PDF417_OPTIONAL_FIELD_ADDRESSEE = 4;
  static const int _MACRO_PDF417_OPTIONAL_FIELD_FILE_SIZE = 5;
  static const int _MACRO_PDF417_OPTIONAL_FIELD_CHECKSUM = 6;

  static const int _PL = 25;
  static const int _LL = 27;
  static const int _AS = 27;
  static const int _ML = 28;
  static const int _AL = 28;
  static const int _PS = 29;
  static const int _PAL = 29;

  static final List<int> _punctChars =
      ";<>@[\\]_`~!\r\t,:\n-.\$/\"|*()?{}'".codeUnits;

  static final List<int> _mixedChars = "0123456789&\r\t,:#-.\$/+%*=^".codeUnits;

  /// Table containing values for the exponent of 900.
  /// This is used in the numeric compaction decode algorithm.
  static final BigInt _nineHundred = BigInt.from(900);
  static final List<BigInt> exp900 =
      List.generate(16, (index) => _nineHundred.pow(index));

  static const int _NUMBER_OF_SEQUENCE_CODEWORDS = 2;

  DecodedBitStreamParser._();

  static DecoderResult decode(List<int> codewords, String ecLevel) {
    ECIStringBuilder result = ECIStringBuilder();
    // Get compaction mode
    int codeIndex = _textCompaction(codewords, 1, result);
    PDF417ResultMetadata resultMetadata = PDF417ResultMetadata();
    while (codeIndex < codewords[0]) {
      int code = codewords[codeIndex++];
      switch (code) {
        case _TEXT_COMPACTION_MODE_LATCH:
          codeIndex = _textCompaction(codewords, codeIndex, result);
          break;
        case _BYTE_COMPACTION_MODE_LATCH:
        case _BYTE_COMPACTION_MODE_LATCH_6:
          codeIndex = _byteCompaction(code, codewords, codeIndex, result);
          break;
        case _MODE_SHIFT_TO_BYTE_COMPACTION_MODE:
          result.writeCharCode(codewords[codeIndex++]);
          break;
        case _NUMERIC_COMPACTION_MODE_LATCH:
          codeIndex = _numericCompaction(codewords, codeIndex, result);
          break;
        case _ECI_CHARSET:
          result.appendECI(codewords[codeIndex++]);
          break;
        case _ECI_GENERAL_PURPOSE:
          // Can't do anything with generic ECI; skip its 2 characters
          codeIndex += 2;
          break;
        case _ECI_USER_DEFINED:
          // Can't do anything with user ECI; skip its 1 character
          codeIndex++;
          break;
        case _BEGIN_MACRO_PDF417_CONTROL_BLOCK:
          codeIndex = decodeMacroBlock(codewords, codeIndex, resultMetadata);
          break;
        case _BEGIN_MACRO_PDF417_OPTIONAL_FIELD:
        case _MACRO_PDF417_TERMINATOR:
          // Should not see these outside a macro block
          throw FormatsException.instance;
        default:
          // Default to text compaction. During testing numerous barcodes
          // appeared to be missing the starting mode. In these cases defaulting
          // to text compaction seems to work.
          codeIndex--;
          codeIndex = _textCompaction(codewords, codeIndex, result);
          break;
      }
    }
    if (result.isEmpty && resultMetadata.fileId == null) {
      throw FormatsException.instance;
    }
    DecoderResult decoderResult =
        DecoderResult(null, result.toString(), null, ecLevel);
    decoderResult.other = resultMetadata;
    return decoderResult;
  }

  // @SuppressWarnings("deprecation")
  static int decodeMacroBlock(
      List<int> codewords, int codeIndex, PDF417ResultMetadata resultMetadata) {
    if (codeIndex + _NUMBER_OF_SEQUENCE_CODEWORDS > codewords[0]) {
      // we must have at least two bytes left for the segment index
      throw FormatsException.instance;
    }
    List<int> segmentIndexArray = List.generate(
        _NUMBER_OF_SEQUENCE_CODEWORDS, (_) => codewords[codeIndex++]);
    //List<int> segmentIndexArray = List.filled(_NUMBER_OF_SEQUENCE_CODEWORDS, 0);
    //for (int i = 0; i < _NUMBER_OF_SEQUENCE_CODEWORDS; i++, codeIndex++) {
    //  segmentIndexArray[i] = codewords[codeIndex];
    //}

    String segmentIndexString = _decodeBase900toBase10(
        segmentIndexArray, _NUMBER_OF_SEQUENCE_CODEWORDS);
    if (segmentIndexString.isEmpty) {
      resultMetadata.segmentIndex = 0;
    } else {
      try {
        resultMetadata.segmentIndex = int.parse(segmentIndexString);
      } on FormatException catch (_) {
        throw FormatsException.instance;
      }
    }

    // Decoding the fileId codewords as 0-899 numbers, each 0-filled to width 3. This follows the spec
    // (See ISO/IEC 15438:2015 Annex H.6) and preserves all info, but some generators (e.g. TEC-IT) write
    // the fileId using text compaction, so in those cases the fileId will appear mangled.
    StringBuffer fileId = StringBuffer();
    while (codeIndex < codewords[0] &&
        codeIndex < codewords.length &&
        codewords[codeIndex] != _MACRO_PDF417_TERMINATOR &&
        codewords[codeIndex] != _BEGIN_MACRO_PDF417_OPTIONAL_FIELD) {
      fileId.write(codewords[codeIndex].toString().padLeft(3, '0'));
      codeIndex++;
    }
    if (fileId.isEmpty) {
      // at least one fileId codeword is required (Annex H.2)
      throw FormatsException.instance;
    }
    resultMetadata.fileId = fileId.toString();

    int optionalFieldsStart = -1;
    if (codewords[codeIndex] == _BEGIN_MACRO_PDF417_OPTIONAL_FIELD) {
      optionalFieldsStart = codeIndex + 1;
    }

    while (codeIndex < codewords[0]) {
      switch (codewords[codeIndex]) {
        case _BEGIN_MACRO_PDF417_OPTIONAL_FIELD:
          codeIndex++;
          switch (codewords[codeIndex]) {
            case _MACRO_PDF417_OPTIONAL_FIELD_FILE_NAME:
              ECIStringBuilder fileName = ECIStringBuilder();
              codeIndex = _textCompaction(codewords, codeIndex + 1, fileName);
              resultMetadata.fileName = fileName.toString();
              break;
            case _MACRO_PDF417_OPTIONAL_FIELD_SENDER:
              ECIStringBuilder sender = ECIStringBuilder();
              codeIndex = _textCompaction(codewords, codeIndex + 1, sender);
              resultMetadata.sender = sender.toString();
              break;
            case _MACRO_PDF417_OPTIONAL_FIELD_ADDRESSEE:
              ECIStringBuilder addressee = ECIStringBuilder();
              codeIndex = _textCompaction(codewords, codeIndex + 1, addressee);
              resultMetadata.addressee = addressee.toString();
              break;
            case _MACRO_PDF417_OPTIONAL_FIELD_SEGMENT_COUNT:
              ECIStringBuilder segmentCount = ECIStringBuilder();
              codeIndex =
                  _numericCompaction(codewords, codeIndex + 1, segmentCount);
              resultMetadata.segmentCount = int.parse(segmentCount.toString());
              break;
            case _MACRO_PDF417_OPTIONAL_FIELD_TIME_STAMP:
              ECIStringBuilder timestamp = ECIStringBuilder();
              codeIndex =
                  _numericCompaction(codewords, codeIndex + 1, timestamp);
              resultMetadata.timestamp = int.parse(timestamp.toString());
              break;
            case _MACRO_PDF417_OPTIONAL_FIELD_CHECKSUM:
              ECIStringBuilder checksum = ECIStringBuilder();
              codeIndex =
                  _numericCompaction(codewords, codeIndex + 1, checksum);
              resultMetadata.checksum = int.parse(checksum.toString());
              break;
            case _MACRO_PDF417_OPTIONAL_FIELD_FILE_SIZE:
              ECIStringBuilder fileSize = ECIStringBuilder();
              codeIndex =
                  _numericCompaction(codewords, codeIndex + 1, fileSize);
              resultMetadata.fileSize = int.parse(fileSize.toString());
              break;
            default:
              throw FormatsException.instance;
          }
          break;
        case _MACRO_PDF417_TERMINATOR:
          codeIndex++;
          resultMetadata.isLastSegment = true;
          break;
        default:
          throw FormatsException.instance;
      }
    }

    // copy optional fields to additional options
    if (optionalFieldsStart != -1) {
      int optionalFieldsLength = codeIndex - optionalFieldsStart;
      if (resultMetadata.isLastSegment) {
        // do not include terminator
        optionalFieldsLength--;
      }

      // ignore: deprecated_consistency
      resultMetadata.optionalData = codewords.sublist(
          optionalFieldsStart, optionalFieldsStart + optionalFieldsLength);
    }

    return codeIndex;
  }

  /// Text Compaction mode (see 5.4.1.5) permits all printable ASCII characters to be
  /// encoded, i.e. values 32 - 126 inclusive in accordance with ISO/IEC 646 (IRV), as
  /// well as selected control characters.
  ///
  /// @param codewords The array of codewords (data + error)
  /// @param codeIndex The current index into the codeword array.
  /// @param result    The decoded data is appended to the result.
  /// @return The next index into the codeword array.
  static int _textCompaction(
      List<int> codewords, int codeIndex, ECIStringBuilder result) {
    // 2 character per codeword
    List<int> textCompactionData =
        List.filled((codewords[0] - codeIndex) * 2, 0);
    // Used to hold the byte compaction value if there is a mode shift
    List<int> byteCompactionData =
        List.filled((codewords[0] - codeIndex) * 2, 0);

    int index = 0;
    bool end = false;
    _Mode subMode = _Mode.ALPHA;
    while ((codeIndex < codewords[0]) && !end) {
      int code = codewords[codeIndex++];
      if (code < _TEXT_COMPACTION_MODE_LATCH) {
        textCompactionData[index] = code ~/ 30;
        textCompactionData[index + 1] = code % 30;
        index += 2;
      } else {
        switch (code) {
          case _TEXT_COMPACTION_MODE_LATCH:
            // reinitialize text compaction mode to alpha sub mode
            textCompactionData[index++] = _TEXT_COMPACTION_MODE_LATCH;
            break;
          case _BYTE_COMPACTION_MODE_LATCH:
          case _BYTE_COMPACTION_MODE_LATCH_6:
          case _NUMERIC_COMPACTION_MODE_LATCH:
          case _BEGIN_MACRO_PDF417_CONTROL_BLOCK:
          case _BEGIN_MACRO_PDF417_OPTIONAL_FIELD:
          case _MACRO_PDF417_TERMINATOR:
            codeIndex--;
            end = true;
            break;
          case _MODE_SHIFT_TO_BYTE_COMPACTION_MODE:
            // The Mode Shift codeword 913 shall cause a temporary
            // switch from Text Compaction mode to Byte Compaction mode.
            // This switch shall be in effect for only the next codeword,
            // after which the mode shall revert to the prevailing sub-mode
            // of the Text Compaction mode. Codeword 913 is only available
            // in Text Compaction mode; its use is described in 5.4.2.4.
            textCompactionData[index] = _MODE_SHIFT_TO_BYTE_COMPACTION_MODE;
            code = codewords[codeIndex++];
            byteCompactionData[index] = code;
            index++;
            break;
          case _ECI_CHARSET:
            subMode = _decodeTextCompaction(
                textCompactionData, byteCompactionData, index, result, subMode);
            result.appendECI(codewords[codeIndex++]);
            textCompactionData = List.filled((codewords[0] - codeIndex) * 2, 0);
            byteCompactionData = List.filled((codewords[0] - codeIndex) * 2, 0);
            index = 0;
            break;
        }
      }
    }
    _decodeTextCompaction(
      textCompactionData,
      byteCompactionData,
      index,
      result,
      subMode,
    );
    return codeIndex;
  }

  /// The Text Compaction mode includes all the printable ASCII characters
  /// (i.e. values from 32 to 126) and three ASCII control characters: HT or tab
  /// (ASCII value 9), LF or line feed (ASCII value 10), and CR or carriage
  /// return (ASCII value 13). The Text Compaction mode also includes various latch
  /// and shift characters which are used exclusively within the mode. The Text
  /// Compaction mode encodes up to 2 characters per codeword. The compaction rules
  /// for converting data into PDF417 codewords are defined in 5.4.2.2. The sub-mode
  /// switches are defined in 5.4.2.3.
  ///
  /// @param textCompactionData The text compaction data.
  /// @param byteCompactionData The byte compaction data if there
  ///                           was a mode shift.
  /// @param length             The size of the text compaction and byte compaction data.
  /// @param result             The decoded data is appended to the result.
  static _Mode _decodeTextCompaction(
      List<int> textCompactionData,
      List<int> byteCompactionData,
      int length,
      ECIStringBuilder result,
      _Mode startMode) {
    // Beginning from an initial state of the Alpha sub-mode
    // The default compaction mode for PDF417 in effect at the start of each symbol shall always be Text
    // Compaction mode Alpha sub-mode (uppercase alphabetic). A latch codeword from another mode to the Text
    // Compaction mode shall always switch to the Text Compaction Alpha sub-mode.
    _Mode subMode = startMode;
    _Mode priorToShiftMode = startMode;
    _Mode latchedMode = startMode;
    int i = 0;
    while (i < length) {
      int subModeCh = textCompactionData[i];
      int ch = 0;
      switch (subMode) {
        case _Mode.ALPHA:
          // Alpha (uppercase alphabetic)
          if (subModeCh < 26) {
            // Upper case Alpha Character
            ch = 65 /* A */ + subModeCh;
          } else {
            switch (subModeCh) {
              case 26:
                ch = 32 /*   */;
                break;
              case _LL:
                subMode = _Mode.LOWER;
                latchedMode = subMode;
                break;
              case _ML:
                subMode = _Mode.MIXED;
                latchedMode = subMode;
                break;
              case _PS:
                // Shift to punctuation
                priorToShiftMode = subMode;
                subMode = _Mode.PUNCT_SHIFT;
                break;
              case _MODE_SHIFT_TO_BYTE_COMPACTION_MODE:
                result.writeCharCode(byteCompactionData[i]);
                break;
              case _TEXT_COMPACTION_MODE_LATCH:
                subMode = _Mode.ALPHA;
                latchedMode = subMode;
                break;
            }
          }
          break;

        case _Mode.LOWER:
          // Lower (lowercase alphabetic)
          if (subModeCh < 26) {
            ch = 97 /* a */ + subModeCh;
          } else {
            switch (subModeCh) {
              case 26:
                ch = 32 /*   */;
                break;
              case _AS:
                // Shift to alpha
                priorToShiftMode = subMode;
                subMode = _Mode.ALPHA_SHIFT;
                break;
              case _ML:
                subMode = _Mode.MIXED;
                latchedMode = subMode;
                break;
              case _PS:
                // Shift to punctuation
                priorToShiftMode = subMode;
                subMode = _Mode.PUNCT_SHIFT;
                break;
              case _MODE_SHIFT_TO_BYTE_COMPACTION_MODE:
                result.writeCharCode(byteCompactionData[i]);
                break;
              case _TEXT_COMPACTION_MODE_LATCH:
                subMode = _Mode.ALPHA;
                latchedMode = subMode;
                break;
            }
          }
          break;

        case _Mode.MIXED:
          // Mixed (numeric and some punctuation)
          if (subModeCh < _PL) {
            ch = _mixedChars[subModeCh];
          } else {
            switch (subModeCh) {
              case _PL:
                subMode = _Mode.PUNCT;
                latchedMode = subMode;
                break;
              case 26:
                ch = 32 /*   */;
                break;
              case _LL:
                subMode = _Mode.LOWER;
                latchedMode = subMode;
                break;
              case _AL:
              case _TEXT_COMPACTION_MODE_LATCH:
                subMode = _Mode.ALPHA;
                latchedMode = subMode;
                break;
              case _PS:
                // Shift to punctuation
                priorToShiftMode = subMode;
                subMode = _Mode.PUNCT_SHIFT;
                break;
              case _MODE_SHIFT_TO_BYTE_COMPACTION_MODE:
                result.writeCharCode(byteCompactionData[i]);
                break;
            }
          }
          break;

        case _Mode.PUNCT:
          // Punctuation
          if (subModeCh < _PAL) {
            ch = _punctChars[subModeCh];
          } else {
            switch (subModeCh) {
              case _PAL:
              case _TEXT_COMPACTION_MODE_LATCH:
                subMode = _Mode.ALPHA;
                latchedMode = subMode;
                break;
              case _MODE_SHIFT_TO_BYTE_COMPACTION_MODE:
                result.writeCharCode(byteCompactionData[i]);
                break;
            }
          }
          break;

        case _Mode.ALPHA_SHIFT:
          // Restore sub-mode
          subMode = priorToShiftMode;
          if (subModeCh < 26) {
            ch = 65 /* A */ + subModeCh;
          } else {
            switch (subModeCh) {
              case 26:
                ch = 32 /*   */;
                break;
              case _TEXT_COMPACTION_MODE_LATCH:
                subMode = _Mode.ALPHA;
                break;
            }
          }
          break;

        case _Mode.PUNCT_SHIFT:
          // Restore sub-mode
          subMode = priorToShiftMode;
          if (subModeCh < _PAL) {
            ch = _punctChars[subModeCh];
          } else {
            switch (subModeCh) {
              case _PAL:
              case _TEXT_COMPACTION_MODE_LATCH:
                subMode = _Mode.ALPHA;
                break;
              case _MODE_SHIFT_TO_BYTE_COMPACTION_MODE:
                // PS before Shift-to-Byte is used as a padding character,
                // see 5.4.2.4 of the specification
                result.writeCharCode(byteCompactionData[i]);
                break;
            }
          }
          break;
      }
      if (ch != 0) {
        // Append decoded character to result
        result.writeCharCode(ch);
      }
      i++;
    }
    return latchedMode;
  }

  /// Byte Compaction mode (see 5.4.3) permits all 256 possible 8-bit byte values to be encoded.
  /// This includes all ASCII characters value 0 to 127 inclusive and provides for international
  /// character set support.
  ///
  /// @param mode      The byte compaction mode i.e. 901 or 924
  /// @param codewords The array of codewords (data + error)
  /// @param codeIndex The current index into the codeword array.
  /// @param result    The decoded data is appended to the result.
  /// @return The next index into the codeword array.
  static int _byteCompaction(
      int mode, List<int> codewords, int codeIndex, ECIStringBuilder result) {
    bool end = false;

    while (codeIndex < codewords[0] && !end) {
      //handle leading ECIs
      while (codeIndex < codewords[0] && codewords[codeIndex] == _ECI_CHARSET) {
        result.appendECI(codewords[++codeIndex]);
        codeIndex++;
      }

      if (codeIndex >= codewords[0] ||
          codewords[codeIndex] >= _TEXT_COMPACTION_MODE_LATCH) {
        end = true;
      } else {
        //decode one block of 5 codewords to 6 bytes
        int value = 0;
        int count = 0;
        do {
          value = 900 * value + codewords[codeIndex++];
          count++;
        } while (count < 5 &&
            codeIndex < codewords[0] &&
            codewords[codeIndex] < _TEXT_COMPACTION_MODE_LATCH);
        if (count == 5 &&
            (mode == _BYTE_COMPACTION_MODE_LATCH_6 ||
                codeIndex < codewords[0] &&
                    codewords[codeIndex] < _TEXT_COMPACTION_MODE_LATCH)) {
          for (int i = 0; i < 6; i++) {
            result.writeCharCode((value >> (8 * (5 - i))) & 0xff);
          }
        } else {
          codeIndex -= count;
          while ((codeIndex < codewords[0]) && !end) {
            int code = codewords[codeIndex++];
            if (code < _TEXT_COMPACTION_MODE_LATCH) {
              result.writeCharCode(code);
            } else if (code == _ECI_CHARSET) {
              result.appendECI(codewords[codeIndex++]);
            } else {
              codeIndex--;
              end = true;
            }
          }
        }
      }
    }
    return codeIndex;
  }

  /// Numeric Compaction mode (see 5.4.4) permits efficient encoding of numeric data strings.
  ///
  /// @param codewords The array of codewords (data + error)
  /// @param codeIndex The current index into the codeword array.
  /// @param result    The decoded data is appended to the result.
  /// @return The next index into the codeword array.
  static int _numericCompaction(
      List<int> codewords, int codeIndex, ECIStringBuilder result) {
    int count = 0;
    bool end = false;

    List<int> numericCodewords = List.filled(_MAX_NUMERIC_CODEWORDS, 0);

    while (codeIndex < codewords[0] && !end) {
      int code = codewords[codeIndex++];
      if (codeIndex == codewords[0]) {
        end = true;
      }
      if (code < _TEXT_COMPACTION_MODE_LATCH) {
        numericCodewords[count] = code;
        count++;
      } else {
        switch (code) {
          case _TEXT_COMPACTION_MODE_LATCH:
          case _BYTE_COMPACTION_MODE_LATCH:
          case _BYTE_COMPACTION_MODE_LATCH_6:
          case _BEGIN_MACRO_PDF417_CONTROL_BLOCK:
          case _BEGIN_MACRO_PDF417_OPTIONAL_FIELD:
          case _MACRO_PDF417_TERMINATOR:
          case _ECI_CHARSET:
            codeIndex--;
            end = true;
            break;
        }
      }
      if ((count % _MAX_NUMERIC_CODEWORDS == 0 ||
              code == _NUMERIC_COMPACTION_MODE_LATCH ||
              end) &&
          count > 0) {
        // Re-invoking Numeric Compaction mode (by using codeword 902
        // while in Numeric Compaction mode) serves  to terminate the
        // current Numeric Compaction mode grouping as described in 5.4.4.2,
        // and then to start a new one grouping.
        result.write(_decodeBase900toBase10(numericCodewords, count));
        count = 0;
      }
    }
    return codeIndex;
  }

  /// Convert a list of Numeric Compacted codewords from Base 900 to Base 10.
  ///
  /// @param codewords The array of codewords
  /// @param count     The number of codewords
  /// @return The decoded string representing the Numeric data.
  /*
     EXAMPLE
     Encode the fifteen digit numeric string 000213298174000
     Prefix the numeric string with a 1 and set the initial value of
     t = 1 000 213 298 174 000
     Calculate codeword 0
     d0 = 1 000 213 298 174 000 mod 900 = 200

     t = 1 000 213 298 174 000 div 900 = 1 111 348 109 082
     Calculate codeword 1
     d1 = 1 111 348 109 082 mod 900 = 282

     t = 1 111 348 109 082 div 900 = 1 234 831 232
     Calculate codeword 2
     d2 = 1 234 831 232 mod 900 = 632

     t = 1 234 831 232 div 900 = 1 372 034
     Calculate codeword 3
     d3 = 1 372 034 mod 900 = 434

     t = 1 372 034 div 900 = 1 524
     Calculate codeword 4
     d4 = 1 524 mod 900 = 624

     t = 1 524 div 900 = 1
     Calculate codeword 5
     d5 = 1 mod 900 = 1
     t = 1 div 900 = 0
     Codeword sequence is: 1, 624, 434, 632, 282, 200

     Decode the above codewords involves
       1 x 900 power of 5 + 624 x 900 power of 4 + 434 x 900 power of 3 +
     632 x 900 power of 2 + 282 x 900 power of 1 + 200 x 900 power of 0 = 1000213298174000

     Remove leading 1 =>  Result is 000213298174000
   */
  static String _decodeBase900toBase10(List<int> codewords, int count) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < count; i++) {
      result = result + (exp900[count - i - 1] * (BigInt.from(codewords[i])));
    }
    String resultString = result.toString();
    if (resultString[0] != '1') {
      throw FormatsException.instance;
    }
    return resultString.substring(1);
  }
}
