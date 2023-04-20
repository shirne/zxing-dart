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

enum _State { numeric, alpha, isoIec646 }

/// @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
class CurrentParsingState {
  int position = 0;
  _State _encoding = _State.numeric;

  CurrentParsingState();

  void incrementPosition(int delta) {
    position += delta;
  }

  bool get isAlpha => _encoding == _State.alpha;

  bool get isNumeric => _encoding == _State.numeric;

  bool get isIsoIec646 => _encoding == _State.isoIec646;

  void setNumeric() {
    _encoding = _State.numeric;
  }

  void setAlpha() {
    _encoding = _State.alpha;
  }

  void setIsoIec646() {
    _encoding = _State.isoIec646;
  }
}
