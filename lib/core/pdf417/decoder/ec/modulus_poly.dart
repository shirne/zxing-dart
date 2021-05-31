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

/**
 * @author Sean Owen
 */
class ModulusPoly {
  final ModulusGF _field;
  late List<int> _coefficients;

  ModulusPoly(this._field, List<int> coefficients) {
    if (coefficients.length == 0) {
      throw Exception();
    }
    int coefficientsLength = coefficients.length;
    if (coefficientsLength > 1 && coefficients[0] == 0) {
      // Leading term must be non-zero for anything except the constant polynomial "0"
      int firstNonZero = 1;
      while (firstNonZero < coefficientsLength &&
          coefficients[firstNonZero] == 0) {
        firstNonZero++;
      }
      if (firstNonZero == coefficientsLength) {
        this._coefficients = [];
      } else {
        this._coefficients = List.filled(coefficientsLength - firstNonZero, 0);
        List.copyRange(this._coefficients, 0, coefficients, firstNonZero,
            firstNonZero + this._coefficients.length);
      }
    } else {
      this._coefficients = coefficients;
    }
  }

  List<int> getCoefficients() {
    return _coefficients;
  }

  /**
   * @return degree of this polynomial
   */
  int getDegree() {
    return _coefficients.length - 1;
  }

  /**
   * @return true iff this polynomial is the monomial "0"
   */
  bool isZero() {
    return _coefficients[0] == 0;
  }

  /**
   * @return coefficient of x^degree term in this polynomial
   */
  int getCoefficient(int degree) {
    return _coefficients[_coefficients.length - 1 - degree];
  }

  /**
   * @return evaluation of this polynomial at a given point
   */
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
    int size = _coefficients.length;
    for (int i = 1; i < size; i++) {
      result = _field.add(_field.multiply(a, result), _coefficients[i]);
    }
    return result;
  }

  ModulusPoly add(ModulusPoly other) {
    if (_field != other._field) {
      throw Exception("ModulusPolys do not have same ModulusGF field");
    }
    if (isZero()) {
      return other;
    }
    if (other.isZero()) {
      return this;
    }

    List<int> smallerCoefficients = this._coefficients;
    List<int> largerCoefficients = other._coefficients;
    if (smallerCoefficients.length > largerCoefficients.length) {
      List<int> temp = smallerCoefficients;
      smallerCoefficients = largerCoefficients;
      largerCoefficients = temp;
    }
    List<int> sumDiff = List.filled(largerCoefficients.length, 0);
    int lengthDiff = largerCoefficients.length - smallerCoefficients.length;
    // Copy high-order terms only found in higher-degree polynomial's coefficients
    List.copyRange(sumDiff, 0, largerCoefficients, 0, lengthDiff);

    for (int i = lengthDiff; i < largerCoefficients.length; i++) {
      sumDiff[i] =
          _field.add(smallerCoefficients[i - lengthDiff], largerCoefficients[i]);
    }

    return ModulusPoly(_field, sumDiff);
  }

  ModulusPoly subtract(ModulusPoly other) {
    if (_field != other._field) {
      throw Exception("ModulusPolys do not have same ModulusGF field");
    }
    if (other.isZero()) {
      return this;
    }
    return add(other.negative());
  }

  ModulusPoly multiplyPoly(ModulusPoly other) {
    if (_field != other._field) {
      throw Exception("ModulusPolys do not have same ModulusGF field");
    }
    if (isZero() || other.isZero()) {
      return _field.getZero();
    }
    List<int> aCoefficients = this._coefficients;
    int aLength = aCoefficients.length;
    List<int> bCoefficients = other._coefficients;
    int bLength = bCoefficients.length;
    List<int> product = List.filled(aLength + bLength - 1, 0);
    for (int i = 0; i < aLength; i++) {
      int aCoeff = aCoefficients[i];
      for (int j = 0; j < bLength; j++) {
        product[i + j] =
            _field.add(product[i + j], _field.multiply(aCoeff, bCoefficients[j]));
      }
    }
    return ModulusPoly(_field, product);
  }

  ModulusPoly negative() {
    int size = _coefficients.length;
    List<int> negativeCoefficients = [];
    for (int i = 0; i < size; i++) {
      negativeCoefficients.add(_field.subtract(0, _coefficients[i]));
    }
    return ModulusPoly(_field, negativeCoefficients);
  }

  ModulusPoly multiply(int scalar) {
    if (scalar == 0) {
      return _field.getZero();
    }
    if (scalar == 1) {
      return this;
    }
    int size = _coefficients.length;
    List<int> product = []; // size
    for (int i = 0; i < size; i++) {
      product.add(_field.multiply(_coefficients[i], scalar));
    }
    return ModulusPoly(_field, product);
  }

  ModulusPoly multiplyByMonomial(int degree, int coefficient) {
    if (degree < 0) {
      throw Exception();
    }
    if (coefficient == 0) {
      return _field.getZero();
    }
    int size = _coefficients.length;
    List<int> product = List.filled(size + degree, 0);
    for (int i = 0; i < size; i++) {
      product[i] = _field.multiply(_coefficients[i], coefficient);
    }
    return ModulusPoly(_field, product);
  }

  @override
  String toString() {
    StringBuffer result = StringBuffer();
    for (int degree = getDegree(); degree >= 0; degree--) {
      int coefficient = getCoefficient(degree);
      if (coefficient != 0) {
        if (coefficient < 0) {
          result.write(" - ");
          coefficient = -coefficient;
        } else {
          if (result.length > 0) {
            result.write(" + ");
          }
        }
        if (degree == 0 || coefficient != 1) {
          result.write(coefficient);
        }
        if (degree != 0) {
          if (degree == 1) {
            result.write('x');
          } else {
            result.write("x^");
            result.write(degree);
          }
        }
      }
    }
    return result.toString();
  }
}
