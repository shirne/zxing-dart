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

import 'generic_gf.dart';

/// Represents a polynomial whose coefficients are elements of a GF.
/// Instances of this class are immutable.
///
/// Much credit is due to William Rucklidge since portions of this code are an indirect
/// port of his C++ Reed-Solomon implementation.
///
/// @author Sean Owen
class GenericGFPoly {
  final GenericGF _field;
  late Int32List _coefficients;

  /// @param field the [GenericGF] instance representing the field to use
  /// to perform computations
  /// @param coefficients coefficients as ints representing elements of GF(size), arranged
  /// from most significant (highest-power term) coefficient to least significant
  /// @throws IllegalArgumentException if argument is null or empty,
  /// or if leading coefficient is 0 and this is not a
  /// constant polynomial (that is, it is not the monomial "0")
  GenericGFPoly(this._field, Int32List coefficients) {
    if (coefficients.isEmpty) {
      throw ArgumentError();
    }
    _coefficients = Int32List.fromList(
      coefficients.skipWhile((value) => value == 0).toList(),
    );
    if (_coefficients.isEmpty) {
      _coefficients = Int32List(1);
    }
  }

  Int32List get coefficients => _coefficients;

  /// @return degree of this polynomial
  int get degree => _coefficients.length - 1;

  /// @return true iff this polynomial is the monomial "0"
  bool get isZero => _coefficients[0] == 0;

  /// @return coefficient of x^degree term in this polynomial
  int getCoefficient(int degree) {
    return _coefficients[_coefficients.length - 1 - degree];
  }

  /// @return evaluation of this polynomial at a given point
  int evaluateAt(int a) {
    if (a == 0) {
      // Just return the x^0 coefficient
      return getCoefficient(0);
    }
    if (a == 1) {
      // Just the sum of the coefficients
      int result = 0;
      for (int coefficient in _coefficients) {
        result = GenericGF.addOrSubtract(result, coefficient);
      }
      return result;
    }
    int result = _coefficients[0];
    final size = _coefficients.length;
    for (int i = 1; i < size; i++) {
      result =
          GenericGF.addOrSubtract(_field.multiply(a, result), _coefficients[i]);
    }
    return result;
  }

  GenericGFPoly addOrSubtract(GenericGFPoly other) {
    if (_field != other._field) {
      throw ArgumentError('GenericGFPolys do not have same GenericGF field');
    }
    if (isZero) {
      return other;
    }
    if (other.isZero) {
      return this;
    }

    List<int> smallerCoefficients = _coefficients;
    List<int> largerCoefficients = other._coefficients;
    if (smallerCoefficients.length > largerCoefficients.length) {
      final temp = smallerCoefficients;
      smallerCoefficients = largerCoefficients;
      largerCoefficients = temp;
    }
    final sumDiff = Int32List(largerCoefficients.length);
    final lengthDiff = largerCoefficients.length - smallerCoefficients.length;
    // Copy high-order terms only found in higher-degree polynomial's coefficients
    List.copyRange(sumDiff, 0, largerCoefficients, 0, lengthDiff);

    for (int i = lengthDiff; i < largerCoefficients.length; i++) {
      sumDiff[i] = GenericGF.addOrSubtract(
        smallerCoefficients[i - lengthDiff],
        largerCoefficients[i],
      );
    }

    return GenericGFPoly(_field, sumDiff);
  }

  GenericGFPoly multiply(GenericGFPoly other) {
    if (_field != other._field) {
      throw ArgumentError('GenericGFPolys do not have same GenericGF field');
    }
    if (isZero || other.isZero) {
      return _field.zero;
    }
    final aCoefficients = _coefficients;
    final aLength = aCoefficients.length;
    final bCoefficients = other._coefficients;
    final bLength = bCoefficients.length;
    final product = Int32List(aLength + bLength - 1);
    for (int i = 0; i < aLength; i++) {
      final aCoeff = aCoefficients[i];
      for (int j = 0; j < bLength; j++) {
        product[i + j] = GenericGF.addOrSubtract(
          product[i + j],
          _field.multiply(aCoeff, bCoefficients[j]),
        );
      }
    }
    return GenericGFPoly(_field, product);
  }

  GenericGFPoly multiplyInt(int scalar) {
    if (scalar == 0) {
      return _field.zero;
    }
    if (scalar == 1) {
      return this;
    }
    final size = _coefficients.length;
    final product = Int32List(size);
    for (int i = 0; i < size; i++) {
      product[i] = _field.multiply(_coefficients[i], scalar);
    }
    return GenericGFPoly(_field, product);
  }

  GenericGFPoly multiplyByMonomial(int degree, int coefficient) {
    if (degree < 0) {
      throw ArgumentError('IllegalArgument');
    }
    if (coefficient == 0) {
      return _field.zero;
    }
    final size = _coefficients.length;
    final product = Int32List(size + degree);
    for (int i = 0; i < size; i++) {
      product[i] = _field.multiply(_coefficients[i], coefficient);
    }
    return GenericGFPoly(_field, product);
  }

  List<GenericGFPoly> divide(GenericGFPoly other) {
    if (_field != other._field) {
      throw ArgumentError('GenericGFPolys do not have same GenericGF field');
    }
    if (other.isZero) {
      throw ArgumentError('Divide by 0');
    }

    GenericGFPoly quotient = _field.zero;
    GenericGFPoly remainder = this;

    final denominatorLeadingTerm = other.getCoefficient(other.degree);
    final inverseDenominatorLeadingTerm =
        _field.inverse(denominatorLeadingTerm);

    while (remainder.degree >= other.degree && !remainder.isZero) {
      final degreeDifference = remainder.degree - other.degree;
      final scale = _field.multiply(
        remainder.getCoefficient(remainder.degree),
        inverseDenominatorLeadingTerm,
      );
      final term = other.multiplyByMonomial(degreeDifference, scale);
      final iterationQuotient = _field.buildMonomial(degreeDifference, scale);
      quotient = quotient.addOrSubtract(iterationQuotient);
      remainder = remainder.addOrSubtract(term);
    }

    return [quotient, remainder];
  }

  @override
  String toString() {
    if (isZero) {
      return '0';
    }
    final result = StringBuffer();
    for (int deg = degree; deg >= 0; deg--) {
      int coefficient = getCoefficient(deg);
      if (coefficient != 0) {
        if (coefficient < 0) {
          if (deg == degree) {
            result.write('-');
          } else {
            result.write(' - ');
          }
          coefficient = -coefficient;
        } else {
          if (result.length > 0) {
            result.write(' + ');
          }
        }
        if (deg == 0 || coefficient != 1) {
          final alphaPower = _field.log(coefficient);
          if (alphaPower == 0) {
            result.write('1');
          } else if (alphaPower == 1) {
            result.write('a');
          } else {
            result.write('a^');
            result.write(alphaPower);
          }
        }
        if (deg != 0) {
          if (deg == 1) {
            result.write('x');
          } else {
            result.write('x^');
            result.write(deg);
          }
        }
      }
    }
    return result.toString();
  }
}
