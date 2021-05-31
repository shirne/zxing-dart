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

import 'parsed_result.dart';
import 'parsed_result_type.dart';

/**
 * Represents a parsed result that encodes extended product information as encoded
 * by the RSS format, like weight, price, dates, etc.
 *
 * @author Antonio Manuel Benjumea Conde, Servinform, S.A.
 * @author Agustín Delgado, Servinform, S.A.
 */
class ExpandedProductParsedResult extends ParsedResult {
  static const String KILOGRAM = "KG";
  static const String POUND = "LB";

  final String? _rawText;
  final String? _productID;
  final String? _sscc;
  final String? _lotNumber;
  final String? _productionDate;
  final String? _packagingDate;
  final String? _bestBeforeDate;
  final String? _expirationDate;
  final String? _weight;
  final String? _weightType;
  final String? _weightIncrement;
  final String? _price;
  final String? _priceIncrement;
  final String? _priceCurrency;
  // For AIS that not exist in this object
  final Map<String, String> _uncommonAIs;

  ExpandedProductParsedResult(
      this._rawText,
      this._productID,
      this._sscc,
      this._lotNumber,
      this._productionDate,
      this._packagingDate,
      this._bestBeforeDate,
      this._expirationDate,
      this._weight,
      this._weightType,
      this._weightIncrement,
      this._price,
      this._priceIncrement,
      this._priceCurrency,
      this._uncommonAIs)
      : super(ParsedResultType.PRODUCT);

  @override
  operator ==(Object o) {
    if (!(o is ExpandedProductParsedResult)) {
      return false;
    }

    ExpandedProductParsedResult other = o;

    return _productID == other._productID &&
        (_sscc == other._sscc) &&
        (_lotNumber == other._lotNumber) &&
        (_productionDate == other._productionDate) &&
        (_bestBeforeDate == other._bestBeforeDate) &&
        (_expirationDate == other._expirationDate) &&
        (_weight == other._weight) &&
        (_weightType == other._weightType) &&
        (_weightIncrement == other._weightIncrement) &&
        (_price == other._price) &&
        (_priceIncrement == other._priceIncrement) &&
        (_priceCurrency == other._priceCurrency) &&
        (_uncommonAIs == other._uncommonAIs);
  }

  @override
  int get hashCode {
    int hash = _productID.hashCode;
    hash ^= _sscc.hashCode;
    hash ^= _lotNumber.hashCode;
    hash ^= _productionDate.hashCode;
    hash ^= _bestBeforeDate.hashCode;
    hash ^= _expirationDate.hashCode;
    hash ^= _weight.hashCode;
    hash ^= _weightType.hashCode;
    hash ^= _weightIncrement.hashCode;
    hash ^= _price.hashCode;
    hash ^= _priceIncrement.hashCode;
    hash ^= _priceCurrency.hashCode;
    hash ^= _uncommonAIs.hashCode;
    return hash;
  }

  String? getRawText() {
    return _rawText;
  }

  String? getProductID() {
    return _productID;
  }

  String? getSscc() {
    return _sscc;
  }

  String? getLotNumber() {
    return _lotNumber;
  }

  String? getProductionDate() {
    return _productionDate;
  }

  String? getPackagingDate() {
    return _packagingDate;
  }

  String? getBestBeforeDate() {
    return _bestBeforeDate;
  }

  String? getExpirationDate() {
    return _expirationDate;
  }

  String? getWeight() {
    return _weight;
  }

  String? getWeightType() {
    return _weightType;
  }

  String? getWeightIncrement() {
    return _weightIncrement;
  }

  String? getPrice() {
    return _price;
  }

  String? getPriceIncrement() {
    return _priceIncrement;
  }

  String? getPriceCurrency() {
    return _priceCurrency;
  }

  Map<String, String> getUncommonAIs() {
    return _uncommonAIs;
  }

  @override
  String getDisplayResult() {
    return _rawText.toString();
  }
}
