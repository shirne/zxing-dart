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

import '../common/bit_array.dart';

import '../barcode_format.dart';
import '../decode_hint_type.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../reader_exception.dart';
import '../result.dart';
import 'coda_bar_reader.dart';
import 'code128_reader.dart';
import 'code39_reader.dart';
import 'code93_reader.dart';
import 'itfreader.dart';
import 'multi_format_upceanreader.dart';
import 'one_dreader.dart';
import 'rss/expanded/rssexpanded_reader.dart';
import 'rss/rss14_reader.dart';

/// @author dswitkin@google.com (Daniel Switkin)
/// @author Sean Owen
class MultiFormatOneDReader extends OneDReader {
  static const List<OneDReader> _emptyOnedArray = [];

  late List<OneDReader> _readers;

  MultiFormatOneDReader(Map<DecodeHintType, Object>? hints) {
    // @SuppressWarnings("unchecked")
    List<BarcodeFormat>? possibleFormats =
      hints?[DecodeHintType.POSSIBLE_FORMATS] as List<BarcodeFormat>?;
    bool useCode39CheckDigit = hints != null &&
        hints[DecodeHintType.ASSUME_CODE_39_CHECK_DIGIT] != null;
    List<OneDReader> readers = [];
    if (possibleFormats != null) {
      if (possibleFormats.contains(BarcodeFormat.EAN_13) ||
          possibleFormats.contains(BarcodeFormat.UPC_A) ||
          possibleFormats.contains(BarcodeFormat.EAN_8) ||
          possibleFormats.contains(BarcodeFormat.UPC_E)) {
        readers.add(MultiFormatUPCEANReader(hints));
      }
      if (possibleFormats.contains(BarcodeFormat.CODE_39)) {
        readers.add(Code39Reader(useCode39CheckDigit));
      }
      if (possibleFormats.contains(BarcodeFormat.CODE_93)) {
        readers.add(Code93Reader());
      }
      if (possibleFormats.contains(BarcodeFormat.CODE_128)) {
        readers.add(Code128Reader());
      }
      if (possibleFormats.contains(BarcodeFormat.ITF)) {
        readers.add(ITFReader());
      }
      if (possibleFormats.contains(BarcodeFormat.CODABAR)) {
        readers.add(CodaBarReader());
      }
      if (possibleFormats.contains(BarcodeFormat.RSS_14)) {
        readers.add(RSS14Reader());
      }
      if (possibleFormats.contains(BarcodeFormat.RSS_EXPANDED)) {
        readers.add(RSSExpandedReader());
      }
    }
    if (readers.isEmpty) {
      readers.add(MultiFormatUPCEANReader(hints));
      readers.add(Code39Reader());
      readers.add(CodaBarReader());
      readers.add(Code93Reader());
      readers.add(Code128Reader());
      readers.add(ITFReader());
      readers.add(RSS14Reader());
      readers.add(RSSExpandedReader());
    }
    this._readers = readers;//.toList();
  }

  @override
  Result decodeRow(
      int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints) {
    for (OneDReader reader in _readers) {
      try {
        return reader.decodeRow(rowNumber, row, hints);
      } on ReaderException catch (_) {
        // continue
      }
    }

    throw NotFoundException.instance;
  }

  @override
  void reset() {
    for (Reader reader in _readers) {
      reader.reset();
    }
  }
}
