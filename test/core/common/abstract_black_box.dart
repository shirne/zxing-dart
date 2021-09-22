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

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/zxing.dart';

import '../buffered_image_luminance_source.dart';
import 'logger.dart';
import 'properties.dart';
import 'test_result.dart';

class AbstractBlackBoxTestCase {
  static final Logger _log = Logger.getLogger(AbstractBlackBoxTestCase);

  final RegExp imageSuffix = RegExp(r'\.(jpe?g|gif|png)$');
  final Directory _testBase;
  final Reader? _barcodeReader;
  final BarcodeFormat? _expectedFormat;
  final List<TestResult> _testResults = [];
  final Map<DecodeHintType, Object> _hints = {};

  static Directory buildTestBase(String testBasePathSuffix) {
    // A little workaround to prevent aggravation in my IDE
    Directory testBase = Directory(testBasePathSuffix);

    return testBase;
  }

  AbstractBlackBoxTestCase(
      String testBasePathSuffix, this._barcodeReader, this._expectedFormat)
      : _testBase = buildTestBase(testBasePathSuffix);

  Directory getTestBase() {
    return _testBase;
  }

  void addHint(DecodeHintType hint) {
    _hints[hint] = true;
  }

  void testBlackBox() {
    assert(_testResults.isNotEmpty);

    List<File> imageFiles = getImageFiles();
    int testCount = _testResults.length;

    List<int> passedCounts = List.filled(testCount, 0);
    List<int> misreadCounts = List.filled(testCount, 0);
    List<int> tryHarderCounts = List.filled(testCount, 0);
    List<int> tryHarderMisreadCounts = List.filled(testCount, 0);

    for (File testImage in imageFiles) {
      _log.info("Starting ${testImage.path}");

      Image image = decodeImage(testImage.readAsBytesSync())!;

      String testImageFileName = testImage.uri.pathSegments.last;
      String fileBaseName =
          testImageFileName.substring(0, testImageFileName.indexOf('.'));
      File expectedTextFile =
          File(_testBase.path + '/' + fileBaseName + ".txt");
      String expectedText;
      if (expectedTextFile.existsSync()) {
        expectedText = expectedTextFile.readAsStringSync();
      } else {
        expectedTextFile = File(_testBase.path + '/' + fileBaseName + ".bin");
        assert(expectedTextFile.existsSync());
        expectedText = expectedTextFile.readAsStringSync(encoding: latin1);
      }

      File expectedMetadataFile =
          File(_testBase.path + '/' + fileBaseName + ".metadata.txt");
      Properties expectedMetadata = Properties();
      if (expectedMetadataFile.existsSync()) {
        expectedMetadata.load(expectedMetadataFile.readAsStringSync());
      }

      for (int x = 0; x < testCount; x++) {
        double rotation = _testResults[x].getRotation();
        Image rotatedImage = rotateImage(image, rotation);
        LuminanceSource source = BufferedImageLuminanceSource(rotatedImage);
        BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));
        try {
          if (_decode(
              bitmap, rotation, expectedText, expectedMetadata.properties,
              filename: fileBaseName)) {
            passedCounts[x]++;
          } else {
            misreadCounts[x]++;
          }
        } on ReaderException catch (_) {
          _log.fine("could not read $fileBaseName at rotation $rotation");
        }
        try {
          if (_decode(
              bitmap, rotation, expectedText, expectedMetadata.properties,
              tryHarder: true, filename: fileBaseName)) {
            tryHarderCounts[x]++;
          } else {
            tryHarderMisreadCounts[x]++;
          }
        } on ReaderException catch (_) {
          _log.fine("could not read $fileBaseName at rotation $rotation w/TH");
        }
      }
    }

    // Print the results of all tests first
    int totalFound = 0;
    int totalMustPass = 0;
    int totalMisread = 0;
    int totalMaxMisread = 0;

    for (int x = 0; x < _testResults.length; x++) {
      TestResult testResult = _testResults[x];
      _log.info("Rotation ${testResult.getRotation()} degrees:");
      _log.info(
          " ${passedCounts[x]} of ${imageFiles.length} images passed (${testResult.getMustPassCount()} required)");
      int failed = imageFiles.length - passedCounts[x];
      _log.info(
          " ${misreadCounts[x]} failed due to misreads, ${failed - misreadCounts[x]} not detected");
      _log.info(
          " ${tryHarderCounts[x]} of ${imageFiles.length} images passed with try harder (${testResult.getTryHarderCount()} required)");
      failed = imageFiles.length - tryHarderCounts[x];
      _log.info(
          " ${tryHarderMisreadCounts[x]} failed due to misreads, ${failed - tryHarderMisreadCounts[x]} not detected");
      totalFound += passedCounts[x] + tryHarderCounts[x];
      totalMustPass +=
          testResult.getMustPassCount() + testResult.getTryHarderCount();
      totalMisread += misreadCounts[x] + tryHarderMisreadCounts[x];
      totalMaxMisread +=
          testResult.getMaxMisreads() + testResult.getMaxTryHarderMisreads();
    }

    int totalTests = imageFiles.length * testCount * 2;
    _log.info(
        "Decoded $totalFound images out of $totalTests (${totalFound * 100 ~/ totalTests}%, $totalMustPass required)");
    if (totalFound > totalMustPass) {
      _log.warning("+++ Test too lax by ${totalFound - totalMustPass} images");
    } else if (totalFound < totalMustPass) {
      _log.warning("--- Test failed by ${totalMustPass - totalFound} images");
    }

    if (totalMisread < totalMaxMisread) {
      _log.warning(
        "+++ Test expects too many misreads by ${totalMaxMisread - totalMisread} images",
      );
    } else if (totalMisread > totalMaxMisread) {
      _log.warning(
          "--- Test had too many misreads by ${totalMisread - totalMaxMisread} images");
    }

    // Then run through again and assert if any failed
    for (int x = 0; x < testCount; x++) {
      TestResult testResult = _testResults[x];
      String label =
          "Rotation ${testResult.getRotation()} degrees: Too many images failed";
      assert(passedCounts[x] >= testResult.getMustPassCount(), label);
      assert(tryHarderCounts[x] >= testResult.getTryHarderCount(),
          "Try harder, $label");
      label =
          "Rotation ${testResult.getRotation()} degrees: Too many images misread";
      assert(misreadCounts[x] <= testResult.getMaxMisreads(), label);
      assert(tryHarderMisreadCounts[x] <= testResult.getMaxTryHarderMisreads(),
          "Try harder, $label");
    }
  }

  /// Adds a new test for the current directory of images.
  ///
  /// @param mustPassCount The number of images which must decode for the test to pass.
  /// @param tryHarderCount The number of images which must pass using the try harder flag.
  /// @param maxMisreads Maximum number of images which can fail due to successfully reading the wrong contents
  /// @param maxTryHarderMisreads Maximum number of images which can fail due to successfully
  ///                             reading the wrong contents using the try harder flag
  /// @param rotation The rotation in degrees clockwise to use for this test.
  void addTest(int mustPassCount, int tryHarderCount, double rotation,
      [int maxMisreads = 0, int maxTryHarderMisreads = 0]) {
    _testResults.add(TestResult(mustPassCount, tryHarderCount, maxMisreads,
        maxTryHarderMisreads, rotation));
  }

  List<File> getImageFiles() {
    assert(_testBase.existsSync(),
        "Please download and install test images, and run from the 'test' directory");
    List<File> paths = [];
    var files = _testBase.listSync();
    for (var element in files) {
      if (element is File && imageSuffix.hasMatch(element.path)) {
        // "*.{jpg,jpeg,gif,png,JPG,JPEG,GIF,PNG}"
        paths.add(element);
      }
    }

    return paths;
  }

  Reader? get reader => _barcodeReader;

  bool _decode(BinaryBitmap source, double rotation, String expectedText,
      Map<Object, Object> expectedMetadata,
      {bool tryHarder = false, filename = ''}) {
    String suffix = " (${tryHarder ? 'try harder, ' : ''}rotation: $rotation)";

    var hints = Map<DecodeHintType, Object>.from(_hints);
    if (tryHarder) {
      hints[DecodeHintType.TRY_HARDER] = true;
      hints[DecodeHintType.ALSO_INVERTED] = true;
    }

    // Try in 'pure' mode mostly to exercise PURE_BARCODE code paths for exceptions;
    // not expected to pass, generally
    Result? result;
    try {
      var pureHints = Map<DecodeHintType, Object>.from(hints);
      pureHints[DecodeHintType.PURE_BARCODE] = true;
      result = _barcodeReader!.decode(source, pureHints);
    } on ReaderException catch (_) {
      // continue
    }

    result ??= _barcodeReader!.decode(source, hints);

    if (_expectedFormat != result.barcodeFormat) {
      _log.warning(
          "Format mismatch: $filename expected '$_expectedFormat' but got '${result.barcodeFormat}'$suffix");
      return false;
    }

    String resultText = result.text;
    if (expectedText != resultText) {
      _log.warning(
          "Content mismatch: $filename expected '$expectedText' but got '$resultText'$suffix");
      return false;
    }

    Map<ResultMetadataType, Object>? resultMetadata = result.resultMetadata;
    for (MapEntry metadatum in expectedMetadata.entries) {
      ResultMetadataType key = string2RMType(metadatum.key)!;
      Object expectedValue = metadatum.value;
      Object? actualValue = resultMetadata?[key];
      if (expectedValue != actualValue) {
        _log.warning(
            "Metadata mismatch $filename for key '${key.toString().replaceFirst('ResultMetadataType.', '')}': expected '$expectedValue' but got '$actualValue'");
        return false;
      }
    }

    return true;
  }

  ResultMetadataType? string2RMType(String type) {
    for (ResultMetadataType rType in ResultMetadataType.values) {
      if (rType.toString().replaceFirst('ResultMetadataType.', '') == type) {
        return rType;
      }
    }
    return null;
  }

  static String readFileAsString(File file, Encoding charset) {
    String stringContents = file.readAsStringSync(encoding: charset);
    if (stringContents.endsWith("\n")) {
      _log.info("String contents of file $file end with a newline. " "This may not be intended and cause a test failure");
    }
    return stringContents;
  }

  static Image rotateImage(Image original, double degrees) {
    if (degrees == 0.0) {
      return original;
    }

    //double radians = Math.pi * 2 * (degrees / 360);

    // Transform simply to find out the new bounding box (don't actually run the image through it)
    //AffineTransform at = AffineTransform();
    //at.rotate(radians, original.width / 2.0, original.height / 2.0);
    //BufferedImageOp op = AffineTransformOp(at, AffineTransformOp.TYPE_BICUBIC);

    //original.rotate(radians);

    //RectangularShape r = op.getBounds2D(original);
    //int width = (int) Math.ceil(r.width);
    //int height = (int) Math.ceil(r.height);

    // Real transform, now that we know the size of the new image and how to translate after we rotate
    // to keep it centered
    //at = AffineTransform();
    //at.rotate(radians, width / 2.0, height / 2.0);
    //at.translate((width - original.width) / 2.0,
    //             (height - original.height) / 2.0);
    //op = AffineTransformOp(at, AffineTransformOp.TYPE_BICUBIC);

    //return op.filter(original, BufferedImage(width, height, original.getType()));

    return copyRotate(original, degrees, interpolation: Interpolation.linear);
  }
}
