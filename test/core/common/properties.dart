/// A simple property reader
class Properties {
  final Map<String, String> _properties = {};
  final Properties? _defaults;

  Properties([this._defaults]);

  load(String inString) {
    final List<String> lines = inString.split(RegExp('(\r\n|\r|\n)'));
    for (var element in lines) {
      if (!element.startsWith('<')) {
        final int equalPos = element.indexOf('=');
        if (equalPos > 0) {
          final String key = element.substring(0, equalPos).trim();
          final String value = element.substring(equalPos + 1).trim();
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
