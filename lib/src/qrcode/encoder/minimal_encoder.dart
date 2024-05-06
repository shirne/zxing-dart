import 'dart:convert';

import '../../../common.dart';
import '../../../qrcode.dart';
import '../../common/eci_encoder_set.dart';
import '../../writer_exception.dart';

class VersionSize {
  static const small = VersionSize('version 1-9');
  static const medium = VersionSize('version 10-26');
  static const large = VersionSize('version 27-40');

  final String description;

  const VersionSize(this.description);

  @override
  String toString() => description;
}

class Context<T> {
  final T context;
  const Context(this.context);
}

class Edge extends Context<MinimalEncoder> {
  final Mode mode;
  final int fromPosition;
  final int charsetEncoderIndex;
  final int characterLength;
  final Edge? previous;
  late int cachedTotalSize;

  Edge(
    this.mode,
    this.fromPosition,
    int charsetEncoderIndex,
    this.characterLength,
    this.previous,
    Version version,
    MinimalEncoder context,
  )   : charsetEncoderIndex = mode == Mode.byte || previous == null
            ? charsetEncoderIndex
            : previous.charsetEncoderIndex,
        super(context) {
    int size = previous?.cachedTotalSize ?? 0;

    final needECI = mode == Mode.byte &&
            (previous == null &&
                this.charsetEncoderIndex !=
                    0) || // at the beginning and charset is not ISO-8859-1
        (previous != null &&
            this.charsetEncoderIndex != (previous?.charsetEncoderIndex ?? 0));

    if (mode != previous?.mode || needECI) {
      size += 4 + mode.getCharacterCountBits(version);
    }
    switch (mode) {
      case Mode.kanji:
        size += 13;
        break;
      case Mode.alphanumeric:
        size += characterLength == 1 ? 6 : 11;
        break;
      case Mode.numeric:
        size += characterLength == 1
            ? 4
            : characterLength == 2
                ? 7
                : 10;
        break;
      case Mode.byte:
        size += 8 *
            context.encoders
                .encode(
                  context.stringToEncode.substring(
                    fromPosition,
                    fromPosition + characterLength,
                  ),
                  charsetEncoderIndex,
                )
                .length;
        if (needECI) {
          // the ECI assignment numbers for ISO-8859-x, UTF-8 and UTF-16 are all 8 bit long
          size += 4 + 8;
        }
        break;
    }
    cachedTotalSize = size;
  }
}

class ResultNode extends Context<ResultList> {
  final Mode mode;
  final int fromPosition;
  final int charsetEncoderIndex;
  final int characterLength;

  ResultNode(
    this.mode,
    this.fromPosition,
    this.charsetEncoderIndex,
    this.characterLength,
    ResultList context,
  ) : super(context);

  /// returns the size in bits
  int getSize(Version version) {
    int size = 4 + mode.getCharacterCountBits(version);
    switch (mode) {
      case Mode.kanji:
        size += 13 * characterLength;
        break;
      case Mode.alphanumeric:
        size += (characterLength ~/ 2) * 11;
        size += (characterLength % 2) == 1 ? 6 : 0;
        break;
      case Mode.numeric:
        size += (characterLength ~/ 3) * 10;
        final rest = characterLength % 3;
        size += rest == 1
            ? 4
            : rest == 2
                ? 7
                : 0;
        break;
      case Mode.byte:
        size += 8 * getCharacterCountIndicator();
        break;
      case Mode.eci:
        size +=
            8; // the ECI assignment numbers for ISO-8859-x, UTF-8 and UTF-16 are all 8 bit long
    }
    return size;
  }

  /// returns the length in characters according to the specification (differs from getCharacterLength() in BYTE mode
  //  for multi byte encoded characters)
  int getCharacterCountIndicator() {
    return mode == Mode.byte
        ? context.context.encoders
            .encode(
              context.context.stringToEncode.substring(
                fromPosition,
                fromPosition + characterLength,
              ),
              charsetEncoderIndex,
            )
            .length
        : characterLength;
  }

  /// appends the bits
  void getBits(BitArray bits) {
    bits.appendBits(mode.bits, 4);
    if (characterLength > 0) {
      final length = getCharacterCountIndicator();
      bits.appendBits(length, mode.getCharacterCountBits(context.version));
    }
    if (mode == Mode.eci) {
      bits.appendBits(
        context.context.encoders.getECIValue(charsetEncoderIndex),
        8,
      );
    } else if (characterLength > 0) {
      // append data
      Encoder.appendBytes(
        context.context.stringToEncode.substring(
          fromPosition,
          fromPosition + characterLength,
        ),
        mode,
        bits,
        context.context.encoders.getCharset(charsetEncoderIndex),
      );
    }
  }

  @override
  String toString() {
    final result = StringBuffer();
    result.write(mode);
    result.write('(');
    if (mode == Mode.eci) {
      result
          .write(context.context.encoders.getCharsetName(charsetEncoderIndex));
    } else {
      result.write(
        makePrintable(
          context.context.stringToEncode.substring(
            fromPosition,
            fromPosition + characterLength,
          ),
        ),
      );
    }
    result.write(')');
    return result.toString();
  }

  String makePrintable(String s) {
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) < 32 || s.codeUnitAt(i) > 126) {
        result.write('.');
      } else {
        result.writeCharCode(s.codeUnitAt(i));
      }
    }
    return result.toString();
  }
}

class ResultList extends Context<MinimalEncoder> {
  late Version version;
  List<ResultNode> list = [];

  ResultList(Version version, Edge? solution, MinimalEncoder context)
      : super(context) {
    int length = 0;
    Edge? current = solution;
    bool containsECI = false;

    while (current != null) {
      length += current.characterLength;
      final previous = current.previous;

      final needECI = current.mode == Mode.byte &&
              (previous == null &&
                  current.charsetEncoderIndex !=
                      0) || // at the beginning and charset is not ISO-8859-1
          (previous != null &&
              current.charsetEncoderIndex != previous.charsetEncoderIndex);

      if (needECI) {
        containsECI = true;
      }

      if (previous == null || previous.mode != current.mode || needECI) {
        list.insert(
          0,
          ResultNode(
            current.mode,
            current.fromPosition,
            current.charsetEncoderIndex,
            length,
            this,
          ),
        );
        length = 0;
      }

      if (needECI) {
        list.insert(
          0,
          ResultNode(
            Mode.eci,
            current.fromPosition,
            current.charsetEncoderIndex,
            0,
            this,
          ),
        );
      }
      current = previous;
    }

    // prepend FNC1 if needed. If the bits contain an ECI then the FNC1 must be preceeded by an ECI.
    // If there is no ECI at the beginning then we put an ECI to the default charset (ISO-8859-1)
    if (context.isGS1) {
      ResultNode first = list[0];
      if (first.mode != Mode.eci && containsECI) {
        // prepend a default character set ECI
        list.insert(0, ResultNode(Mode.eci, 0, 0, 0, this));
      }
      first = list[0];
      // prepend or insert a FNC1_FIRST_POSITION after the ECI (if any)
      list.insert(
        first.mode != Mode.eci ? 0 : 1,
        ResultNode(Mode.fnc1FirstPosition, 0, 0, 0, this),
      );
    }

    // set version to smallest version into which the bits fit.
    int versionNumber = version.versionNumber;
    int lowerLimit;
    int upperLimit;
    switch (MinimalEncoder.getVersionSize(version)) {
      case VersionSize.small:
        lowerLimit = 1;
        upperLimit = 9;
        break;
      case VersionSize.medium:
        lowerLimit = 10;
        upperLimit = 26;
        break;
      case VersionSize.large:
      default:
        lowerLimit = 27;
        upperLimit = 40;
        break;
    }
    final size = getSize(version);
    // increase version if needed
    while (versionNumber < upperLimit &&
        !Encoder.willFit(
          size,
          Version.getVersionForNumber(versionNumber),
          context.ecLevel,
        )) {
      versionNumber++;
    }
    // shrink version if possible
    while (versionNumber > lowerLimit &&
        Encoder.willFit(
          size,
          Version.getVersionForNumber(versionNumber - 1),
          context.ecLevel,
        )) {
      versionNumber--;
    }
    this.version = Version.getVersionForNumber(versionNumber);
  }

  /// returns the size in bits
  int getSize([Version? version]) {
    int result = 0;
    for (ResultNode resultNode in list) {
      result += resultNode.getSize(version ?? this.version);
    }
    return result;
  }

  /// appends the bits
  void getBits(BitArray bits) {
    for (ResultNode resultNode in list) {
      resultNode.getBits(bits);
    }
  }

  Version getVersion() {
    return version;
  }

  @override
  String toString() {
    final result = StringBuffer();
    ResultNode? previous;
    for (ResultNode current in list) {
      if (previous != null) {
        result.write(',');
      }
      result.write(current.toString());
      previous = current;
    }
    return result.toString();
  }
}

/// Encoder that encodes minimally
///
/// Algorithm:
///
/// The eleventh commandment was "Thou Shalt Compute" or "Thou Shalt Not Compute" - I forget which (Alan Perilis).
///
/// This implementation computes. As an alternative, the QR-Code specification suggests heuristics like this one:
///
/// If initial input data is in the exclusive subset of the Alphanumeric character set AND if there are less than
/// [6,7,8] characters followed by data from the remainder of the 8-bit byte character set, THEN select the 8-
/// bit byte mode ELSE select Alphanumeric mode;
///
/// This is probably right for 99.99% of cases but there is at least this one counter example: The string "AAAAAAa"
/// encodes 2 bits smaller as ALPHANUMERIC(AAAAAA), BYTE(a) than by encoding it as BYTE(AAAAAAa).
/// Perhaps that is the only counter example but without having proof, it remains unclear.
///
/// ECI switching:
///
/// In multi language content the algorithm selects the most compact representation using ECI modes.
/// For example the most compact representation of the string "\u0150\u015C" (O-double-acute, S-circumflex) is
/// ECI(UTF-8), BYTE(\u0150\u015C) while prepending one or more times the same leading character as in
/// "\u0150\u0150\u015C", the most compact representation uses two ECIs so that the string is encoded as
/// ECI(ISO-8859-2), BYTE(\u0150\u0150), ECI(ISO-8859-3), BYTE(\u015C).
///
/// @author Alex Geller
class MinimalEncoder {
  final String stringToEncode;
  final bool isGS1;
  final ECIEncoderSet encoders;
  final ErrorCorrectionLevel ecLevel;

  /// Creates a MinimalEncoder
  ///
  /// @param stringToEncode The string to encode
  /// @param priorityCharset The preferred {@link Charset}. When the value of the argument is null, the algorithm
  ///   chooses charsets that leads to a minimal representation. Otherwise the algorithm will use the priority
  ///   charset to encode any character in the input that can be encoded by it if the charset is among the
  ///   supported charsets.
  /// @param isGS1 {@code true} if a FNC1 is to be prepended; {@code false} otherwise
  /// @param ecLevel The error correction level.
  /// @see ResultList#getVersion
  MinimalEncoder(
    this.stringToEncode,
    Encoding? priorityCharset,
    this.isGS1,
    this.ecLevel,
  ) : encoders = ECIEncoderSet(stringToEncode, priorityCharset, -1);

  /// Encodes the string minimally
  ///
  /// @param stringToEncode The string to encode
  /// @param version The preferred [Version]. A minimal version is computed (see
  ///   [ResultList.getVersion] when the value of the argument is null
  /// @param priorityCharset The preferred [Charset]. When the value of the argument is null, the algorithm
  ///   chooses charsets that leads to a minimal representation. Otherwise the algorithm will use the priority
  ///   charset to encode any character in the input that can be encoded by it if the charset is among the
  ///   supported charsets.
  /// @param isGS1 `true` if a FNC1 is to be prepended; `false` otherwise
  /// @param ecLevel The error correction level.
  /// @return An instance of [ResultList] representing the minimal solution.
  /// @see [ResultList.getBits]
  /// @see [ResultList.getVersion]
  /// @see [ResultList.getSize]
  static ResultList encode(
    String stringToEncode,
    Version? version,
    Encoding? priorityCharset,
    bool isGS1,
    ErrorCorrectionLevel ecLevel,
  ) {
    return MinimalEncoder(stringToEncode, priorityCharset, isGS1, ecLevel)
        .doEncode(version);
  }

  ResultList doEncode(Version? version) {
    if (version == null) {
      // compute minimal encoding trying the three version sizes.
      final versions = [
        getVersion(VersionSize.small),
        getVersion(VersionSize.medium),
        getVersion(VersionSize.large),
      ];
      final results = [
        encodeSpecificVersion(versions[0]),
        encodeSpecificVersion(versions[1]),
        encodeSpecificVersion(versions[2]),
      ];
      int smallestSize = MathUtils.maxValue;
      int smallestResult = -1;
      for (int i = 0; i < 3; i++) {
        final size = results[i].getSize();
        if (Encoder.willFit(size, versions[i], ecLevel) &&
            size < smallestSize) {
          smallestSize = size;
          smallestResult = i;
        }
      }
      if (smallestResult < 0) {
        throw WriterException('Data too big for any version');
      }
      return results[smallestResult];
    } else {
      // compute minimal encoding for a given version
      final result = encodeSpecificVersion(version);
      if (!Encoder.willFit(
        result.getSize(),
        getVersion(getVersionSize(result.getVersion())),
        ecLevel,
      )) {
        throw WriterException('Data too big for version $version');
      }
      return result;
    }
  }

  static VersionSize getVersionSize(Version version) {
    return version.versionNumber <= 9
        ? VersionSize.small
        : version.versionNumber <= 26
            ? VersionSize.medium
            : VersionSize.large;
  }

  static Version getVersion(VersionSize versionSize) {
    switch (versionSize) {
      case VersionSize.small:
        return Version.getVersionForNumber(9);
      case VersionSize.medium:
        return Version.getVersionForNumber(26);
      case VersionSize.large:
      default:
        return Version.getVersionForNumber(40);
    }
  }

  static bool isNumeric(int c) {
    return c >= 48 /*'0'*/ && c <= 57 /*'9'*/;
  }

  static bool isDoubleByteKanji(int c) {
    return Encoder.isOnlyDoubleByteKanji(String.fromCharCode(c));
  }

  static bool isAlphanumeric(int c) {
    return Encoder.getAlphanumericCode(c) != -1;
  }

  bool canEncode(Mode mode, int c) {
    switch (mode) {
      case Mode.kanji:
        return isDoubleByteKanji(c);
      case Mode.alphanumeric:
        return isAlphanumeric(c);
      case Mode.numeric:
        return isNumeric(c);
      // any character can be encoded as byte(s). Up to the caller to manage splitting into
      // multiple bytes when String.getBytes(Charset) return more than one byte.
      case Mode.byte:
        return true;

      default:
        return false;
    }
  }

  static int getCompactedOrdinal(Mode? mode) {
    if (mode == null) {
      return 0;
    }
    switch (mode) {
      case Mode.kanji:
        return 0;
      case Mode.alphanumeric:
        return 1;
      case Mode.numeric:
        return 2;
      case Mode.byte:
        return 3;
      default:
        throw StateError('Illegal mode $mode');
    }
  }

  void addEdge(List<List<List<Edge?>>> edges, int position, Edge edge) {
    final vertexIndex = position + edge.characterLength;
    final modeEdges = edges[vertexIndex][edge.charsetEncoderIndex];
    final modeOrdinal = getCompactedOrdinal(edge.mode);
    if (modeEdges[modeOrdinal] == null ||
        modeEdges[modeOrdinal]!.cachedTotalSize > edge.cachedTotalSize) {
      modeEdges[modeOrdinal] = edge;
    }
  }

  void addEdges(
    Version version,
    List<List<List<Edge?>>> edges,
    int from,
    Edge? previous,
  ) {
    int start = 0;
    int end = encoders.length;
    final priorityEncoderIndex = encoders.priorityEncoderIndex;
    if (priorityEncoderIndex >= 0 &&
        encoders.canEncode(
          stringToEncode.codeUnitAt(from),
          priorityEncoderIndex,
        )) {
      start = priorityEncoderIndex;
      end = priorityEncoderIndex + 1;
    }

    for (int i = start; i < end; i++) {
      if (encoders.canEncode(stringToEncode.codeUnitAt(from), i)) {
        addEdge(
          edges,
          from,
          Edge(Mode.byte, from, i, 1, previous, version, this),
        );
      }
    }

    if (canEncode(Mode.kanji, stringToEncode.codeUnitAt(from))) {
      addEdge(
        edges,
        from,
        Edge(Mode.kanji, from, 0, 1, previous, version, this),
      );
    }

    final inputLength = stringToEncode.length;
    if (canEncode(Mode.alphanumeric, stringToEncode.codeUnitAt(from))) {
      addEdge(
        edges,
        from,
        Edge(
          Mode.alphanumeric,
          from,
          0,
          from + 1 >= inputLength ||
                  !canEncode(
                    Mode.alphanumeric,
                    stringToEncode.codeUnitAt(from + 1),
                  )
              ? 1
              : 2,
          previous,
          version,
          this,
        ),
      );
    }

    if (canEncode(Mode.numeric, stringToEncode.codeUnitAt(from))) {
      addEdge(
        edges,
        from,
        Edge(
          Mode.numeric,
          from,
          0,
          from + 1 >= inputLength ||
                  !canEncode(
                    Mode.numeric,
                    stringToEncode.codeUnitAt(from + 1),
                  )
              ? 1
              : from + 2 >= inputLength ||
                      !canEncode(
                        Mode.numeric,
                        stringToEncode.codeUnitAt(from + 2),
                      )
                  ? 2
                  : 3,
          previous,
          version,
          this,
        ),
      );
    }
  }

  ResultList encodeSpecificVersion(Version version) {
    /// A vertex represents a tuple of a position in the input, a mode and a character encoding where position 0
    /// denotes the position left of the first character, 1 the position left of the second character and so on.
    /// Likewise the end vertices are located after the last character at position stringToEncode.length().
    ///
    /// An edge leading to such a vertex encodes one or more of the characters left of the position that the vertex
    /// represents and encodes it in the same encoding and mode as the vertex on which the edge ends. In other words,
    /// all edges leading to a particular vertex encode the same characters in the same mode with the same character
    /// encoding. They differ only by their source vertices who are all located at i+1 minus the number of encoded
    /// characters.
    ///
    /// The edges leading to a vertex are stored in such a way that there is a fast way to enumerate the edges ending
    /// on a particular vertex.
    ///
    /// The algorithm processes the vertices in order of their position thereby performing the following:
    ///
    /// For every vertex at position i the algorithm enumerates the edges ending on the vertex and removes all but the
    /// shortest from that list.
    /// Then it processes the vertices for the position i+1. If i+1 == stringToEncode.length() then the algorithm ends
    /// and chooses the the edge with the smallest size from any of the edges leading to vertices at this position.
    /// Otherwise the algorithm computes all possible outgoing edges for the vertices at the position i+1
    ///
    /// Examples:
    /// The process is illustrated by showing the graph (edges) after each iteration from left to right over the input:
    /// An edge is drawn as follows "(" + fromVertex + ") -- " + encodingMode + "(" + encodedInput + ") (" +
    /// accumulatedSize + ") --> (" + toVertex + ")"
    ///
    /// Example 1 encoding the string "ABCDE":
    /// Note: This example assumes that alphanumeric encoding is only possible in multiples of two characters so that
    /// the example is both short and showing the principle. In reality this restriction does not exist.
    ///
    /// Initial situation
    /// (initial) -- BYTE(A) (20) --> (1_BYTE)
    /// (initial) -- ALPHANUMERIC(AB)                     (24) --> (2_ALPHANUMERIC)
    ///
    /// Situation after adding edges to vertices at position 1
    /// (initial) -- BYTE(A) (20) --> (1_BYTE) -- BYTE(B) (28) --> (2_BYTE)
    ///                               (1_BYTE) -- ALPHANUMERIC(BC)                             (44) --> (3_ALPHANUMERIC)
    /// (initial) -- ALPHANUMERIC(AB)                     (24) --> (2_ALPHANUMERIC)
    ///
    /// Situation after adding edges to vertices at position 2
    /// (initial) -- BYTE(A) (20) --> (1_BYTE)
    /// (initial) -- ALPHANUMERIC(AB)                     (24) --> (2_ALPHANUMERIC)
    /// (initial) -- BYTE(A) (20) --> (1_BYTE) -- BYTE(B) (28) --> (2_BYTE)
    /// (1_BYTE) -- ALPHANUMERIC(BC)                             (44) --> (3_ALPHANUMERIC)
    /// (initial) -- ALPHANUMERIC(AB)                     (24) --> (2_ALPHANUMERIC) -- BYTE(C) (44) --> (3_BYTE)
    ///                                                            (2_ALPHANUMERIC) -- ALPHANUMERIC(CD)                             (35) --> (4_ALPHANUMERIC)
    ///
    /// Situation after adding edges to vertices at position 3
    /// (initial) -- BYTE(A) (20) --> (1_BYTE) -- BYTE(B) (28) --> (2_BYTE) -- BYTE(C)         (36) --> (3_BYTE)
    ///                               (1_BYTE) -- ALPHANUMERIC(BC)                             (44) --> (3_ALPHANUMERIC) -- BYTE(D) (64) --> (4_BYTE)
    ///                                                                                                 (3_ALPHANUMERIC) -- ALPHANUMERIC(DE)                             (55) --> (5_ALPHANUMERIC)
    /// (initial) -- ALPHANUMERIC(AB)                     (24) --> (2_ALPHANUMERIC) -- ALPHANUMERIC(CD)                             (35) --> (4_ALPHANUMERIC)
    ///                                                            (2_ALPHANUMERIC) -- ALPHANUMERIC(CD)                             (35) --> (4_ALPHANUMERIC)
    ///
    /// Situation after adding edges to vertices at position 4
    /// (initial) -- BYTE(A) (20) --> (1_BYTE) -- BYTE(B) (28) --> (2_BYTE) -- BYTE(C)         (36) --> (3_BYTE) -- BYTE(D) (44) --> (4_BYTE)
    ///                               (1_BYTE) -- ALPHANUMERIC(BC)                             (44) --> (3_ALPHANUMERIC) -- ALPHANUMERIC(DE)                             (55) --> (5_ALPHANUMERIC)
    /// (initial) -- ALPHANUMERIC(AB)                     (24) --> (2_ALPHANUMERIC) -- ALPHANUMERIC(CD)                             (35) --> (4_ALPHANUMERIC) -- BYTE(E) (55) --> (5_BYTE)
    ///
    /// Situation after adding edges to vertices at position 5
    /// (initial) -- BYTE(A) (20) --> (1_BYTE) -- BYTE(B) (28) --> (2_BYTE) -- BYTE(C)         (36) --> (3_BYTE) -- BYTE(D)         (44) --> (4_BYTE) -- BYTE(E)         (52) --> (5_BYTE)
    ///                               (1_BYTE) -- ALPHANUMERIC(BC)                             (44) --> (3_ALPHANUMERIC) -- ALPHANUMERIC(DE)                             (55) --> (5_ALPHANUMERIC)
    /// (initial) -- ALPHANUMERIC(AB)                     (24) --> (2_ALPHANUMERIC) -- ALPHANUMERIC(CD)                             (35) --> (4_ALPHANUMERIC)
    ///
    /// Encoding as BYTE(ABCDE) has the smallest size of 52 and is hence chosen. The encodation ALPHANUMERIC(ABCD),
    /// BYTE(E) is longer with a size of 55.
    ///
    /// Example 2 encoding the string "XXYY" where X denotes a character unique to character set ISO-8859-2 and Y a
    /// character unique to ISO-8859-3. Both characters encode as double byte in UTF-8:
    ///
    /// Initial situation
    /// (initial) -- BYTE(X) (32) --> (1_BYTE_ISO-8859-2)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-8)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-16BE)
    ///
    /// Situation after adding edges to vertices at position 1
    /// (initial) -- BYTE(X) (32) --> (1_BYTE_ISO-8859-2) -- BYTE(X) (40) --> (2_BYTE_ISO-8859-2)
    ///                               (1_BYTE_ISO-8859-2) -- BYTE(X) (72) --> (2_BYTE_UTF-8)
    ///                               (1_BYTE_ISO-8859-2) -- BYTE(X) (72) --> (2_BYTE_UTF-16BE)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-8)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-16BE)
    ///
    /// Situation after adding edges to vertices at position 2
    /// (initial) -- BYTE(X) (32) --> (1_BYTE_ISO-8859-2) -- BYTE(X) (40) --> (2_BYTE_ISO-8859-2)
    ///                                                                       (2_BYTE_ISO-8859-2) -- BYTE(Y) (72) --> (3_BYTE_ISO-8859-3)
    ///                                                                       (2_BYTE_ISO-8859-2) -- BYTE(Y) (80) --> (3_BYTE_UTF-8)
    ///                                                                       (2_BYTE_ISO-8859-2) -- BYTE(Y) (80) --> (3_BYTE_UTF-16BE)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-8) -- BYTE(X) (56) --> (2_BYTE_UTF-8)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-16BE) -- BYTE(X) (56) --> (2_BYTE_UTF-16BE)
    ///
    /// Situation after adding edges to vertices at position 3
    /// (initial) -- BYTE(X) (32) --> (1_BYTE_ISO-8859-2) -- BYTE(X) (40) --> (2_BYTE_ISO-8859-2) -- BYTE(Y) (72) --> (3_BYTE_ISO-8859-3)
    ///                                                                                                               (3_BYTE_ISO-8859-3) -- BYTE(Y) (80) --> (4_BYTE_ISO-8859-3)
    ///                                                                                                               (3_BYTE_ISO-8859-3) -- BYTE(Y) (112) --> (4_BYTE_UTF-8)
    ///                                                                                                               (3_BYTE_ISO-8859-3) -- BYTE(Y) (112) --> (4_BYTE_UTF-16BE)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-8) -- BYTE(X) (56) --> (2_BYTE_UTF-8) -- BYTE(Y) (72) --> (3_BYTE_UTF-8)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-16BE) -- BYTE(X) (56) --> (2_BYTE_UTF-16BE) -- BYTE(Y) (72) --> (3_BYTE_UTF-16BE)
    ///
    /// Situation after adding edges to vertices at position 4
    /// (initial) -- BYTE(X) (32) --> (1_BYTE_ISO-8859-2) -- BYTE(X) (40) --> (2_BYTE_ISO-8859-2) -- BYTE(Y) (72) --> (3_BYTE_ISO-8859-3) -- BYTE(Y) (80) --> (4_BYTE_ISO-8859-3)
    ///                                                                                                               (3_BYTE_UTF-8) -- BYTE(Y) (88) --> (4_BYTE_UTF-8)
    ///                                                                                                               (3_BYTE_UTF-16BE) -- BYTE(Y) (88) --> (4_BYTE_UTF-16BE)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-8) -- BYTE(X) (56) --> (2_BYTE_UTF-8) -- BYTE(Y) (72) --> (3_BYTE_UTF-8)
    /// (initial) -- BYTE(X) (40) --> (1_BYTE_UTF-16BE) -- BYTE(X) (56) --> (2_BYTE_UTF-16BE) -- BYTE(Y) (72) --> (3_BYTE_UTF-16BE)
    ///
    /// Encoding as ECI(ISO-8859-2),BYTE(XX),ECI(ISO-8859-3),BYTE(YY) has the smallest size of 80 and is hence chosen.
    /// The encodation ECI(UTF-8),BYTE(XXYY) is longer with a size of 88.

    final inputLength = stringToEncode.length;

    // Array that represents vertices. There is a vertex for every character, encoding and mode. The vertex contains
    // a list of all edges that lead to it that have the same encoding and mode.
    // The lists are created lazily

    // The last dimension in the array below encodes the 4 modes KANJI, ALPHANUMERIC, NUMERIC and BYTE via the
    // function getCompactedOrdinal(Mode)
    final List<List<List<Edge?>>> edges = List.generate(
      inputLength + 1,
      (idx) => List.generate(encoders.length, (idx2) => List.filled(4, null)),
    );
    addEdges(version, edges, 0, null);

    for (int i = 1; i <= inputLength; i++) {
      for (int j = 0; j < encoders.length; j++) {
        for (int k = 0; k < 4; k++) {
          if (edges[i][j][k] != null && i < inputLength) {
            addEdges(version, edges, i, edges[i][j][k]);
          }
        }
      }
    }
    int minimalJ = -1;
    int minimalK = -1;
    int minimalSize = MathUtils.maxValue;
    for (int j = 0; j < encoders.length; j++) {
      for (int k = 0; k < 4; k++) {
        if (edges[inputLength][j][k] != null) {
          final edge = edges[inputLength][j][k];
          if (edge != null && edge.cachedTotalSize < minimalSize) {
            minimalSize = edge.cachedTotalSize;
            minimalJ = j;
            minimalK = k;
          }
        }
      }
    }
    if (minimalJ < 0) {
      throw WriterException(
        'Internal error: failed to encode "$stringToEncode"',
      );
    }
    return ResultList(version, edges[inputLength][minimalJ][minimalK], this);
  }
}
