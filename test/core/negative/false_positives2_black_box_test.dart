/*
 * Copyright 2008 ZXing authors
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

import '../common/abstract_negative_black_box.dart';

/// Additional random images with high contrast patterns which should not find any barcodes.
///
void main(){

  test('FalsePositives2BlackBoxTestCase', () {
    AbstractNegativeBlackBoxTestCase("test/resources/blackbox/falsepositives-2")
    ..addNegativeTest(4, 0.0)
    ..addNegativeTest(4, 90.0)
    ..addNegativeTest(4, 180.0)
    ..addNegativeTest(4, 270.0)
        ..testBlackBox();
  });

}
