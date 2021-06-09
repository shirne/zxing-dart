
class StringBuilder extends StringBuffer {
  String? _buffer;

  StringBuilder([String content = '']) : super(content);

  _initBuffer([force = false]) {
    if (_buffer == null || force) {
      _buffer = super.toString();
    }
  }

  String operator [](int idx){
    return charAt(idx);
  }

  operator []=(int idx, String char){
    setCharAt(idx, char);
  }

  String charAt(int idx) {
    _initBuffer();
    return _buffer![idx];
  }

  void setCharAt(int index, dynamic char) {
    replace(index, index+1, char);
  }

  int codePointAt(int index){
    _initBuffer();
    return _buffer!.codeUnitAt(index);
  }

  void replace(int start, int end, dynamic obj) {
    _initBuffer();
    super.clear();
    if(start > 0)super.write(_buffer!.substring(0, start));
    _writeAuto(obj);
    if (end < _buffer!.length - 1)
      super.write(_buffer!.substring(end));
    _buffer = null;
  }

  String substring(int start, [int? end]) {
    _initBuffer();
    return _buffer!.substring(start, end);
  }

  reverse() {
    _initBuffer();
    super.clear();
    super.writeAll(_buffer!.split('').reversed);
    _buffer = null;
  }

  insert(int offset, Object? obj) {
    _initBuffer();
    super.clear();
    if(offset > 0)super.write(_buffer!.substring(0, offset));
    _writeAuto(obj);
    if (offset < _buffer!.length - 1)
      super.write(_buffer!.substring(offset));
    _buffer = null;
  }

  _writeAuto(Object? obj){
    if(obj is int) {
      super.writeCharCode(obj);
    }else if(obj is List){
      if(obj.isNotEmpty){
        if(obj[0] is int){
          obj.forEach((element) {
            super.writeCharCode(element);
          });
        }else{
          super.writeAll(obj);
        }
      }
    }else if(obj != null) {
      super.write(obj);
    }
  }

  delete(int start, int end) {
    _initBuffer();
    super.clear();
    if(start > 0)super.write(_buffer!.substring(0, start));
    if (end < _buffer!.length - 1) super.write(_buffer!.substring(end));
    _buffer = null;
  }

  deleteCharAt(int idx) {
    delete(idx, idx + 1);
  }

  setLength(int length){
    delete(length, this.length);
  }

  void write(Object? object) {
    _buffer = null;
    super.write(object);
  }

  /// Adds the string representation of [charCode] to the buffer.
  ///
  /// Equivalent to `write(String.fromCharCode(charCode))`.
  void writeCharCode(int charCode) {
    _buffer = null;
    super.writeCharCode(charCode);
  }

  /// Writes all [objects] separated by [separator].
  ///
  /// Writes each individual object in [objects] in iteration order,
  /// and writes [separator] between any two objects.
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    _buffer = null;
    super.writeAll(objects, separator);
  }

  void writeln([Object? obj = ""]) {
    _buffer = null;
    super.writeln(obj);
  }

  /// Clears the string buffer.
  void clear() {
    _buffer = null;
    super.clear();
  }
}
