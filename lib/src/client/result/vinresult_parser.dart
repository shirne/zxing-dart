/*
 * Copyright 2014 ZXing authors
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

import 'package:zxing_lib/src/arguments_exception.dart';

import '../../barcode_format.dart';
import '../../result.dart';
import 'result_parser.dart';
import 'vinparsed_result.dart';

/// Detects a result that is likely a vehicle identification number.
///
/// @author Sean Owen
class VINResultParser extends ResultParser {
  static final RegExp _ioq = RegExp("[IOQ]");
  static final RegExp _az09 = RegExp(r"^[A-Z0-9]{17}$");

  @override
  VINParsedResult? parse(Result result) {
    if (result.barcodeFormat != BarcodeFormat.CODE_39) {
      return null;
    }
    String rawText = result.text;
    rawText = rawText.replaceAll(_ioq, "").trim();
    if (!_az09.hasMatch(rawText)) {
      return null;
    }
    try {
      if (!_checkChecksum(rawText)) {
        return null;
      }
      String wmi = rawText.substring(0, 3);
      return VINParsedResult(
        vin: rawText,
        worldManufacturerID: wmi,
        vehicleDescriptorSection: rawText.substring(3, 9),
        vehicleIdentifierSection: rawText.substring(9, 17),
        countryCode: _countryCode(wmi),
        vehicleAttributes: rawText.substring(3, 8),
        modelYear: _modelYear(rawText.codeUnitAt(9)),
        plantCode: rawText.codeUnitAt(10),
        sequentialNumber: rawText.substring(11),
      );
    } on ArgumentsException catch (_) {
      // IllegalArgumentException
      return null;
    }
  }

  static bool _checkChecksum(String vin) {
    int sum = 0;
    for (int i = 0; i < vin.length; i++) {
      sum += _vinPositionWeight(i + 1) * _vinCharValue(vin.codeUnitAt(i));
    }
    String checkedChar = vin[8];
    String expectedCheckChar = _checkChar(sum % 11);
    return checkedChar == expectedCheckChar;
  }

  static int _vinCharValue(int c) {
    if (c >= 65 /*'A'*/ && c <= 73 /*'I'*/) {
      return (c - 65) + 1;
    }
    if (c >= 74 /*'J'*/ && c <= 82 /*'R'*/) {
      return (c - 74) + 1;
    }
    if (c >= 83 /*'S'*/ && c <= 90 /*'Z'*/) {
      return (c - 83) + 2;
    }
    if (c >= 48 /*'0'*/ && c <= 57 /*'9'*/) {
      return c - 48;
    }
    throw ArgumentsException();
  }

  static int _vinPositionWeight(int position) {
    if (position >= 1 && position <= 7) {
      return 9 - position;
    }
    if (position == 8) {
      return 10;
    }
    if (position == 9) {
      return 0;
    }
    if (position >= 10 && position <= 17) {
      return 19 - position;
    }
    throw ArgumentsException();
  }

  static String _checkChar(int remainder) {
    if (remainder < 10) {
      return String.fromCharCode(48 /*'0'*/ + remainder);
    }
    if (remainder == 10) {
      return 'X';
    }
    throw ArgumentsException();
  }

  static int _modelYear(int c) {
    if (c >= 69 /*'E'*/ && c <= 72 /*'H'*/) {
      return (c - 69) + 1984;
    }
    if (c >= 74 /*'J'*/ && c <= 78 /*'N'*/) {
      return (c - 74) + 1988;
    }
    if (c == 80 /*'P'*/) {
      return 1993;
    }
    if (c >= 82 /*'R'*/ && c <= 84 /*'T'*/) {
      return (c - 82) + 1994;
    }
    if (c >= 86 /*'V'*/ && c <= 89 /*'Y'*/) {
      return (c - 86) + 1997;
    }
    if (c >= 49 /*'1'*/ && c <= 57 /*'9'*/) {
      return (c - 49) + 2001;
    }
    if (c >= 65 /*'A'*/ && c <= 68 /*'D'*/) {
      return (c - 65) + 2010;
    }
    throw ArgumentsException();
  }

  static String? _countryCode(String wmi) {
    String c1 = wmi[0];
    int c2 = wmi.codeUnitAt(1);
    switch (c1) {
      case '1':
      case '4':
      case '5':
        return "US";
      case '2':
        return "CA";
      case '3':
        if (c2 >= 65 /*'A'*/ && c2 <= 8 /*'W'*/) {
          return "MX";
        }
        break;
      case '9':
        if ((c2 >= 65 /* A */ && c2 <= 69 /* E */) ||
            (c2 >= 51 /* 3 */ && c2 <= 57 /* 9 */)) {
          return "BR";
        }
        break;
      case 'J':
        if (c2 >= 65 /* A */ && c2 <= 84 /* T */) {
          return "JP";
        }
        break;
      case 'K':
        if (c2 >= 76 /* L */ && c2 <= 82 /* R */) {
          return "KO";
        }
        break;
      case 'L':
        return "CN";
      case 'M':
        if (c2 >= 65 /* A */ && c2 <= 69 /* E */) {
          return "IN";
        }
        break;
      case 'S':
        if (c2 >= 65 /* A */ && c2 <= 77 /* M */) {
          return "UK";
        }
        if (c2 >= 78 /* N */ && c2 <= 84 /* T */) {
          return "DE";
        }
        break;
      case 'V':
        if (c2 >= 70 /* F */ && c2 <= 82 /* R */) {
          return "FR";
        }
        if (c2 >= 83 /* S */ && c2 <= 87 /* W */) {
          return "ES";
        }
        break;
      case 'W':
        return "DE";
      case 'X':
        if (c2 == 48 /* 0 */ || (c2 >= 51 /* 3 */ && c2 <= 57 /* 9 */)) {
          return "RU";
        }
        break;
      case 'Z':
        if (c2 >= 65 /* A */ && c2 <= 82 /* R */) {
          return "IT";
        }
        break;
    }
    return null;
  }
}
