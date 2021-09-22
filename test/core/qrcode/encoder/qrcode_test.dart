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
import 'package:zxing_lib/qrcode.dart';

void main() {
  test('test', () {
    // First, test simple setters and getters.
    // We use numbers of version 7-H.
    QRCode qrCode = QRCode(
        mode: Mode.BYTE,
        ecLevel: ErrorCorrectionLevel.H,
        version: Version.getVersionForNumber(7),
        maskPattern: 3);

    expect(Mode.BYTE, qrCode.mode);
    expect(ErrorCorrectionLevel.H, qrCode.ecLevel);
    expect(7, qrCode.version!.versionNumber);
    expect(3, qrCode.maskPattern);

    // Prepare the matrix.
    ByteMatrix matrix = ByteMatrix(45, 45);
    // Just set bogus zero/one values.
    for (int y = 0; y < 45; ++y) {
      for (int x = 0; x < 45; ++x) {
        matrix.set(x, y, (y + x) % 2);
      }
    }

    // Set the matrix.
    qrCode.matrix = matrix;
    expect(matrix, qrCode.matrix);
  });

  test('testToString1', () {
    QRCode qrCode = QRCode();
    String expected = "<<\n"
        " mode: null\n"
        " ecLevel: null\n"
        " version: null\n"
        " maskPattern: -1\n"
        " matrix: null\n"
        ">>\n";
    expect(expected, qrCode.toString());
  });

  test('testToString2', () {
    QRCode qrCode = QRCode(
        mode: Mode.BYTE,
        ecLevel: ErrorCorrectionLevel.H,
        version: Version.getVersionForNumber(1),
        maskPattern: 3);
    ByteMatrix matrix = ByteMatrix(21, 21);
    for (int y = 0; y < 21; ++y) {
      for (int x = 0; x < 21; ++x) {
        matrix.set(x, y, (y + x) % 2);
      }
    }
    qrCode.matrix = matrix;
    String expected = "<<\n"
        " mode: BYTE\n"
        " ecLevel: H\n"
        " version: 1\n"
        " maskPattern: 3\n"
        " matrix:\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        " 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1\n"
        " 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0\n"
        ">>\n";
    expect(expected, qrCode.toString());
  });

  test('testIsValidMaskPattern', () {
    assert(!QRCode.isValidMaskPattern(-1));
    assert(QRCode.isValidMaskPattern(0));
    assert(QRCode.isValidMaskPattern(7));
    assert(!QRCode.isValidMaskPattern(8));
  });
}
