import 'dart:convert';

import '../formats_exception.dart';
import 'character_set_eci.dart';
import 'string_builder.dart';

class ECIStringBuilder {
  late StringBuffer _currentBytes;
  late StringBuffer? _result;
  Encoding _currentCharset = latin1;

  ECIStringBuilder() {
    _currentBytes = StringBuffer();
  }

  void write(dynamic value) {
    if (value is StringBuffer || value is StringBuilder) {
      _encodeCurrentBytesIfAny();
      _currentBytes.write(value.toString());
    } else {
      _currentBytes.write(value);
    }
  }

  void writeCharCode(int value) {
    _currentBytes.writeCharCode(value);
  }

  /// Appends ECI value to output.
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
    if (_currentCharset.name == latin1.name) {
      if (_currentBytes.isNotEmpty) {
        if (_result == null) {
          _result = _currentBytes;
          _currentBytes = StringBuffer();
        } else {
          _result!.write(_currentBytes);
          _currentBytes = StringBuffer();
        }
      }
    } else if (_currentBytes.isNotEmpty) {
      List<int> bytes = latin1.encode(_currentBytes.toString());
      _currentBytes = StringBuffer();
      if (_result == null) {
        _result = StringBuffer(latin1.decode(bytes));
      } else {
        _result!.write(latin1.decode(bytes));
      }
    }
  }

  /// returns the length of toString()
  int get length => toString().length;

  bool get isEmpty =>
      _currentBytes.isEmpty && (_result == null || _result!.isEmpty);

  @override
  String toString() {
    _encodeCurrentBytesIfAny();
    return _result == null ? "" : _result.toString();
  }
}
