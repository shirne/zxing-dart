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
import 'ai013103decoder.dart';
import 'ai01320x_decoder.dart';
import 'ai01392x_decoder.dart';
import 'ai01393x_decoder.dart';
import 'ai013x0x1x_decoder.dart';
import 'ai01_and_other_ais.dart';
import 'any_aidecoder.dart';
import 'general_app_id_decoder.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
/// @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
abstract class AbstractExpandedDecoder {
  final BitArray _information;
  final GeneralAppIdDecoder _generalDecoder;

  AbstractExpandedDecoder(this._information)
      : _generalDecoder = GeneralAppIdDecoder(_information);

  BitArray get information => _information;

  GeneralAppIdDecoder get generalDecoder => _generalDecoder;

  String parseInformation();

  static AbstractExpandedDecoder createDecoder(BitArray information) {
    if (information.get(1)) {
      return AI01AndOtherAIs(information);
    }
    if (!information.get(2)) {
      return AnyAIDecoder(information);
    }

    final fourBitEncodationMethod =
        GeneralAppIdDecoder.extractNumericFromBitArray(information, 1, 4);

    switch (fourBitEncodationMethod) {
      case 4:
        return AI013103decoder(information);
      case 5:
        return AI01320xDecoder(information);
    }

    final fiveBitEncodationMethod =
        GeneralAppIdDecoder.extractNumericFromBitArray(information, 1, 5);
    switch (fiveBitEncodationMethod) {
      case 12:
        return AI01392xDecoder(information);
      case 13:
        return AI01393xDecoder(information);
    }

    final sevenBitEncodationMethod =
        GeneralAppIdDecoder.extractNumericFromBitArray(information, 1, 7);
    switch (sevenBitEncodationMethod) {
      case 56:
        return AI013x0x1xDecoder(information, '310', '11');
      case 57:
        return AI013x0x1xDecoder(information, '320', '11');
      case 58:
        return AI013x0x1xDecoder(information, '310', '13');
      case 59:
        return AI013x0x1xDecoder(information, '320', '13');
      case 60:
        return AI013x0x1xDecoder(information, '310', '15');
      case 61:
        return AI013x0x1xDecoder(information, '320', '15');
      case 62:
        return AI013x0x1xDecoder(information, '310', '17');
      case 63:
        return AI013x0x1xDecoder(information, '320', '17');
    }

    throw StateError('unknown decoder: $information');
  }
}
