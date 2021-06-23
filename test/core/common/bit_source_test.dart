/*
 * Copyright 2007 ZXing authors
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

import 'dart:typed_data';

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';



void main() {

  test('testSource', () {
    Uint8List bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    BitSource source = new BitSource(bytes);
    expect(40, source.available());
    expect(0, source.readBits(1));
    expect(39, source.available());
    expect(0, source.readBits(6));
    expect(33, source.available());
    expect(1, source.readBits(1));
    expect(32, source.available());
    expect(2, source.readBits(8));
    expect(24, source.available());
    expect(12, source.readBits(10));
    expect(14, source.available());
    expect(16, source.readBits(8));
    expect(6, source.available());
    expect(5, source.readBits(6));
    expect(0, source.available());
  });

}