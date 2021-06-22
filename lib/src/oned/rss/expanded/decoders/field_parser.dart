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

import 'dart:math' as Math;

import '../../../../not_found_exception.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
/// @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
class FieldParser {
  static final Object _variableLength = Object();

  static final List<List<Object>> _twoDigitDataLength = [
    // "DIGITS", new Integer(LENGTH)
    //    or
    // "DIGITS", VARIABLE_LENGTH, new Integer(MAX_SIZE)

    ["00", 18],
    ["01", 14],
    ["02", 14],

    ["10", _variableLength, 20],
    ["11", 6],
    ["12", 6],
    ["13", 6],
    ["15", 6],
    ["17", 6],

    ["20", 2],
    ["21", _variableLength, 20],
    ["22", _variableLength, 29],

    ["30", _variableLength, 8],
    ["37", _variableLength, 8],

    //internal company codes
    ["90", _variableLength, 30],
    ["91", _variableLength, 30],
    ["92", _variableLength, 30],
    ["93", _variableLength, 30],
    ["94", _variableLength, 30],
    ["95", _variableLength, 30],
    ["96", _variableLength, 30],
    ["97", _variableLength, 30],
    ["98", _variableLength, 30],
    ["99", _variableLength, 30],
  ];

  static final List<List<Object>> _threeDigitDataLength = [
    // Same format as above

    ["240", _variableLength, 30],
    ["241", _variableLength, 30],
    ["242", _variableLength, 6],
    ["250", _variableLength, 30],
    ["251", _variableLength, 30],
    ["253", _variableLength, 17],
    ["254", _variableLength, 20],

    ["400", _variableLength, 30],
    ["401", _variableLength, 30],
    ["402", 17],
    ["403", _variableLength, 30],
    ["410", 13],
    ["411", 13],
    ["412", 13],
    ["413", 13],
    ["414", 13],
    ["420", _variableLength, 20],
    ["421", _variableLength, 15],
    ["422", 3],
    ["423", _variableLength, 15],
    ["424", 3],
    ["425", 3],
    ["426", 3],
  ];

  static final List<List<Object>> _threeDigitPlusDigitDataLength = [
    // Same format as above

    ["310", 6],
    ["311", 6],
    ["312", 6],
    ["313", 6],
    ["314", 6],
    ["315", 6],
    ["316", 6],
    ["320", 6],
    ["321", 6],
    ["322", 6],
    ["323", 6],
    ["324", 6],
    ["325", 6],
    ["326", 6],
    ["327", 6],
    ["328", 6],
    ["329", 6],
    ["330", 6],
    ["331", 6],
    ["332", 6],
    ["333", 6],
    ["334", 6],
    ["335", 6],
    ["336", 6],
    ["340", 6],
    ["341", 6],
    ["342", 6],
    ["343", 6],
    ["344", 6],
    ["345", 6],
    ["346", 6],
    ["347", 6],
    ["348", 6],
    ["349", 6],
    ["350", 6],
    ["351", 6],
    ["352", 6],
    ["353", 6],
    ["354", 6],
    ["355", 6],
    ["356", 6],
    ["357", 6],
    ["360", 6],
    ["361", 6],
    ["362", 6],
    ["363", 6],
    ["364", 6],
    ["365", 6],
    ["366", 6],
    ["367", 6],
    ["368", 6],
    ["369", 6],
    ["390", _variableLength, 15],
    ["391", _variableLength, 18],
    ["392", _variableLength, 15],
    ["393", _variableLength, 18],
    ["703", _variableLength, 30],
  ];

  static final List<List<Object>> _fourDigitDataLength = [
    // Same format as above

    ["7001", 13],
    ["7002", _variableLength, 30],
    ["7003", 10],

    ["8001", 14],
    ["8002", _variableLength, 20],
    ["8003", _variableLength, 30],
    ["8004", _variableLength, 30],
    ["8005", 6],
    ["8006", 18],
    ["8007", _variableLength, 30],
    ["8008", _variableLength, 12],
    ["8018", 18],
    ["8020", _variableLength, 25],
    ["8100", 6],
    ["8101", 10],
    ["8102", 2],
    ["8110", _variableLength, 70],
    ["8200", _variableLength, 70],
  ];

  FieldParser._();

  static String? parseFieldsInGeneralPurpose(String rawInformation) {
    if (rawInformation.isEmpty) {
      return null;
    }

    // Processing 2-digit AIs

    if (rawInformation.length < 2) {
      throw NotFoundException.instance;
    }

    String firstTwoDigits = rawInformation.substring(0, 2);

    for (List<Object> dataLength in _twoDigitDataLength) {
      if (dataLength[0] == firstTwoDigits) {
        if (dataLength[1] == _variableLength) {
          return _processVariableAI(2, dataLength[2] as int, rawInformation);
        }
        return _processFixedAI(2, dataLength[1] as int, rawInformation);
      }
    }

    if (rawInformation.length < 3) {
      throw NotFoundException.instance;
    }

    String firstThreeDigits = rawInformation.substring(0, 3);

    for (List<Object> dataLength in _threeDigitDataLength) {
      if (dataLength[0] == firstThreeDigits) {
        if (dataLength[1] == _variableLength) {
          return _processVariableAI(3, dataLength[2] as int, rawInformation);
        }
        return _processFixedAI(3, dataLength[1] as int, rawInformation);
      }
    }

    for (List<Object> dataLength in _threeDigitPlusDigitDataLength) {
      if (dataLength[0] == firstThreeDigits) {
        if (dataLength[1] == _variableLength) {
          return _processVariableAI(4, dataLength[2] as int, rawInformation);
        }
        return _processFixedAI(4, dataLength[1] as int, rawInformation);
      }
    }

    if (rawInformation.length < 4) {
      throw NotFoundException.instance;
    }

    String firstFourDigits = rawInformation.substring(0, 4);

    for (List<Object> dataLength in _fourDigitDataLength) {
      if (dataLength[0] == firstFourDigits) {
        if (dataLength[1] == _variableLength) {
          return _processVariableAI(4, dataLength[2] as int, rawInformation);
        }
        return _processFixedAI(4, dataLength[1] as int, rawInformation);
      }
    }

    throw NotFoundException.instance;
  }

  static String _processFixedAI(
      int aiSize, int fieldSize, String rawInformation) {
    if (rawInformation.length < aiSize) {
      throw NotFoundException.instance;
    }

    String ai = rawInformation.substring(0, aiSize);

    if (rawInformation.length < aiSize + fieldSize) {
      throw NotFoundException.instance;
    }

    String field = rawInformation.substring(aiSize, aiSize + fieldSize);
    String remaining = rawInformation.substring(aiSize + fieldSize);
    String result = '($ai)$field';
    String? parsedAI = parseFieldsInGeneralPurpose(remaining);
    return parsedAI == null ? result : (result + parsedAI);
  }

  static String _processVariableAI(
      int aiSize, int variableFieldSize, String rawInformation) {
    String ai = rawInformation.substring(0, aiSize);
    int maxSize = Math.min(rawInformation.length, aiSize + variableFieldSize);
    String field = rawInformation.substring(aiSize, maxSize);
    String remaining = rawInformation.substring(maxSize);
    String result = '($ai)$field';
    String? parsedAI = parseFieldsInGeneralPurpose(remaining);
    return parsedAI == null ? result : (result + parsedAI);
  }
}
