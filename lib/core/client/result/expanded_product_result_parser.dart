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

import '../../barcode_format.dart';
import '../../result.dart';
import 'expanded_product_parsed_result.dart';
import 'result_parser.dart';

/// Parses strings of digits that represent a RSS Extended code.
/// 
/// @author Antonio Manuel Benjumea Conde, Servinform, S.A.
/// @author Agustín Delgado, Servinform, S.A.
class ExpandedProductResultParser extends ResultParser {
  @override
  ExpandedProductParsedResult? parse(Result result) {
    BarcodeFormat format = result.getBarcodeFormat();
    if (format != BarcodeFormat.RSS_EXPANDED) {
      // ExtendedProductParsedResult NOT created. Not a RSS Expanded barcode
      return null;
    }
    String rawText = ResultParser.getMassagedText(result);

    String? productID;
    String? sscc;
    String? lotNumber;
    String? productionDate;
    String? packagingDate;
    String? bestBeforeDate;
    String? expirationDate;
    String? weight;
    String? weightType;
    String? weightIncrement;
    String? price;
    String? priceIncrement;
    String? priceCurrency;
    Map<String, String> uncommonAIs = {};

    int i = 0;

    while (i < rawText.length) {
      String? ai = _findAIvalue(i, rawText);
      if (ai == null) {
        // Error. Code doesn't match with RSS expanded pattern
        // ExtendedProductParsedResult NOT created. Not match with RSS Expanded pattern
        return null;
      }
      i += ai.length + 2;
      String value = _findValue(i, rawText);
      i += value.length;

      switch (ai) {
        case "00":
          sscc = value;
          break;
        case "01":
          productID = value;
          break;
        case "10":
          lotNumber = value;
          break;
        case "11":
          productionDate = value;
          break;
        case "13":
          packagingDate = value;
          break;
        case "15":
          bestBeforeDate = value;
          break;
        case "17":
          expirationDate = value;
          break;
        case "3100":
        case "3101":
        case "3102":
        case "3103":
        case "3104":
        case "3105":
        case "3106":
        case "3107":
        case "3108":
        case "3109":
          weight = value;
          weightType = ExpandedProductParsedResult.KILOGRAM;
          weightIncrement = ai.substring(3);
          break;
        case "3200":
        case "3201":
        case "3202":
        case "3203":
        case "3204":
        case "3205":
        case "3206":
        case "3207":
        case "3208":
        case "3209":
          weight = value;
          weightType = ExpandedProductParsedResult.POUND;
          weightIncrement = ai.substring(3);
          break;
        case "3920":
        case "3921":
        case "3922":
        case "3923":
          price = value;
          priceIncrement = ai.substring(3);
          break;
        case "3930":
        case "3931":
        case "3932":
        case "3933":
          if (value.length < 4) {
            // The value must have more of 3 symbols (3 for currency and
            // 1 at least for the price)
            // ExtendedProductParsedResult NOT created. Not match with RSS Expanded pattern
            return null;
          }
          price = value.substring(3);
          priceCurrency = value.substring(0, 3);
          priceIncrement = ai.substring(3);
          break;
        default:
          // No match with common AIs
          uncommonAIs[ai] = value;
          break;
      }
    }

    return ExpandedProductParsedResult(
        rawText,
        productID,
        sscc,
        lotNumber,
        productionDate,
        packagingDate,
        bestBeforeDate,
        expirationDate,
        weight,
        weightType,
        weightIncrement,
        price,
        priceIncrement,
        priceCurrency,
        uncommonAIs);
  }

  static String? _findAIvalue(int i, String rawText) {
    String c = rawText[i];
    // First character must be a open parenthesis.If not, ERROR
    if (c != '(') {
      return null;
    }

    String rawTextAux = rawText.substring(i + 1);

    StringBuffer buf = StringBuffer();
    for (int index = 0; index < rawTextAux.length; index++) {
      int currentChar = rawTextAux.codeUnitAt(index);
      if (currentChar == ')'.codeUnitAt(0)) {
        return buf.toString();
      }
      if (currentChar < '0'.codeUnitAt(0) || currentChar > '9'.codeUnitAt(0)) {
        return null;
      }
      buf.writeCharCode(currentChar);
    }
    return buf.toString();
  }

  static String _findValue(int i, String rawText) {
    StringBuffer buf = StringBuffer();
    String rawTextAux = rawText.substring(i);

    for (int index = 0; index < rawTextAux.length; index++) {
      String c = rawTextAux[index];
      if (c == '(') {
        // We look for a new AI. If it doesn't exist (ERROR), we continue
        // with the iteration
        if (_findAIvalue(index, rawTextAux) != null) {
          break;
        }
        buf.write('(');
      } else {
        buf.write(c);
      }
    }
    return buf.toString();
  }
}
