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

import 'generic_gf.dart';
import 'generic_gfpoly.dart';

/// <p>Implements Reed-Solomon encoding, as the name implies.</p>
///
/// @author Sean Owen
/// @author William Rucklidge
class ReedSolomonEncoder {
  final GenericGF _field;
  final List<GenericGFPoly> _cachedGenerators;

  ReedSolomonEncoder(this._field) : _cachedGenerators = [] {
    _cachedGenerators.add(GenericGFPoly(_field, [1]));
  }

  GenericGFPoly _buildGenerator(int degree) {
    if (degree >= _cachedGenerators.length) {
      GenericGFPoly lastGenerator =
        _cachedGenerators[_cachedGenerators.length - 1];
      for (int d = _cachedGenerators.length; d <= degree; d++) {
        GenericGFPoly nextGenerator = lastGenerator.multiply(GenericGFPoly(
            _field, [1, _field.exp(d - 1 + _field.getGeneratorBase())]));
        _cachedGenerators.add(nextGenerator);
        lastGenerator = nextGenerator;
      }
    }
    return _cachedGenerators[degree];
  }

  void encode(List<int> toEncode, int ecBytes) {
    if (ecBytes == 0) {
      throw Exception("No error correction bytes");
    }
    int dataBytes = toEncode.length - ecBytes;
    if (dataBytes <= 0) {
      throw Exception("No data bytes provided");
    }
    GenericGFPoly generator = _buildGenerator(ecBytes);
    List<int> infoCoefficients = List.generate(dataBytes, (index) => 0);
    List.copyRange(infoCoefficients, 0, toEncode, 0, dataBytes);
    GenericGFPoly info = GenericGFPoly(_field, infoCoefficients);
    info = info.multiplyByMonomial(ecBytes, 1);
    GenericGFPoly remainder = info.divide(generator)[1];
    List<int> coefficients = remainder.getCoefficients();
    int numZeroCoefficients = ecBytes - coefficients.length;
    for (int i = 0; i < numZeroCoefficients; i++) {
      toEncode[dataBytes + i] = 0;
    }
    List.copyRange(toEncode, dataBytes + numZeroCoefficients, coefficients, 0,
        coefficients.length);
  }
}
