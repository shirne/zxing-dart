
class Logger{
  final String prefix;

  Logger([this.prefix = '']);

  void fine(Object message){
    record(message, LoggerType.fine);
  }

  void info(Object message){
    record(message, LoggerType.info);
  }

  void error(Object message){
    record(message, LoggerType.error);
  }

  void warning(Object message){
    record(message, LoggerType.warning);
  }

  void record(Object message, [LoggerType type = LoggerType.info]){
    print("[$type] $prefix $message");
  }

  static Logger getLogger(Type prefix){
    return Logger(prefix.toString());
  }
}

enum LoggerType{
  fine,
  info,
  warning,
  error
}