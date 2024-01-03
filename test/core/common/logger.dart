import 'dart:developer';

/// A simple logger
class Logger {
  final String prefix;
  static const _logTypes = {
    LoggerType.fine: 'FINE',
    LoggerType.info: 'INFO',
    LoggerType.warning: 'WARNING',
    LoggerType.error: 'ERROR',
  };

  Logger([this.prefix = '']);

  void fine(Object message) {
    record(message, LoggerType.fine);
  }

  void info(Object message) {
    record(message, LoggerType.info);
  }

  void error(Object message) {
    record(message, LoggerType.error);
  }

  void warning(Object message) {
    record(message, LoggerType.warning);
  }

  void record(Object message, [LoggerType type = LoggerType.info]) {
    log('$prefix $message', name: _logTypes[type] ?? '');
  }

  static final _loggers = <Type, Logger>{};
  static Logger getLogger(Type belong) {
    return _loggers.putIfAbsent(belong, () => Logger());
  }
}

enum LoggerType { fine, info, warning, error }
