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

import 'generic_gfpoly.dart';

/**
 * <p>This class contains utility methods for performing mathematical operations over
 * the Galois Fields. Operations use a given primitive polynomial in calculations.</p>
 *
 * <p>Throughout this package, elements of the GF are represented as an {@code int}
 * for convenience and speed (but at the cost of memory).
 * </p>
 *
 * @author Sean Owen
 * @author David Olivier
 */
class GenericGF {
  static final GenericGF AZTEC_DATA_12 =
      new GenericGF(0x1069, 4096, 1); // x^12 + x^6 + x^5 + x^3 + 1
  static final GenericGF AZTEC_DATA_10 =
      new GenericGF(0x409, 1024, 1); // x^10 + x^3 + 1
  static final GenericGF AZTEC_DATA_6 =
      new GenericGF(0x43, 64, 1); // x^6 + x + 1
  static final GenericGF AZTEC_PARAM =
      new GenericGF(0x13, 16, 1); // x^4 + x + 1
  static final GenericGF QR_CODE_FIELD_256 =
      new GenericGF(0x011D, 256, 0); // x^8 + x^4 + x^3 + x^2 + 1
  static final GenericGF DATA_MATRIX_FIELD_256 =
      new GenericGF(0x012D, 256, 1); // x^8 + x^5 + x^3 + x^2 + 1
  static final GenericGF AZTEC_DATA_8 = DATA_MATRIX_FIELD_256;
  static final GenericGF MAXICODE_FIELD_64 = AZTEC_DATA_6;

  late List<int> expTable;
  late List<int> logTable;
  late GenericGFPoly zero;
  late GenericGFPoly one;
  final int size;
  final int primitive;
  final int generatorBase;

  /**
   * Create a representation of GF(size) using the given primitive polynomial.
   *
   * @param primitive irreducible polynomial whose coefficients are represented by
   *  the bits of an int, where the least-significant bit represents the constant
   *  coefficient
   * @param size the size of the field
   * @param b the factor b in the generator polynomial can be 0- or 1-based
   *  (g(x) = (x+a^b)(x+a^(b+1))...(x+a^(b+2t-1))).
   *  In most cases it should be 1, but for QR code it is 0.
   */
  GenericGF(this.primitive, this.size, this.generatorBase) {
    expTable = List.generate(size, (index) => 0);
    logTable = List.generate(size, (index) => 0);
    int x = 1;
    for (int i = 0; i < size; i++) {
      expTable[i] = x;
      x *= 2; // we're assuming the generator alpha is 2
      if (x >= size) {
        x ^= primitive;
        x &= size - 1;
      }
    }
    for (int i = 0; i < size - 1; i++) {
      logTable[expTable[i]] = i;
    }
    // logTable[0] == 0 but this should never be used
    zero = new GenericGFPoly(this, [0]);
    one = new GenericGFPoly(this, [1]);
  }

  GenericGFPoly getZero() {
    return zero;
  }

  GenericGFPoly getOne() {
    return one;
  }

  /**
   * @return the monomial representing coefficient * x^degree
   */
  GenericGFPoly buildMonomial(int degree, int coefficient) {
    if (degree < 0) {
      throw Exception('IllegalArgument');
    }
    if (coefficient == 0) {
      return zero;
    }
    List<int> coefficients = List.generate(degree + 1, (index) => 0);
    coefficients[0] = coefficient;
    return new GenericGFPoly(this, coefficients);
  }

  /**
   * Implements both addition and subtraction -- they are the same in GF(size).
   *
   * @return sum/difference of a and b
   */
  static int addOrSubtract(int a, int b) {
    return a ^ b;
  }

  /**
   * @return 2 to the power of a in GF(size)
   */
  int exp(int a) {
    return expTable[a];
  }

  /**
   * @return base 2 log of a in GF(size)
   */
  int log(int a) {
    if (a == 0) {
      throw Exception('IllegalArgument');
    }
    return logTable[a];
  }

  /**
   * @return multiplicative inverse of a
   */
  int inverse(int a) {
    if (a == 0) {
      throw Exception('Arithmetic');
    }
    return expTable[size - logTable[a] - 1];
  }

  /**
   * @return product of a and b in GF(size)
   */
  int multiply(int a, int b) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return expTable[(logTable[a] + logTable[b]) % (size - 1)];
  }

  int getSize() {
    return size;
  }

  int getGeneratorBase() {
    return generatorBase;
  }

  @override
  String toString() {
    return "GF(0x${primitive.toRadixString(16)},$size)";
  }
}
