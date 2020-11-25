// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_dart;

/// Managing messages that Couchbase Lite logs at runtime.
class CBLLog {
  CBLLogDomain domain;
  CBLLogLevel level;

  static cbl.CBLLogFileConfiguration _cblFileConfig;
  static CBLLogFileConfiguration _fileConfig;
  static ReceivePort _cblLogPort;
  static CBLLogCallback _callback;

  CBLLog(this.domain, this.level);

  /// Writes a pre-formatted message to the log, exactly as given.
  void call(String message) {
    log(domain, level, message);
  }

  /// Writes a pre-formatted message to the log, exactly as given, associated to
  /// the log [domain].
  /// If the [level] is lower than the current minimum level for the domain as
  /// set by [consoleLevel], nothing is logged.
  static void log(CBLLogDomain domain, CBLLogLevel level, String message) =>
      cbl.CBL_Log(domain.index, level.index, cbl.strToUtf8(message));

  /// Returns true if a message with the given domain and level would be logged to the console.
  bool get isLoggedToConsole =>
      cbl.CBLLog_WillLogToConsole(domain.index, level.index) != 0;

  /// Returns true if a message with the given domain and level would be logged to the console.
  static bool willLogToConsole(CBLLogDomain domain, CBLLogLevel level) =>
      cbl.CBLLog_WillLogToConsole(domain.index, level.index) != 0;

  /// Gets the current log level for debug console logging.
  /// Only messages at this level or higher will be logged to the console or callback.
  static CBLLogLevel get consoleLevel =>
      CBLLogLevel.values[cbl.CBLLog_ConsoleLevel()] ?? CBLLogLevel.none;

  /// Sets the detail level of logging.
  /// Only messages whose level is ≥ the given level will be logged to the console or callback.
  static set consoleLevel(CBLLogLevel level) =>
      cbl.CBLLog_SetConsoleLevel(level.index);

  /// Gets the current file logging configuration.
  static CBLLogFileConfiguration get fileConfig => _fileConfig;

  /// Sets the file logging configuration.
  static set fileConfig(CBLLogFileConfiguration config) {
    // Free the previous value
    _cblFileConfig?.free();

    _fileConfig = config;
    _cblFileConfig = cbl.CBLLogFileConfiguration.allocate(
      directory: config.directory,
      maxRotateCount: config.maxRotateCount,
      maxSize: config.maxSize,
      usePlainText: config.usePlaintext,
      logLevel: config.logLevel,
    );
    final error = cbl.CBLError.allocate();
    cbl.CBLLog_SetFileConfig(_cblFileConfig.addressOf, error.addressOf);

    validateError(error);
  }

  static void _logCallbackListener(dynamic message) {
    if (_callback != null) {
      final log = jsonDecode(message);
      _callback(
        log['domain'] != null
            ? CBLLogDomain.values[log['domain']]
            : CBLLogDomain.all,
        log['level'] != null
            ? CBLLogLevel.values[log['level']]
            : CBLLogLevel.info,
        log['message'] ?? '',
      );
    }
  }

  static set callback(CBLLogCallback callback) {
    _cblLogPort ??= ReceivePort()..listen(_logCallbackListener);
    _callback = callback;

    if (_callback == null) {
      _cblLogPort.close();
      _cblLogPort = null;
    }

    /// Sets the callback for receiving log messages. If set to NULL, no messages are logged to the console.
    cbl.CBLLog_SetCallback_d(
      _callback != null ? _cblLogPort.sendPort.nativePort : 0,
    );
  }
}

/// A logging callback that the application can register.
typedef CBLLogCallback = void Function(
    CBLLogDomain domain, CBLLogLevel level, String msg);

/// The properties for configuring logging to files.
/// **Warning** `usePlaintext` results in significantly larger log files and
/// higher CPU usage that may slow down your app; we recommend turning it off in production.
class CBLLogFileConfiguration {
  /// The directory where log files will be created.
  final String directory;

  /// Max number of older logs to keep (i.e. total number will be one more.)
  final int maxRotateCount;

  /// The size in bytes at which a file will be rotated out (best effort).
  final int maxSize;

  /// Whether or not to log in plaintext (as opposed to binary)
  final bool usePlaintext;

  /// The detail level of logging.
  /// Only messages whose level is ≥ the given level will be logged to the file.
  final CBLLogLevel logLevel;

  CBLLogFileConfiguration(
      {this.directory,
      this.maxRotateCount = 1,
      this.maxSize = 1024000,
      this.usePlaintext = false,
      this.logLevel = CBLLogLevel.info});
}

/// Subsystems that log information.
enum CBLLogDomain {
  all,
  database,
  query,
  replicator,
  network,
}

/// Levels of log messages. Higher values are more important/severe. Each level includes the lower ones.
enum CBLLogLevel {
  /// Extremely detailed messages, only written by debug builds of CBL.
  debug,

  /// Detailed messages about normally-unimportant stuff.
  verbose,

  /// Messages about ordinary behavior.
  info,

  /// Messages warning about unlikely and possibly bad stuff.
  warning,

  /// Messages about errors
  error,

  /// Disables logging entirely.
  none
}
