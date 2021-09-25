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

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/multi.dart';
import 'package:zxing_lib/pdf417.dart';
import 'package:zxing_lib/zxing.dart';

import '../buffered_image_luminance_source.dart';
import '../common/abstract_black_box.dart';
import '../common/logger.dart';
import '../common/test_result.dart';

void main() {
  test('PDF417BlackBox4TestCase', () {
    PDF417BlackBox4TestCase().testBlackBox();
  });
}

/// This class tests Macro PDF417 barcode specific functionality. It ensures that information, which is split into
/// several barcodes can be properly combined again to yield the original data content.
///
class PDF417BlackBox4TestCase extends AbstractBlackBoxTestCase {
  static final Logger log = Logger.getLogger(AbstractBlackBoxTestCase);

  final MultipleBarcodeReader barcodeReader = PDF417Reader();

  final List<TestResult> testResults = [];

  PDF417BlackBox4TestCase()
      : super("test/resources/blackbox/pdf417-4", null, BarcodeFormat.PDF_417) {
    testResults.add(TestResult(3, 3, 0, 0, 0.0));
  }

  @override
  void testBlackBox() {
    assert(testResults.isNotEmpty);

    Map<String, List<File>> imageFiles = getImageFileLists();
    assert(imageFiles.isNotEmpty);
    int testCount = testResults.length;

    List<int> passedCounts = List.filled(testCount, 0);
    List<int> tryHarderCounts = List.filled(testCount, 0);

    Directory testBase = getTestBase();

    for (MapEntry<String, List<File>> testImageGroup in imageFiles.entries) {
      log.fine("Starting Image Group ${testImageGroup.key}");

      String fileBaseName = testImageGroup.key;
      String expectedText;
      File expectedTextFile = File(testBase.path + '/' + fileBaseName + ".txt");
      if (expectedTextFile.existsSync()) {
        expectedText = expectedTextFile.readAsStringSync();
      } else {
        expectedTextFile = File(testBase.path + '/' + fileBaseName + ".bin");
        assert(expectedTextFile.existsSync());
        expectedText = expectedTextFile.readAsStringSync(encoding: latin1);
      }

      for (int x = 0; x < testCount; x++) {
        List<Result> results = [];
        for (File imageFile in testImageGroup.value) {
          Image image = decodeImage(imageFile.readAsBytesSync())!;
          double rotation = testResults[x].rotation;
          Image rotatedImage =
              AbstractBlackBoxTestCase.rotateImage(image, rotation);
          LuminanceSource source = BufferedImageLuminanceSource(rotatedImage);
          BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));

          try {
            results.addAll(decode(bitmap, false));
          } on ReaderException catch (_) {
            // ignore
          }
        }
        results.sort((Result r, Result o) =>
            getMeta(r)!.segmentIndex.compareTo(getMeta(o)!.segmentIndex));
        var resultText = StringBuffer();
        String? fileId;
        for (Result result in results) {
          PDF417ResultMetadata resultMetadata = getMeta(result)!;
          //assertNotNull("resultMetadata", resultMetadata);
          fileId ??= resultMetadata.fileId;
          expect(fileId, resultMetadata.fileId, reason: "FileId");
          resultText.write(result.text);
        }
        expect(resultText.toString(), expectedText, reason: "ExpectedText");
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
      log.info(
        "Rotation ${testResult.rotation} degrees:",
      );
      log.info(
          " ${passedCounts[x]} of $numberOfTests images passed (${testResult.mustPassCount} required)");
      log.info(
          " ${tryHarderCounts[x]} of $numberOfTests images passed with try harder (${testResult.tryHarderCount} required)");
      totalFound += passedCounts[x] + tryHarderCounts[x];
      totalMustPass += testResult.mustPassCount + testResult.tryHarderCount;
    }

    int totalTests = numberOfTests * testCount * 2;
    log.info(
        "Decoded $totalFound images out of $totalTests (${totalFound * 100 ~/ totalTests}%, $totalMustPass required)");
    if (totalFound > totalMustPass) {
      log.warning("+++ Test too lax by ${totalFound - totalMustPass} images");
    } else if (totalFound < totalMustPass) {
      log.warning("--- Test failed by ${totalMustPass - totalFound} images");
    }

    // Then run through again and assert if any failed
    for (int x = 0; x < testCount; x++) {
      TestResult testResult = testResults[x];
      String label =
          "Rotation ${testResult.rotation} degrees: Too many images failed";
      assert(passedCounts[x] >= testResult.mustPassCount, label);
      assert(tryHarderCounts[x] >= testResult.tryHarderCount,
          "Try harder, $label");
    }
  }

  static PDF417ResultMetadata? getMeta(Result result) {
    return result.resultMetadata == null
        ? null
        : result.resultMetadata![ResultMetadataType.PDF417_EXTRA_METADATA]
            as PDF417ResultMetadata?;
  }

  List<Result> decode(BinaryBitmap source, bool tryHarder) {
    Map<DecodeHintType, Object> hints = {};
    if (tryHarder) {
      hints[DecodeHintType.TRY_HARDER] = true;
    }

    return barcodeReader.decodeMultiple(source, hints);
  }

  Map<String, List<File>> getImageFileLists() {
    Map<String, List<File>> result = {};
    for (File file in getImageFiles()) {
      String testImageFileName = file.uri.pathSegments.last;
      String fileBaseName =
          testImageFileName.substring(0, testImageFileName.indexOf('-'));
      List<File> files = result.putIfAbsent(fileBaseName, () => []);
      files.add(file);
    }
    return result;
  }
}
