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

import '../../../../formats_exception.dart';
import 'decoded_object.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
/// @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
class DecodedNumeric extends DecodedObject {
  final int _firstDigit;
  final int _secondDigit;

  static final int fnc1 = 10;

  DecodedNumeric(int newPosition, this._firstDigit, this._secondDigit)
      : super(newPosition) {
    if (_firstDigit < 0 ||
        _firstDigit > 10 ||
        _secondDigit < 0 ||
        _secondDigit > 10) {
      throw FormatsException.instance;
    }
  }

  int get firstDigit => _firstDigit;

  int get secondDigit => _secondDigit;

  int get value => _firstDigit * 10 + _secondDigit;

  bool get isFirstDigitFNC1 => _firstDigit == fnc1;

  bool get isSecondDigitFNC1 => _secondDigit == fnc1;
}
