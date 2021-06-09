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

import '../../../../common/bit_array.dart';
import '../../../../common/string_builder.dart';

import '../../../../not_found_exception.dart';
import 'ai01decoder.dart';
import 'decoded_information.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
class AI01392xDecoder extends AI01decoder {
  static const int _HEADER_SIZE = 5 + 1 + 2;
  static const int _LAST_DIGIT_SIZE = 2;

  AI01392xDecoder(BitArray information) : super(information);

  @override
  String parseInformation() {
    if (this.information.size < _HEADER_SIZE + AI01decoder.GTIN_SIZE) {
      throw NotFoundException.instance;
    }

    StringBuilder buf = StringBuilder();

    encodeCompressedGtin(buf, _HEADER_SIZE);

    int lastAIdigit = this.generalDecoder.extractNumericValueFromBitArray(
        _HEADER_SIZE + AI01decoder.GTIN_SIZE, _LAST_DIGIT_SIZE);
    buf.write("(392");
    buf.write(lastAIdigit);
    buf.write(')');

    DecodedInformation decodedInformation = this
        .generalDecoder
        .decodeGeneralPurposeField(
            _HEADER_SIZE + AI01decoder.GTIN_SIZE + _LAST_DIGIT_SIZE, null);
    buf.write(decodedInformation.newString);

    return buf.toString();
  }
}
