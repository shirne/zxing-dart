/*
 * Copyright 2013 ZXing authors
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
import 'dart:typed_data';

import '../../common/bit_array.dart';
import '../../common/character_set_eci.dart';

import 'state.dart';

/**
 * This produces nearly optimal encodings of text into the first-level of
 * encoding used by Aztec code.
 *
 * It uses a dynamic algorithm.  For each prefix of the string, it determines
 * a set of encodings that could lead to this prefix.  We repeatedly add a
 * character and generate a new set of optimal encodings until we have read
 * through the entire input.
 *
 * @author Frank Yellin
 * @author Rustam Abdullaev
 */
class HighLevelEncoder {
  static const List<String> MODE_NAMES = [
    "UPPER",
    "LOWER",
    "DIGIT",
    "MIXED",
    "PUNCT"
  ];

  static const int MODE_UPPER = 0; // 5 bits
  static const int MODE_LOWER = 1; // 5 bits
  static const int MODE_DIGIT = 2; // 4 bits
  static const int MODE_MIXED = 3; // 5 bits
  static const int MODE_PUNCT = 4; // 5 bits

  // The Latch Table shows, for each pair of Modes, the optimal method for
  // getting from one mode to another.  In the worst possible case, this can
  // be up to 14 bits.  In the best possible case, we are already there!
  // The high half-word of each entry gives the number of bits.
  // The low half-word of each entry are the actual bits necessary to change
  static const List<List<int>> LATCH_TABLE = [
    [
      0,
      (5 << 16) + 28, // UPPER -> LOWER
      (5 << 16) + 30, // UPPER -> DIGIT
      (5 << 16) + 29, // UPPER -> MIXED
      (10 << 16) + (29 << 5) + 30, // UPPER -> MIXED -> PUNCT
    ],
    [
      (9 << 16) + (30 << 4) + 14, // LOWER -> DIGIT -> UPPER
      0,
      (5 << 16) + 30, // LOWER -> DIGIT
      (5 << 16) + 29, // LOWER -> MIXED
      (10 << 16) + (29 << 5) + 30, // LOWER -> MIXED -> PUNCT
    ],
    [
      (4 << 16) + 14, // DIGIT -> UPPER
      (9 << 16) + (14 << 5) + 28, // DIGIT -> UPPER -> LOWER
      0,
      (9 << 16) + (14 << 5) + 29, // DIGIT -> UPPER -> MIXED
      (14 << 16) + (14 << 10) + (29 << 5) + 30,
      // DIGIT -> UPPER -> MIXED -> PUNCT
    ],
    [
      (5 << 16) + 29, // MIXED -> UPPER
      (5 << 16) + 28, // MIXED -> LOWER
      (10 << 16) + (29 << 5) + 30, // MIXED -> UPPER -> DIGIT
      0,
      (5 << 16) + 30, // MIXED -> PUNCT
    ],
    [
      (5 << 16) + 31, // PUNCT -> UPPER
      (10 << 16) + (31 << 5) + 28, // PUNCT -> UPPER -> LOWER
      (10 << 16) + (31 << 5) + 30, // PUNCT -> UPPER -> DIGIT
      (10 << 16) + (31 << 5) + 29, // PUNCT -> UPPER -> MIXED
      0,
    ],
  ];

  // A reverse mapping from [mode][char] to the encoding for that character
  // in that mode.  An entry of 0 indicates no mapping exists.
  static final List<List<int>> CHAR_MAP = List.generate(
      5,
      (idx) => List.generate(256, (index) {
            if (idx == MODE_UPPER) {
              if (index == ' '.codeUnitAt(0)) return 1;
              if (index >= 'A'.codeUnitAt(0) && index <= 'Z'.codeUnitAt(0)) {
                return index - 'A'.codeUnitAt(0) + 2;
              }
            } else if (idx == MODE_LOWER) {
              if (index == ' '.codeUnitAt(0)) return 1;
              if (index >= 'a'.codeUnitAt(0) && index <= 'z'.codeUnitAt(0)) {
                return index - 'a'.codeUnitAt(0) + 2;
              }
            } else if (idx == MODE_DIGIT) {
              if (index == ' '.codeUnitAt(0)) return 1;
              if (index >= '0'.codeUnitAt(0) && index <= '9'.codeUnitAt(0)) {
                return index - '0'.codeUnitAt(0) + 2;
              }
              if (index == ','.codeUnitAt(0)) return 12;
              if (index == '.'.codeUnitAt(0)) return 13;
            } else if (idx == MODE_MIXED) {
              return [
                '\0', ' ', '\1', '\2', '\3', '\4', '\5', '\6', '\7', '\b', '\t',
                '\n', //
                '\13', '\f', '\r', '\33', '\34', '\35', '\36', '\37', '@', '\\',
                '^',
                '_', '`', '|', '~', '\177'
              ].indexOf(String.fromCharCode(index));
            } else if (idx == MODE_PUNCT) {
              return [
                '\0', '\r', '\0', '\0', '\0', '\0', '!', '\'', '#', r'$', '%',
                '&', '\'', //
                '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>',
                '?',
                '[', ']', '{', '}'
              ].indexOf(String.fromCharCode(index));
            }

            return 0;
          }));

  // A map showing the available shift codes.  (The shifts to BINARY are not
  // shown
  static final List<List<int>> SHIFT_TABLE = List.generate(
      6,
      (idx) => List.generate(6, (index) {
            if (idx == MODE_UPPER) {
              if (index == MODE_PUNCT) return 0;
            } else if (idx == MODE_LOWER) {
              if (index == MODE_PUNCT) return 0;
              if (index == MODE_UPPER) return 28;
            } else if (idx == MODE_MIXED) {
              if (index == MODE_PUNCT) return 0;
            } else if (idx == MODE_DIGIT) {
              if (index == MODE_PUNCT) return 0;
              if (index == MODE_UPPER) return 15;
            }

            return -1;
          })); // mode shift codes, per table

  final Uint8List text;
  final Encoding? charset;

  HighLevelEncoder(this.text, [this.charset]);

  /**
   * @return text represented by this encoder encoded as a {@link BitArray}
   */
  BitArray encode() {
    State initialState = State.INITIAL_STATE;
    if (charset != null) {
      CharacterSetECI? eci = CharacterSetECI.getCharacterSetECI(charset!);
      if (null == eci) {
        throw Exception("No ECI code for character set $charset");
      }
      initialState = initialState.appendFLGn(eci.getValue());
    }
    List<State> states = [initialState];
    for (int index = 0; index < text.length; index++) {
      int pairCode;
      String nextChar =
          String.fromCharCode(index + 1 < text.length ? text[index + 1] : 0);
      switch (String.fromCharCode(text[index])) {
        case '\r':
          pairCode = nextChar == '\n' ? 2 : 0;
          break;
        case '.':
          pairCode = nextChar == ' ' ? 3 : 0;
          break;
        case ',':
          pairCode = nextChar == ' ' ? 4 : 0;
          break;
        case ':':
          pairCode = nextChar == ' ' ? 5 : 0;
          break;
        default:
          pairCode = 0;
      }
      if (pairCode > 0) {
        // We have one of the four special PUNCT pairs.  Treat them specially.
        // Get a new set of states for the two new characters.
        states = updateStateListForPair(states, index, pairCode);
        index++;
      } else {
        // Get a new set of states for the new character.
        states = updateStateListForChar(states, index);
      }
    }
    State minState = states.singleWhere((element) {
      return states.every((ele) => element.getBitCount() <= ele.getBitCount());
    });
    // We are left with a set of states.  Find the shortest one.
    //State minState = Collections.min(states, new Comparator<State>() {
    //  @override
    //  int compare(State a, State b) {
    //    return a.getBitCount() - b.getBitCount();
    //  }
    //});
    // Convert it to a bit array, and return.
    return minState.toBitArray(text);
  }

  // We update a set of states for a new character by updating each state
  // for the new character, merging the results, and then removing the
  // non-optimal states.
  List<State> updateStateListForChar(Iterable<State> states, int index) {
    List<State> result = [];
    for (State state in states) {
      updateStateForChar(state, index, result);
    }
    return simplifyStates(result);
  }

  // Return a set of states that represent the possible ways of updating this
  // state for the next character.  The resulting set of states are added to
  // the "result" list.
  void updateStateForChar(State state, int index, List<State> result) {
    int ch = text[index] & 0xFF;
    bool charInCurrentTable = CHAR_MAP[state.getMode()][ch] > 0;
    State? stateNoBinary;
    for (int mode = 0; mode <= MODE_PUNCT; mode++) {
      int charInMode = CHAR_MAP[mode][ch];
      if (charInMode > 0) {
        if (stateNoBinary == null) {
          // Only create stateNoBinary the first time it's required.
          stateNoBinary = state.endBinaryShift(index);
        }
        // Try generating the character by latching to its mode
        if (!charInCurrentTable ||
            mode == state.getMode() ||
            mode == MODE_DIGIT) {
          // If the character is in the current table, we don't want to latch to
          // any other mode except possibly digit (which uses only 4 bits).  Any
          // other latch would be equally successful *after* this character, and
          // so wouldn't save any bits.
          State latchState = stateNoBinary.latchAndAppend(mode, charInMode);
          result.add(latchState);
        }
        // Try generating the character by switching to its mode.
        if (!charInCurrentTable && SHIFT_TABLE[state.getMode()][mode] >= 0) {
          // It never makes sense to temporarily shift to another mode if the
          // character exists in the current mode.  That can never save bits.
          State shiftState = stateNoBinary.shiftAndAppend(mode, charInMode);
          result.add(shiftState);
        }
      }
    }
    if (state.getBinaryShiftByteCount() > 0 ||
        CHAR_MAP[state.getMode()][ch] == 0) {
      // It's never worthwhile to go into binary shift mode if you're not already
      // in binary shift mode, and the character exists in your current mode.
      // That can never save bits over just outputting the char in the current mode.
      State binaryState = state.addBinaryShiftChar(index);
      result.add(binaryState);
    }
  }

  static List<State> updateStateListForPair(
      Iterable<State> states, int index, int pairCode) {
    List<State> result = [];
    for (State state in states) {
      updateStateForPair(state, index, pairCode, result);
    }
    return simplifyStates(result);
  }

  static void updateStateForPair(
      State state, int index, int pairCode, List<State> result) {
    State stateNoBinary = state.endBinaryShift(index);
    // Possibility 1.  Latch to MODE_PUNCT, and then append this code
    result.add(stateNoBinary.latchAndAppend(MODE_PUNCT, pairCode));
    if (state.getMode() != MODE_PUNCT) {
      // Possibility 2.  Shift to MODE_PUNCT, and then append this code.
      // Every state except MODE_PUNCT (handled above) can shift
      result.add(stateNoBinary.shiftAndAppend(MODE_PUNCT, pairCode));
    }
    if (pairCode == 3 || pairCode == 4) {
      // both characters are in DIGITS.  Sometimes better to just add two digits
      State digitState = stateNoBinary
          .latchAndAppend(MODE_DIGIT, 16 - pairCode) // period or comma in DIGIT
          .latchAndAppend(MODE_DIGIT, 1); // space in DIGIT
      result.add(digitState);
    }
    if (state.getBinaryShiftByteCount() > 0) {
      // It only makes sense to do the characters as binary if we're already
      // in binary mode.
      State binaryState =
          state.addBinaryShiftChar(index).addBinaryShiftChar(index + 1);
      result.add(binaryState);
    }
  }

  static List<State> simplifyStates(Iterable<State> states) {
    return states
        .where((newEle) =>
            states.every((oldEle) => newEle.isBetterThanOrEqualTo(oldEle)))
        .toList();
    /* List<State> result = [];
    for (State newState in states) {
      bool add = true;
      for (Iterator<State> iterator = result.iterator(); iterator.hasNext();) {
        State oldState = iterator.next();
        if (oldState.isBetterThanOrEqualTo(newState)) {
          add = false;
          break;
        }
        if (newState.isBetterThanOrEqualTo(oldState)) {
          iterator.remove();
        }
      }
      if (add) {
        result.add(newState);
      }
    }
    return result; */
  }
}
