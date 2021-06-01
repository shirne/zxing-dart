

class Properties{
  final Map<String, String> _properties = {};
  Properties? _defaults;

  Properties([this._defaults]);

  load(String inString){
    List<String> lines = inString.split(RegExp("(\r\n|\r|\n)"));
    lines.forEach((element) {
      if(!element.startsWith('<')){
        int equalPos = element.indexOf('=');
        if(equalPos > 0){
          String key = element.substring(0, equalPos).trim();
          String value = element.substring(equalPos).trim();
          _properties[key] = value;
        }
      }
    });
  }

  Map<String, String> get properties{
    return _properties;
  }

  String? getProperty(String key, [String? defaultValue]){
    return _properties[key] ?? (_defaults?.getProperty(key) ?? defaultValue);
  }

  setProperty(String key, String value){
    _properties[key] = value;
  }
}