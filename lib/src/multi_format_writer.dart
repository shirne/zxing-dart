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

import 'aztec/aztec_writer.dart';
import 'barcode_format.dart';
import 'common/bit_matrix.dart';
import 'datamatrix/data_matrix_writer.dart';
import 'encode_hint_type.dart';
import 'oned/coda_bar_writer.dart';
import 'oned/code128_writer.dart';
import 'oned/code39_writer.dart';
import 'oned/code93_writer.dart';
import 'oned/ean13_writer.dart';
import 'oned/ean8_writer.dart';
import 'oned/itfwriter.dart';
import 'oned/upcawriter.dart';
import 'oned/upcewriter.dart';
import 'pdf417/pdf417_writer.dart';
import 'qrcode/qrcode_writer.dart';
import 'writer.dart';

/// This is a factory class which finds the appropriate Writer subclass for the BarcodeFormat
/// requested and encodes the barcode with the supplied contents.
///
/// @author dswitkin@google.com (Daniel Switkin)
class MultiFormatWriter implements Writer {
  @override
  BitMatrix encode(
    String contents,
    BarcodeFormat format,
    int width,
    int height, [
    Map<EncodeHintType, Object>? hints,
  ]) {
    Writer writer;
    switch (format) {
      case BarcodeFormat.EAN_8:
        writer = EAN8Writer();
        break;
      case BarcodeFormat.UPC_E:
        writer = UPCEWriter();
        break;
      case BarcodeFormat.EAN_13:
        writer = EAN13Writer();
        break;
      case BarcodeFormat.UPC_A:
        writer = UPCAWriter();
        break;
      case BarcodeFormat.QR_CODE:
        writer = QRCodeWriter();
        break;
      case BarcodeFormat.CODE_39:
        writer = Code39Writer();
        break;
      case BarcodeFormat.CODE_93:
        writer = Code93Writer();
        break;
      case BarcodeFormat.CODE_128:
        writer = Code128Writer();
        break;
      case BarcodeFormat.ITF:
        writer = ITFWriter();
        break;
      case BarcodeFormat.PDF_417:
        writer = PDF417Writer();
        break;
      case BarcodeFormat.CODABAR:
        writer = CodaBarWriter();
        break;
      case BarcodeFormat.DATA_MATRIX:
        writer = DataMatrixWriter();
        break;
      case BarcodeFormat.AZTEC:
        writer = AztecWriter();
        break;
      default:
        throw ArgumentError('No encoder available for format $format');
    }
    return writer.encode(contents, format, width, height, hints);
  }
}
