/*
 * Copyright 2006 Jeremias Maerki.
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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/datamatrix.dart';

import '../../utils.dart';

/// Tests for the ECC200 error correction.
void main() {
  test('testRS', () {
    //Sample from Annexe R in ISO/IEC 16022:2000(E)
    List<int> cw = [142, 164, 186];
    final symbolInfo = SymbolInfo.lookup(3)!;
    String s =
        ErrorCorrection.encodeECC200(String.fromCharCodes(cw), symbolInfo);
    expect('142 164 186 114 25 5 88 102', visualize(s));

    //"A" encoded (ASCII encoding + 2 padding characters)
    cw = [66, 129, 70];
    s = ErrorCorrection.encodeECC200(String.fromCharCodes(cw), symbolInfo);
    expect('66 129 70 138 234 82 82 95', visualize(s));
  });
}
