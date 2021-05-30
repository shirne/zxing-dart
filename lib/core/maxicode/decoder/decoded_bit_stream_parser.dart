/*
 * Copyright 2011 ZXing authors
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

import '../../common/decoder_result.dart';
import '../../common/string_builder.dart';

/**
 * <p>MaxiCodes can encode text or structured information as bits in one of several modes,
 * with multiple character sets in one code. This class decodes the bits back into text.</p>
 *
 * @author mike32767
 * @author Manuel Kasten
 */
class DecodedBitStreamParser {
  static const String SHIFTA = '\uFFF0';
  static const String SHIFTB = '\uFFF1';
  static const String SHIFTC = '\uFFF2';
  static const String SHIFTD = '\uFFF3';
  static const String SHIFTE = '\uFFF4';
  static const String TWOSHIFTA = '\uFFF5';
  static const String THREESHIFTA = '\uFFF6';
  static const String LATCHA = '\uFFF7';
  static const String LATCHB = '\uFFF8';
  static const String LOCK = '\uFFF9';
  static const String ECI = '\uFFFA';
  static const String NS = '\uFFFB';
  static const String PAD = '\uFFFC';
  static const String FS = '\u001C';
  static const String GS = '\u001D';
  static const String RS = '\u001E';

  static final List<String> SETS = [
    "\nABCDEFGHIJKLMNOPQRSTUVWXYZ" +
        ECI +
        FS +
        GS +
        RS +
        NS +
        ' ' +
        PAD + //
        '"' +
        r"#$%&'()*+,-./0123456789:" +
        SHIFTB +
        SHIFTC +
        SHIFTD +
        SHIFTE +
        LATCHB,
    "`abcdefghijklmnopqrstuvwxyz" +
        ECI +
        FS +
        GS +
        RS +
        NS +
        '{' +
        PAD +
        "}~\u007F;<=>?[\\]^_ ,./:@!|" +
        PAD +
        TWOSHIFTA +
        THREESHIFTA +
        PAD +
        SHIFTA +
        SHIFTC +
        SHIFTD +
        SHIFTE +
        LATCHA,
    "\u00C0\u00C1\u00C2\u00C3\u00C4\u00C5\u00C6\u00C7\u00C8\u00C9\u00CA\u00CB\u00CC\u00CD\u00CE\u00CF\u00D0\u00D1\u00D2\u00D3\u00D4\u00D5\u00D6\u00D7\u00D8\u00D9\u00DA" +
        ECI +
        FS +
        GS +
        RS +
        NS +
        "\u00DB\u00DC\u00DD\u00DE\u00DF\u00AA\u00AC\u00B1\u00B2\u00B3\u00B5\u00B9\u00BA\u00BC\u00BD\u00BE\u0080\u0081\u0082\u0083\u0084\u0085\u0086\u0087\u0088\u0089" +
        LATCHA +
        ' ' +
        LOCK +
        SHIFTD +
        SHIFTE +
        LATCHB,
    "\u00E0\u00E1\u00E2\u00E3\u00E4\u00E5\u00E6\u00E7\u00E8\u00E9\u00EA\u00EB\u00EC\u00ED\u00EE\u00EF\u00F0\u00F1\u00F2\u00F3\u00F4\u00F5\u00F6\u00F7\u00F8\u00F9\u00FA" +
        ECI +
        FS +
        GS +
        RS +
        NS +
        "\u00FB\u00FC\u00FD\u00FE\u00FF\u00A1\u00A8\u00AB\u00AF\u00B0\u00B4\u00B7\u00B8\u00BB\u00BF\u008A\u008B\u008C\u008D\u008E\u008F\u0090\u0091\u0092\u0093\u0094" +
        LATCHA +
        ' ' +
        SHIFTC +
        LOCK +
        SHIFTE +
        LATCHB,
    "\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\u0009\n\u000B\u000C\r\u000E\u000F\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001A" +
        ECI +
        PAD +
        PAD +
        '\u001B' +
        NS +
        FS +
        GS +
        RS +
        "\u001F\u009F\u00A0\u00A2\u00A3\u00A4\u00A5\u00A6\u00A7\u00A9\u00AD\u00AE\u00B6\u0095\u0096\u0097\u0098\u0099\u009A\u009B\u009C\u009D\u009E" +
        LATCHA +
        ' ' +
        SHIFTC +
        SHIFTD +
        LOCK +
        LATCHB,
  ];

  DecodedBitStreamParser() ;

  static DecoderResult decode(Uint8List bytes, int mode) {
    StringBuilder result = StringBuilder();
    switch (mode) {
      case 2:
      case 3:
        String postcode;
        if (mode == 2) {
          int pc = getPostCode2(bytes);
          //NumberFormat df = new DecimalFormat(
          //    "0000000000".substring(0, getPostCode2Length(bytes)));
          //postcode = df.format(pc);
          postcode = pc
              .toString()
              .padLeft(Math.min(10, getPostCode2Length(bytes)), '0');
        } else {
          postcode = getPostCode3(bytes);
        }
        // NumberFormat threeDigits = new DecimalFormat("000");
        String country = getCountry(bytes).toString().padLeft(3, '0');
        String service = getServiceClass(bytes).toString().padLeft(3, '0');
        result.write(getMessage(bytes, 10, 84));
        if (result.toString().startsWith("[)>" + RS + "01" + GS)) {
          result.insert(9, postcode + GS + country + GS + service + GS);
        } else {
          result.insert(0, postcode + GS + country + GS + service + GS);
        }
        break;
      case 4:
        result.write(getMessage(bytes, 1, 93));
        break;
      case 5:
        result.write(getMessage(bytes, 1, 77));
        break;
    }
    return DecoderResult(bytes, result.toString(), null, (mode).toString());
  }

  static int getBit(int bit, Uint8List bytes) {
    bit--;
    return (bytes[bit ~/ 6] & (1 << (5 - (bit % 6)))) == 0 ? 0 : 1;
  }

  static int getInt(Uint8List bytes, Uint8List x) {
    if (x.length == 0) {
      throw Exception();
    }
    int val = 0;
    for (int i = 0; i < x.length; i++) {
      val += getBit(x[i], bytes) << (x.length - i - 1);
    }
    return val;
  }

  static int getCountry(Uint8List bytes) {
    return getInt(
        bytes, Uint8List.fromList([53, 54, 43, 44, 45, 46, 47, 48, 37, 38]));
  }

  static int getServiceClass(Uint8List bytes) {
    return getInt(
        bytes, Uint8List.fromList([55, 56, 57, 58, 59, 60, 49, 50, 51, 52]));
  }

  static int getPostCode2Length(Uint8List bytes) {
    return getInt(bytes, Uint8List.fromList([39, 40, 41, 42, 31, 32]));
  }

  static int getPostCode2(Uint8List bytes) {
    return getInt(
        bytes,
        Uint8List.fromList([
          33, 34, 35, 36, 25, 26, 27, 28, 29, 30, 19, //
          20, 21, 22, 23, 24, 13, 14, 15, 16, 17, 18,
          7, 8, 9, 10, 11, 12, 1, 2
        ]));
  }

  static String getPostCode3(Uint8List bytes) {
    return String.fromCharCodes([
      SETS[0].codeUnitAt(
          getInt(bytes, Uint8List.fromList([39, 40, 41, 42, 31, 32]))), //
      SETS[0].codeUnitAt(
          getInt(bytes, Uint8List.fromList([33, 34, 35, 36, 25, 26]))), //
      SETS[0].codeUnitAt(
          getInt(bytes, Uint8List.fromList([27, 28, 29, 30, 19, 20]))), //
      SETS[0].codeUnitAt(
          getInt(bytes, Uint8List.fromList([21, 22, 23, 24, 13, 14]))), //
      SETS[0].codeUnitAt(
          getInt(bytes, Uint8List.fromList([15, 16, 17, 18, 7, 8]))), //
      SETS[0].codeUnitAt(
          getInt(bytes, Uint8List.fromList([9, 10, 11, 12, 1, 2]))), //
    ]);
  }

  static String getMessage(Uint8List bytes, int start, int len) {
    StringBuilder sb = StringBuilder();
    int shift = -1;
    int set = 0;
    int lastset = 0;
    for (int i = start; i < start + len; i++) {
      String c = SETS[set][bytes[i]];
      switch (c) {
        case LATCHA:
          set = 0;
          shift = -1;
          break;
        case LATCHB:
          set = 1;
          shift = -1;
          break;
        case SHIFTA:
        case SHIFTB:
        case SHIFTC:
        case SHIFTD:
        case SHIFTE:
          lastset = set;
          set = c.codeUnitAt(0) - SHIFTA.codeUnitAt(0);
          shift = 1;
          break;
        case TWOSHIFTA:
          lastset = set;
          set = 0;
          shift = 2;
          break;
        case THREESHIFTA:
          lastset = set;
          set = 0;
          shift = 3;
          break;
        case NS:
          int nsval = (bytes[++i] << 24) +
              (bytes[++i] << 18) +
              (bytes[++i] << 12) +
              (bytes[++i] << 6) +
              bytes[++i];
          sb.write(nsval.toString().padLeft(9, '0'));
          break;
        case LOCK:
          shift = -1;
          break;
        default:
          sb.write(c);
      }
      if (shift-- == 0) {
        set = lastset;
      }
    }
    while (sb.length > 0 && sb.charAt(sb.length - 1) == PAD) {
      sb.setLength(sb.length - 1);
    }
    return sb.toString();
  }
}
