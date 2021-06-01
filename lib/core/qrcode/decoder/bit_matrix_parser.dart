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

import 'dart:typed_data';

import '../../common/bit_matrix.dart';

import 'data_mask.dart';
import 'format_information.dart';
import 'version.dart';

/// @author Sean Owen
class BitMatrixParser {
  final BitMatrix _bitMatrix;
  Version? _parsedVersion;
  FormatInformation? _parsedFormatInfo;
  bool _isMirror = false;

  /// @param bitMatrix {@link BitMatrix} to parse
  /// @throws FormatException if dimension is not >= 21 and 1 mod 4
  BitMatrixParser(this._bitMatrix) {
    int dimension = _bitMatrix.getHeight();
    if (dimension < 21 || (dimension & 0x03) != 1) {
      throw FormatException();
    }
  }

  /// <p>Reads format information from one of its two locations within the QR Code.</p>
  ///
  /// @return {@link FormatInformation} encapsulating the QR Code's format info
  /// @throws FormatException if both format information locations cannot be parsed as
  /// the valid encoding of format information
  FormatInformation readFormatInformation() {
    if (_parsedFormatInfo != null) {
      return _parsedFormatInfo!;
    }

    // Read top-left format info bits
    int formatInfoBits1 = 0;
    for (int i = 0; i < 6; i++) {
      formatInfoBits1 = _copyBit(i, 8, formatInfoBits1);
    }
    // .. and skip a bit in the timing pattern ...
    formatInfoBits1 = _copyBit(7, 8, formatInfoBits1);
    formatInfoBits1 = _copyBit(8, 8, formatInfoBits1);
    formatInfoBits1 = _copyBit(8, 7, formatInfoBits1);
    // .. and skip a bit in the timing pattern ...
    for (int j = 5; j >= 0; j--) {
      formatInfoBits1 = _copyBit(8, j, formatInfoBits1);
    }

    // Read the top-right/bottom-left pattern too
    int dimension = _bitMatrix.getHeight();
    int formatInfoBits2 = 0;
    int jMin = dimension - 7;
    for (int j = dimension - 1; j >= jMin; j--) {
      formatInfoBits2 = _copyBit(8, j, formatInfoBits2);
    }
    for (int i = dimension - 8; i < dimension; i++) {
      formatInfoBits2 = _copyBit(i, 8, formatInfoBits2);
    }

    _parsedFormatInfo = FormatInformation.decodeFormatInformation(
        formatInfoBits1, formatInfoBits2);
    if (_parsedFormatInfo != null) {
      return _parsedFormatInfo!;
    }
    throw FormatException();
  }

  /// <p>Reads version information from one of its two locations within the QR Code.</p>
  ///
  /// @return {@link Version} encapsulating the QR Code's version
  /// @throws FormatException if both version information locations cannot be parsed as
  /// the valid encoding of version information
  Version readVersion() {
    if (_parsedVersion != null) {
      return _parsedVersion!;
    }

    int dimension = _bitMatrix.getHeight();

    int provisionalVersion = (dimension - 17) ~/ 4;
    if (provisionalVersion <= 6) {
      return Version.getVersionForNumber(provisionalVersion);
    }

    // Read top-right version info: 3 wide by 6 tall
    int versionBits = 0;
    int ijMin = dimension - 11;
    for (int j = 5; j >= 0; j--) {
      for (int i = dimension - 9; i >= ijMin; i--) {
        versionBits = _copyBit(i, j, versionBits);
      }
    }

    Version? theParsedVersion = Version.decodeVersionInformation(versionBits);
    if (theParsedVersion != null &&
        theParsedVersion.getDimensionForVersion() == dimension) {
      _parsedVersion = theParsedVersion;
      return theParsedVersion;
    }

    // Hmm, failed. Try bottom left: 6 wide by 3 tall
    versionBits = 0;
    for (int i = 5; i >= 0; i--) {
      for (int j = dimension - 9; j >= ijMin; j--) {
        versionBits = _copyBit(i, j, versionBits);
      }
    }

    theParsedVersion = Version.decodeVersionInformation(versionBits);
    if (theParsedVersion != null &&
        theParsedVersion.getDimensionForVersion() == dimension) {
      _parsedVersion = theParsedVersion;
      return theParsedVersion;
    }
    throw FormatException();
  }

  int _copyBit(int i, int j, int versionBits) {
    bool bit = _isMirror ? _bitMatrix.get(j, i) : _bitMatrix.get(i, j);
    return bit ? (versionBits << 1) | 0x1 : versionBits << 1;
  }

  /// <p>Reads the bits in the {@link BitMatrix} representing the finder pattern in the
  /// correct order in order to reconstruct the codewords bytes contained within the
  /// QR Code.</p>
  ///
  /// @return bytes encoded within the QR Code
  /// @throws FormatException if the exact number of bytes expected is not read
  Uint8List readCodewords() {
    FormatInformation formatInfo = readFormatInformation();
    Version version = readVersion();

    // Get the data mask for the format used in this QR Code. This will exclude
    // some bits from reading as we wind through the bit matrix.
    DataMask dataMask = DataMask.values[formatInfo.getDataMask()];
    int dimension = _bitMatrix.getHeight();
    dataMask.unmaskBitMatrix(_bitMatrix, dimension);

    BitMatrix functionPattern = version.buildFunctionPattern();

    bool readingUp = true;
    Uint8List result = Uint8List(version.getTotalCodewords());
    int resultOffset = 0;
    int currentByte = 0;
    int bitsRead = 0;
    // Read columns in pairs, from right to left
    for (int j = dimension - 1; j > 0; j -= 2) {
      if (j == 6) {
        // Skip whole column with vertical alignment pattern;
        // saves time and makes the other code proceed more cleanly
        j--;
      }
      // Read alternatingly from bottom to top then top to bottom
      for (int count = 0; count < dimension; count++) {
        int i = readingUp ? dimension - 1 - count : count;
        for (int col = 0; col < 2; col++) {
          // Ignore bits covered by the function pattern
          if (!functionPattern.get(j - col, i)) {
            // Read a bit
            bitsRead++;
            currentByte <<= 1;
            if (_bitMatrix.get(j - col, i)) {
              currentByte |= 1;
            }
            // If we've made a whole byte, save it off
            if (bitsRead == 8) {
              result[resultOffset++] = currentByte;
              bitsRead = 0;
              currentByte = 0;
            }
          }
        }
      }
      readingUp ^= true; // readingUp = !readingUp; // switch directions
    }
    if (resultOffset != version.getTotalCodewords()) {
      throw FormatException();
    }
    return result;
  }

  /// Revert the mask removal done while reading the code words. The bit matrix should revert to its original state.
  void remask() {
    if (_parsedFormatInfo == null) {
      return; // We have no format information, and have no data mask
    }
    DataMask dataMask = DataMask.values[_parsedFormatInfo!.getDataMask()];
    int dimension = _bitMatrix.getHeight();
    dataMask.unmaskBitMatrix(_bitMatrix, dimension);
  }

  /// Prepare the parser for a mirrored operation.
  /// This flag has effect only on the {@link #readFormatInformation()} and the
  /// {@link #readVersion()}. Before proceeding with {@link #readCodewords()} the
  /// {@link #mirror()} method should be called.
  ///
  /// @param mirror Whether to read version and format information mirrored.
  void setMirror(bool mirror) {
    _parsedVersion = null;
    _parsedFormatInfo = null;
    this._isMirror = mirror;
  }

  /// Mirror the bit matrix in order to attempt a second reading.
  void mirror() {
    for (int x = 0; x < _bitMatrix.getWidth(); x++) {
      for (int y = x + 1; y < _bitMatrix.getHeight(); y++) {
        if (_bitMatrix.get(x, y) != _bitMatrix.get(y, x)) {
          _bitMatrix.flip(y, x);
          _bitMatrix.flip(x, y);
        }
      }
    }
  }
}
