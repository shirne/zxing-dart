import 'package:zxing_lib/client.dart';

abstract class ResultGenerator<T extends ParsedResult> {
  static const text = TextResultGenerator();
  static const wifi = WifiResultGenerator();
  static const geo = GeoResultGenerator();
  static const vcard = VCardResultGenerator();
  static const sms = SMSResultGenerator();

  static const values = <ResultGenerator>[text, wifi, geo, vcard, sms];

  final String name;
  final String type;

  const ResultGenerator(this.name, this.type);

  String generator(T data);

  @override
  String toString() {
    return name;
  }
}

class TextResultGenerator extends ResultGenerator<TextParsedResult> {
  const TextResultGenerator() : super('文本', 'text');

  @override
  String generator(TextParsedResult data) {
    return data.text;
  }
}

class WifiResultGenerator extends ResultGenerator<WifiParsedResult> {
  const WifiResultGenerator() : super('WIFI', 'wifi');

  @override
  String generator(WifiParsedResult data) {
    return "WIFI:S:${data.ssid};P:${data.password};T:${data.networkEncryption};;";
  }
}

class GeoResultGenerator extends ResultGenerator<GeoParsedResult> {
  const GeoResultGenerator() : super('位置', 'geo');

  @override
  String generator(GeoParsedResult data) {
    String geo = "GEO:${data.latitude},${data.longitude}";
    if (data.altitude > 0) {
      geo += ",${data.altitude}";
    }
    if (data.query != null && data.query!.isNotEmpty) {
      geo += "?q=${data.query}";
    }
    return geo;
  }
}

class VCardResultGenerator extends ResultGenerator<AddressBookParsedResult> {
  const VCardResultGenerator() : super('名片', 'vcard');

  @override
  String generator(AddressBookParsedResult data) {
    StringBuffer buffer = StringBuffer("BEGIN:VCARD\r\n");
    List<String>? cField = data.names;
    if (cField != null && cField.isNotEmpty) {
      for (String name in cField) {
        buffer.write("FN:$name\r\n");
      }
    }
    if (data.org != null && data.org!.isNotEmpty) {
      buffer.write("ORG:${data.org}\r\n");
    }
    if (data.title != null && data.title!.isNotEmpty) {
      buffer.write("TITLE:${data.title}\r\n");
    }

    cField = data.phoneNumbers;
    if (cField != null && cField.isNotEmpty) {
      for (int i = 0; i < cField.length; i++) {
        if (data.phoneTypes?[i] == null) {
          buffer.write("TEL;:${cField[i]}\r\n");
        } else {
          buffer.write("TEL;${data.phoneTypes![i]}:${cField[i]}\r\n");
        }
      }
    }
    cField = data.addresses;
    if (cField != null && cField.isNotEmpty) {
      for (int i = 0; i < cField.length; i++) {
        if (data.addressTypes?[i] == null) {
          buffer.write("ADR;:;;${cField[i]}\r\n");
        } else {
          buffer.write("ADR;${data.addressTypes![i]}:;;${cField[i]}\r\n");
        }
      }
    }
    if (data.note != null && data.note!.isNotEmpty) {
      buffer.write("NOTE;:${data.note}\r\n");
    }
    buffer.write("END:VCARD");
    return buffer.toString();
  }

  void _writeN(String name, StringBuffer buffer) {
    List<String> namePart = name.split(RegExp('\\s+'));
    if (namePart.length < 2) {
      buffer.write("N:$name\r\n");
    } else {
      List<String> parts = [];
      if (namePart.length > 3) {
        parts.add(namePart[3]);
      }
      parts.add(namePart[1]);
      if (namePart.length > 2) {
        parts.add(namePart[2]);
      }
      parts.add(namePart[0]);
      if (namePart.length > 4) {
        parts.add(namePart[4]);
      }
      buffer.write("N;${parts.join(';')}\r\n");
    }
  }
}

class SMSResultGenerator extends ResultGenerator<SMSParsedResult> {
  const SMSResultGenerator() : super('短信', 'sms');

  @override
  String generator(SMSParsedResult data) {
    return "SMS:${data.numbers.join(',')}?subject=${data.subject}&body=${data.body}";
  }
}
