/*
 * Copyright 2009 ZXing authors
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


import 'package:flutter_test/flutter_test.dart';
import 'package:zxing/common.dart';
import 'package:zxing/pdf417.dart';
import 'package:zxing/zxing.dart';


/// Tests {@link DecodedBitStreamParser}.
void main(){

  /// Tests the first sample given in ISO/IEC 15438:2015(E) - Annex H.4
  test('testStandardSample1', (){
    PDF417ResultMetadata resultMetadata = new PDF417ResultMetadata();
    List<int> sampleCodes = [20, 928, 111, 100, 17, 53, 923, 1, 111, 104, 923, 3, 64, 416, 34, 923, 4, 258, 446, 67,
      // we should never reach these
      1000, 1000, 1000];

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);

    expect(resultMetadata.getSegmentIndex(), 0);
    expect(resultMetadata.getFileId(), "017053");
    assert(!resultMetadata.isLastSegment());
    expect(resultMetadata.getSegmentCount(), 4);
    expect(resultMetadata.getSender(), "CEN BE");
    expect(resultMetadata.getAddressee(), "ISO CH");

    //@SuppressWarnings("deprecation")
    List<int> optionalData = resultMetadata.getOptionalData()!;
    expect(optionalData[0], 1, reason:"first element of optional array should be the first field identifier");
    expect(optionalData[optionalData.length - 1], 67,
        reason: "last element of optional array should be the last codeword of the last field");
  });


  /// Tests the second given in ISO/IEC 15438:2015(E) - Annex H.4
  test('testStandardSample2', (){
    PDF417ResultMetadata resultMetadata = new PDF417ResultMetadata();
    List<int> sampleCodes = [11, 928, 111, 103, 17, 53, 923, 1, 111, 104, 922,
      // we should never reach these
      1000, 1000, 1000];

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);

    expect(3, resultMetadata.getSegmentIndex());
    expect("017053", resultMetadata.getFileId());
    assert(resultMetadata.isLastSegment());
    expect(4, resultMetadata.getSegmentCount());
    assert(resultMetadata.getAddressee() == null);
    assert(resultMetadata.getSender() == null);

    //@SuppressWarnings("deprecation")
    List<int> optionalData = resultMetadata.getOptionalData()!;
    expect(1, optionalData[0], reason: "first element of optional array should be the first field identifier");
    expect(104, optionalData[optionalData.length - 1], reason: "last element of optional array should be the last codeword of the last field");
  });


  /// Tests the example given in ISO/IEC 15438:2015(E) - Annex H.6
  test('testStandardSample3', (){
    PDF417ResultMetadata resultMetadata = new PDF417ResultMetadata();
    List<int> sampleCodes = [7, 928, 111, 100, 100, 200, 300,
      0]; // Final dummy ECC codeword required to avoid ArrayIndexOutOfBounds

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);

    expect(0, resultMetadata.getSegmentIndex());
    expect("100200300", resultMetadata.getFileId());
    assert(!resultMetadata.isLastSegment());
    expect(-1, resultMetadata.getSegmentCount());
    assert(resultMetadata.getAddressee() == null);
    assert(resultMetadata.getSender() == null);
    assert(resultMetadata.getOptionalData() == null);

    // Check that symbol containing no data except Macro is accepted (see note in Annex H.2)
    DecoderResult decoderResult = DecodedBitStreamParser.decode(sampleCodes, "0");
    expect("", decoderResult.getText());
    assert(decoderResult.getOther() != null);
  });

  test('testSampleWithFilename', (){
    List<int> sampleCodes = [23, 477, 928, 111, 100, 0, 252, 21, 86, 923, 0, 815, 251, 133, 12, 148, 537, 593,
        599, 923, 1, 111, 102, 98, 311, 355, 522, 920, 779, 40, 628, 33, 749, 267, 506, 213, 928, 465, 248,
        493, 72, 780, 699, 780, 493, 755, 84, 198, 628, 368, 156, 198, 809, 19, 113];
    PDF417ResultMetadata resultMetadata = new PDF417ResultMetadata();

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 3, resultMetadata);

    expect(0, resultMetadata.getSegmentIndex());
    expect("000252021086", resultMetadata.getFileId());
    assert(!resultMetadata.isLastSegment());
    expect(2, resultMetadata.getSegmentCount());
    assert(resultMetadata.getAddressee() == null);
    assert(resultMetadata.getSender() == null);
    expect("filename.txt", resultMetadata.getFileName());
  });

  test('testSampleWithNumericValues', (){
    List<int> sampleCodes = [25, 477, 928, 111, 100, 0, 252, 21, 86, 923, 2, 2, 0, 1, 0, 0, 0, 923, 5, 130, 923,
        6, 1, 500, 13, 0];
    PDF417ResultMetadata resultMetadata = new PDF417ResultMetadata();

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 3, resultMetadata);

    expect(0, resultMetadata.getSegmentIndex());
    expect("000252021086", resultMetadata.getFileId());
    assert(!resultMetadata.isLastSegment());

    expect(180980729000000, resultMetadata.getTimestamp());
    expect(30, resultMetadata.getFileSize());
    expect(260013, resultMetadata.getChecksum());
  });

  test('testSampleWithMacroTerminatorOnly', (){
    List<int> sampleCodes = [7, 477, 928, 222, 198, 0, 922];
    PDF417ResultMetadata resultMetadata = new PDF417ResultMetadata();

    DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 3, resultMetadata);

    expect(99998, resultMetadata.getSegmentIndex());
    expect("000", resultMetadata.getFileId());
    assert(resultMetadata.isLastSegment());
    expect(-1, resultMetadata.getSegmentCount());
    assert(resultMetadata.getOptionalData() == null);
  });

  test('testSampleWithBadSequenceIndexMacro', (){
    List<int> sampleCodes = [3, 928, 222, 0];
    PDF417ResultMetadata resultMetadata = new PDF417ResultMetadata();

    try {
      DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);
    } catch ( _) { // FormatException
      // continue
    }
  });

  test('testSampleWithNoFileIdMacro', (){
    List<int> sampleCodes = [4, 928, 222, 198, 0];
    PDF417ResultMetadata resultMetadata = new PDF417ResultMetadata();

    try {
      DecodedBitStreamParser.decodeMacroBlock(sampleCodes, 2, resultMetadata);
    } catch ( _) { // FormatException
      // continue
    }
  });

  test('testSampleWithNoDataNoMacro', (){
    List<int> sampleCodes = [3, 899, 899, 0];

    try {
      DecodedBitStreamParser.decode(sampleCodes, "0");
    } catch ( _) { // FormatException
      // continue
    }

  });

}