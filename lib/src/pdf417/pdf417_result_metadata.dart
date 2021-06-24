/*
 * Copyright 2013 ZXing authors
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

/// @author Guenther Grau
class PDF417ResultMetadata {

  /// The File segment index represents the segment of the whole file distributed over different symbols.
  int segmentIndex = 0;

  /// Is the same for each related PDF417 symbol
  String? fileId;

  /// Whether if it is the last segment
  bool isLastSegment = false;

  /// count of segments, -1 if not set
  int segmentCount = -1;

  String? sender;

  String? addressee;

  /// Filename of the encoded file
  String? fileName;

  /// fileSize in bytes of the encoded file
  int fileSize = -1;

  /// unix epock timestamp, elapsed seconds since 1970-01-01
  int timestamp = -1;

  /// 16-bit CRC checksum using CCITT-16
  int checksum = -1;

  /// optionalData old optional data format as int array
  @Deprecated('use dedicated already parsed fields')
  List<int>? optionalData;


}
