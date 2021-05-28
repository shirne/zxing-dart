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

import '../data_character.dart';
import '../finder_pattern.dart';

/**
 * @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
 */
class ExpandedPair {
  final DataCharacter? leftChar;
  final DataCharacter? rightChar;
  final FinderPattern? finderPattern;

  ExpandedPair(this.leftChar, this.rightChar, this.finderPattern);

  DataCharacter? getLeftChar() {
    return this.leftChar;
  }

  DataCharacter? getRightChar() {
    return this.rightChar;
  }

  FinderPattern? getFinderPattern() {
    return this.finderPattern;
  }

  bool mustBeLast() {
    return this.rightChar == null;
  }

  @override
  String toString() {
    return "[ $leftChar , $rightChar : ${finderPattern == null ? "null" : finderPattern!.getValue()} ]";
  }

  @override
  operator ==(Object o) {
    if (!(o is ExpandedPair)) {
      return false;
    }
    ExpandedPair that = o;
    return (leftChar == that.leftChar) &&
        (rightChar == that.rightChar) &&
        (finderPattern == that.finderPattern);
  }

  @override
  int get hashCode {
    return leftChar.hashCode ^ rightChar.hashCode ^ finderPattern.hashCode;
  }
}
