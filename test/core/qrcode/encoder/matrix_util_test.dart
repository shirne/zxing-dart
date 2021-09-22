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

import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';

void main() {
  test('testToString', () {
    ByteMatrix array = ByteMatrix(3, 3);
    array.set(0, 0, 0);
    array.set(1, 0, 1);
    array.set(2, 0, 0);
    array.set(0, 1, 1);
    array.set(1, 1, 0);
    array.set(2, 1, 1);
    array.set(0, 2, -1);
    array.set(1, 2, -1);
    array.set(2, 2, -1);
    String expected = " 0 1 0\n" " 1 0 1\n" "      \n";
    expect(expected, array.toString());
  });

  test('testClearMatrix', () {
    ByteMatrix matrix = ByteMatrix(2, 2);
    MatrixUtil.clearMatrix(matrix);
    expect(-1, matrix.get(0, 0));
    expect(-1, matrix.get(1, 0));
    expect(-1, matrix.get(0, 1));
    expect(-1, matrix.get(1, 1));
  });

  test('testEmbedBasicPatterns1', () {
    // Version 1.
    ByteMatrix matrix = ByteMatrix(21, 21);
    MatrixUtil.clearMatrix(matrix);
    MatrixUtil.embedBasicPatterns(Version.getVersionForNumber(1), matrix);
    String expected = " 1 1 1 1 1 1 1 0           0 1 1 1 1 1 1 1\n"
        " 1 0 0 0 0 0 1 0           0 1 0 0 0 0 0 1\n"
        " 1 0 1 1 1 0 1 0           0 1 0 1 1 1 0 1\n"
        " 1 0 1 1 1 0 1 0           0 1 0 1 1 1 0 1\n"
        " 1 0 1 1 1 0 1 0           0 1 0 1 1 1 0 1\n"
        " 1 0 0 0 0 0 1 0           0 1 0 0 0 0 0 1\n"
        " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n"
        " 0 0 0 0 0 0 0 0           0 0 0 0 0 0 0 0\n"
        "             1                            \n"
        "             0                            \n"
        "             1                            \n"
        "             0                            \n"
        "             1                            \n"
        " 0 0 0 0 0 0 0 0 1                        \n"
        " 1 1 1 1 1 1 1 0                          \n"
        " 1 0 0 0 0 0 1 0                          \n"
        " 1 0 1 1 1 0 1 0                          \n"
        " 1 0 1 1 1 0 1 0                          \n"
        " 1 0 1 1 1 0 1 0                          \n"
        " 1 0 0 0 0 0 1 0                          \n"
        " 1 1 1 1 1 1 1 0                          \n";
    expect(expected, matrix.toString());
  });

  test('testEmbedBasicPatterns2', () {
    // Version 2.  Position adjustment pattern should apppear at right
    // bottom corner.
    ByteMatrix matrix = ByteMatrix(25, 25);
    MatrixUtil.clearMatrix(matrix);
    MatrixUtil.embedBasicPatterns(Version.getVersionForNumber(2), matrix);
    String expected = " 1 1 1 1 1 1 1 0                   0 1 1 1 1 1 1 1\n"
        " 1 0 0 0 0 0 1 0                   0 1 0 0 0 0 0 1\n"
        " 1 0 1 1 1 0 1 0                   0 1 0 1 1 1 0 1\n"
        " 1 0 1 1 1 0 1 0                   0 1 0 1 1 1 0 1\n"
        " 1 0 1 1 1 0 1 0                   0 1 0 1 1 1 0 1\n"
        " 1 0 0 0 0 0 1 0                   0 1 0 0 0 0 0 1\n"
        " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n"
        " 0 0 0 0 0 0 0 0                   0 0 0 0 0 0 0 0\n"
        "             1                                    \n"
        "             0                                    \n"
        "             1                                    \n"
        "             0                                    \n"
        "             1                                    \n"
        "             0                                    \n"
        "             1                                    \n"
        "             0                                    \n"
        "             1                   1 1 1 1 1        \n"
        " 0 0 0 0 0 0 0 0 1               1 0 0 0 1        \n"
        " 1 1 1 1 1 1 1 0                 1 0 1 0 1        \n"
        " 1 0 0 0 0 0 1 0                 1 0 0 0 1        \n"
        " 1 0 1 1 1 0 1 0                 1 1 1 1 1        \n"
        " 1 0 1 1 1 0 1 0                                  \n"
        " 1 0 1 1 1 0 1 0                                  \n"
        " 1 0 0 0 0 0 1 0                                  \n"
        " 1 1 1 1 1 1 1 0                                  \n";
    expect(expected, matrix.toString());
  });

  test('testEmbedTypeInfo', () {
    // Type info bits = 100000011001110.
    ByteMatrix matrix = ByteMatrix(21, 21);
    MatrixUtil.clearMatrix(matrix);
    MatrixUtil.embedTypeInfo(ErrorCorrectionLevel.M, 5, matrix);
    String expected = "                 0                        \n"
        "                 1                        \n"
        "                 1                        \n"
        "                 1                        \n"
        "                 0                        \n"
        "                 0                        \n"
        "                                          \n"
        "                 1                        \n"
        " 1 0 0 0 0 0   0 1         1 1 0 0 1 1 1 0\n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        "                 0                        \n"
        "                 0                        \n"
        "                 0                        \n"
        "                 0                        \n"
        "                 0                        \n"
        "                 0                        \n"
        "                 1                        \n";
    expect(expected, matrix.toString());
  });

  test('testEmbedVersionInfo', () {
    // Version info bits = 000111 110010 010100
    // Actually, version 7 QR Code has 45x45 matrix but we use 21x21 here
    // since 45x45 matrix is too big to depict.
    ByteMatrix matrix = ByteMatrix(21, 21);
    MatrixUtil.clearMatrix(matrix);
    MatrixUtil.maybeEmbedVersionInfo(Version.getVersionForNumber(7), matrix);
    String expected = "                     0 0 1                \n"
        "                     0 1 0                \n"
        "                     0 1 0                \n"
        "                     0 1 1                \n"
        "                     1 1 1                \n"
        "                     0 0 0                \n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        " 0 0 0 0 1 0                              \n"
        " 0 1 1 1 1 0                              \n"
        " 1 0 0 1 1 0                              \n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        "                                          \n"
        "                                          \n";
    expect(expected, matrix.toString());
  });

  test('testEmbedDataBits', () {
    // Cells other than basic patterns should be filled with zero.
    ByteMatrix matrix = ByteMatrix(21, 21);
    MatrixUtil.clearMatrix(matrix);
    MatrixUtil.embedBasicPatterns(Version.getVersionForNumber(1), matrix);
    BitArray bits = BitArray();
    MatrixUtil.embedDataBits(bits, -1, matrix);
    String expected = " 1 1 1 1 1 1 1 0 0 0 0 0 0 0 1 1 1 1 1 1 1\n"
        " 1 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 1\n"
        " 1 0 1 1 1 0 1 0 0 0 0 0 0 0 1 0 1 1 1 0 1\n"
        " 1 0 1 1 1 0 1 0 0 0 0 0 0 0 1 0 1 1 1 0 1\n"
        " 1 0 1 1 1 0 1 0 0 0 0 0 0 0 1 0 1 1 1 0 1\n"
        " 1 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 1\n"
        " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n"
        " 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 1 0 1 1 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 1 0 1 1 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 1 0 1 1 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n"
        " 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n";
    expect(expected, matrix.toString());
  });

  test('testBuildMatrix', () {
    // From http://www.swetake.com/qr/qr7.html
    List<int> bytes = [
      32, 65, 205, 69, 41, 220, 46, 128, 236, //
      42, 159, 74, 221, 244, 169, 239, 150, 138,
      70, 237, 85, 224, 96, 74, 219, 61
    ];
    BitArray bits = BitArray();
    for (int c in bytes) {
      bits.appendBits(c, 8);
    }
    ByteMatrix matrix = ByteMatrix(21, 21);
    MatrixUtil.buildMatrix(
        bits,
        ErrorCorrectionLevel.H,
        Version.getVersionForNumber(1), // Version 1
        3, // Mask pattern 3
        matrix);
    String expected = " 1 1 1 1 1 1 1 0 0 1 1 0 0 0 1 1 1 1 1 1 1\n"
        " 1 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 1\n"
        " 1 0 1 1 1 0 1 0 0 0 0 1 0 0 1 0 1 1 1 0 1\n"
        " 1 0 1 1 1 0 1 0 0 1 1 0 0 0 1 0 1 1 1 0 1\n"
        " 1 0 1 1 1 0 1 0 1 1 0 0 1 0 1 0 1 1 1 0 1\n"
        " 1 0 0 0 0 0 1 0 0 0 1 1 1 0 1 0 0 0 0 0 1\n"
        " 1 1 1 1 1 1 1 0 1 0 1 0 1 0 1 1 1 1 1 1 1\n"
        " 0 0 0 0 0 0 0 0 1 1 0 1 1 0 0 0 0 0 0 0 0\n"
        " 0 0 1 1 0 0 1 1 1 0 0 1 1 1 1 0 1 0 0 0 0\n"
        " 1 0 1 0 1 0 0 0 0 0 1 1 1 0 0 1 0 1 1 1 0\n"
        " 1 1 1 1 0 1 1 0 1 0 1 1 1 0 0 1 1 1 0 1 0\n"
        " 1 0 1 0 1 1 0 1 1 1 0 0 1 1 1 0 0 1 0 1 0\n"
        " 0 0 1 0 0 1 1 1 0 0 0 0 0 0 1 0 1 1 1 1 1\n"
        " 0 0 0 0 0 0 0 0 1 1 0 1 0 0 0 0 0 1 0 1 1\n"
        " 1 1 1 1 1 1 1 0 1 1 1 1 0 0 0 0 1 0 1 1 0\n"
        " 1 0 0 0 0 0 1 0 0 0 0 1 0 1 1 1 0 0 0 0 0\n"
        " 1 0 1 1 1 0 1 0 0 1 0 0 1 1 0 0 1 0 0 1 1\n"
        " 1 0 1 1 1 0 1 0 1 1 0 1 0 0 0 0 0 1 1 1 0\n"
        " 1 0 1 1 1 0 1 0 1 1 1 1 0 0 0 0 1 1 1 0 0\n"
        " 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 1 0 0\n"
        " 1 1 1 1 1 1 1 0 0 0 1 1 1 1 1 0 1 0 0 1 0\n";
    expect(expected, matrix.toString());
  });

  test('testFindMSBSet', () {
    expect(0, MatrixUtil.findMSBSet(0));
    expect(1, MatrixUtil.findMSBSet(1));
    expect(8, MatrixUtil.findMSBSet(0x80));
    expect(32, MatrixUtil.findMSBSet(0x80000000));
  });

  test('testCalculateBCHCode', () {
    // Encoding of type information.
    // From Appendix C in JISX0510:2004 (p 65)
    expect(0xdc, MatrixUtil.calculateBCHCode(5, 0x537));
    // From http://www.swetake.com/qr/qr6.html
    expect(0x1c2, MatrixUtil.calculateBCHCode(0x13, 0x537));
    // From http://www.swetake.com/qr/qr11.html
    expect(0x214, MatrixUtil.calculateBCHCode(0x1b, 0x537));

    // Encoding of version information.
    // From Appendix D in JISX0510:2004 (p 68)
    expect(0xc94, MatrixUtil.calculateBCHCode(7, 0x1f25));
    expect(0x5bc, MatrixUtil.calculateBCHCode(8, 0x1f25));
    expect(0xa99, MatrixUtil.calculateBCHCode(9, 0x1f25));
    expect(0x4d3, MatrixUtil.calculateBCHCode(10, 0x1f25));
    expect(0x9a6, MatrixUtil.calculateBCHCode(20, 0x1f25));
    expect(0xd75, MatrixUtil.calculateBCHCode(30, 0x1f25));
    expect(0xc69, MatrixUtil.calculateBCHCode(40, 0x1f25));
  });

  // We don't test a lot of cases in this function since we've already
  // tested them in TEST(calculateBCHCode).
  test('testMakeVersionInfoBits', () {
    // From Appendix D in JISX0510:2004 (p 68)
    BitArray bits = BitArray();
    MatrixUtil.makeVersionInfoBits(Version.getVersionForNumber(7), bits);
    expect(" ...XXXXX ..X..X.X ..", bits.toString());
  });

  // We don't test a lot of cases in this function since we've already
  // tested them in TEST(calculateBCHCode).
  test('testMakeTypeInfoInfoBits', () {
    // From Appendix C in JISX0510:2004 (p 65)
    BitArray bits = BitArray();
    MatrixUtil.makeTypeInfoBits(ErrorCorrectionLevel.M, 5, bits);
    expect(" X......X X..XXX.", bits.toString());
  });
}
