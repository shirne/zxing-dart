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

import 'dart:math' as math;

import '../../../../not_found_exception.dart';

class DataLength {
  final bool variable;
  final int length;

  const DataLength._(this.variable, this.length);

  const DataLength.fixed(int length) : this._(false, length);

  const DataLength.variable(int length) : this._(true, length);
}

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
/// @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
class FieldParser {
  static final Map<String, DataLength> _twoDigitDataLength = {
    // "DIGITS", Integer(LENGTH)
    //    or
    // "DIGITS", VARIABLE_LENGTH, Integer(MAX_SIZE)

    '00': DataLength.fixed(18),
    '01': DataLength.fixed(14),
    '02': DataLength.fixed(14),

    '10': DataLength.variable(20),
    '11': DataLength.fixed(6),
    '12': DataLength.fixed(6),
    '13': DataLength.fixed(6),
    '15': DataLength.fixed(6),
    '17': DataLength.fixed(6),

    '20': DataLength.fixed(2),
    '21': DataLength.variable(20),
    '22': DataLength.variable(29),

    '30': DataLength.variable(8),
    '37': DataLength.variable(8),

    //internal company codes
    '90': DataLength.variable(30),
    '91': DataLength.variable(30),
    '92': DataLength.variable(30),
    '93': DataLength.variable(30),
    '94': DataLength.variable(30),
    '95': DataLength.variable(30),
    '96': DataLength.variable(30),
    '97': DataLength.variable(30),
    '98': DataLength.variable(30),
    '99': DataLength.variable(30),
  };

  static final Map<String, DataLength> _threeDigitDataLength = {
    // Same format as above

    '240': DataLength.variable(30),
    '241': DataLength.variable(30),
    '242': DataLength.variable(6),
    '250': DataLength.variable(30),
    '251': DataLength.variable(30),
    '253': DataLength.variable(17),
    '254': DataLength.variable(20),

    '400': DataLength.variable(30),
    '401': DataLength.variable(30),
    '402': DataLength.fixed(17),
    '403': DataLength.variable(30),
    '410': DataLength.fixed(13),
    '411': DataLength.fixed(13),
    '412': DataLength.fixed(13),
    '413': DataLength.fixed(13),
    '414': DataLength.fixed(13),
    '420': DataLength.variable(20),
    '421': DataLength.variable(15),
    '422': DataLength.fixed(3),
    '423': DataLength.variable(15),
    '424': DataLength.fixed(3),
    '425': DataLength.fixed(3),
    '426': DataLength.fixed(3),
  };

  static final Map<String, DataLength> _threeDigitPlusDigitDataLength = {
    // Same format as above

    '310': DataLength.fixed(6),
    '311': DataLength.fixed(6),
    '312': DataLength.fixed(6),
    '313': DataLength.fixed(6),
    '314': DataLength.fixed(6),
    '315': DataLength.fixed(6),
    '316': DataLength.fixed(6),
    '320': DataLength.fixed(6),
    '321': DataLength.fixed(6),
    '322': DataLength.fixed(6),
    '323': DataLength.fixed(6),
    '324': DataLength.fixed(6),
    '325': DataLength.fixed(6),
    '326': DataLength.fixed(6),
    '327': DataLength.fixed(6),
    '328': DataLength.fixed(6),
    '329': DataLength.fixed(6),
    '330': DataLength.fixed(6),
    '331': DataLength.fixed(6),
    '332': DataLength.fixed(6),
    '333': DataLength.fixed(6),
    '334': DataLength.fixed(6),
    '335': DataLength.fixed(6),
    '336': DataLength.fixed(6),
    '340': DataLength.fixed(6),
    '341': DataLength.fixed(6),
    '342': DataLength.fixed(6),
    '343': DataLength.fixed(6),
    '344': DataLength.fixed(6),
    '345': DataLength.fixed(6),
    '346': DataLength.fixed(6),
    '347': DataLength.fixed(6),
    '348': DataLength.fixed(6),
    '349': DataLength.fixed(6),
    '350': DataLength.fixed(6),
    '351': DataLength.fixed(6),
    '352': DataLength.fixed(6),
    '353': DataLength.fixed(6),
    '354': DataLength.fixed(6),
    '355': DataLength.fixed(6),
    '356': DataLength.fixed(6),
    '357': DataLength.fixed(6),
    '360': DataLength.fixed(6),
    '361': DataLength.fixed(6),
    '362': DataLength.fixed(6),
    '363': DataLength.fixed(6),
    '364': DataLength.fixed(6),
    '365': DataLength.fixed(6),
    '366': DataLength.fixed(6),
    '367': DataLength.fixed(6),
    '368': DataLength.fixed(6),
    '369': DataLength.fixed(6),
    '390': DataLength.variable(15),
    '391': DataLength.variable(18),
    '392': DataLength.variable(15),
    '393': DataLength.variable(18),
    '703': DataLength.variable(30),
  };

  static final Map<String, DataLength> _fourDigitDataLength = {
    // Same format as above

    '7001': DataLength.fixed(13),
    '7002': DataLength.variable(30),
    '7003': DataLength.fixed(10),

    '8001': DataLength.fixed(14),
    '8002': DataLength.variable(20),
    '8003': DataLength.variable(30),
    '8004': DataLength.variable(30),
    '8005': DataLength.fixed(6),
    '8006': DataLength.fixed(18),
    '8007': DataLength.variable(30),
    '8008': DataLength.variable(12),
    '8018': DataLength.fixed(18),
    '8020': DataLength.variable(25),
    '8100': DataLength.fixed(6),
    '8101': DataLength.fixed(10),
    '8102': DataLength.fixed(2),
    '8110': DataLength.variable(70),
    '8200': DataLength.variable(70),
  };

  FieldParser._();

  static String? parseFieldsInGeneralPurpose(String rawInformation) {
    if (rawInformation.isEmpty) {
      return null;
    }

    // Processing 2-digit AIs

    if (rawInformation.length < 2) {
      throw NotFoundException.instance;
    }
    final firstTwoDigits = rawInformation.substring(0, 2);
    final twoDigitDataLength = _twoDigitDataLength[firstTwoDigits];
    if (twoDigitDataLength != null) {
      if (twoDigitDataLength.variable) {
        return _processVariableAI(2, twoDigitDataLength.length, rawInformation);
      }
      return _processFixedAI(2, twoDigitDataLength.length, rawInformation);
    }

    if (rawInformation.length < 3) {
      throw NotFoundException.instance;
    }

    final firstThreeDigits = rawInformation.substring(0, 3);
    final threeDigitDataLength = _threeDigitDataLength[firstThreeDigits];
    if (threeDigitDataLength != null) {
      if (threeDigitDataLength.variable) {
        return _processVariableAI(
          3,
          threeDigitDataLength.length,
          rawInformation,
        );
      }
      return _processFixedAI(3, threeDigitDataLength.length, rawInformation);
    }

    if (rawInformation.length < 4) {
      throw NotFoundException.instance;
    }

    final threeDigitPlusDigitDataLength =
        _threeDigitPlusDigitDataLength[firstThreeDigits];
    if (threeDigitPlusDigitDataLength != null) {
      if (threeDigitPlusDigitDataLength.variable) {
        return _processVariableAI(
          4,
          threeDigitPlusDigitDataLength.length,
          rawInformation,
        );
      }
      return _processFixedAI(
        4,
        threeDigitPlusDigitDataLength.length,
        rawInformation,
      );
    }

    final firstFourDigits = rawInformation.substring(0, 4);
    final firstFourDigitLength = _fourDigitDataLength[firstFourDigits];
    if (firstFourDigitLength != null) {
      if (firstFourDigitLength.variable) {
        return _processVariableAI(
          4,
          firstFourDigitLength.length,
          rawInformation,
        );
      }
      return _processFixedAI(4, firstFourDigitLength.length, rawInformation);
    }

    throw NotFoundException.instance;
  }

  static String _processFixedAI(
    int aiSize,
    int fieldSize,
    String rawInformation,
  ) {
    if (rawInformation.length < aiSize) {
      throw NotFoundException.instance;
    }

    final ai = rawInformation.substring(0, aiSize);

    if (rawInformation.length < aiSize + fieldSize) {
      throw NotFoundException.instance;
    }

    final field = rawInformation.substring(aiSize, aiSize + fieldSize);
    final remaining = rawInformation.substring(aiSize + fieldSize);
    final result = '($ai)$field';
    final parsedAI = parseFieldsInGeneralPurpose(remaining);
    return parsedAI == null ? result : (result + parsedAI);
  }

  static String _processVariableAI(
    int aiSize,
    int variableFieldSize,
    String rawInformation,
  ) {
    final ai = rawInformation.substring(0, aiSize);
    final maxSize = math.min(rawInformation.length, aiSize + variableFieldSize);
    final field = rawInformation.substring(aiSize, maxSize);
    final remaining = rawInformation.substring(maxSize);
    final result = '($ai)$field';
    final parsedAI = parseFieldsInGeneralPurpose(remaining);
    return parsedAI == null ? result : (result + parsedAI);
  }
}
