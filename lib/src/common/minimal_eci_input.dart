/*
 * Copyright 2021 ZXing authors
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

import 'dart:convert';

import 'detector/math_utils.dart';
import 'eci_encoder_set.dart';
import 'eci_input.dart';

class InputEdge {
  /* private */ final int c; //char
  /* private */ final int encoderIndex; //the encoding of this edge
  /* private */ final InputEdge? previous;
  /* private */ late int cachedTotalSize;

  InputEdge(
    int c,
    ECIEncoderSet encoderSet,
    this.encoderIndex,
    this.previous,
    int fnc1,
  ) : c = c == fnc1 ? 1000 : c {
    int size = this.c == 1000 ? 1 : encoderSet.encode(c, encoderIndex).length;
    final previousEncoderIndex = previous?.encoderIndex ?? 0;
    if (previousEncoderIndex != encoderIndex) {
      size += MinimalECIInput.costPerECI;
    }
    size += previous?.cachedTotalSize ?? 0;

    cachedTotalSize = size;
  }

  bool get isFNC1 => c == 1000;
}

/// Class that converts a character string into a sequence of ECIs and bytes
///
/// The implementation uses the Dijkstra algorithm to produce minimal encodings
///
/// @author Alex Geller
class MinimalECIInput implements ECIInput {
  // approximated (latch + 2 codewords)
  /* private */ static final int costPerECI = 3;
  /* private */ late List<int> bytes;
  /* private */ final int fnc1;

  /// Constructs a minimal input
  ///
  /// @param stringToEncode the character string to encode
  /// @param priorityCharset The preferred [Charset]. When the value of the argument is null, the algorithm
  ///   chooses charsets that leads to a minimal representation. Otherwise the algorithm will use the priority
  ///   charset to encode any character in the input that can be encoded by it if the charset is among the
  ///   supported charsets.
  /// @param fnc1 denotes the character in the input that represents the FNC1 character or -1 if this is not GS1
  ///   input.
  MinimalECIInput(String stringToEncode, Encoding? priorityCharset, this.fnc1) {
    final encoderSet = ECIEncoderSet(stringToEncode, priorityCharset, fnc1);
    //optimization for the case when all can be encoded without ECI in ISO-8859-1
    if (encoderSet.length == 1) {
      bytes = List.filled(stringToEncode.length, 0);
      for (int i = 0; i < bytes.length; i++) {
        final c = stringToEncode.codeUnitAt(i);
        bytes[i] = c == fnc1 ? 1000 : c;
      }
    } else {
      bytes = encodeMinimally(stringToEncode, encoderSet, fnc1);
    }
  }

  int get fnc1Character => fnc1;

  /// Returns the length of this input.  The length is the number
  /// of `byte`s, FNC1 characters or ECIs in the sequence.
  ///
  /// @return  the number of `char`s in this sequence
  @override
  int get length => bytes.length;

  @override
  bool haveNCharacters(int index, int n) {
    if (index + n - 1 >= bytes.length) {
      return false;
    }
    for (int i = 0; i < n; i++) {
      if (isECI(index + i)) {
        return false;
      }
    }
    return true;
  }

  /// Returns the `byte` value at the specified index.  An index ranges from zero
  /// to `length - 1`.  The first `byte` value of the sequence is at
  /// index zero, the next at index one, and so on, as for array
  /// indexing.
  ///
  /// @param   index the index of the `byte` value to be returned
  ///
  /// @return  the specified `byte` value as character or the FNC1 character
  ///
  /// @throws  IndexOutOfBoundsException
  ///          if the `index` argument is negative or not less than
  ///          `length`
  /// @throws  IllegalArgumentException
  ///          if the value at the `index` argument is an ECI ([isECI])
  @override
  int charAt(int index) {
    if (index < 0 || index >= length) {
      //IndexOutOfBoundsException
      throw IndexError.withLength(index, length);
    }
    if (isECI(index)) {
      //IllegalArgumentException
      throw ArgumentError(
        'value at $index (${bytes[index]}) is not a character but an ECI',
      );
    }
    return isFNC1(index) ? fnc1 : bytes[index];
  }

  /// Returns a `CharSequence` that is a subsequence of this sequence.
  /// The subsequence starts with the `char` value at the specified index and
  /// ends with the `char` value at index `end - 1`.  The length
  /// (in `char`s) of the
  /// returned sequence is `end - start`, so if `start == end`
  /// then an empty sequence is returned.
  ///
  /// @param   start   the start index, inclusive
  /// @param   end     the end index, exclusive
  ///
  /// @return  the specified subsequence
  ///
  /// @throws  IndexOutOfBoundsException
  ///          if `start` or `end` are negative,
  ///          if `end` is greater than `length`,
  ///          or if `start` is greater than `end`
  /// @throws  IllegalArgumentException
  ///          if a value in the range `start`-`end` is an ECI (@see #isECI)
  @override
  String subSequence(int start, int end) {
    if (start < 0 || start > end || end > length) {
      //IndexOutOfBoundsException
      throw IndexError.withLength(start, length);
    }
    final result = StringBuffer();
    for (int i = start; i < end; i++) {
      if (isECI(i)) {
        // IllegalArgumentException
        throw ArgumentError(
          'value at $i (${charAt(i)}) is not a character but an ECI',
        );
      }
      result.writeCharCode(charAt(i));
    }
    return result.toString();
  }

  /// Determines if a value is an ECI
  ///
  /// @param   index the index of the value
  ///
  /// @return  true if the value at position `index` is an ECI
  ///
  /// @throws  IndexOutOfBoundsException
  ///          if the `index` argument is negative or not less than
  ///          `length`
  @override
  bool isECI(int index) {
    if (index < 0 || index >= length) {
      // IndexOutOfBoundsException
      throw IndexError.withLength(index, length);
    }
    return bytes[index] > 255 && bytes[index] <= 999;
  }

  /// Determines if a value is the FNC1 character
  ///
  /// @param   index the index of the value
  ///
  /// @return  true if the value at position `index` is the FNC1 character
  ///
  /// @throws  IndexOutOfBoundsException
  ///          if the `index` argument is negative or not less than
  ///          `length`
  bool isFNC1(int index) {
    if (index < 0 || index >= length) {
      // IndexOutOfBoundsException
      throw IndexError.withLength(index, length);
    }
    return bytes[index] == 1000;
  }

  /// Returns the `int` ECI value at the specified index.  An index ranges from zero
  /// to `length - 1`.  The first `byte` value of the sequence is at
  /// index zero, the next at index one, and so on, as for array
  /// indexing.
  ///
  /// @param   index the index of the `int` value to be returned
  ///
  /// @return  the specified `int` ECI value.
  ///          The ECI specified the encoding of all bytes with a higher index until the
  ///          next ECI or until the end of the input if no other ECI follows.
  ///
  /// @throws  IndexOutOfBoundsException
  ///          if the `index` argument is negative or not less than
  ///          `length`
  /// @throws  IllegalArgumentException
  ///          if the value at the `index` argument is not an ECI (@see #isECI)
  @override
  int getECIValue(int index) {
    if (index < 0 || index >= length) {
      // IndexOutOfBoundsException
      throw IndexError.withLength(index, length);
    }
    if (!isECI(index)) {
      //IllegalArgumentException
      throw ArgumentError('value at $index is not an ECI but a character');
    }
    return bytes[index] - 256;
  }

  @override
  String toString() {
    final result = StringBuffer();
    for (int i = 0; i < length; i++) {
      if (i > 0) {
        result.write(', ');
      }
      if (isECI(i)) {
        result.write('ECI(');
        result.write(getECIValue(i));
        result.write(')');
      } else if (charAt(i) < 128) {
        result.write('\'');
        result.writeCharCode(charAt(i));
        result.write('\'');
      } else {
        result.write(charAt(i));
      }
    }
    return result.toString();
  }

  static void addEdge(List<List<InputEdge?>> edges, int to, InputEdge edge) {
    if (edges[to][edge.encoderIndex] == null ||
        edges[to][edge.encoderIndex]!.cachedTotalSize > edge.cachedTotalSize) {
      edges[to][edge.encoderIndex] = edge;
    }
  }

  static void addEdges(
    String stringToEncode,
    ECIEncoderSet encoderSet,
    List<List<InputEdge?>> edges,
    int from,
    InputEdge? previous,
    int fnc1,
  ) {
    // chr
    final ch = stringToEncode.codeUnitAt(from);

    int start = 0;
    int end = encoderSet.length;
    if (encoderSet.priorityEncoderIndex >= 0 &&
        (ch == fnc1 ||
            encoderSet.canEncode(ch, encoderSet.priorityEncoderIndex))) {
      start = encoderSet.priorityEncoderIndex;
      end = start + 1;
    }

    for (int i = start; i < end; i++) {
      if (ch == fnc1 || encoderSet.canEncode(ch, i)) {
        addEdge(edges, from + 1, InputEdge(ch, encoderSet, i, previous, fnc1));
      }
    }
  }

  static List<int> encodeMinimally(
    String stringToEncode,
    ECIEncoderSet encoderSet,
    int fnc1,
  ) {
    final inputLength = stringToEncode.length;

    // Array that represents vertices. There is a vertex for every character and encoding.
    final List<List<InputEdge?>> edges = List.generate(
      inputLength + 1,
      (index) => List.filled(encoderSet.length, null),
    );
    addEdges(stringToEncode, encoderSet, edges, 0, null, fnc1);

    for (int i = 1; i <= inputLength; i++) {
      for (int j = 0; j < encoderSet.length; j++) {
        if (edges[i][j] != null && i < inputLength) {
          addEdges(stringToEncode, encoderSet, edges, i, edges[i][j], fnc1);
        }
      }
      //optimize memory by removing edges that have been passed.
      for (int j = 0; j < encoderSet.length; j++) {
        edges[i - 1][j] = null;
      }
    }
    int minimalJ = -1;
    int minimalSize = MathUtils.MAX_VALUE;
    for (int j = 0; j < encoderSet.length; j++) {
      if (edges[inputLength][j] != null) {
        final edge = edges[inputLength][j]!;
        if (edge.cachedTotalSize < minimalSize) {
          minimalSize = edge.cachedTotalSize;
          minimalJ = j;
        }
      }
    }
    if (minimalJ < 0) {
      // IllegalStateException
      throw StateError(
        'Failed to encode "$stringToEncode"',
      );
    }
    final intsAL = <int>[];
    InputEdge? current = edges[inputLength][minimalJ];
    while (current != null) {
      if (current.isFNC1) {
        intsAL.insert(0, 1000);
      } else {
        final bytes = encoderSet.encode(current.c, current.encoderIndex);
        for (int i = bytes.length - 1; i >= 0; i--) {
          intsAL.insert(0, bytes[i]);
        }
      }
      final previousEncoderIndex = current.previous?.encoderIndex ?? 0;
      if (previousEncoderIndex != current.encoderIndex) {
        intsAL.insert(0, 256 + encoderSet.getECIValue(current.encoderIndex));
      }
      current = current.previous;
    }

    return intsAL;
  }
}
