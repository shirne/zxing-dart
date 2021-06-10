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

import 'dart:io';

import 'package:buffer_image/buffer_image.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

import '../buffered_image_luminance_source.dart';
import 'abstract_black_box.dart';
import 'logger.dart';

class TestResult {
  final int falsePositivesAllowed;
  final double rotation;

  TestResult(this.falsePositivesAllowed, this.rotation);

  int getFalsePositivesAllowed() {
    return falsePositivesAllowed;
  }

  double getRotation() {
    return rotation;
  }
}

/// This abstract class looks for negative results, i.e. it only allows a certain number of false
/// positives in images which should not decode. This helps ensure that we are not too lenient.
///

class AbstractNegativeBlackBoxTestCase extends AbstractBlackBoxTestCase {

  static final Logger log = Logger.getLogger(AbstractNegativeBlackBoxTestCase);

  final List<TestResult> testResults = [];

  // Use the multiformat reader to evaluate all decoders in the system.
  AbstractNegativeBlackBoxTestCase(String testBasePathSuffix):super(testBasePathSuffix, new MultiFormatReader(), null);

  void addNegativeTest(int falsePositivesAllowed, double rotation) {
    testResults.add(new TestResult(falsePositivesAllowed, rotation));
  }

  void testBlackBox() async{
    assert(testResults.isNotEmpty);

    List<File> imageFiles = getImageFiles();
    List<int> falsePositives = List.filled(testResults.length, 0);
    for (File testImage in imageFiles) {
      log.info("Starting $testImage");
      BufferImage image = (await BufferImage.fromFile(testImage))!;
      //if (image == null) {
      //  throw new IOException("Could not read image: " + testImage);
      //}
      for (int x = 0; x < testResults.length; x++) {
        TestResult testResult = testResults[x];
        if (!checkForFalsePositives(image, testResult.getRotation())) {
          falsePositives[x]++;
        }
      }
    }

    int totalFalsePositives = 0;
    int totalAllowed = 0;

    for (int x = 0; x < testResults.length; x++) {
      TestResult testResult = testResults[x];
      totalFalsePositives += falsePositives[x];
      totalAllowed += testResult.getFalsePositivesAllowed();
    }

    if (totalFalsePositives < totalAllowed) {
      log.warning("+++ Test too lax by ${totalAllowed - totalFalsePositives} images");
    } else if (totalFalsePositives > totalAllowed) {
      log.warning("--- Test failed by ${totalFalsePositives - totalAllowed} images");
    }

    for (int x = 0; x < testResults.length; x++) {
      TestResult testResult = testResults[x];
      log.info("Rotation ${testResult.getRotation().toInt()} degrees: ${falsePositives[x]} of ${imageFiles.length} images were false positives (${testResult.getFalsePositivesAllowed()} allowed)");
      assert(falsePositives[x] <= testResult.getFalsePositivesAllowed(),
      "Rotation ${testResult.getRotation()} degrees: Too many false positives found");
    }
  }

  /// Make sure ZXing does NOT find a barcode in the image.
  ///
  /// @param image The image to test
  /// @param rotationInDegrees The amount of rotation to apply
  /// @return true if nothing found, false if a non-existent barcode was detected
  bool checkForFalsePositives(BufferImage image, double rotationInDegrees) {
    BufferImage rotatedImage = AbstractBlackBoxTestCase.rotateImage(image, rotationInDegrees);
    LuminanceSource source = new BufferedImageLuminanceSource(rotatedImage);
    BinaryBitmap bitmap = new BinaryBitmap(HybridBinarizer(source));
    Result result;
    try {
      result = reader!.decode(bitmap);
      log.info("Found false positive: '${result.text}' with format '${result.barcodeFormat}' (rotation: ${rotationInDegrees.toInt()})");
      return false;
    } catch ( _) { // ReaderException
      // continue
    }

    // Try "try harder" getMode
    Map<DecodeHintType,Object> hints = {};
    hints[DecodeHintType.TRY_HARDER] = true;
    try {
      result = reader!.decode(bitmap, hints);
      log.info("Try harder found false positive: '${result.text}' with format '${result.barcodeFormat}' (rotation: ${rotationInDegrees.toInt()})");
      return false;
    } catch ( re) { // ReaderException
      // continue
    }
    return true;
  }

}
