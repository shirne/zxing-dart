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

import '../../../../common/string_builder.dart';

import '../../../../not_found_exception.dart';
import 'ai01_decoder.dart';
import 'ai01_weight_decoder.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
/// @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
class AI013x0x1xDecoder extends AI01WeightDecoder {
  static const int _headerSize = 7 + 1;
  static const int _weightSize = 20;
  static const int _dateSize = 16;

  final String _dateCode;
  final String _firstAIdigits;

  AI013x0x1xDecoder(super.information, this._firstAIdigits, this._dateCode);

  @override
  String parseInformation() {
    if (information.size !=
        _headerSize + AI01Decoder.gtinSize + _weightSize + _dateSize) {
      throw NotFoundException.instance;
    }

    final buf = StringBuilder();

    encodeCompressedGtin(buf, _headerSize);
    encodeCompressedWeight(
      buf,
      _headerSize + AI01Decoder.gtinSize,
      _weightSize,
    );
    _encodeCompressedDate(
      buf,
      _headerSize + AI01Decoder.gtinSize + _weightSize,
    );

    return buf.toString();
  }

  void _encodeCompressedDate(StringBuffer buf, int currentPos) {
    int numericDate =
        generalDecoder.extractNumericValueFromBitArray(currentPos, _dateSize);
    if (numericDate == 38400) {
      return;
    }

    buf.write('(');
    buf.write(_dateCode);
    buf.write(')');

    final day = numericDate % 32;
    numericDate = numericDate ~/ 32;
    final month = numericDate % 12 + 1;
    numericDate = numericDate ~/ 12;
    final year = numericDate;

    if (year ~/ 10 == 0) {
      buf.write('0');
    }
    buf.write(year);
    if (month ~/ 10 == 0) {
      buf.write('0');
    }
    buf.write(month);
    if (day ~/ 10 == 0) {
      buf.write('0');
    }
    buf.write(day);
  }

  //@protected
  @override
  void addWeightCode(StringBuffer buf, int weight) {
    buf.write('(');
    buf.write(_firstAIdigits);
    buf.write(weight ~/ 100000);
    buf.write(')');
  }

  //@protected
  @override
  int checkWeight(int weight) => weight % 100000;
}
