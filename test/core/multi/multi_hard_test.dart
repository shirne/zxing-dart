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
import 'package:zxing_lib/zxing.dart';

import '../buffered_image_luminance_source.dart';
import '../common/abstract_black_box.dart';
import '../utils.dart';

/// This is a high difficulty test.
/// I'm looking for a way to do it
///
/// todo Not passed yet
void main(){

  test('testMulti', () async{
    // Very basic test for now
    Directory testBase = AbstractBlackBoxTestCase.buildTestBase("test/resources/blackbox/multi-2");

    File testImage = File(testBase.path + '/multi.jpg');
    BufferImage image = (await BufferImage.fromFile(testImage.readAsBytesSync()))!;
    BufferedImageLuminanceSource source = BufferedImageLuminanceSource(image.toGray()..deNoise()..deNoise());
    //source = source.scaleDown(2);
    BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));

    MultipleBarcodeReader reader = GenericMultipleBarcodeReader(MultiFormatReader());
    List<Result> results = reader.decodeMultiple(bitmap);
    //assertNotNull(results);
    expect(results.length, 2);

    expect("031415926531", results[0].text);
    expect(BarcodeFormat.UPC_A, results[0].barcodeFormat);

    expect("www.airtable.com/jobs", results[1].text);
    expect(BarcodeFormat.QR_CODE, results[1].barcodeFormat);
  });

  Future<void> testQR(String name, {int down = 4, String result = 'www.airtable.com/jobs'}) async{
    Directory testBase = AbstractBlackBoxTestCase.buildTestBase("test/resources/blackbox/multi-2");

    File testImage = File('${testBase.path}/$name');
    BufferImage image = (await BufferImage.fromFile(testImage.readAsBytesSync()))!;
    //BufferedImageLuminanceSource source = BufferedImageLuminanceSource(image);
    var source = PlanarYUVLuminanceSource(getYUV420sp(image, image.width, image.height),
      image.width, image.height, 0, 0, image.width, image.height, false);


    //MultipleBarcodeReader reader = GenericMultipleBarcodeReader(MultiFormatReader());
    var reader = MultiFormatReader();
    var hints = {DecodeHintType.TRY_HARDER: true};
    Result? result;
    try {
      result = reader.decode(BinaryBitmap(HybridBinarizer(source)), hints);
    } on NotFoundException catch(_){
      try {
        result = reader.decode(BinaryBitmap(GlobalHistogramBinarizer(source)), hints);
      } on NotFoundException catch(_){
        image.inverse();
        source = PlanarYUVLuminanceSource(getYUV420sp(image, image.width, image.height),
            image.width, image.height, 0, 0, image.width, image.height, false);
        result = reader.decode(BinaryBitmap(GlobalHistogramBinarizer(source)), hints);
      }
    }

    expect(result, result.text);
    expect(BarcodeFormat.QR_CODE, result.barcodeFormat);
    print('$name passed');

  }

  test('testHardQR', () async{
    await testQR('inverse.jpg');
    await testQR('qr-clip3.png');
    await testQR('qr-clip2.png');
    await testQR('qr-clip1.png');
    await testQR('qr2.jpg');
    await testQR('qr1.jpg', down:3);
  });
}
