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

import 'modulus_gf.dart';

/// @author Sean Owen
class ModulusPoly {
  final ModulusGF _field;
  late List<int> _coefficients;

  ModulusPoly(this._field, List<int> coefficients) {
    if (coefficients.isEmpty) {
      throw ArgumentError();
    }
    final coefficientsLength = coefficients.length;
    if (coefficientsLength > 1 && coefficients[0] == 0) {
      // Leading term must be non-zero for anything except the constant polynomial "0"
      int firstNonZero = 1;
      while (firstNonZero < coefficientsLength &&
          coefficients[firstNonZero] == 0) {
        firstNonZero++;
      }
      if (firstNonZero == coefficientsLength) {
        _coefficients = [];
      } else {
        _coefficients = List.filled(coefficientsLength - firstNonZero, 0);
        List.copyRange(_coefficients, 0, coefficients, firstNonZero,
            firstNonZero + _coefficients.length);
      }
    } else {
      _coefficients = coefficients;
    }
  }

  List<int> get coefficients => _coefficients;

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
        result = _field.add(result, coefficient);
      }
      return result;
    }
    int result = _coefficients[0];
    final size = _coefficients.length;
    for (int i = 1; i < size; i++) {
      result = _field.add(_field.multiply(a, result), _coefficients[i]);
    }
    return result;
  }

  ModulusPoly add(ModulusPoly other) {
    if (_field != other._field) {
      throw ArgumentError('ModulusPolys do not have same ModulusGF field');
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
    final sumDiff = List.filled(largerCoefficients.length, 0);
    final lengthDiff = largerCoefficients.length - smallerCoefficients.length;
    // Copy high-order terms only found in higher-degree polynomial's coefficients
    List.copyRange(sumDiff, 0, largerCoefficients, 0, lengthDiff);

    for (int i = lengthDiff; i < largerCoefficients.length; i++) {
      sumDiff[i] = _field.add(
          smallerCoefficients[i - lengthDiff], largerCoefficients[i]);
    }

    return ModulusPoly(_field, sumDiff);
  }

  ModulusPoly subtract(ModulusPoly other) {
    if (_field != other._field) {
      throw ArgumentError('ModulusPolys do not have same ModulusGF field');
    }
    if (other.isZero) {
      return this;
    }
    return add(other.negative());
  }

  ModulusPoly multiplyPoly(ModulusPoly other) {
    if (_field != other._field) {
      throw ArgumentError('ModulusPolys do not have same ModulusGF field');
    }
    if (isZero || other.isZero) {
      return _field.zero;
    }
    final aCoefficients = _coefficients;
    final aLength = aCoefficients.length;
    final bCoefficients = other._coefficients;
    final bLength = bCoefficients.length;
    final product = List.filled(aLength + bLength - 1, 0);
    for (int i = 0; i < aLength; i++) {
      final aCoeff = aCoefficients[i];
      for (int j = 0; j < bLength; j++) {
        product[i + j] = _field.add(
            product[i + j], _field.multiply(aCoeff, bCoefficients[j]));
      }
    }
    return ModulusPoly(_field, product);
  }

  ModulusPoly negative() {
    final size = _coefficients.length;
    final negativeCoefficients = <int>[];
    for (int i = 0; i < size; i++) {
      negativeCoefficients.add(_field.subtract(0, _coefficients[i]));
    }
    return ModulusPoly(_field, negativeCoefficients);
  }

  ModulusPoly multiply(int scalar) {
    if (scalar == 0) {
      return _field.zero;
    }
    if (scalar == 1) {
      return this;
    }
    final size = _coefficients.length;
    final product = <int>[]; // size
    for (int i = 0; i < size; i++) {
      product.add(_field.multiply(_coefficients[i], scalar));
    }
    return ModulusPoly(_field, product);
  }

  ModulusPoly multiplyByMonomial(int degree, int coefficient) {
    if (degree < 0) {
      throw ArgumentError();
    }
    if (coefficient == 0) {
      return _field.zero;
    }
    final size = _coefficients.length;
    final product = List.filled(size + degree, 0);
    for (int i = 0; i < size; i++) {
      product[i] = _field.multiply(_coefficients[i], coefficient);
    }
    return ModulusPoly(_field, product);
  }

  @override
  String toString() {
    final result = StringBuffer();
    for (int deg = degree; deg >= 0; deg--) {
      int coefficient = getCoefficient(deg);
      if (coefficient != 0) {
        if (coefficient < 0) {
          result.write(' - ');
          coefficient = -coefficient;
        } else {
          if (result.length > 0) {
            result.write(' + ');
          }
        }
        if (deg == 0 || coefficient != 1) {
          result.write(coefficient);
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
