import 'barcode_format.dart';
import 'result_point_callback.dart';

/// Encapsulates a type of hint that a caller may pass to a barcode reader to help it
/// more quickly or accurately decode it. It is up to implementations to decide what,
/// if anything, to do with the information that is supplied.
class DecodeHint {
  const DecodeHint({
    this.other,
    this.pureBarcode = false,
    this.possibleFormats,
    this.tryHarder = false,
    this.characterSet,
    this.allowedLengths,
    this.assumeCode39CheckDigit = false,
    this.assumeGs1 = false,
    this.returnCodabarStartEnd = false,
    this.needResultPointCallback,
    this.allowedEanExtensions,
    this.alsoInverted = false,
  });

  /// Unspecified, application-specific hint. Maps to an unspecified [Object].
  final Object? other;

  /// Image is a pure monochrome image of a barcode. Doesn't matter what it maps to;
  /// use [bool]`true`.
  final bool pureBarcode;

  /// Image is known to be of one of a few possible formats.
  /// Maps to a [List] of [BarcodeFormat]s.
  final List<BarcodeFormat>? possibleFormats;

  /// Spend more time to try to find a barcode; optimize for accuracy, not speed.
  /// Doesn't matter what it maps to; use [bool]`true`.
  final bool tryHarder;

  /// Specifies what character encoding to use when decoding, where applicable (type String)
  final String? characterSet;

  /// Allowed lengths of encoded data -- reject anything else. Maps to an `List<int>`.
  final List<int>? allowedLengths;

  /// Assume Code 39 codes employ a check digit. Doesn't matter what it maps to;
  /// use [bool]`true`.
  final bool assumeCode39CheckDigit;

  /// Assume the barcode is being processed as a GS1 barcode, and modify behavior as needed.
  /// For example this affects FNC1 handling for Code 128 (aka GS1-128). Doesn't matter what it maps to;
  /// use [bool]`true`.
  final bool assumeGs1;

  /// If true, return the start and end digits in a Codabar barcode instead of stripping them. They
  /// are alpha, whereas the rest are numeric. By default, they are stripped, but this causes them
  /// to not be. Doesn't matter what it maps to; use [bool]`true`.
  final bool returnCodabarStartEnd;

  /// The caller needs to be notified via callback when a possible [ResultPoint]
  /// is found. Maps to a [ResultPointCallback].
  final ResultPointCallback? needResultPointCallback;

  /// Allowed extension lengths for EAN or UPC barcodes. Other formats will ignore this.
  /// Maps to an `List<int>` of the allowed extension lengths, for example [2], [5], or [2, 5].
  /// If it is optional to have an extension, do not set this hint. If this is set,
  /// and a UPC or EAN barcode is found but an extension is not, then no result will be returned
  /// at all.
  final List<int>? allowedEanExtensions;

  /// If true, also tries to decode as inverted image. All configured decoders are simply called a
  /// second time with an inverted image. Doesn't matter what it maps to; use [bool]`true`.
  final bool alsoInverted;

  DecodeHint withoutCallback() {
    return DecodeHint(
      other: other,
      pureBarcode: pureBarcode,
      possibleFormats: possibleFormats,
      tryHarder: tryHarder,
      characterSet: characterSet,
      allowedLengths: allowedLengths,
      assumeCode39CheckDigit: assumeCode39CheckDigit,
      assumeGs1: assumeGs1,
      returnCodabarStartEnd: returnCodabarStartEnd,
      allowedEanExtensions: allowedEanExtensions,
      alsoInverted: alsoInverted,
    );
  }

  DecodeHint copyWith({
    bool? other,
    bool? pureBarcode,
    List<BarcodeFormat>? possibleFormats,
    bool? tryHarder,
    String? characterSet,
    List<int>? allowedLengths,
    bool? assumeCode39CheckDigit,
    bool? assumeGs1,
    bool? returnCodabarStartEnd,
    ResultPointCallback? needResultPointCallback,
    List<int>? allowedEanExtensions,
    bool? alsoInverted,
  }) {
    return DecodeHint(
      other: other ?? this.other,
      pureBarcode: pureBarcode ?? this.pureBarcode,
      possibleFormats: possibleFormats ?? this.possibleFormats,
      tryHarder: tryHarder ?? this.tryHarder,
      characterSet: characterSet ?? this.characterSet,
      allowedLengths: allowedLengths ?? this.allowedLengths,
      assumeCode39CheckDigit:
          assumeCode39CheckDigit ?? this.assumeCode39CheckDigit,
      assumeGs1: assumeGs1 ?? this.assumeGs1,
      returnCodabarStartEnd:
          returnCodabarStartEnd ?? this.returnCodabarStartEnd,
      needResultPointCallback:
          needResultPointCallback ?? this.needResultPointCallback,
      allowedEanExtensions: allowedEanExtensions ?? this.allowedEanExtensions,
      alsoInverted: alsoInverted ?? this.alsoInverted,
    );
  }
}
