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

/// These are a set of hints that you may pass to Writers to specify their behavior.
///
/// @author dswitkin@google.com (Daniel Switkin)
enum EncodeHintType {
  /// Specifies what degree of error correction to use, for example in QR Codes.
  /// Type depends on the encoder. For example for QR codes it's type [ErrorCorrectionLevel].
  /// For Aztec it is of type [int], representing the minimal percentage of error correction words.
  /// For PDF417 it is of type [int], valid values being 0 to 8.
  /// In all cases, it can also be a [String] representation of the desired value as well.
  /// Note: an Aztec symbol should have a minimum of 25% EC words.
  errorCorrection,

  /// Specifies what character encoding to use where applicable (type [String])
  characterSet,

  /// Specifies the matrix shape for Data Matrix (type {@link com.google.zxing.datamatrix.encoder.SymbolShapeHint})
  dataMatrixShape,

  /// Specifies whether to use compact mode for Data Matrix (type [bool], or "true" or "false" [String] value)
  /// The compact encoding mode also supports the encoding of characters that are not in the ISO-8859-1
  /// character set via ECIs.
  /// Please note that in that case, the most compact character encoding is chosen for characters in
  /// the input that are not in the ISO-8859-1 character set. Based on experience, some scanners do not
  /// support encodings like cp-1256 (Arabic). In such cases the encoding can be forced to UTF-8 by
  /// means of the [CHARACTER_SET] encoding hint.
  /// Compact encoding also provides GS1-FNC1 support when {@link #GS1_FORMAT} is selected. In this case
  /// group-separator character (ASCII 29 decimal) can be used to encode the positions of FNC1 codewords
  /// for the purpose of delimiting AIs.
  /// This option and [forceC40] are mutually exclusive.
  dataMatrixCompact,

  /// Specifies a minimum barcode size (type [Dimension]). Only applicable to Data Matrix now.
  ///
  /// @deprecated use width/height params in
  /// [DataMatrixWriter.encode]
  @Deprecated('use width/height params instead')
  minSize,

  /// Specifies a maximum barcode size (type [Dimension]). Only applicable to Data Matrix now.
  ///
  /// @deprecated without replacement
  @Deprecated('without replacement')
  maxSize,

  /// Specifies margin, in pixels, to use when generating the barcode. The meaning can vary
  /// by format; for example it controls margin before and after the barcode horizontally for
  /// most 1D formats. (Type [Integer], or [String] representation of the integer value).
  margin,

  /// Specifies whether to use compact mode for PDF417 (type [bool], or "true" or "false"
  /// [String] value).
  pdf417Compact,

  /// Specifies what compaction mode to use for PDF417 (type
  /// [pdf417.Compaction] or [String] value of one of its
  /// enum values).
  pdf417Compaction,

  /// Specifies the minimum and maximum number of rows and columns for PDF417 (type [pdf417.Dimensions]).
  pdf417Dimensions,

  /// Specifies whether to automatically insert ECIs when encoding PDF417 (type [bool]).
  //  Please note that in that case, the most compact character encoding is chosen for characters in
  //  the input that are not in the ISO-8859-1 character set. Based on experience, some scanners do not
  //  support encodings like cp-1256 (Arabic). In such cases the encoding can be forced to UTF-8 by
  //  means of the [CHARACTER_SET] encoding hint.
  pdf417AutoEci,

  /// Specifies the required number of layers for an Aztec code.
  /// A negative number (-1, -2, -3, -4) specifies a compact Aztec code.
  /// 0 indicates to use the minimum number of layers (the default).
  /// A positive number (1, 2, .. 32) specifies a normal (non-compact) Aztec code.
  /// (Type [Integer], or [String] representation of the integer value).
  aztecLayers,

  /// Specifies the exact version of QR code to be encoded.
  /// (Type [Integer], or [String] representation of the integer value).
  qrVersion,

  /// Specifies the QR code mask pattern to be used. Allowed values are
  /// 0..QRCode.NUM_MASK_PATTERNS-1. By default the code will automatically select
  /// the optimal mask pattern.
  /// (Type [Integer], or [String] representation of the integer value).
  qrMaskPattern,

  /// Specifies whether to use compact mode for QR code (type [bool], or "true" or "false" [String] value)
  /// Please note that when compaction is performed, the most compact character encoding is chosen
  /// for characters in the input that are not in the ISO-8859-1 character set. Based on experience,
  /// some scanners do not support encodings like cp-1256 (Arabic). In such cases the encoding can
  /// be forced to UTF-8 by means of the [Encoding] encoding hint.
  qrCompact,

  /// Specifies whether the data should be encoded to the GS1 standard (type [bool],
  /// or "true" or "false" [String] value).
  gs1Format,

  /// Forces which encoding will be used. Currently only used for Code-128 code sets (Type [String]). Valid values are "A", "B", "C".
  /// This option and [code128Compact] are mutually exclusive.
  forceCodeSet,

  /// Forces C40 encoding for data-matrix (type [bool], or "true" or "false" [String] value). This
  /// option and [dataMatrixCompact] are mutually exclusive.
  forceC40,

  /// Specifies whether to use compact mode for Code-128 code (type [bool], or "true" or "false" [String] value)
  /// This can yield slightly smaller bar codes. This option and [forceCodeSet] are mutually exclusive.
  code128Compact,
}
