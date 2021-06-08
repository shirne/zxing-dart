/*
 * Copyright 2016 ZXing authors
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




import 'dart:io';

import 'package:buffer_image/buffer_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/multi.dart';
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../buffered_image_luminance_source.dart';
import '../common/abstract_black_box.dart';

/// Tests {@link MultipleBarcodeReader}.
void main(){

  test('testMulti', () async{
    // Very basic test for now
    Directory testBase = AbstractBlackBoxTestCase.buildTestBase("test/resources/blackbox/multi-1");

    File testImage = File(testBase.path + '/1.png');
    BufferImage image = (await BufferImage.fromFile(testImage))!;
    LuminanceSource source = BufferedImageLuminanceSource(image);
    BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));

    MultipleBarcodeReader reader = GenericMultipleBarcodeReader(MultiFormatReader());
    List<Result> results = reader.decodeMultiple(bitmap);
    //assertNotNull(results);
    expect(results.length, 2);

    expect("031415926531", results[0].getText());
    expect(BarcodeFormat.UPC_A, results[0].getBarcodeFormat());

    expect("www.airtable.com/jobs", results[1].getText());
    expect(BarcodeFormat.QR_CODE, results[1].getBarcodeFormat());
  });

}
