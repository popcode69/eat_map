import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
    // In release: filter all but warnings/errors
    filter: kReleaseMode ? ProductionFilter() : DevelopmentFilter(),
    output: null, // ConsoleOutput is default
  );

  void d(String msg, [Object? extra]) {
    _logger.d('[DEBUG] $msg', error: extra);
  }

  void i(String msg, [Object? extra]) {
    _logger.i('[INFO]  $msg', error: extra);
  }

  void w(String msg, [Object? extra]) {
    _logger.w('[WARN]  $msg', error: extra);
  }

  void e(String msg, Object error, StackTrace st) {
    _logger.e('[ERROR] $msg', error: error, stackTrace: st);
  }
}
