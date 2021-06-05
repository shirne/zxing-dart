
import 'dart:convert';
import 'euc_kr_table.dart';

const eucKr = EucKR(true);

class EucKR extends Encoding{
  final bool _allowInvalid;

  const EucKR([this._allowInvalid = false]):super();

  String get name => "euc-kr";

  EucKREncoder get encoder => const EucKREncoder();

  EucKRDecoder get decoder => _allowInvalid
      ? const EucKRDecoder(true)
      : const EucKRDecoder();
}


class EucKREncoder extends Converter<String, List<int>>{

  const EucKREncoder();

  @override
  List<int> convert(String input) {
    List<int> bits = [];
    input.codeUnits.forEach((i) {
      if(i < 0x80){
        bits.add(i);
      }else {
        int code = utf8ToEucKr[i] ?? 0;
        if(code > 0){
          // bits.add(code ~/ 190 + 0x81);
          // bits.add(code % 190 + 0x41);
          bits.add(code >> 8);
          bits.add(code & 0xff);
        }
      }
    });
    return bits;
  }
}

class EucKRDecoder extends Converter<List<int>, String>{
  final bool _allowInvalid;
  const EucKRDecoder([this._allowInvalid = false]);

  @override
  String convert(List<int> input) {
    int leadPointer = 0;
    StringBuffer sb = StringBuffer();
    for(int i=0;i<input.length;i++){
      int pointer = input[i];
      if(leadPointer != 0){
        if(pointer >= 0x41 && pointer <= 0xfe){
          // int code = (leadPointer - 0x81) * 190 + (pointer - 0x41);
          int code = leadPointer << 8 + pointer;

          sb.writeCharCode(code < 0x80 ? code : (eucKrToUtf8[code] ?? 0));
        }
        leadPointer = 0;
      }else if(pointer < 0x80){
        sb.writeCharCode(pointer);
      }else if(pointer >= 0x81 && pointer <= 0xfe){
        leadPointer = pointer;
      }else{
        if(!_allowInvalid)throw Exception('');
      }
    }
    if(leadPointer != 0){
      if(!_allowInvalid)throw Exception('');
    }
    return sb.toString();
  }

}