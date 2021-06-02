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



import '../../barcode_format.dart';
import '../../result.dart';
import 'result_parser.dart';
import 'vinparsed_result.dart';

/// Detects a result that is likely a vehicle identification number.
///
/// @author Sean Owen
class VINResultParser extends ResultParser {

  static final RegExp _ioq = RegExp("[IOQ]");
  static final RegExp _az09 = RegExp("[A-Z0-9]{17}");

  @override
  VINParsedResult? parse(Result result) {
    if (result.getBarcodeFormat() != BarcodeFormat.CODE_39) {
      return null;
    }
    String rawText = result.getText();
    rawText = rawText.replaceAll(_ioq, "").trim();
    if (!_az09.hasMatch(rawText)) {
      return null;
    }
    try {
      if (!_checkChecksum(rawText)) {
        return null;
      }
      String wmi = rawText.substring(0, 3);
      return VINParsedResult(rawText,
          wmi,
          rawText.substring(3, 9),
          rawText.substring(9, 17),
          _countryCode(wmi),
          rawText.substring(3, 8),
          _modelYear(rawText.codeUnitAt(9)),
          rawText.codeUnitAt(10),
          rawText.substring(11));
    } catch ( _) { // IllegalArgumentException
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
    if (c >= 'A'.codeUnitAt(0) && c <= 'I'.codeUnitAt(0)) {
      return (c - 'A'.codeUnitAt(0)) + 1;
    }
    if (c >= 'J'.codeUnitAt(0) && c <= 'R'.codeUnitAt(0)) {
      return (c - 'J'.codeUnitAt(0)) + 1;
    }
    if (c >= 'S'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0)) {
      return (c - 'S'.codeUnitAt(0)) + 2;
    }
    if (c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
      return c - '0'.codeUnitAt(0);
    }
    throw Exception();
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
    throw Exception();
  }

  static String _checkChar(int remainder) {
    if (remainder < 10) {
      return String.fromCharCode('0'.codeUnitAt(0) + remainder);
    }
    if (remainder == 10) {
      return 'X';
    }
    throw Exception();
  }
  
  static int _modelYear(int c) {
    if (c >= 'E'.codeUnitAt(0) && c <= 'H'.codeUnitAt(0)) {
      return (c - 'E'.codeUnitAt(0)) + 1984;
    }
    if (c >= 'J'.codeUnitAt(0) && c <= 'N'.codeUnitAt(0)) {
      return (c - 'J'.codeUnitAt(0)) + 1988;
    }
    if (c == 'P'.codeUnitAt(0)) {
      return 1993;
    }
    if (c >= 'R'.codeUnitAt(0) && c <= 'T'.codeUnitAt(0)) {
      return (c - 'R'.codeUnitAt(0)) + 1994;
    }
    if (c >= 'V'.codeUnitAt(0) && c <= 'Y'.codeUnitAt(0)) {
      return (c - 'V'.codeUnitAt(0)) + 1997;
    }
    if (c >= '1'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
      return (c - '1'.codeUnitAt(0)) + 2001;
    }
    if (c >= 'A'.codeUnitAt(0) && c <= 'D'.codeUnitAt(0)) {
      return (c - 'A'.codeUnitAt(0)) + 2010;
    }
    throw Exception();
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
        if (c2 >= 'A'.codeUnitAt(0) && c2 <= 'W'.codeUnitAt(0)) {
          return "MX";
        }
        break;
      case '9':
        if ((c2 >= 'A'.codeUnitAt(0) && c2 <= 'E'.codeUnitAt(0)) || (c2 >= '3'.codeUnitAt(0) && c2 <= '9'.codeUnitAt(0))) {
          return "BR";
        }
        break;
      case 'J':
        if (c2 >= 'A'.codeUnitAt(0) && c2 <= 'T'.codeUnitAt(0)) {
          return "JP";
        }
        break;
      case 'K':
        if (c2 >= 'L'.codeUnitAt(0) && c2 <= 'R'.codeUnitAt(0)) {
          return "KO";
        }
        break;
      case 'L':
        return "CN";
      case 'M':
        if (c2 >= 'A'.codeUnitAt(0) && c2 <= 'E'.codeUnitAt(0)) {
          return "IN";
        }
        break;
      case 'S':
        if (c2 >= 'A'.codeUnitAt(0) && c2 <= 'M'.codeUnitAt(0)) {
          return "UK";
        }
        if (c2 >= 'N'.codeUnitAt(0) && c2 <= 'T'.codeUnitAt(0)) {
          return "DE";
        }
        break;
      case 'V':
        if (c2 >= 'F'.codeUnitAt(0) && c2 <= 'R'.codeUnitAt(0)) {
          return "FR";
        }
        if (c2 >= 'S'.codeUnitAt(0) && c2 <= 'W'.codeUnitAt(0)) {
          return "ES";
        }
        break;
      case 'W':
        return "DE";
      case 'X':
        if (c2 == '0'.codeUnitAt(0) || (c2 >= '3'.codeUnitAt(0) && c2 <= '9'.codeUnitAt(0))) {
          return "RU";
        }
        break;
      case 'Z':
        if (c2 >= 'A'.codeUnitAt(0) && c2 <= 'R'.codeUnitAt(0)) {
          return "IT";
        }
        break;
    }
    return null;
  }

}
