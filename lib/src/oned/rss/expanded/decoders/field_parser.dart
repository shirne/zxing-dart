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
    '16': DataLength.fixed(6),
    '17': DataLength.fixed(6),

    '20': DataLength.fixed(2),
    '21': DataLength.variable(20),
    // limited to 20 in latest versions of spec
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

    '235': DataLength.variable(28),
    '240': DataLength.variable(30),
    '241': DataLength.variable(30),
    '242': DataLength.variable(6),
    '243': DataLength.variable(20),
    '250': DataLength.variable(30),
    '251': DataLength.variable(30),
    '253': DataLength.variable(30),
    '254': DataLength.variable(20),
    '255': DataLength.variable(25),

    '400': DataLength.variable(30),
    '401': DataLength.variable(30),
    '402': DataLength.fixed(17),
    '403': DataLength.variable(30),
    '410': DataLength.fixed(13),
    '411': DataLength.fixed(13),
    '412': DataLength.fixed(13),
    '413': DataLength.fixed(13),
    '414': DataLength.fixed(13),
    '415': DataLength.fixed(13),
    '416': DataLength.fixed(13),
    '417': DataLength.fixed(13),
    '420': DataLength.variable(20),
    // limited to 12 in latest versions of spec
    '421': DataLength.variable(15),
    '422': DataLength.fixed(3),
    '423': DataLength.variable(15),
    '424': DataLength.fixed(3),
    '425': DataLength.variable(15),
    '426': DataLength.fixed(3),
    '427': DataLength.variable(3),
    '710': DataLength.variable(20),
    '711': DataLength.variable(20),
    '712': DataLength.variable(20),
    '713': DataLength.variable(20),
    '714': DataLength.variable(20),
    '715': DataLength.variable(20),
  };

  static final Map<String, DataLength> _threeDigitPlusDigitDataLength = {
    // Same format as above
    for (int i = 310; i <= 316; i++) '$i': DataLength.fixed(6),
    for (int i = 320; i <= 337; i++) '$i': DataLength.fixed(6),
    for (int i = 340; i <= 357; i++) '$i': DataLength.fixed(6),

    for (int i = 360; i <= 369; i++) '$i': DataLength.fixed(6),

    '390': DataLength.variable(15),
    '391': DataLength.variable(18),
    '392': DataLength.variable(15),
    '393': DataLength.variable(18),
    '394': DataLength.fixed(4),
    '395': DataLength.fixed(6),
    '703': DataLength.variable(30),
    '723': DataLength.variable(30),
  };

  static final Map<String, DataLength> _fourDigitDataLength = {
    // Same format as above

    '4300': DataLength.variable(35),
    '4301': DataLength.variable(35),
    '4302': DataLength.variable(70),
    '4303': DataLength.variable(70),
    '4304': DataLength.variable(70),
    '4305': DataLength.variable(70),
    '4306': DataLength.variable(70),
    '4307': DataLength.fixed(2),
    '4308': DataLength.variable(30),
    '4309': DataLength.fixed(20),
    '4310': DataLength.variable(35),
    '4311': DataLength.variable(35),
    '4312': DataLength.variable(70),
    '4313': DataLength.variable(70),
    '4314': DataLength.variable(70),
    '4315': DataLength.variable(70),
    '4316': DataLength.variable(70),
    '4317': DataLength.fixed(2),
    '4318': DataLength.variable(20),
    '4319': DataLength.variable(30),
    '4320': DataLength.variable(35),
    '4321': DataLength.fixed(1),
    '4322': DataLength.fixed(1),
    '4323': DataLength.fixed(1),
    '4324': DataLength.fixed(10),
    '4325': DataLength.fixed(10),
    '4326': DataLength.fixed(6),
    '7001': DataLength.fixed(13),
    '7002': DataLength.variable(30),
    '7003': DataLength.fixed(10),
    '7004': DataLength.variable(4),
    '7005': DataLength.variable(12),
    '7006': DataLength.fixed(6),
    '7007': DataLength.variable(12),
    '7008': DataLength.variable(3),
    '7009': DataLength.variable(10),
    '7010': DataLength.variable(2),
    '7011': DataLength.variable(10),
    '7020': DataLength.variable(20),
    '7021': DataLength.variable(20),
    '7022': DataLength.variable(20),
    '7023': DataLength.variable(30),
    '7040': DataLength.fixed(4),
    '7240': DataLength.variable(20),
    '8001': DataLength.fixed(14),
    '8002': DataLength.variable(20),
    '8003': DataLength.variable(30),
    '8004': DataLength.variable(30),
    '8005': DataLength.fixed(6),
    '8006': DataLength.fixed(18),
    '8007': DataLength.variable(34),
    '8008': DataLength.variable(12),
    '8009': DataLength.variable(50),
    '8010': DataLength.variable(30),
    '8011': DataLength.variable(12),
    '8012': DataLength.variable(20),
    '8013': DataLength.variable(25),
    '8017': DataLength.fixed(18),
    '8018': DataLength.fixed(18),
    '8019': DataLength.variable(10),
    '8020': DataLength.variable(25),
    '8026': DataLength.fixed(18),
    '8100': DataLength.fixed(6),
    '8101': DataLength.fixed(10),
    '8102': DataLength.fixed(2),
    '8110': DataLength.variable(70),
    '8111': DataLength.fixed(4),
    '8112': DataLength.variable(70),
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
