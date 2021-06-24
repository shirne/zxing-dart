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

/// See ISO 18004:2006, 6.5.1. This enum encapsulates the four error correction levels
/// defined by the QR code standard.
///
/// @author Sean Owen
enum ErrorCorrectionLevel {
  /// M = ~15% correction
  M, //(0x00),
  /// L = ~7% correction
  L, //(0x01),
  /// H = ~30% correction
  H, //(0x02),
  /// Q = ~25% correction
  Q, //(0x03),
}

int ecOrdinal(ErrorCorrectionLevel ecLevel) {
  switch (ecLevel) {
    case ErrorCorrectionLevel.L:
      return 0;
    case ErrorCorrectionLevel.M:
      return 1;
    case ErrorCorrectionLevel.Q:
      return 2;
    case ErrorCorrectionLevel.H:
      return 3;
    default:
      return 0;
  }
}
