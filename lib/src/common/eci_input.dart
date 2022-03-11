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

/// Interface to navigate a sequence of ECIs and bytes.
///
/// @author Alex Geller
abstract class ECIInput {
  /// Returns the length of this input.  The length is the number
  /// of `byte`s in or ECIs in the sequence.
  ///
  /// @return  the number of `char`s in this sequence
  int get length => 0;

  /// Returns the `byte` value at the specified index.  An index ranges from zero
  /// to `length() - 1`.  The first `byte` value of the sequence is at
  /// index zero, the next at index one, and so on, as for array
  /// indexing.
  ///
  /// @param   index the index of the `byte` value to be returned
  ///
  /// @return  the specified `byte` value as character or the FNC1 character
  ///
  /// @throws  IndexOutOfBoundsException
  ///          if the `index` argument is negative or not less than
  ///          `length()`
  /// @throws  IllegalArgumentException
  ///          if the value at the `index` argument is an ECI ([isECI])
  int charAt(int index);

  /// Returns a `String` that is a subsequence of this sequence.
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
  ///          if `end` is greater than `length()`,
  ///          or if `start` is greater than `end`
  /// @throws  IllegalArgumentException
  ///          if a value in the range `start - end` is an ECI ([isECI])
  String subSequence(int start, int end);

  /// Determines if a value is an ECI
  ///
  /// @param   index the index of the value
  ///
  /// @return  true if the value at position `index` is an ECI
  ///
  /// @throws  IndexOutOfBoundsException
  ///          if the `index` argument is negative or not less than
  ///          `length()`
  bool isECI(int index);

  /// Returns the `int` ECI value at the specified index.  An index ranges from zero
  /// to `length() - 1`.  The first `byte` value of the sequence is at
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
  ///          `length()`
  /// @throws  IllegalArgumentException
  ///          if the value at the `index` argument is not an ECI ([isECI])
  int getECIValue(int index);
  bool haveNCharacters(int index, int n);
}
