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
  int _segmentIndex = 0;
  String? _fileId = '';
  bool _lastSegment = false;
  int _segmentCount = -1;
  String _sender = '';
  String _addressee = '';
  String _fileName = '';
  int _fileSize = -1;
  int _timestamp = -1;
  int _checksum = -1;
  List<int>? _optionalData;

  /**
   * The Segment ID represents the segment of the whole file distributed over different symbols.
   *
   * @return File segment index
   */
  int getSegmentIndex() {
    return _segmentIndex;
  }

  void setSegmentIndex(int segmentIndex) {
    this._segmentIndex = segmentIndex;
  }

  /**
   * Is the same for each related PDF417 symbol
   *
   * @return File ID
   */
  String? getFileId() {
    return _fileId;
  }

  void setFileId(String fileId) {
    this._fileId = fileId;
  }

  /**
   * @return always null
   * @deprecated use dedicated already parsed fields
   */
  @deprecated
  List<int>? getOptionalData() {
    return _optionalData;
  }

  /**
   * @param optionalData old optional data format as int array
   * @deprecated parse and use new fields
   */
  @deprecated
  void setOptionalData(List<int> optionalData) {
    this._optionalData = optionalData;
  }

  /**
   * @return true if it is the last segment
   */
  bool isLastSegment() {
    return _lastSegment;
  }

  void setLastSegment(bool lastSegment) {
    this._lastSegment = lastSegment;
  }

  /**
   * @return count of segments, -1 if not set
   */
  int getSegmentCount() {
    return _segmentCount;
  }

  void setSegmentCount(int segmentCount) {
    this._segmentCount = segmentCount;
  }

  String getSender() {
    return _sender;
  }

  void setSender(String sender) {
    this._sender = sender;
  }

  String getAddressee() {
    return _addressee;
  }

  void setAddressee(String addressee) {
    this._addressee = addressee;
  }

  /**
   * Filename of the encoded file
   *
   * @return filename
   */
  String getFileName() {
    return _fileName;
  }

  void setFileName(String fileName) {
    this._fileName = fileName;
  }

  /**
   * filesize in bytes of the encoded file
   *
   * @return filesize in bytes, -1 if not set
   */
  int getFileSize() {
    return _fileSize;
  }

  void setFileSize(int fileSize) {
    this._fileSize = fileSize;
  }

  /**
   * 16-bit CRC checksum using CCITT-16
   *
   * @return crc checksum, -1 if not set
   */
  int getChecksum() {
    return _checksum;
  }

  void setChecksum(int checksum) {
    this._checksum = checksum;
  }

  /**
   * unix epock timestamp, elapsed seconds since 1970-01-01
   *
   * @return elapsed seconds, -1 if not set
   */
  int getTimestamp() {
    return _timestamp;
  }

  void setTimestamp(int timestamp) {
    this._timestamp = timestamp;
  }
}
