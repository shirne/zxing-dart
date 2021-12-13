import 'dart:convert';
import 'dart:typed_data';

import '../../../common.dart';
import '../../../qrcode.dart';
import '../../writer_exception.dart';

class VersionSize {
  static const SMALL = VersionSize("version 1-9");
  static const MEDIUM = VersionSize("version 10-26");
  static const LARGE = VersionSize("version 27-40");

  final String description;

  const VersionSize(this.description);

  @override
  String toString() => description;
}

class Context<T>{
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

  Edge(this.mode, this.fromPosition, int charsetEncoderIndex, this.characterLength, this.previous,
      Version version,MinimalEncoder context):charsetEncoderIndex = mode == Mode.BYTE || previous == null ? charsetEncoderIndex :
  previous.charsetEncoderIndex, super(context) {

    int size = previous?.cachedTotalSize ?? 0;

    bool needECI = mode == Mode.BYTE &&
        (previous == null && this.charsetEncoderIndex != 0) || // at the beginning and charset is not ISO-8859-1
        (previous != null && this.charsetEncoderIndex != (previous?.charsetEncoderIndex ?? 0));

    if (mode != previous?.mode || needECI) {
      size += 4 + mode.getCharacterCountBits(version);
    }
    switch (mode) {
      case Mode.KANJI:
        size += 13;
        break;
      case Mode.ALPHANUMERIC:
        size += characterLength == 1 ? 6 : 11;
        break;
      case Mode.NUMERIC:
        size += characterLength == 1 ? 4 : characterLength == 2 ? 7 : 10;
        break;
      case Mode.BYTE:
        size += 8 * context.stringToEncode.substring(fromPosition, fromPosition + characterLength).getBytes(
            encoders[charsetEncoderIndex].charset()).length;
        if (needECI) {
          size += 4 + 8; // the ECI assignment numbers for ISO-8859-x, UTF-8 and UTF-16 are all 8 bit long
        }
        break;
    }
    cachedTotalSize = size;
  }
}

class ResultNode {
  final Mode mode;
  final int fromPosition;
  final int charsetEncoderIndex;
  final int characterLength;

  ResultNode(this.mode, this.fromPosition, this.charsetEncoderIndex, this.characterLength);

  /// returns the size in bits
  int getSize(Version version) {
    int size = 4 + mode.getCharacterCountBits(version);
    switch (mode) {
      case Mode.KANJI:
        size += 13 * characterLength;
        break;
      case Mode.ALPHANUMERIC:
        size += (characterLength / 2) * 11;
        size += (characterLength % 2) == 1 ? 6 : 0;
        break;
      case Mode.NUMERIC:
        size += (characterLength / 3) * 10;
        int rest = characterLength % 3;
        size += rest == 1 ? 4 : rest == 2 ? 7 : 0;
        break;
      case Mode.BYTE:
        size += 8 * getCharacterCountIndicator();
        break;
      case Mode.ECI:
        size += 8; // the ECI assignment numbers for ISO-8859-x, UTF-8 and UTF-16 are all 8 bit long
    }
    return size;
  }

  /// returns the length in characters according to the specification (differs from getCharacterLength() in BYTE mode
  //  for multi byte encoded characters)
  int getCharacterCountIndicator() {
    return mode == Mode.BYTE ? stringToEncode.substring(fromPosition, fromPosition + characterLength).getBytes(
        encoders[charsetEncoderIndex].charset()).length : characterLength;
  }

  /// appends the bits
  void getBits(BitArray bits) {
    bits.appendBits(mode.getBits(), 4);
    if (characterLength > 0) {
      int length = getCharacterCountIndicator();
      bits.appendBits(length, mode.getCharacterCountBits(version));
    }
    if (mode == Mode.ECI) {
      bits.appendBits(CharacterSetECI.getCharacterSetECI(encoders[charsetEncoderIndex].charset()).getValue(), 8);
    } else if (characterLength > 0) {
      // append data
      Encoder.appendBytes(stringToEncode.substring(fromPosition, fromPosition + characterLength), mode, bits,
          encoders[charsetEncoderIndex].charset());
    }
  }

  String toString() {
    StringBuffer result = StringBuffer();
    result.write(mode);result.write('(');
    if (mode == Mode.ECI) {
      result.write(encoders[charsetEncoderIndex].charset().displayName());
    } else {
      result.write(makePrintable(stringToEncode.substring(fromPosition, fromPosition + characterLength)));
    }
    result.write(')');
    return result.toString();
  }

  String makePrintable(String s) {
    StringBuffer result = StringBuffer();
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

class ResultList extends  Context<MinimalEncoder>{
  late Version version;
  List<ResultNode> list=[];

  ResultList(Version version, Edge? solution, MinimalEncoder context):super(context) {
    int length = 0;
    Edge? current = solution;
    bool containsECI = false;

    while (current != null) {
      length += current.characterLength;
      Edge? previous = current.previous;

      bool needECI = current.mode == Mode.BYTE &&
          (previous == null && current.charsetEncoderIndex != 0) || // at the beginning and charset is not ISO-8859-1
          (previous != null && current.charsetEncoderIndex != previous.charsetEncoderIndex);

      if (needECI) {
        containsECI = true;
      }

      if (previous == null || previous.mode != current.mode || needECI) {
        list.insert(0, ResultNode(current.mode, current.fromPosition, current.charsetEncoderIndex, length));
        length = 0;
      }

      if (needECI) {
        list.insert(0, ResultNode(Mode.ECI, current.fromPosition, current.charsetEncoderIndex, 0));
      }
      current = previous;
    }

    // prepend FNC1 if needed. If the bits contain an ECI then the FNC1 must be preceeded by an ECI.
    // If there is no ECI at the beginning then we put an ECI to the default charset (ISO-8859-1)
    if (context.isGS1) {
      ResultNode first = list[0];
      if (first != null && first.mode != Mode.ECI && containsECI) {
        // prepend a default character set ECI
        list.insert(0, new ResultNode(Mode.ECI, 0, 0, 0));
      }
      first = list[0];
      // prepend or insert a FNC1_FIRST_POSITION after the ECI (if any)
      list.insert(first.mode != Mode.ECI ? 0 : 1, new ResultNode(Mode.FNC1_FIRST_POSITION, 0, 0, 0));
    }

    // set version to smallest version into which the bits fit.
    int versionNumber = version.versionNumber;
    int lowerLimit;
    int upperLimit;
    switch (MinimalEncoder.getVersionSize(version)) {
      case VersionSize.SMALL:
        lowerLimit = 1;
        upperLimit = 9;
        break;
      case VersionSize.MEDIUM:
        lowerLimit = 10;
        upperLimit = 26;
        break;
      case VersionSize.LARGE:
      default:
        lowerLimit = 27;
        upperLimit = 40;
        break;
    }
    int size = getSize(version);
    // increase version if needed
    while (versionNumber < upperLimit && !Encoder.willFit(size, Version.getVersionForNumber(versionNumber),
        context.ecLevel)) {
      versionNumber++;
    }
    // shrink version if possible
    while (versionNumber > lowerLimit && Encoder.willFit(size, Version.getVersionForNumber(versionNumber - 1),
        context.ecLevel)) {
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
  void getBits(BitArray bits)  {
    for (ResultNode resultNode in list) {
      resultNode.getBits(bits);
    }
  }

  Version getVersion() {
    return version;
  }

  @override
  String toString() {
    StringBuffer result = StringBuffer();
    ResultNode? previous;
    for (ResultNode current in list) {
      if (previous != null) {
        result.write(",");
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

//  static final bool DEBUG = false;


  final String stringToEncode;
  final bool isGS1;
  late List<Encoding> encoders;
  late int priorityEncoderIndex;
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
  MinimalEncoder(this.stringToEncode, Charset priorityCharset, this.isGS1,
      this.ecLevel) {

    List<CharsetEncoder> neededEncoders = [];
    neededEncoders.add(StandardCharsets.ISO_8859_1.newEncoder());
    bool needUnicodeEncoder = priorityCharset != null && priorityCharset.name().startsWith("UTF");

    for (int i = 0; i < stringToEncode.length(); i++) {
      bool canEncode = false;
      for (CharsetEncoder encoder in neededEncoders) {
        if (encoder.canEncode(stringToEncode.charAt(i))) {
          canEncode = true;
          break;
        }
      }

      if (!canEncode) {
        for (CharsetEncoder encoder in ENCODERS) {
          if (encoder.canEncode(stringToEncode.charAt(i))) {
            neededEncoders.add(encoder);
            canEncode = true;
            break;
          }
        }
      }

      if (!canEncode) {
        needUnicodeEncoder = true;
      }
    }

    if (neededEncoders.size() == 1 && !needUnicodeEncoder) {
      encoders = new CharsetEncoder[] { neededEncoders.get(0) };
    } else {
      encoders = new CharsetEncoder[neededEncoders.size() + 2];
      int index = 0;
      for (CharsetEncoder encoder in neededEncoders) {
        encoders[index++] = encoder;
      }

      encoders[index] = StandardCharsets.UTF_8.newEncoder();
      encoders[index + 1] = StandardCharsets.UTF_16BE.newEncoder();
    }

    int priorityEncoderIndexValue = -1;
    if (priorityCharset != null) {
      for (int i = 0; i < encoders.length; i++) {
        if (encoders[i] != null && priorityCharset.name().equals(encoders[i].charset().name())) {
          priorityEncoderIndexValue = i;
          break;
        }
      }
    }
    priorityEncoderIndex = priorityEncoderIndexValue;
  }

  /// Encodes the string minimally
  ///
  /// @param stringToEncode The string to encode
  /// @param version The preferred {@link Version}. A minimal version is computed (see
  ///   {@link ResultList#getVersion method} when the value of the argument is null
  /// @param priorityCharset The preferred {@link Charset}. When the value of the argument is null, the algorithm
  ///   chooses charsets that leads to a minimal representation. Otherwise the algorithm will use the priority
  ///   charset to encode any character in the input that can be encoded by it if the charset is among the
  ///   supported charsets.
  /// @param isGS1 {@code true} if a FNC1 is to be prepended; {@code false} otherwise
  /// @param ecLevel The error correction level.
  /// @return An instance of {@code ResultList} representing the minimal solution.
  /// @see ResultList#getBits
  /// @see ResultList#getVersion
  /// @see ResultList#getSize
  static ResultList encode(String stringToEncode, Version? version, Charset priorityCharset, bool isGS1,
      ErrorCorrectionLevel ecLevel) {
    return MinimalEncoder(stringToEncode, priorityCharset, isGS1, ecLevel).doEncode(version);
  }

  ResultList doEncode(Version? version) {
    if (version == null) { // compute minimal encoding trying the three version sizes.
      final List<Version> versions = [getVersion(VersionSize.SMALL),
        getVersion(VersionSize.MEDIUM),
        getVersion(VersionSize.LARGE)];
      List<ResultList> results = [encodeSpecificVersion(versions[0]),
        encodeSpecificVersion(versions[1]),
        encodeSpecificVersion(versions[2])];
      int smallestSize = Integer.MAX_VALUE;
      int smallestResult = -1;
      for (int i = 0; i < 3; i++) {
        int size = results[i].getSize();
        if (Encoder.willFit(size, versions[i], ecLevel) && size < smallestSize) {
          smallestSize = size;
          smallestResult = i;
        }
      }
      if (smallestResult < 0) {
        throw WriterException("Data too big for any version");
      }
      return results[smallestResult];
    } else { // compute minimal encoding for a given version
      ResultList result = encodeSpecificVersion(version);
      if (!Encoder.willFit(result.getSize(), getVersion(getVersionSize(result.getVersion())), ecLevel)) {
        throw WriterException("Data too big for version $version");
      }
      return result;
    }
  }

  static VersionSize getVersionSize(Version version) {
    return version.versionNumber <= 9 ? VersionSize.SMALL : version.versionNumber <= 26 ?
    VersionSize.MEDIUM : VersionSize.LARGE;
  }

  static Version getVersion(VersionSize versionSize) {
    switch (versionSize) {
      case VersionSize.SMALL:
        return Version.getVersionForNumber(9);
      case VersionSize.MEDIUM:
        return Version.getVersionForNumber(26);
      case VersionSize.LARGE:
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
      case Mode.KANJI: return isDoubleByteKanji(c);
      case Mode.ALPHANUMERIC: return isAlphanumeric(c);
      case Mode.NUMERIC: return isNumeric(c);
    // any character can be encoded as byte(s). Up to the caller to manage splitting into
    // multiple bytes when String.getBytes(Charset) return more than one byte.
      case Mode.BYTE: return true;

      default:
        return false;
    }
  }

  static int getCompactedOrdinal(Mode? mode) {
    if (mode == null) {
      return 0;
    }
    switch (mode) {
      case Mode.KANJI:
        return 0;
      case Mode.ALPHANUMERIC:
        return 1;
      case Mode.NUMERIC:
        return 2;
      case Mode.BYTE:
        return 3;
      default:
        throw IllegalStateException("Illegal mode " + mode);
    }
  }

  void addEdge(List<List<List<Edge>>> edges, int position, Edge edge) {
    int vertexIndex = position + edge.characterLength;
    List<Edge?> modeEdges = edges[vertexIndex][edge.charsetEncoderIndex];
    int modeOrdinal = getCompactedOrdinal(edge.mode);
    if (modeEdges[modeOrdinal] == null || modeEdges[modeOrdinal]!.cachedTotalSize > edge.cachedTotalSize) {
      modeEdges[modeOrdinal] = edge;
    }
  }

  void addEdges(Version version, List<List<List<Edge>>> edges, int from, Edge? previous) {
    int start = 0;
    int end = encoders.length;
    if (priorityEncoderIndex >= 0 && encoders[priorityEncoderIndex]?.canEncode(stringToEncode.codeUnitAt(from))) {
      start = priorityEncoderIndex;
      end = priorityEncoderIndex + 1;
    }

    for (int i = start; i < end; i++) {
      if (encoders[i]?.canEncode(stringToEncode.codeUnitAt(from))) {
        addEdge(edges, from, Edge(Mode.BYTE, from, i, 1, previous, version, this));
      }
    }

    if (canEncode(Mode.KANJI, stringToEncode.codeUnitAt(from))) {
      addEdge(edges, from, Edge(Mode.KANJI, from, 0, 1, previous, version, this));
    }

    int inputLength = stringToEncode.length;
    if (canEncode(Mode.ALPHANUMERIC, stringToEncode.codeUnitAt(from))) {
      addEdge(edges, from, Edge(Mode.ALPHANUMERIC, from, 0, from + 1 >= inputLength ||
          !canEncode(Mode.ALPHANUMERIC, stringToEncode.codeUnitAt(from + 1)) ? 1 : 2, previous, version,this));
    }

    if (canEncode(Mode.NUMERIC, stringToEncode.codeUnitAt(from))) {
      addEdge(edges, from, Edge(Mode.NUMERIC, from, 0, from + 1 >= inputLength ||
          !canEncode(Mode.NUMERIC, stringToEncode.codeUnitAt(from + 1)) ? 1 : from + 2 >= inputLength ||
          !canEncode(Mode.NUMERIC, stringToEncode.codeUnitAt(from + 2)) ? 2 : 3, previous, version,this));
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

    int inputLength = stringToEncode.length;

    // Array that represents vertices. There is a vertex for every character, encoding and mode. The vertex contains
    // a list of all edges that lead to it that have the same encoding and mode.
    // The lists are created lazily

    // The last dimension in the array below encodes the 4 modes KANJI, ALPHANUMERIC, NUMERIC and BYTE via the
    // function getCompactedOrdinal(Mode)
    List<List<List<Edge>>> edges = List.generate(inputLength + 1,(idx)=>List.generate(encoders.length,(idx2)=>List.filled(4,null)));
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
    int minimalSize = Integer.MAX_VALUE;
    for (int j = 0; j < encoders.length; j++) {
      for (int k = 0; k < 4; k++) {
        if (edges[inputLength][j][k] != null) {
          Edge? edge = edges[inputLength][j][k];
          if (edge.cachedTotalSize < minimalSize) {
            minimalSize = edge.cachedTotalSize;
            minimalJ = j;
            minimalK = k;
          }
        }
      }
    }
    if (minimalJ < 0) {
      throw WriterException("Internal error: failed to encode \"" + stringToEncode + "\"");
    }
    return ResultList(version, edges[inputLength][minimalJ][minimalK], this);
  }
}