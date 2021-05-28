/*
 * Copyright 2007 ZXing authors
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

import 'parsed_result.dart';
import 'parsed_result_type.dart';

/**
 * Represents a parsed result that encodes a product by an identifier of some kind.
 *
 * @author dswitkin@google.com (Daniel Switkin)
 */
class ProductParsedResult extends ParsedResult {
  final String productID;
  final String normalizedProductID;

  ProductParsedResult(this.productID, [String? normalizedProductID])
      : this.normalizedProductID = normalizedProductID ?? productID,
        super(ParsedResultType.PRODUCT);

  String getProductID() {
    return productID;
  }

  String getNormalizedProductID() {
    return normalizedProductID;
  }

  @override
  String getDisplayResult() {
    return productID;
  }
}
