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

import '../../../common/bit_array.dart';

import 'expanded_pair.dart';

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
/// @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
class BitArrayBuilder {
  BitArrayBuilder._();

  static BitArray buildBitArray(List<ExpandedPair> pairs) {
    int charNumber = (pairs.length * 2) - 1;
    if (pairs[pairs.length - 1].rightChar == null) {
      charNumber -= 1;
    }

    final size = 12 * charNumber;

    final binary = BitArray(size);
    int accPos = 0;

    final firstPair = pairs[0];
    final firstValue = firstPair.rightChar!.value;
    for (int i = 11; i >= 0; --i) {
      if ((firstValue & (1 << i)) != 0) {
        binary.set(accPos);
      }
      accPos++;
    }

    for (int i = 1; i < pairs.length; ++i) {
      final currentPair = pairs[i];

      final leftValue = currentPair.leftChar!.value;
      for (int j = 11; j >= 0; --j) {
        if ((leftValue & (1 << j)) != 0) {
          binary.set(accPos);
        }
        accPos++;
      }

      if (currentPair.rightChar != null) {
        final rightValue = currentPair.rightChar!.value;
        for (int j = 11; j >= 0; --j) {
          if ((rightValue & (1 << j)) != 0) {
            binary.set(accPos);
          }
          accPos++;
        }
      }
    }
    return binary;
  }
}
