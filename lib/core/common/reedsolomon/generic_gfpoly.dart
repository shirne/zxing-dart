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

import 'generic_gf.dart';

/**
 * <p>Represents a polynomial whose coefficients are elements of a GF.
 * Instances of this class are immutable.</p>
 *
 * <p>Much credit is due to William Rucklidge since portions of this code are an indirect
 * port of his C++ Reed-Solomon implementation.</p>
 *
 * @author Sean Owen
 */
class GenericGFPoly {
  final GenericGF field;
  late List<int> coefficients;

  /**
   * @param field the {@link GenericGF} instance representing the field to use
   * to perform computations
   * @param coefficients coefficients as ints representing elements of GF(size), arranged
   * from most significant (highest-power term) coefficient to least significant
   * @throws IllegalArgumentException if argument is null or empty,
   * or if leading coefficient is 0 and this is not a
   * constant polynomial (that is, it is not the monomial "0")
   */
  GenericGFPoly(this.field, List<int> coefficients):
        assert(coefficients.length > 0,'IllegalArgument'),
      this.coefficients = coefficients.skipWhile((value) => value == 0).toList()
  {
    if(this.coefficients.length < 1){
      this.coefficients.add(0);
    }
  }

  List<int> getCoefficients() {
    return coefficients;
  }

  /**
   * @return degree of this polynomial
   */
  int getDegree() {
    return coefficients.length - 1;
  }

  /**
   * @return true iff this polynomial is the monomial "0"
   */
  bool isZero() {
    return coefficients[0] == 0;
  }

  /**
   * @return coefficient of x^degree term in this polynomial
   */
  int getCoefficient(int degree) {
    return coefficients[coefficients.length - 1 - degree];
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
      for (int coefficient in coefficients) {
        result = GenericGF.addOrSubtract(result, coefficient);
      }
      return result;
    }
    int result = coefficients[0];
    int size = coefficients.length;
    for (int i = 1; i < size; i++) {
      result =
          GenericGF.addOrSubtract(field.multiply(a, result), coefficients[i]);
    }
    return result;
  }

  GenericGFPoly addOrSubtract(GenericGFPoly other) {
    if (field != other.field) {
      throw Exception("GenericGFPolys do not have same GenericGF field");
    }
    if (isZero()) {
      return other;
    }
    if (other.isZero()) {
      return this;
    }

    List<int> smallerCoefficients = this.coefficients;
    List<int> largerCoefficients = other.coefficients;
    if (smallerCoefficients.length > largerCoefficients.length) {
      List<int> temp = smallerCoefficients;
      smallerCoefficients = largerCoefficients;
      largerCoefficients = temp;
    }
    List<int> sumDiff = List.generate(largerCoefficients.length, (index) => 0);
    int lengthDiff = largerCoefficients.length - smallerCoefficients.length;
    // Copy high-order terms only found in higher-degree polynomial's coefficients
    List.copyRange(sumDiff, 0, largerCoefficients, 0, lengthDiff);

    for (int i = lengthDiff; i < largerCoefficients.length; i++) {
      sumDiff[i] = GenericGF.addOrSubtract(
          smallerCoefficients[i - lengthDiff], largerCoefficients[i]);
    }

    return GenericGFPoly(field, sumDiff);
  }

  GenericGFPoly multiply(GenericGFPoly other) {
    if (field != other.field) {
      throw Exception("GenericGFPolys do not have same GenericGF field");
    }
    if (isZero() || other.isZero()) {
      return field.getZero();
    }
    List<int> aCoefficients = this.coefficients;
    int aLength = aCoefficients.length;
    List<int> bCoefficients = other.coefficients;
    int bLength = bCoefficients.length;
    List<int> product = List.generate(aLength + bLength - 1, (index) => 0);
    for (int i = 0; i < aLength; i++) {
      int aCoeff = aCoefficients[i];
      for (int j = 0; j < bLength; j++) {
        product[i + j] = GenericGF.addOrSubtract(
            product[i + j], field.multiply(aCoeff, bCoefficients[j]));
      }
    }
    return GenericGFPoly(field, product);
  }

  GenericGFPoly multiplyInt(int scalar) {
    if (scalar == 0) {
      return field.getZero();
    }
    if (scalar == 1) {
      return this;
    }
    int size = coefficients.length;
    List<int> product = List.generate(size, (index) => 0);
    for (int i = 0; i < size; i++) {
      product[i] = field.multiply(coefficients[i], scalar);
    }
    return GenericGFPoly(field, product);
  }

  GenericGFPoly multiplyByMonomial(int degree, int coefficient) {
    if (degree < 0) {
      throw Exception('IllegalArgument');
    }
    if (coefficient == 0) {
      return field.getZero();
    }
    int size = coefficients.length;
    List<int> product = List.generate(size + degree, (index) => 0);
    for (int i = 0; i < size; i++) {
      product[i] = field.multiply(coefficients[i], coefficient);
    }
    return GenericGFPoly(field, product);
  }

  List<GenericGFPoly> divide(GenericGFPoly other) {
    if (field != other.field) {
      throw Exception("GenericGFPolys do not have same GenericGF field");
    }
    if (other.isZero()) {
      throw Exception("Divide by 0");
    }

    GenericGFPoly quotient = field.getZero();
    GenericGFPoly remainder = this;

    int denominatorLeadingTerm = other.getCoefficient(other.getDegree());
    int inverseDenominatorLeadingTerm = field.inverse(denominatorLeadingTerm);

    while (remainder.getDegree() >= other.getDegree() && !remainder.isZero()) {
      int degreeDifference = remainder.getDegree() - other.getDegree();
      int scale = field.multiply(
          remainder.getCoefficient(remainder.getDegree()),
          inverseDenominatorLeadingTerm);
      GenericGFPoly term = other.multiplyByMonomial(degreeDifference, scale);
      GenericGFPoly iterationQuotient =
          field.buildMonomial(degreeDifference, scale);
      quotient = quotient.addOrSubtract(iterationQuotient);
      remainder = remainder.addOrSubtract(term);
    }

    return [quotient, remainder];
  }

  @override
  String toString() {
    if (isZero()) {
      return "0";
    }
    StringBuffer result = StringBuffer();
    for (int degree = getDegree(); degree >= 0; degree--) {
      int coefficient = getCoefficient(degree);
      if (coefficient != 0) {
        if (coefficient < 0) {
          if (degree == getDegree()) {
            result.write("-");
          } else {
            result.write(" - ");
          }
          coefficient = -coefficient;
        } else {
          if (result.length > 0) {
            result.write(" + ");
          }
        }
        if (degree == 0 || coefficient != 1) {
          int alphaPower = field.log(coefficient);
          if (alphaPower == 0) {
            result.write('1');
          } else if (alphaPower == 1) {
            result.write('a');
          } else {
            result.write("a^");
            result.write(alphaPower);
          }
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
