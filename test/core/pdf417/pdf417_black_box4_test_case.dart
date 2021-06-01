/*
 * Copyright 2013 ZXing authors
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
import 'package:zxing/common.dart';
import 'package:zxing/multi.dart';
import 'package:zxing/pdf417.dart';
import 'package:zxing/zxing.dart';


import '../buffered_image_luminance_source.dart';
import '../common/abstract_black_box.dart';
import '../common/logger.dart';
import '../common/test_result.dart';

void main(){
  test('testBlackBox', (){
    PDF417BlackBox4TestCase testCase = PDF417BlackBox4TestCase();
    testCase.testBlackBox();
  });
}

/**
 * This class tests Macro PDF417 barcode specific functionality. It ensures that information, which is split into
 * several barcodes can be properly combined again to yield the original data content.
 *
 * @author Guenther Grau
 */
class PDF417BlackBox4TestCase extends AbstractBlackBoxTestCase {
  static final Logger log = Logger.getLogger(AbstractBlackBoxTestCase);

  final MultipleBarcodeReader barcodeReader = new PDF417Reader();

  final List<TestResult> testResults = [];

  PDF417BlackBox4TestCase():super("src/test/resources/blackbox/pdf417-4", null, BarcodeFormat.PDF_417) {
    testResults.add(TestResult(3, 3, 0, 0, 0.0));
  }

  @override
  void testBlackBox() async{
    assert(testResults.isNotEmpty);

    Map<String,List<File>> imageFiles = getImageFileLists();
    int testCount = testResults.length;

    List<int> passedCounts = List.filled(testCount, 0);
    List<int> tryHarderCounts = List.filled(testCount, 0);

    Directory testBase = getTestBase();

    for (MapEntry<String,List<File>> testImageGroup in imageFiles.entries) {
      log.fine("Starting Image Group ${testImageGroup.key}");

      String fileBaseName = testImageGroup.key;
      String expectedText;
      File expectedTextFile = File(testBase.path +'/'+fileBaseName + ".txt");
      if (expectedTextFile.existsSync()) {
        expectedText = expectedTextFile.readAsStringSync();
      } else {
        expectedTextFile = File(testBase.path +'/'+fileBaseName + ".bin");
        assert(expectedTextFile.existsSync());
        expectedText = expectedTextFile.readAsStringSync();
      }

      for (int x = 0; x < testCount; x++) {
        List<Result> results = [];
        for (File imageFile in testImageGroup.value) {
          BufferImage image = (await BufferImage.fromFile(imageFile))!;
          double rotation = testResults[x].getRotation();
          BufferImage rotatedImage = AbstractBlackBoxTestCase.rotateImage(image, rotation);
          LuminanceSource source = BufferedImageLuminanceSource(rotatedImage);
          BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));

          try {
            results.addAll(decode(bitmap, false));
          } catch ( _) { // ReaderException
            // ignore
          }
        }
        results.sort((Result r, Result o) => getMeta(r)!.getSegmentIndex().compareTo(getMeta(o)!.getSegmentIndex()));
        StringBuilder resultText = new StringBuilder();
        String? fileId;
        for (Result result in results) {
          PDF417ResultMetadata resultMetadata = getMeta(result)!;
          //assertNotNull("resultMetadata", resultMetadata);
          if (fileId == null) {
            fileId = resultMetadata.getFileId();
          }
          expect(fileId, resultMetadata.getFileId(),reason: "FileId");
          resultText.write(result.getText());
        }
        expect( expectedText, resultText.toString(), reason:"ExpectedText");
        passedCounts[x]++;
        tryHarderCounts[x]++;
      }
    }

    // Print the results of all tests first
    int totalFound = 0;
    int totalMustPass = 0;

    int numberOfTests = imageFiles.keys.length;
    for (int x = 0; x < testResults.length; x++) {
      TestResult testResult = testResults[x];
      log.info("Rotation ${testResult.getRotation()} degrees:", );
      log.info(" ${passedCounts[x]} of $numberOfTests images passed (${testResult.getMustPassCount()} required)");
      log.info(" ${tryHarderCounts[x]} of $numberOfTests images passed with try harder (${testResult.getTryHarderCount()} required)");
      totalFound += passedCounts[x] + tryHarderCounts[x];
      totalMustPass += testResult.getMustPassCount() + testResult.getTryHarderCount();
    }

    int totalTests = numberOfTests * testCount * 2;
    log.info("Decoded $totalFound images out of $totalTests (${totalFound * 100 ~/ totalTests}%, $totalMustPass required)");
    if (totalFound > totalMustPass) {
      log.warning("+++ Test too lax by ${totalFound - totalMustPass} images");
    } else if (totalFound < totalMustPass) {
      log.warning("--- Test failed by ${totalMustPass - totalFound} images");
    }

    // Then run through again and assert if any failed
    for (int x = 0; x < testCount; x++) {
      TestResult testResult = testResults[x];
      String label = "Rotation ${testResult.getRotation()} degrees: Too many images failed";
      assert( passedCounts[x] >= testResult.getMustPassCount(), label);
      assert( tryHarderCounts[x] >= testResult.getTryHarderCount(), "Try harder, $label");
    }
  }

  static PDF417ResultMetadata? getMeta(Result result) {
    return result.getResultMetadata() == null ? null :
      result.getResultMetadata()![ResultMetadataType.PDF417_EXTRA_METADATA] as PDF417ResultMetadata;
  }

  List<Result> decode(BinaryBitmap source, bool tryHarder){
    Map<DecodeHintType,Object> hints = {};
    if (tryHarder) {
      hints[DecodeHintType.TRY_HARDER] = true;
    }

    return barcodeReader.decodeMultiple(source, hints);
  }

  Map<String,List<File>> getImageFileLists(){
    Map<String,List<File>> result = {};
    for (File file in getImageFiles()) {
      String testImageFileName = file.uri.pathSegments.last;
      String fileBaseName = testImageFileName.substring(0, testImageFileName.indexOf('-'));
      List<File> files = result[fileBaseName] ?? [];
      files.add(file);
    }
    return result;
  }

}