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

import 'dart:typed_data';

import 'generic_gf.dart';
import 'generic_gfpoly.dart';

/// Implements Reed-Solomon encoding, as the name implies.
///
/// @author Sean Owen
/// @author William Rucklidge
class ReedSolomonEncoder {
  final GenericGF _field;
  final List<GenericGFPoly> _cachedGenerators;

  ReedSolomonEncoder(this._field) : _cachedGenerators = [] {
    _cachedGenerators.add(GenericGFPoly(_field, Int32List.fromList([1])));
  }

  GenericGFPoly _buildGenerator(int degree) {
    if (degree >= _cachedGenerators.length) {
      GenericGFPoly lastGenerator =
          _cachedGenerators[_cachedGenerators.length - 1];
      for (int d = _cachedGenerators.length; d <= degree; d++) {
        final nextGenerator = lastGenerator.multiply(GenericGFPoly(_field,
            Int32List.fromList([1, _field.exp(d - 1 + _field.generatorBase)])));
        _cachedGenerators.add(nextGenerator);
        lastGenerator = nextGenerator;
      }
    }
    return _cachedGenerators[degree];
  }

  void encode(List<int> toEncode, int ecBytes) {
    if (ecBytes == 0) {
      throw ArgumentError('No error correction bytes');
    }
    final dataBytes = toEncode.length - ecBytes;
    if (dataBytes <= 0) {
      throw ArgumentError('No data bytes provided');
    }
    final generator = _buildGenerator(ecBytes);
    final infoCoefficients = Int32List(dataBytes);
    List.copyRange(infoCoefficients, 0, toEncode, 0, dataBytes);
    GenericGFPoly info = GenericGFPoly(_field, infoCoefficients);
    info = info.multiplyByMonomial(ecBytes, 1);
    final remainder = info.divide(generator)[1];
    final coefficients = remainder.coefficients;
    final numZeroCoefficients = ecBytes - coefficients.length;
    for (int i = 0; i < numZeroCoefficients; i++) {
      toEncode[dataBytes + i] = 0;
    }
    List.copyRange(toEncode, dataBytes + numZeroCoefficients, coefficients, 0,
        coefficients.length);
  }
}
