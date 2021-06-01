/*
 * Copyright 2007 ZXing authors
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

import 'result_point_callback.dart';

typedef IntList = List<int>;

/// Encapsulates a type of hint that a caller may pass to a barcode reader to help it
/// more quickly or accurately decode it. It is up to implementations to decide what,
/// if anything, to do with the information that is supplied.
///
/// @author Sean Owen
/// @author dswitkin@google.com (Daniel Switkin)
/// @see Reader#decode(BinaryBitmap,java.util.Map)
class DecodeHintType {
  /// Unspecified, application-specific hint. Maps to an unspecified {@link Object}.
  static const OTHER = DecodeHintType(Object);

  /// Image is a pure monochrome image of a barcode. Doesn't matter what it maps to;
  /// use {@link bool#TRUE}.
  static const PURE_BARCODE = DecodeHintType(Null);

  /// Image is known to be of one of a few possible formats.
  /// Maps to a {@link List} of {@link BarcodeFormat}s.
  static const POSSIBLE_FORMATS = DecodeHintType(List);

  /// Spend more time to try to find a barcode; optimize for accuracy, not speed.
  /// Doesn't matter what it maps to; use {@link bool#TRUE}.
  static const TRY_HARDER = DecodeHintType(Null);

  /// Specifies what character encoding to use when decoding, where applicable (type String)
  static const CHARACTER_SET = DecodeHintType(String);

  /// Allowed lengths of encoded data -- reject anything else. Maps to an {@code List<int>}.
  static const ALLOWED_LENGTHS = DecodeHintType(IntList);

  /// Assume Code 39 codes employ a check digit. Doesn't matter what it maps to;
  /// use {@link bool#TRUE}.
  static const ASSUME_CODE_39_CHECK_DIGIT = DecodeHintType(Null);

  /// Assume the barcode is being processed as a GS1 barcode, and modify behavior as needed.
  /// For example this affects FNC1 handling for Code 128 (aka GS1-128). Doesn't matter what it maps to;
  /// use {@link bool#TRUE}.
  static const ASSUME_GS1 = DecodeHintType(Null);

  /// If true, return the start and end digits in a Codabar barcode instead of stripping them. They
  /// are alpha, whereas the rest are numeric. By default, they are stripped, but this causes them
  /// to not be. Doesn't matter what it maps to; use {@link bool#TRUE}.
  static const RETURN_CODABAR_START_END = DecodeHintType(Null);

  /// The caller needs to be notified via callback when a possible {@link ResultPoint}
  /// is found. Maps to a {@link ResultPointCallback}.
  static const NEED_RESULT_POINT_CALLBACK = DecodeHintType(ResultPointCallback);

  /// Allowed extension lengths for EAN or UPC barcodes. Other formats will ignore this.
  /// Maps to an {@code List<int>} of the allowed extension lengths, for example [2], [5], or [2, 5].
  /// If it is optional to have an extension, do not set this hint. If this is set,
  /// and a UPC or EAN barcode is found but an extension is not, then no result will be returned
  /// at all.
  static const ALLOWED_EAN_EXTENSIONS = DecodeHintType(IntList);

  /// If true, also tries to decode as inverted image. All configured decoders are simply called a
  /// second time with an inverted image. Doesn't matter what it maps to; use {@link bool#TRUE}.
  static const ALSO_INVERTED = DecodeHintType(Null);

  // End of enumeration values.

  /// Data type the hint is expecting.
  /// Among the possible values the {@link Null} stands out as being used for
  /// hints that do not expect a value to be supplied (flag hints). Such hints
  /// will possibly have their value ignored, or replaced by a
  /// {@link bool#TRUE}. Hint suppliers should probably use
  /// {@link bool#TRUE} as directed by the actual hint documentation.
  final Type valueType;

  const DecodeHintType(this.valueType);
}
