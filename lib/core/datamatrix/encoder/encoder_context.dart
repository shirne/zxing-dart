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
  late String _msg;
  SymbolShapeHint? _shape;
  Dimension? _minSize;
  Dimension? _maxSize;
  late StringBuffer _codewords;
  late int _newEncoding;
  SymbolInfo? _symbolInfo;
  late int _skipAtEnd = 0;

  late int pos = 0;

  EncoderContext(String msg) {
    //From this point on Strings are not Unicode anymore!
    Uint8List msgBinary = latin1.encode(msg);
    StringBuffer sb = StringBuffer();
    for (int i = 0, c = msgBinary.length; i < c; i++) {
      int ch = msgBinary[i] & 0xff;
      if (ch == 63/*'?'*/ && msg[i] != '?') {
        throw Exception(
            "Message contains characters outside ISO-8859-1 encoding.");
      }
      sb.writeCharCode(ch);
    }
    this._msg = sb.toString(); //Not Unicode here!
    _shape = SymbolShapeHint.FORCE_NONE;
    this._codewords = StringBuffer();
    _newEncoding = -1;
  }

  void setSymbolShape(SymbolShapeHint shape) {
    this._shape = shape;
  }

  void setSizeConstraints(Dimension? minSize, Dimension? maxSize) {
    this._minSize = minSize;
    this._maxSize = maxSize;
  }

  String getMessage() {
    return this._msg;
  }

  void setSkipAtEnd(int count) {
    this._skipAtEnd = count;
  }

  int getCurrentChar() {
    return _msg.codeUnitAt(pos);
  }

  String getCurrent() {
    return _msg[pos];
  }

  StringBuffer getCodewords() {
    return _codewords;
  }

  void writeCodewords(String codewords) {
    this._codewords.write(codewords);
  }

  void writeCodeword(dynamic codeword) {
    if(codeword is int){
      this._codewords.writeCharCode(codeword);
    }else{
      this._codewords.write(codeword);
    }
  }

  int getCodewordCount() {
    return this._codewords.length;
  }

  int getNewEncoding() {
    return _newEncoding;
  }

  void signalEncoderChange(int encoding) {
    this._newEncoding = encoding;
  }

  void resetEncoderSignal() {
    this._newEncoding = -1;
  }

  bool hasMoreCharacters() {
    return pos < _getTotalMessageCharCount();
  }

  int _getTotalMessageCharCount() {
    return _msg.length - _skipAtEnd;
  }

  int getRemainingCharacters() {
    return _getTotalMessageCharCount() - pos;
  }

  SymbolInfo? getSymbolInfo() {
    return _symbolInfo;
  }

  void updateSymbolInfo([int? len]) {
    if (len == null) len = getCodewordCount();
    if (this._symbolInfo == null || len > this._symbolInfo!.getDataCapacity()) {
      this._symbolInfo = SymbolInfo.lookup(len, _shape, _minSize, _maxSize, true);
    }
  }

  void resetSymbolInfo() {
    this._symbolInfo = null;
  }
}
