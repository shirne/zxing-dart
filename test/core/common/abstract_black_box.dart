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
  final Directory testBase;
  final Reader? _barcodeReader;
  final BarcodeFormat? _expectedFormat;
  final List<TestResult> _testResults = [];
  final DecodeHint hints;
  final Image Function(Image, String)? imageProcess;

  static Directory buildTestBase(String testBasePathSuffix) {
    // A little workaround to prevent aggravation in my IDE
    final testBase = Directory(testBasePathSuffix);

    return testBase;
  }

  AbstractBlackBoxTestCase(
    String testBasePathSuffix,
    this._barcodeReader,
    this._expectedFormat, {
    this.imageProcess,
    this.hints = const DecodeHint(),
  }) : testBase = buildTestBase(testBasePathSuffix);

  void testBlackBox() {
    assert(_testResults.isNotEmpty);

    final imageFiles = getImageFiles();
    final testCount = _testResults.length;

    final passedCounts = List.filled(testCount, 0);
    final misreadCounts = List.filled(testCount, 0);
    final tryHarderCounts = List.filled(testCount, 0);
    final tryHarderMisreadCounts = List.filled(testCount, 0);

    for (File testImage in imageFiles) {
      _log.info('Starting ${testImage.path}');

      Image image = decodeImage(testImage.readAsBytesSync())!;
      if (imageProcess != null) {
        image = imageProcess!.call(image, testImage.absolute.path);
      }

      final testImageFileName = testImage.uri.pathSegments.last;
      final fileBaseName = testImageFileName.substring(
        0,
        testImageFileName.indexOf('.'),
      );
      File expectedTextFile = File('${testBase.path}/$fileBaseName.txt');
      String expectedText;
      if (expectedTextFile.existsSync()) {
        expectedText = expectedTextFile.readAsStringSync();
      } else {
        expectedTextFile = File('${testBase.path}/$fileBaseName.bin');
        assert(expectedTextFile.existsSync());
        expectedText = expectedTextFile.readAsStringSync(encoding: latin1);
      }

      final expectedMetadataFile =
          File('${testBase.path}/$fileBaseName.metadata.txt');
      final expectedMetadata = Properties();
      if (expectedMetadataFile.existsSync()) {
        expectedMetadata.load(expectedMetadataFile.readAsStringSync());

        correctInteger(expectedMetadata, ResultMetadataType.errorsCorrected);
        correctInteger(expectedMetadata, ResultMetadataType.erasuresCorrected);
      }

      for (int x = 0; x < testCount; x++) {
        final rotation = _testResults[x].rotation;
        final rotatedImage = rotateImage(image, rotation);
        final source = BufferedImageLuminanceSource(rotatedImage);
        final bitmap = BinaryBitmap(HybridBinarizer(source));
        try {
          if (_decode(
            bitmap,
            rotation,
            expectedText,
            expectedMetadata.properties,
            filename: fileBaseName,
          )) {
            passedCounts[x]++;
          } else {
            misreadCounts[x]++;
          }
        } on ReaderException catch (_) {
          _log.fine('could not read $fileBaseName at rotation $rotation');
        }
        try {
          if (_decode(
            bitmap,
            rotation,
            expectedText,
            expectedMetadata.properties,
            tryHarder: true,
            filename: fileBaseName,
          )) {
            tryHarderCounts[x]++;
          } else {
            tryHarderMisreadCounts[x]++;
          }
        } on ReaderException catch (_) {
          _log.fine('could not read $fileBaseName at rotation $rotation w/TH');
        }
      }
    }

    // Print the results of all tests first
    int totalFound = 0;
    int totalMustPass = 0;
    int totalMisread = 0;
    int totalMaxMisread = 0;

    for (int x = 0; x < _testResults.length; x++) {
      final testResult = _testResults[x];
      _log.info('Rotation ${testResult.rotation} degrees:');
      _log.info(
        ' ${passedCounts[x]} of ${imageFiles.length} images passed (${testResult.mustPassCount} required)',
      );
      int failed = imageFiles.length - passedCounts[x];
      _log.info(
        ' ${misreadCounts[x]} failed due to misreads, ${failed - misreadCounts[x]} not detected',
      );
      _log.info(
        ' ${tryHarderCounts[x]} of ${imageFiles.length} images passed with try harder (${testResult.tryHarderCount} required)',
      );
      failed = imageFiles.length - tryHarderCounts[x];
      _log.info(
        ' ${tryHarderMisreadCounts[x]} failed due to misreads, ${failed - tryHarderMisreadCounts[x]} not detected',
      );
      totalFound += passedCounts[x] + tryHarderCounts[x];
      totalMustPass += testResult.mustPassCount + testResult.tryHarderCount;
      totalMisread += misreadCounts[x] + tryHarderMisreadCounts[x];
      totalMaxMisread +=
          testResult.maxMisreads + testResult.maxTryHarderMisreads;
    }

    final totalTests = imageFiles.length * testCount * 2;
    _log.info(
      'Decoded $totalFound images out of $totalTests (${totalFound * 100 ~/ totalTests}%, $totalMustPass required)',
    );
    if (totalFound > totalMustPass) {
      _log.warning('+++ Test too lax by ${totalFound - totalMustPass} images');
    } else if (totalFound < totalMustPass) {
      _log.warning('--- Test failed by ${totalMustPass - totalFound} images');
    }

    if (totalMisread < totalMaxMisread) {
      _log.warning(
        '+++ Test expects too many misreads by ${totalMaxMisread - totalMisread} images',
      );
    } else if (totalMisread > totalMaxMisread) {
      _log.warning(
        '--- Test had too many misreads by ${totalMisread - totalMaxMisread} images',
      );
    }

    // Then run through again and assert if any failed
    for (int x = 0; x < testCount; x++) {
      final testResult = _testResults[x];
      String label = 'Rotation ${testResult.rotation} degrees: '
          'Too many images failed(${passedCounts[x]}/${testResult.mustPassCount})';
      assert(passedCounts[x] >= testResult.mustPassCount, label);
      assert(
        tryHarderCounts[x] >= testResult.tryHarderCount,
        'Try harder, $label',
      );
      label = 'Rotation ${testResult.rotation} degrees: '
          'Too many images misread(${passedCounts[x]}/${testResult.mustPassCount})';
      assert(misreadCounts[x] <= testResult.maxMisreads, label);
      assert(
        tryHarderMisreadCounts[x] <= testResult.maxTryHarderMisreads,
        'Try harder, $label',
      );
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
  void addTest(
    int mustPassCount,
    int tryHarderCount,
    double rotation, [
    int maxMisreads = 0,
    int maxTryHarderMisreads = 0,
  ]) {
    _testResults.add(
      TestResult(
        mustPassCount,
        tryHarderCount,
        maxMisreads,
        maxTryHarderMisreads,
        rotation,
      ),
    );
  }

  List<File> getImageFiles() {
    assert(
      testBase.existsSync(),
      "Please download and install test images, and run from the 'test' directory",
    );
    final paths = <File>[];
    final files = testBase.listSync();
    for (var element in files) {
      if (element is File && imageSuffix.hasMatch(element.path)) {
        // "*.{jpg,jpeg,gif,png,JPG,JPEG,GIF,PNG}"
        paths.add(element);
      }
    }

    return paths;
  }

  void correctInteger(Properties metadata, ResultMetadataType key) {
    final skey = key.identifier;
    if (metadata.properties.containsKey(skey)) {
      final sval = metadata.getProperty(skey) ?? '';
      final ival = int.tryParse(sval) ?? 0;
      metadata.setProperty(skey, ival);
    }
  }

  Reader? get reader => _barcodeReader;

  bool _decode(
    BinaryBitmap source,
    double rotation,
    String expectedText,
    Map<Object, dynamic> expectedMetadata, {
    bool tryHarder = false,
    String filename = '',
  }) {
    final suffix = " (${tryHarder ? 'try harder, ' : ''}rotation: $rotation)";

    final hints = tryHarder
        ? this.hints.copyWith(
              tryHarder: true,
              alsoInverted: true,
            )
        : this.hints;

    // Try in 'pure' mode mostly to exercise PURE_BARCODE code paths for exceptions;
    // not expected to pass, generally
    Result? result;
    try {
      result = _barcodeReader!.decode(
        source,
        hints.copyWith(pureBarcode: true),
      );
    } on ReaderException catch (_) {
      // continue
    }

    result ??= _barcodeReader!.decode(source, hints);

    if (_expectedFormat != result.barcodeFormat) {
      _log.warning(
        "Format mismatch: $filename expected '$_expectedFormat'"
        " but got '${result.barcodeFormat}'$suffix",
      );
      return false;
    }

    final resultText = result.text;
    if (expectedText != resultText) {
      _log.warning(
        "Content mismatch: $filename expected '$expectedText'"
        " but got '$resultText'$suffix",
      );
      return false;
    }

    final resultMetadata = result.resultMetadata;
    for (MapEntry metadatum in expectedMetadata.entries) {
      final key = string2RMType(metadatum.key)!;
      final Object expectedValue = metadatum.value;
      final Object? actualValue = resultMetadata?[key];
      if (expectedValue != actualValue) {
        _log.warning(
          "Metadata mismatch $filename for key '${key.toString().replaceFirst('ResultMetadataType.', '')}': expected '$expectedValue' but got '$actualValue'",
        );
        return false;
      }
    }

    return true;
  }

  ResultMetadataType? string2RMType(String type) {
    for (ResultMetadataType rType in ResultMetadataType.values) {
      if (rType.identifier == type) {
        return rType;
      }
    }
    return null;
  }

  static String readFileAsString(File file, Encoding charset) {
    final stringContents = file.readAsStringSync(encoding: charset);
    if (stringContents.endsWith('\n')) {
      _log.info('String contents of file $file end with a newline. '
          'This may not be intended and cause a test failure');
    }
    return stringContents;
  }

  static Image rotateImage(Image original, double degrees) {
    if (degrees == 0.0) {
      return original;
    }

    return copyRotate(
      original,
      angle: degrees,
      interpolation: Interpolation.linear,
    );
  }
}
