/*
 * Copyright 2012 ZXing authors
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

import '../../../checksum_exception.dart';
import 'modulus_gf.dart';
import 'modulus_poly.dart';

/// PDF417 error correction implementation.
///
/// This <a href="http://en.wikipedia.org/wiki/Reed%E2%80%93Solomon_error_correction#Example">example</a>
/// is quite useful in understanding the algorithm.
///
/// See [ReedSolomonDecoder]
///
/// @author Sean Owen
class ErrorCorrection {
  final ModulusGF _field;

  ErrorCorrection() : _field = ModulusGF.pdf417Gf;

  /// @param received received codewords
  /// @param numECCodewords number of those codewords used for EC
  /// @param erasures location of erasures
  /// @return number of errors
  /// @throws ChecksumException if errors cannot be corrected, maybe because of too many errors
  int decode(List<int> received, int numECCodewords, List<int>? erasures) {
    final poly = ModulusPoly(_field, received);
    final S = List.filled(numECCodewords, 0);
    bool error = false;
    for (int i = numECCodewords; i > 0; i--) {
      final eval = poly.evaluateAt(_field.exp(i));
      S[numECCodewords - i] = eval;
      if (eval != 0) {
        error = true;
      }
    }

    if (!error) {
      return 0;
    }

    ModulusPoly knownErrors = _field.one;
    if (erasures != null) {
      for (int erasure in erasures) {
        final b = _field.exp(received.length - 1 - erasure);
        // Add (1 - bx) term:
        final term = ModulusPoly(_field, [_field.subtract(0, b), 1]);
        knownErrors = knownErrors.multiplyPoly(term);
      }
    }

    final syndrome = ModulusPoly(_field, S);
    //syndrome = syndrome.multiply(knownErrors);

    final sigmaOmega = _runEuclideanAlgorithm(
        _field.buildMonomial(numECCodewords, 1), syndrome, numECCodewords);
    final sigma = sigmaOmega[0];
    final omega = sigmaOmega[1];

    //sigma = sigma.multiply(knownErrors);

    final errorLocations = _findErrorLocations(sigma);
    final errorMagnitudes = _findErrorMagnitudes(omega, sigma, errorLocations);

    for (int i = 0; i < errorLocations.length; i++) {
      final position = received.length - 1 - _field.log(errorLocations[i]);
      if (position < 0) {
        throw ChecksumException.getChecksumInstance();
      }
      received[position] =
          _field.subtract(received[position], errorMagnitudes[i]);
    }
    return errorLocations.length;
  }

  List<ModulusPoly> _runEuclideanAlgorithm(
      ModulusPoly a, ModulusPoly b, int R) {
    // Assume a's degree is >= b's
    if (a.degree < b.degree) {
      final temp = a;
      a = b;
      b = temp;
    }

    ModulusPoly rLast = a;
    ModulusPoly r = b;
    ModulusPoly tLast = _field.zero;
    ModulusPoly t = _field.one;

    // Run Euclidean algorithm until r's degree is less than R/2
    while (r.degree >= R / 2) {
      final rLastLast = rLast;
      final tLastLast = tLast;
      rLast = r;
      tLast = t;

      // Divide rLastLast by rLast, with quotient in q and remainder in r
      if (rLast.isZero) {
        // Oops, Euclidean algorithm already terminated?
        throw ChecksumException.getChecksumInstance();
      }
      r = rLastLast;
      ModulusPoly q = _field.zero;
      final denominatorLeadingTerm = rLast.getCoefficient(rLast.degree);
      final dltInverse = _field.inverse(denominatorLeadingTerm);
      while (r.degree >= rLast.degree && !r.isZero) {
        final degreeDiff = r.degree - rLast.degree;
        final scale = _field.multiply(r.getCoefficient(r.degree), dltInverse);
        q = q.add(_field.buildMonomial(degreeDiff, scale));
        r = r.subtract(rLast.multiplyByMonomial(degreeDiff, scale));
      }

      t = q.multiplyPoly(tLast).subtract(tLastLast).negative();
    }

    final sigmaTildeAtZero = t.getCoefficient(0);
    if (sigmaTildeAtZero == 0) {
      throw ChecksumException.getChecksumInstance();
    }

    final inverse = _field.inverse(sigmaTildeAtZero);
    final sigma = t.multiply(inverse);
    final omega = r.multiply(inverse);
    return [sigma, omega];
  }

  List<int> _findErrorLocations(ModulusPoly errorLocator) {
    // This is a direct application of Chien's search
    final numErrors = errorLocator.degree;
    final result = <int>[];
    for (int i = 1; i < _field.size; i++) {
      if (errorLocator.evaluateAt(i) == 0) {
        result.add(_field.inverse(i));
      }
    }
    if (result.length != numErrors) {
      throw ChecksumException.getChecksumInstance();
    }
    return result;
  }

  List<int> _findErrorMagnitudes(ModulusPoly errorEvaluator,
      ModulusPoly errorLocator, List<int> errorLocations) {
    final errorLocatorDegree = errorLocator.degree;
    if (errorLocatorDegree < 1) {
      return [0];
    }
    final formalDerivativeCoefficients = List.filled(errorLocatorDegree, 0);
    for (int i = 1; i <= errorLocatorDegree; i++) {
      formalDerivativeCoefficients[errorLocatorDegree - i] =
          _field.multiply(i, errorLocator.getCoefficient(i));
    }
    final formalDerivative = ModulusPoly(_field, formalDerivativeCoefficients);

    // This is directly applying Forney's Formula
    final s = errorLocations.length;
    final result = <int>[];
    for (int i = 0; i < s; i++) {
      final xiInverse = _field.inverse(errorLocations[i]);
      final numerator =
          _field.subtract(0, errorEvaluator.evaluateAt(xiInverse));
      final denominator =
          _field.inverse(formalDerivative.evaluateAt(xiInverse));
      result.add(_field.multiply(numerator, denominator));
    }
    return result;
  }
}
