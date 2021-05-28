/*
 * Copyright 2006-2007 Jeremias Maerki.
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

import 'dart:convert';
import 'dart:typed_data';

import '../../dimension.dart';
import 'symbol_info.dart';
import 'symbol_shape_hint.dart';

class EncoderContext {
  late String msg;
  SymbolShapeHint? shape;
  Dimension? minSize;
  Dimension? maxSize;
  late StringBuffer codewords;
  late int pos;
  late int newEncoding;
  SymbolInfo? symbolInfo;
  late int skipAtEnd;

  EncoderContext(String msg) {
    //From this point on Strings are not Unicode anymore!
    Uint8List msgBinary = latin1.encode(msg);
    StringBuffer sb = StringBuffer();
    for (int i = 0, c = msgBinary.length; i < c; i++) {
      String ch = String.fromCharCode(msgBinary[i] & 0xff);
      if (ch == '?' && msg[i] != '?') {
        throw Exception(
            "Message contains characters outside ISO-8859-1 encoding.");
      }
      sb.write(ch);
    }
    this.msg = sb.toString(); //Not Unicode here!
    shape = SymbolShapeHint.FORCE_NONE;
    this.codewords = StringBuffer();
    newEncoding = -1;
  }

  void setSymbolShape(SymbolShapeHint shape) {
    this.shape = shape;
  }

  void setSizeConstraints(Dimension? minSize, Dimension? maxSize) {
    this.minSize = minSize;
    this.maxSize = maxSize;
  }

  String getMessage() {
    return this.msg;
  }

  void setSkipAtEnd(int count) {
    this.skipAtEnd = count;
  }

  String getCurrentChar() {
    return msg[pos];
  }

  String getCurrent() {
    return msg[pos];
  }

  StringBuffer getCodewords() {
    return codewords;
  }

  void writeCodewords(String codewords) {
    this.codewords.write(codewords);
  }

  void writeCodeword(dynamic codeword) {
    this.codewords.write(
        codeword is int ? String.fromCharCode(codeword) : codeword.toString());
  }

  int getCodewordCount() {
    return this.codewords.length;
  }

  int getNewEncoding() {
    return newEncoding;
  }

  void signalEncoderChange(int encoding) {
    this.newEncoding = encoding;
  }

  void resetEncoderSignal() {
    this.newEncoding = -1;
  }

  bool hasMoreCharacters() {
    return pos < getTotalMessageCharCount();
  }

  int getTotalMessageCharCount() {
    return msg.length - skipAtEnd;
  }

  int getRemainingCharacters() {
    return getTotalMessageCharCount() - pos;
  }

  SymbolInfo? getSymbolInfo() {
    return symbolInfo;
  }

  void updateSymbolInfo([int? len]) {
    if (len == null) len = getCodewordCount();
    if (this.symbolInfo == null || len > this.symbolInfo!.getDataCapacity()) {
      this.symbolInfo = SymbolInfo.lookupDm(len, shape, minSize, maxSize, true);
    }
  }

  void resetSymbolInfo() {
    this.symbolInfo = null;
  }
}
