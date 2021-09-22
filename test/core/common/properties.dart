/// A simple property reader
class Properties {
  final Map<String, String> _properties = {};
  final Properties? _defaults;

  Properties([this._defaults]);

  load(String inString) {
    List<String> lines = inString.split(RegExp("(\r\n|\r|\n)"));
    for (var element in lines) {
      if (!element.startsWith('<')) {
        int equalPos = element.indexOf('=');
        if (equalPos > 0) {
          String key = element.substring(0, equalPos).trim();
          String value = element.substring(equalPos + 1).trim();
          _properties[key] = value;
        }
      }
    }
  }

  Map<String, String> get properties => _properties;

  String? getProperty(String key, [String? defaultValue]) {
    return _properties[key] ?? (_defaults?.getProperty(key) ?? defaultValue);
  }

  setProperty(String key, String value) {
    _properties[key] = value;
  }
}
