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

/// MaxiCodes can encode text or structured information as bits in one of several modes,
/// with multiple character sets in one code. This class decodes the bits back into text.
///
/// @author mike32767
/// @author Manuel Kasten
class DecodedBitStreamParser {
  static const String _shiftA = '\uFFF0';
  static const String _shiftB = '\uFFF1';
  static const String _shiftC = '\uFFF2';
  static const String _shiftD = '\uFFF3';
  static const String _shiftE = '\uFFF4';
  static const String _twoShiftA = '\uFFF5';
  static const String _threeShiftA = '\uFFF6';
  static const String _latchA = '\uFFF7';
  static const String _latchB = '\uFFF8';
  static const String _lock = '\uFFF9';
  static const String _eci = '\uFFFA';
  static const String _ns = '\uFFFB';
  static const String _pad = '\uFFFC';
  static const String _fs = '\u001C';
  static const String _gs = '\u001D';
  static const String _rs = '\u001E';

  static final List<String> _sets = [
    "\nABCDEFGHIJKLMNOPQRSTUVWXYZ" +
        "$_eci$_fs$_gs$_rs$_ns $_pad\"" +
        r"#$%&'()*+,-./0123456789:" +
        "$_shiftB$_shiftC$_shiftD$_shiftE$_latchB",
    "`abcdefghijklmnopqrstuvwxyz" +
        "$_eci$_fs$_gs$_rs$_ns" +
        "{$_pad}~\u007F;<=>?[\\]^_ ,./:@!|" +
        "$_pad$_twoShiftA$_threeShiftA$_pad$_shiftA$_shiftC$_shiftD$_shiftE$_latchA",
    "\u00C0\u00C1\u00C2\u00C3\u00C4\u00C5\u00C6\u00C7\u00C8\u00C9\u00CA\u00CB\u00CC\u00CD\u00CE\u00CF\u00D0\u00D1\u00D2\u00D3\u00D4\u00D5\u00D6\u00D7\u00D8\u00D9\u00DA" +
        "$_eci$_fs$_gs$_rs$_ns" +
        "\u00DB\u00DC\u00DD\u00DE\u00DF\u00AA\u00AC\u00B1\u00B2\u00B3\u00B5\u00B9\u00BA\u00BC\u00BD\u00BE\u0080\u0081\u0082\u0083\u0084\u0085\u0086\u0087\u0088\u0089" +
        "$_latchA $_lock$_shiftD$_shiftE$_latchB",
    "\u00E0\u00E1\u00E2\u00E3\u00E4\u00E5\u00E6\u00E7\u00E8\u00E9\u00EA\u00EB\u00EC\u00ED\u00EE\u00EF\u00F0\u00F1\u00F2\u00F3\u00F4\u00F5\u00F6\u00F7\u00F8\u00F9\u00FA" +
        "$_eci$_fs$_gs$_rs$_ns" +
        "\u00FB\u00FC\u00FD\u00FE\u00FF\u00A1\u00A8\u00AB\u00AF\u00B0\u00B4\u00B7\u00B8\u00BB\u00BF\u008A\u008B\u008C\u008D\u008E\u008F\u0090\u0091\u0092\u0093\u0094" +
        "$_latchA $_shiftC$_lock$_shiftE$_latchB",
    "\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\u0009\n\u000B\u000C\r\u000E\u000F\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001A" +
        "$_eci$_pad$_pad\u001B$_ns$_fs$_gs$_rs" +
        "\u001F\u009F\u00A0\u00A2\u00A3\u00A4\u00A5\u00A6\u00A7\u00A9\u00AD\u00AE\u00B6\u0095\u0096\u0097\u0098\u0099\u009A\u009B\u009C\u009D\u009E" +
        "$_latchA $_shiftC$_shiftD$_lock$_latchB",
  ];

  DecodedBitStreamParser._();

  static DecoderResult decode(Uint8List bytes, int mode) {
    StringBuilder result = StringBuilder();
    switch (mode) {
      case 2:
      case 3:
        String postcode;
        if (mode == 2) {
          int pc = _getPostCode2(bytes);
          //NumberFormat df = DecimalFormat(
          //    "0000000000".substring(0, getPostCode2Length(bytes)));
          //postcode = df.format(pc);
          postcode = pc
              .toString()
              .padLeft(Math.min(10, _getPostCode2Length(bytes)), '0');
        } else {
          postcode = _getPostCode3(bytes);
        }
        // NumberFormat threeDigits = DecimalFormat("000");
        String country = _getCountry(bytes).toString().padLeft(3, '0');
        String service = _getServiceClass(bytes).toString().padLeft(3, '0');
        result.write(_getMessage(bytes, 10, 84));
        if (result.toString().startsWith("[)>" + _rs + "01" + _gs)) {
          result.insert(9, postcode + _gs + country + _gs + service + _gs);
        } else {
          result.insert(0, postcode + _gs + country + _gs + service + _gs);
        }
        break;
      case 4:
        result.write(_getMessage(bytes, 1, 93));
        break;
      case 5:
        result.write(_getMessage(bytes, 1, 77));
        break;
    }
    return DecoderResult(bytes, result.toString(), null, (mode).toString());
  }

  static int _getBit(int bit, Uint8List bytes) {
    bit--;
    return (bytes[bit ~/ 6] & (1 << (5 - (bit % 6)))) == 0 ? 0 : 1;
  }

  static int _getInt(Uint8List bytes, Uint8List x) {
    if (x.length == 0) {
      throw Exception();
    }
    int val = 0;
    for (int i = 0; i < x.length; i++) {
      val += _getBit(x[i], bytes) << (x.length - i - 1);
    }
    return val;
  }

  static int _getCountry(Uint8List bytes) {
    return _getInt(
        bytes, Uint8List.fromList([53, 54, 43, 44, 45, 46, 47, 48, 37, 38]));
  }

  static int _getServiceClass(Uint8List bytes) {
    return _getInt(
        bytes, Uint8List.fromList([55, 56, 57, 58, 59, 60, 49, 50, 51, 52]));
  }

  static int _getPostCode2Length(Uint8List bytes) {
    return _getInt(bytes, Uint8List.fromList([39, 40, 41, 42, 31, 32]));
  }

  static int _getPostCode2(Uint8List bytes) {
    return _getInt(
        bytes,
        Uint8List.fromList([
          33, 34, 35, 36, 25, 26, 27, 28, 29, 30, 19, //
          20, 21, 22, 23, 24, 13, 14, 15, 16, 17, 18,
          7, 8, 9, 10, 11, 12, 1, 2
        ]));
  }

  static String _getPostCode3(Uint8List bytes) {
    return String.fromCharCodes([
      _sets[0].codeUnitAt(
          _getInt(bytes, Uint8List.fromList([39, 40, 41, 42, 31, 32]))), //
      _sets[0].codeUnitAt(
          _getInt(bytes, Uint8List.fromList([33, 34, 35, 36, 25, 26]))), //
      _sets[0].codeUnitAt(
          _getInt(bytes, Uint8List.fromList([27, 28, 29, 30, 19, 20]))), //
      _sets[0].codeUnitAt(
          _getInt(bytes, Uint8List.fromList([21, 22, 23, 24, 13, 14]))), //
      _sets[0].codeUnitAt(
          _getInt(bytes, Uint8List.fromList([15, 16, 17, 18, 7, 8]))), //
      _sets[0].codeUnitAt(
          _getInt(bytes, Uint8List.fromList([9, 10, 11, 12, 1, 2]))), //
    ]);
  }

  static String _getMessage(Uint8List bytes, int start, int len) {
    StringBuilder sb = StringBuilder();
    int shift = -1;
    int set = 0;
    int lastSet = 0;
    for (int i = start; i < start + len; i++) {
      String c = _sets[set][bytes[i]];
      switch (c) {
        case _latchA:
          set = 0;
          shift = -1;
          break;
        case _latchB:
          set = 1;
          shift = -1;
          break;
        case _shiftA:
        case _shiftB:
        case _shiftC:
        case _shiftD:
        case _shiftE:
          lastSet = set;
          set = c.codeUnitAt(0) - _shiftA.codeUnitAt(0);
          shift = 1;
          break;
        case _twoShiftA:
          lastSet = set;
          set = 0;
          shift = 2;
          break;
        case _threeShiftA:
          lastSet = set;
          set = 0;
          shift = 3;
          break;
        case _ns:
          int nsval = (bytes[++i] << 24) +
              (bytes[++i] << 18) +
              (bytes[++i] << 12) +
              (bytes[++i] << 6) +
              bytes[++i];
          sb.write(nsval.toString().padLeft(9, '0'));
          break;
        case _lock:
          shift = -1;
          break;
        default:
          sb.write(c);
      }
      if (shift-- == 0) {
        set = lastSet;
      }
    }
    while (sb.length > 0 && sb.charAt(sb.length - 1) == _pad) {
      sb.setLength(sb.length - 1);
    }
    return sb.toString();
  }
}
