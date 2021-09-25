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

import '../../common/bit_array.dart';
import '../../common/character_set_eci.dart';
import 'state.dart';

/// This produces nearly optimal encodings of text into the first-level of
/// encoding used by Aztec code.
///
/// It uses a dynamic algorithm.  For each prefix of the string, it determines
/// a set of encodings that could lead to this prefix.  We repeatedly add a
/// character and generate a new set of optimal encodings until we have read
/// through the entire input.
///
/// @author Frank Yellin
/// @author Rustam Abdullaev
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
  static final List<Map<int, int>> _charMap = [
    {
      // A-Z
      32: 1, 65: 2, 66: 3, 67: 4, 68: 5, 69: 6, 70: 7, 71: 8, 72: 9, 73: 10,
      74: 11, 75: 12, 76: 13, 77: 14, 78: 15, 79: 16, 80: 17, 81: 18, 82: 19,
      83: 20, 84: 21, 85: 22, 86: 23, 87: 24, 88: 25, 89: 26, 90: 27
    },
    {
      // a-z
      32: 1, 97: 2, 98: 3, 99: 4, 100: 5, 101: 6, 102: 7, 103: 8, 104: 9,
      105: 10, 106: 11, 107: 12, 108: 13, 109: 14, 110: 15, 111: 16, 112: 17,
      113: 18, 114: 19, 115: 20, 116: 21, 117: 22, 118: 23, 119: 24, 120: 25,
      121: 26, 122: 27
    },
    {
      // BLANK 0-9,.
      32: 1, 44: 12, 46: 13, 48: 2, 49: 3, 50: 4, 51: 5, 52: 6, 53: 7, 54: 8,
      55: 9, 56: 10, 57: 11
    },
    {
      // \0 \1\2\3\4\5\6\7\b\t\n\13\f\r\33\34\35\36\37@\\^_`|~\177
      1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8, 8: 9, 9: 10, 10: 11, 11: 12,
      12: 13, 13: 14, 27: 15, 28: 16, 29: 17, 30: 18, 31: 19, 32: 1, 64: 20,
      92: 21, 94: 22, 95: 23, 96: 24, 124: 25, 126: 26, 127: 27
    },
    {
      // \0\r\0\0\0\0!\'#$%&'()*+,-./:;<=>?[]{}
      13: 1, 33: 6, 35: 8, 36: 9, 37: 10, 38: 11, 39: 12, 40: 13, 41: 14,
      42: 15, 43: 16, 44: 17, 45: 18, 46: 19, 47: 20, 58: 21, 59: 22,
      60: 23, 61: 24, 62: 25, 63: 26, 91: 27, 93: 28, 123: 29, 125: 30
    },
  ];

  // A map showing the available shift codes.  (The shifts to BINARY are not
  // shown
  static final List<List<int>> shiftTable = List.generate(
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

  final List<int> _text;
  final Encoding? _charset;

  HighLevelEncoder(this._text, [this._charset]);

  /// @return text represented by this encoder encoded as a [BitArray]
  BitArray encode() {
    State initialState = State.initialState;
    if (_charset != null) {
      CharacterSetECI? eci = CharacterSetECI.getCharacterSetECI(_charset!);
      if (null == eci) {
        throw ArgumentError("No ECI code for character set ${_charset!.name}");
      }
      initialState = initialState.appendFLGn(eci.value);
    }
    List<State> states = [initialState];
    for (int index = 0; index < _text.length; index++) {
      int pairCode;
      int nextChar = index + 1 < _text.length ? _text[index + 1] : 0;
      switch (_text[index]) {
        case 13: //'\r':
          pairCode = nextChar == 10 /*'\n'*/ ? 2 : 0;
          break;
        case 46: //'.':
          pairCode = nextChar == 32 /*' '*/ ? 3 : 0;
          break;
        case 44: //',':
          pairCode = nextChar == 32 ? 4 : 0;
          break;
        case 58: //':':
          pairCode = nextChar == 32 ? 5 : 0;
          break;
        default:
          pairCode = 0;
      }
      if (pairCode > 0) {
        // We have one of the four special PUNCT pairs.  Treat them specially.
        // Get a new set of states for the two new characters.
        states = _updateStateListForPair(states, index, pairCode);
        index++;
      } else {
        // Get a new set of states for the new character.
        states = _updateStateListForChar(states, index);
      }
    }
    State minState = states.singleWhere((element) {
      return states.every((ele) => element.bitCount <= ele.bitCount);
    });
    // We are left with a set of states.  Find the shortest one.
    //State minState = Collections.min(states, Comparator<State>() {
    //  @override
    //  int compare(State a, State b) {
    //    return a.getBitCount() - b.getBitCount();
    //  }
    //});
    // Convert it to a bit array, and return.
    return minState.toBitArray(_text);
  }

  // We update a set of states for a new character by updating each state
  // for the new character, merging the results, and then removing the
  // non-optimal states.
  List<State> _updateStateListForChar(Iterable<State> states, int index) {
    List<State> result = [];
    for (State state in states) {
      _updateStateForChar(state, index, result);
    }
    return _simplifyStates(result);
  }

  // Return a set of states that represent the possible ways of updating this
  // state for the next character.  The resulting set of states are added to
  // the "result" list.
  void _updateStateForChar(State state, int index, List<State> result) {
    int ch = _text[index] & 0xFF;
    bool charInCurrentTable = _charMap[state.mode].containsKey(ch);
    State? stateNoBinary;
    for (int mode = 0; mode <= MODE_PUNCT; mode++) {
      int charInMode = _charMap[mode][ch] ?? 0;
      if (charInMode > 0) {
        // Only create stateNoBinary the first time it's required.
        stateNoBinary ??= state.endBinaryShift(index);
        // Try generating the character by latching to its mode
        if (!charInCurrentTable || mode == state.mode || mode == MODE_DIGIT) {
          // If the character is in the current table, we don't want to latch to
          // any other mode except possibly digit (which uses only 4 bits).  Any
          // other latch would be equally successful *after* this character, and
          // so wouldn't save any bits.
          State latchState = stateNoBinary.latchAndAppend(mode, charInMode);
          result.add(latchState);
        }
        // Try generating the character by switching to its mode.
        if (!charInCurrentTable && shiftTable[state.mode][mode] >= 0) {
          // It never makes sense to temporarily shift to another mode if the
          // character exists in the current mode.  That can never save bits.
          State shiftState = stateNoBinary.shiftAndAppend(mode, charInMode);
          result.add(shiftState);
        }
      }
    }
    if (state.binaryShiftByteCount > 0 ||
        !_charMap[state.mode].containsKey(ch)) {
      // It's never worthwhile to go into binary shift mode if you're not already
      // in binary shift mode, and the character exists in your current mode.
      // That can never save bits over just outputting the char in the current mode.
      State binaryState = state.addBinaryShiftChar(index);
      result.add(binaryState);
    }
  }

  static List<State> _updateStateListForPair(
      Iterable<State> states, int index, int pairCode) {
    List<State> result = [];
    for (State state in states) {
      _updateStateForPair(state, index, pairCode, result);
    }
    return _simplifyStates(result);
  }

  static void _updateStateForPair(
      State state, int index, int pairCode, List<State> result) {
    State stateNoBinary = state.endBinaryShift(index);
    // Possibility 1.  Latch to MODE_PUNCT, and then append this code
    result.add(stateNoBinary.latchAndAppend(MODE_PUNCT, pairCode));
    if (state.mode != MODE_PUNCT) {
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
    if (state.binaryShiftByteCount > 0) {
      // It only makes sense to do the characters as binary if we're already
      // in binary mode.
      State binaryState =
          state.addBinaryShiftChar(index).addBinaryShiftChar(index + 1);
      result.add(binaryState);
    }
  }

  static List<State> _simplifyStates(Iterable<State> states) {
    //return states
    //    .where((newEle) =>
    //        states.every((oldEle) => newEle.isBetterThanOrEqualTo(oldEle)))
    //    .toList();
    List<State> result = [];
    List<State> removedState = [];
    for (State newState in states) {
      bool add = true;
      for (Iterator<State> iterator = result.iterator; iterator.moveNext();) {
        State oldState = iterator.current;
        if (oldState.isBetterThanOrEqualTo(newState)) {
          add = false;
          break;
        }
        if (newState.isBetterThanOrEqualTo(oldState)) {
          removedState.add(oldState);
        }
      }
      //result.removeWhere((element) => newState.isBetterThanOrEqualTo(element));
      for (var rState in removedState) {
        result.remove(rState);
      }
      removedState.clear();
      if (add) {
        result.insert(0, newState);
      }
    }
    return result;
  }
}
