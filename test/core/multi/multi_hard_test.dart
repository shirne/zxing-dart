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
import 'dart:typed_data';
import 'dart:ui';

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

  Future<ByteData?> source2Data(LuminanceSource source) async{
    //List<String> data = [];
    var image = BufferImage(source.width, source.height);
    for(int y=0;y<image.height;y++){
      var row = source.getRow(y, null);
      for(int x=0;x<image.width;x++){
        int c = row[x] & 0xff;
        //print("${row[x]} => $c");
        image.setColor(x, y, Color.fromARGB(255, c, c, c));
      }
    }
    var buffer = await ImmutableBuffer.fromUint8List(image.buffer);
    var desc = ImageDescriptor.raw(buffer, width: image.width, height: image.height, pixelFormat: PixelFormat.rgba8888);
    var codec = await desc.instantiateCodec();
    var frame = await codec.getNextFrame();
    //var byteData = await frame.image.toByteData(format: ImageByteFormat.png);
    return await frame.image.toByteData(format: ImageByteFormat.png);
  }

  Future<void> testQR(String name, {int down = 0, String text = 'www.airtable.com/jobs'}) async{
    Directory testBase = AbstractBlackBoxTestCase.buildTestBase("test/resources/blackbox/multi-2");
    int startTimer = DateTime.now().millisecondsSinceEpoch;

    File testImage = File('${testBase.path}/$name');
    BufferImage image = (await BufferImage.fromFile(testImage.readAsBytesSync()))!;
    if(down > 0){
      image.scaleDown(down.toDouble());
    }

    LuminanceSource source = RGBLuminanceSource(image.width, image.height, image.pixels);

    //MultipleBarcodeReader reader = GenericMultipleBarcodeReader(MultiFormatReader());
    var reader = MultiFormatReader();
    var hints = <DecodeHintType, Object>{
      DecodeHintType.TRY_HARDER: true,
      DecodeHintType.ALSO_INVERTED: true
    };

    Result? result;

    try {
      result = reader.decode(BinaryBitmap(HybridBinarizer(source)), hints);
    } on NotFoundException catch(_){
      try {
        result = reader.decode(BinaryBitmap(GlobalHistogramBinarizer(source)), hints);
      } on NotFoundException catch(_){ }
    }
    print('${DateTime.now().millisecondsSinceEpoch - startTimer} ms');
    if(result == null){
      print('decode failed: $name');
    }else {
      expect(text, result.text);
      expect(BarcodeFormat.QR_CODE, result.barcodeFormat);
      print('decoded:$name');
    }
  }

  test('testHardQR', () async{
    await testQR('inverted.png');
    await testQR('inverse.jpg', down: 2);
    await testQR('qr-clip3.png');
    await testQR('qr-clip2.png');
    await testQR('qr-clip1.png');
    await testQR('qr2.jpg', down: 2);
    await testQR('qr1.jpg', down:3);
  });
}
