import 'dart:convert';
import 'dart:typed_data';

import '../formats_exception.dart';
import 'character_set_eci.dart';

class ECIStringBuilder {
  late StringBuffer _currentBytes;
  late StringBuffer _currentChars;
  Encoding _currentCharset = latin1;
  String? _result;
  bool _hadECI = false;

  ECIStringBuilder() {
    _currentBytes = StringBuffer();
  }

  void write(dynamic value) {
    if (value is String) {
      _currentBytes.write(value);
    } else if (value is int) {
      _currentBytes.writeCharCode(value);
    } else if (value is StringBuffer) {
      _encodeCurrentBytesIfAny();
      _currentBytes.write(value.toString());
    }
  }

  void writeCharCode(int value) {
    _currentBytes.writeCharCode(value);
  }

  void appendECI(int value) {
    _encodeCurrentBytesIfAny();
    CharacterSetECI? characterSetECI =
        CharacterSetECI.getCharacterSetECIByValue(value);
    if (characterSetECI == null) {
      throw FormatsException("Unsupported ECI value $value");
    }
    _currentCharset = characterSetECI.charset!;
  }

  void _encodeCurrentBytesIfAny() {
    if (!_hadECI) {
      _currentChars = _currentBytes;
      _currentBytes = StringBuffer();
      _hadECI = true;
    } else if (_currentBytes.length > 0) {
      Uint8List bytes = Uint8List(_currentBytes.length);
      String currentString = _currentBytes.toString();
      _currentBytes.clear();
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = (currentString.codeUnitAt(i) & 0xff);
      }
      _currentChars.write(_currentCharset.decode(bytes));
    }
  }

  /// returns the length of toString()
  int get length {
    return toString().length;
  }

  @override
  String toString() {
    _encodeCurrentBytesIfAny();
    _result = _result == null
        ? _currentChars.toString()
        : _result! + _currentChars.toString();
    _currentChars.clear();
    return _result!;
  }
}
