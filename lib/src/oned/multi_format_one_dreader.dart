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
import '../decode_hint.dart';
import '../not_found_exception.dart';
import '../reader.dart';
import '../reader_exception.dart';
import '../result.dart';
import 'coda_bar_reader.dart';
import 'code128_reader.dart';
import 'code39_reader.dart';
import 'code93_reader.dart';
import 'itf_reader.dart';
import 'multi_format_upceanreader.dart';
import 'one_dreader.dart';
import 'rss/expanded/rss_expanded_reader.dart';
import 'rss/rss14_reader.dart';

/// @author dswitkin@google.com (Daniel Switkin)
/// @author Sean Owen
class MultiFormatOneDReader extends OneDReader {
  //static const List<OneDReader> _emptyOnedArray = [];

  late List<OneDReader> _readers;

  MultiFormatOneDReader(DecodeHint? hints) {
    // @SuppressWarnings("unchecked")
    final possibleFormats = hints?.possibleFormats;
    final useCode39CheckDigit = hints?.assumeCode39CheckDigit ?? false;
    final readers = <OneDReader>[];
    if (possibleFormats != null) {
      if (possibleFormats.contains(BarcodeFormat.ean13) ||
          possibleFormats.contains(BarcodeFormat.upcA) ||
          possibleFormats.contains(BarcodeFormat.ean8) ||
          possibleFormats.contains(BarcodeFormat.upcE)) {
        readers.add(MultiFormatUPCEANReader(hints));
      }
      if (possibleFormats.contains(BarcodeFormat.code39)) {
        readers.add(Code39Reader(useCode39CheckDigit));
      }
      if (possibleFormats.contains(BarcodeFormat.code93)) {
        readers.add(Code93Reader());
      }
      if (possibleFormats.contains(BarcodeFormat.code128)) {
        readers.add(Code128Reader());
      }
      if (possibleFormats.contains(BarcodeFormat.itf)) {
        readers.add(ITFReader());
      }
      if (possibleFormats.contains(BarcodeFormat.codabar)) {
        readers.add(CodaBarReader());
      }
      if (possibleFormats.contains(BarcodeFormat.rss14)) {
        readers.add(RSS14Reader());
      }
      if (possibleFormats.contains(BarcodeFormat.rssExpanded)) {
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
    _readers = readers; //.toList();
  }

  @override
  Result decodeRow(
    int rowNumber,
    BitArray row,
    DecodeHint? hints,
  ) {
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
