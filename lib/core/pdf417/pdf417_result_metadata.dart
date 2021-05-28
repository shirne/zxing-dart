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

/**
 * @author Guenther Grau
 */
class PDF417ResultMetadata {
  int segmentIndex = 0;
  String fileId = '';
  bool lastSegment = false;
  int segmentCount = -1;
  String sender = '';
  String addressee = '';
  String fileName = '';
  int fileSize = -1;
  int timestamp = -1;
  int checksum = -1;
  List<int>? optionalData;

  /**
   * The Segment ID represents the segment of the whole file distributed over different symbols.
   *
   * @return File segment index
   */
  int getSegmentIndex() {
    return segmentIndex;
  }

  void setSegmentIndex(int segmentIndex) {
    this.segmentIndex = segmentIndex;
  }

  /**
   * Is the same for each related PDF417 symbol
   *
   * @return File ID
   */
  String getFileId() {
    return fileId;
  }

  void setFileId(String fileId) {
    this.fileId = fileId;
  }

  /**
   * @return always null
   * @deprecated use dedicated already parsed fields
   */
  @deprecated
  List<int>? getOptionalData() {
    return optionalData;
  }

  /**
   * @param optionalData old optional data format as int array
   * @deprecated parse and use new fields
   */
  @deprecated
  void setOptionalData(List<int> optionalData) {
    this.optionalData = optionalData;
  }

  /**
   * @return true if it is the last segment
   */
  bool isLastSegment() {
    return lastSegment;
  }

  void setLastSegment(bool lastSegment) {
    this.lastSegment = lastSegment;
  }

  /**
   * @return count of segments, -1 if not set
   */
  int getSegmentCount() {
    return segmentCount;
  }

  void setSegmentCount(int segmentCount) {
    this.segmentCount = segmentCount;
  }

  String getSender() {
    return sender;
  }

  void setSender(String sender) {
    this.sender = sender;
  }

  String getAddressee() {
    return addressee;
  }

  void setAddressee(String addressee) {
    this.addressee = addressee;
  }

  /**
   * Filename of the encoded file
   *
   * @return filename
   */
  String getFileName() {
    return fileName;
  }

  void setFileName(String fileName) {
    this.fileName = fileName;
  }

  /**
   * filesize in bytes of the encoded file
   *
   * @return filesize in bytes, -1 if not set
   */
  int getFileSize() {
    return fileSize;
  }

  void setFileSize(int fileSize) {
    this.fileSize = fileSize;
  }

  /**
   * 16-bit CRC checksum using CCITT-16
   *
   * @return crc checksum, -1 if not set
   */
  int getChecksum() {
    return checksum;
  }

  void setChecksum(int checksum) {
    this.checksum = checksum;
  }

  /**
   * unix epock timestamp, elapsed seconds since 1970-01-01
   *
   * @return elapsed seconds, -1 if not set
   */
  int getTimestamp() {
    return timestamp;
  }

  void setTimestamp(int timestamp) {
    this.timestamp = timestamp;
  }
}
