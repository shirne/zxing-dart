/*
 * Copyright 2006 Jeremias Maerki in part, and ZXing Authors in part
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * This file has been modified from its original form in Barcode4J.
 */

import 'dart:math' as Math;
import 'dart:convert';
import 'dart:typed_data';

import 'package:zxing/core/common/character_set_eci.dart';
import 'package:zxing/core/common/string_builder.dart';

import '../../writer_exception.dart';
import 'compaction.dart';

/**
 * PDF417 high-level encoder following the algorithm described in ISO/IEC 15438:2001(E) in
 * annex P.
 */
class PDF417HighLevelEncoder {
  static final int blankCode = ' '.codeUnitAt(0);
  /**
   * code for Text compaction
   */
  static const int TEXT_COMPACTION = 0;

  /**
   * code for Byte compaction
   */
  static const int BYTE_COMPACTION = 1;

  /**
   * code for Numeric compaction
   */
  static const int NUMERIC_COMPACTION = 2;

  /**
   * Text compaction submode Alpha
   */
  static const int SUBMODE_ALPHA = 0;

  /**
   * Text compaction submode Lower
   */
  static const int SUBMODE_LOWER = 1;

  /**
   * Text compaction submode Mixed
   */
  static const int SUBMODE_MIXED = 2;

  /**
   * Text compaction submode Punctuation
   */
  static const int SUBMODE_PUNCTUATION = 3;

  /**
   * mode latch to Text Compaction mode
   */
  static const int LATCH_TO_TEXT = 900;

  /**
   * mode latch to Byte Compaction mode (number of characters NOT a multiple of 6)
   */
  static const int LATCH_TO_BYTE_PADDED = 901;

  /**
   * mode latch to Numeric Compaction mode
   */
  static const int LATCH_TO_NUMERIC = 902;

  /**
   * mode shift to Byte Compaction mode
   */
  static const int SHIFT_TO_BYTE = 913;

  /**
   * mode latch to Byte Compaction mode (number of characters a multiple of 6)
   */
  static const int LATCH_TO_BYTE = 924;

  /**
   * identifier for a user defined Extended Channel Interpretation (ECI)
   */
  static const int ECI_USER_DEFINED = 925;

  /**
   * identifier for a general purpose ECO format
   */
  static const int ECI_GENERAL_PURPOSE = 926;

  /**
   * identifier for an ECI of a character set of code page
   */
  static const int ECI_CHARSET = 927;

  /**
   * Raw code table for text compaction Mixed sub-mode
   */
  static const List<int> TEXT_MIXED_RAW = [
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 38, 13, 9, 44, 58, //
    35, 45, 46, 36, 47, 43, 37, 42, 61, 94, 0, 32, 0, 0, 0
  ];

  /**
   * Raw code table for text compaction: Punctuation sub-mode
   */
  static final List<int> TEXT_PUNCTUATION_RAW = [
    59, 60, 62, 64, 91, 92, 93, 95, 96, 126, 33, 13, 9, 44, 58, //
    10, 45, 46, 36, 47, 34, 124, 42, 40, 41, 63, 123, 125, 39, 0
  ];

  static final Uint8List MIXED = Uint8List.fromList(
      List.generate(128, (index) => TEXT_MIXED_RAW.indexOf(index)));
  static final Uint8List PUNCTUATION = Uint8List.fromList(
      List.generate(128, (index) => TEXT_PUNCTUATION_RAW.indexOf(index)));

  static final Encoding DEFAULT_ENCODING = latin1;

  PDF417HighLevelEncoder();

  /**
   * Performs high-level encoding of a PDF417 message using the algorithm described in annex P
   * of ISO/IEC 15438:2001(E). If byte compaction has been selected, then only byte compaction
   * is used.
   *
   * @param msg the message
   * @param compaction compaction mode to use
   * @param encoding character encoding used to encode in default or byte compaction
   *  or {@code null} for default / not applicable
   * @return the encoded message (the char values range from 0 to 928)
   */
  static String encodeHighLevel(
      String msg, Compaction compaction, Encoding? encoding) {
    //the codewords 0..928 are encoded as Unicode characters
    StringBuffer sb = new StringBuffer(msg.length);

    if (encoding == null) {
      encoding = DEFAULT_ENCODING;
    } else if (DEFAULT_ENCODING != encoding) {
      CharacterSetECI? eci = CharacterSetECI.getCharacterSetECI(encoding);
      if (eci != null) {
        encodingECI(eci.getValue(), sb);
      }
    }

    int len = msg.length;
    int p = 0;
    int textSubMode = SUBMODE_ALPHA;

    // User selected encoding mode
    switch (compaction) {
      case Compaction.TEXT:
        encodeText(msg, p, len, sb, textSubMode);
        break;
      case Compaction.BYTE:
        Uint8List msgBytes = Uint8List.fromList(encoding.encode(msg));
        encodeBinary(msgBytes, p, msgBytes.length, BYTE_COMPACTION, sb);
        break;
      case Compaction.NUMERIC:
        sb.writeCharCode(LATCH_TO_NUMERIC);
        encodeNumeric(msg, p, len, sb);
        break;
      default:
        int encodingMode = TEXT_COMPACTION; //Default mode, see 4.4.2.1
        while (p < len) {
          int n = determineConsecutiveDigitCount(msg, p);
          if (n >= 13) {
            sb.writeCharCode(LATCH_TO_NUMERIC);
            encodingMode = NUMERIC_COMPACTION;
            textSubMode = SUBMODE_ALPHA; //Reset after latch
            encodeNumeric(msg, p, n, sb);
            p += n;
          } else {
            int t = determineConsecutiveTextCount(msg, p);
            if (t >= 5 || n == len) {
              if (encodingMode != TEXT_COMPACTION) {
                sb.writeCharCode(LATCH_TO_TEXT);
                encodingMode = TEXT_COMPACTION;
                textSubMode =
                    SUBMODE_ALPHA; //start with submode alpha after latch
              }
              textSubMode = encodeText(msg, p, t, sb, textSubMode);
              p += t;
            } else {
              int b = determineConsecutiveBinaryCount(msg, p, encoding);
              if (b == 0) {
                b = 1;
              }
              Uint8List bytes =
                  Uint8List.fromList(encoding.encode(msg.substring(p, p + b)));
              if (bytes.length == 1 && encodingMode == TEXT_COMPACTION) {
                //Switch for one byte (instead of latch)
                encodeBinary(bytes, 0, 1, TEXT_COMPACTION, sb);
              } else {
                //Mode latch performed by encodeBinary()
                encodeBinary(bytes, 0, bytes.length, encodingMode, sb);
                encodingMode = BYTE_COMPACTION;
                textSubMode = SUBMODE_ALPHA; //Reset after latch
              }
              p += b;
            }
          }
        }
        break;
    }

    return sb.toString();
  }

  /**
   * Encode parts of the message using Text Compaction as described in ISO/IEC 15438:2001(E),
   * chapter 4.4.2.
   *
   * @param msg            the message
   * @param startpos       the start position within the message
   * @param count          the number of characters to encode
   * @param sb             receives the encoded codewords
   * @param initialSubmode should normally be SUBMODE_ALPHA
   * @return the text submode in which this method ends
   */
  static int encodeText(String msg, int startpos, int count, StringBuffer sb,
      int initialSubmode) {
    StringBuilder tmp = new StringBuilder();
    int submode = initialSubmode;
    int idx = 0;
    while (true) {
      int ch = msg.codeUnitAt(startpos + idx);
      switch (submode) {
        case SUBMODE_ALPHA:
          if (isAlphaUpper(ch)) {
            if (ch == blankCode) {
              tmp.writeCharCode(26); //space
            } else {
              tmp.write(String.fromCharCode(ch - 65));
            }
          } else {
            if (isAlphaLower(ch)) {
              submode = SUBMODE_LOWER;
              tmp.writeCharCode(27); //ll
              continue;
            } else if (isMixed(ch)) {
              submode = SUBMODE_MIXED;
              tmp.writeCharCode(28); //ml
              continue;
            } else {
              tmp.writeCharCode(29); //ps
              tmp.writeCharCode(PUNCTUATION[ch]);
              break;
            }
          }
          break;
        case SUBMODE_LOWER:
          if (isAlphaLower(ch)) {
            if (ch == blankCode) {
              tmp.writeCharCode(26); //space
            } else {
              tmp.writeCharCode(ch - 97);
            }
          } else {
            if (isAlphaUpper(ch)) {
              tmp.writeCharCode(27); //as
              tmp.writeCharCode(ch - 65);
              //space cannot happen here, it is also in "Lower"
              break;
            } else if (isMixed(ch)) {
              submode = SUBMODE_MIXED;
              tmp.writeCharCode(28); //ml
              continue;
            } else {
              tmp.writeCharCode(29); //ps
              tmp.writeCharCode(PUNCTUATION[ch]);
              break;
            }
          }
          break;
        case SUBMODE_MIXED:
          if (isMixed(ch)) {
            tmp.writeCharCode(MIXED[ch]);
          } else {
            if (isAlphaUpper(ch)) {
              submode = SUBMODE_ALPHA;
              tmp.writeCharCode(28); //al
              continue;
            } else if (isAlphaLower(ch)) {
              submode = SUBMODE_LOWER;
              tmp.writeCharCode(27); //ll
              continue;
            } else {
              if (startpos + idx + 1 < count) {
                int next = msg.codeUnitAt(startpos + idx + 1);
                if (isPunctuation(next)) {
                  submode = SUBMODE_PUNCTUATION;
                  tmp.writeCharCode(25); //pl
                  continue;
                }
              }
              tmp.writeCharCode(29); //ps
              tmp.writeCharCode(PUNCTUATION[ch]);
            }
          }
          break;
        default: //SUBMODE_PUNCTUATION
          if (isPunctuation(ch)) {
            tmp.writeCharCode(PUNCTUATION[ch]);
          } else {
            submode = SUBMODE_ALPHA;
            tmp.writeCharCode(29); //al
            continue;
          }
      }
      idx++;
      if (idx >= count) {
        break;
      }
    }
    int h = 0;
    int len = tmp.length;
    for (int i = 0; i < len; i++) {
      bool odd = (i % 2) != 0;
      if (odd) {
        h = (h * 30) + tmp.codePointAt(i);
        sb.writeCharCode(h);
      } else {
        h = tmp.codePointAt(i);
      }
    }
    if ((len % 2) != 0) {
      sb.writeCharCode((h * 30) + 29); //ps
    }
    return submode;
  }

  /**
   * Encode parts of the message using Byte Compaction as described in ISO/IEC 15438:2001(E),
   * chapter 4.4.3. The Unicode characters will be converted to binary using the cp437
   * codepage.
   *
   * @param bytes     the message converted to a byte array
   * @param startpos  the start position within the message
   * @param count     the number of bytes to encode
   * @param startmode the mode from which this method starts
   * @param sb        receives the encoded codewords
   */
  static void encodeBinary(Uint8List bytes, int startpos, int count,
      int startmode, StringBuffer sb) {
    if (count == 1 && startmode == TEXT_COMPACTION) {
      sb.writeCharCode(SHIFT_TO_BYTE);
    } else {
      if ((count % 6) == 0) {
        sb.writeCharCode(LATCH_TO_BYTE);
      } else {
        sb.writeCharCode(LATCH_TO_BYTE_PADDED);
      }
    }

    int idx = startpos;
    // Encode sixpacks
    if (count >= 6) {
      List<int> chars = [0, 0, 0, 0, 0];
      while ((startpos + count - idx) >= 6) {
        int t = 0;
        for (int i = 0; i < 6; i++) {
          t <<= 8;
          t += bytes[idx + i] & 0xff;
        }
        for (int i = 0; i < 5; i++) {
          chars[i] = t % 900;
          t = t ~/ 900;
        }
        for (int i = chars.length - 1; i >= 0; i--) {
          sb.writeCharCode(chars[i]);
        }
        idx += 6;
      }
    }
    //Encode rest (remaining n<5 bytes if any)
    for (int i = idx; i < startpos + count; i++) {
      int ch = bytes[i] & 0xff;
      sb.writeCharCode(ch);
    }
  }

  static void encodeNumeric(
      String msg, int startpos, int count, StringBuffer sb) {
    int idx = 0;
    StringBuilder tmp = new StringBuilder();
    BigInt num900 = BigInt.from(900);
    BigInt num0 = BigInt.from(0);
    while (idx < count) {
      tmp.clear();
      int len = Math.min(44, count - idx);
      String part = '1' + msg.substring(startpos + idx, startpos + idx + len);
      BigInt bigint = BigInt.parse(part);
      do {
        tmp.writeCharCode((bigint % num900).toInt());
        bigint = bigint ~/ num900;
      } while (bigint != num0);

      //Reverse temporary string
      for (int i = tmp.length - 1; i >= 0; i--) {
        sb.writeCharCode(tmp.codePointAt(i));
      }
      idx += len;
    }
  }

  static bool isDigit(int ch) {
    return ch >= '0'.codeUnitAt(0) && ch <= '9'.codeUnitAt(0);
  }

  static bool isAlphaUpper(int ch) {
    return ch == blankCode ||
        (ch >= 'A'.codeUnitAt(0) && ch <= 'Z'.codeUnitAt(0));
  }

  static bool isAlphaLower(int ch) {
    return ch == blankCode ||
        (ch >= 'a'.codeUnitAt(0) && ch <= 'z'.codeUnitAt(0));
  }

  static bool isMixed(int ch) {
    return MIXED[ch] != -1;
  }

  static bool isPunctuation(int ch) {
    return PUNCTUATION[ch] != -1;
  }

  static bool isText(String chr) {
    int ch = chr.codeUnitAt(0);
    return chr == '\t' || chr == '\n' || chr == '\r' || (ch >= 32 && ch <= 126);
  }

  /**
   * Determines the number of consecutive characters that are encodable using numeric compaction.
   *
   * @param msg      the message
   * @param startpos the start position within the message
   * @return the requested character count
   */
  static int determineConsecutiveDigitCount(String msg, int startpos) {
    int count = 0;
    int len = msg.length;
    int idx = startpos;
    if (idx < len) {
      int ch = msg.codeUnitAt(idx);
      while (isDigit(ch) && idx < len) {
        count++;
        idx++;
        if (idx < len) {
          ch = msg.codeUnitAt(idx);
        }
      }
    }
    return count;
  }

  /**
   * Determines the number of consecutive characters that are encodable using text compaction.
   *
   * @param msg      the message
   * @param startpos the start position within the message
   * @return the requested character count
   */
  static int determineConsecutiveTextCount(String msg, int startpos) {
    int len = msg.length;
    int idx = startpos;
    while (idx < len) {
      int ch = msg.codeUnitAt(idx);
      int numericCount = 0;
      while (numericCount < 13 && isDigit(ch) && idx < len) {
        numericCount++;
        idx++;
        if (idx < len) {
          ch = msg.codeUnitAt(idx);
        }
      }
      if (numericCount >= 13) {
        return idx - startpos - numericCount;
      }
      if (numericCount > 0) {
        //Heuristic: All text-encodable chars or digits are binary encodable
        continue;
      }
      ch = msg.codeUnitAt(idx);

      //Check if character is encodable
      if (!isText(String.fromCharCode(ch))) {
        break;
      }
      idx++;
    }
    return idx - startpos;
  }

  /**
   * Determines the number of consecutive characters that are encodable using binary compaction.
   *
   * @param msg      the message
   * @param startpos the start position within the message
   * @param encoding the charset used to convert the message to a byte array
   * @return the requested character count
   */
  static int determineConsecutiveBinaryCount(
      String msg, int startpos, Encoding encoding) {

    int len = msg.length;
    int idx = startpos;
    while (idx < len) {
      int ch = msg.codeUnitAt(idx);
      int numericCount = 0;

      while (numericCount < 13 && isDigit(ch)) {
        numericCount++;
        //textCount++;
        int i = idx + numericCount;
        if (i >= len) {
          break;
        }
        ch = msg.codeUnitAt(i);
      }
      if (numericCount >= 13) {
        return idx - startpos;
      }
      ch = msg.codeUnitAt(idx);

      // todo 判断是否超出字符集
      //if (!encoder.canEncode(ch)) {
      //  throw WriterException(
      //      "Non-encodable character detected: ${String.fromCharCode(ch)} (Unicode: $ch)");
      //}
      idx++;
    }
    return idx - startpos;
  }

  static void encodingECI(int eci, StringBuffer sb) {
    if (eci >= 0 && eci < 900) {
      sb.writeCharCode(ECI_CHARSET);
      sb.writeCharCode(eci);
    } else if (eci < 810900) {
      sb.writeCharCode(ECI_GENERAL_PURPOSE);
      sb.writeCharCode((eci ~/ 900 - 1));
      sb.writeCharCode((eci % 900));
    } else if (eci < 811800) {
      sb.writeCharCode(ECI_USER_DEFINED);
      sb.writeCharCode((810900 - eci));
    } else {
      throw new WriterException(
          "ECI number not in valid range from 0..811799, but was $eci");
    }
  }
}
