// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_c_bindings;

class CBLLogFileConfiguration extends ffi.Struct {
  ffi.Pointer<ffi.Int8> directory;

  /// Domain of errors; a namespace for the `code`.
  @ffi.Uint32()
  int maxRotateCount;

  /// Error code, specific to the domain. 0 always means no error.
  @ffi.Uint64()
  int maxSize;

  @ffi.Uint8()
  int usePlaintext;

  @ffi.Int8()
  int logLevel;

  static ffi.Pointer<CBLLogFileConfiguration> allocate({
    String directory = '',
    int maxRotateCount = 2,
    int maxSize = 10485760,
    bool usePlainText,
    CBLLogLevel logLevel,
  }) {
    final p = pffi.calloc<CBLLogFileConfiguration>();

    p.ref
      ..directory = directory.toNativeUtf8().cast()
      ..maxRotateCount = maxRotateCount
      ..maxSize = maxSize
      ..usePlaintext = usePlainText ? 1 : 0
      ..logLevel = logLevel.index;
    return p;
  }
}

final CBL_Log = _dylib.lookupFunction<_c_CBLLog, _dart_CBLLog>('CBL_Log');
final CBL_Log_s =
    _dylib.lookupFunction<_c_CBLLog_s, _dart_CBLLog_s>('CBL_Log_d');

final CBLLog_ConsoleLevel =
    _dylib.lookupFunction<_c_CBLLog_ConsoleLevel, _dart_CBLLog_ConsoleLevel>(
        'CBLLog_ConsoleLevel');

final CBLLog_SetConsoleLevel = _dylib.lookupFunction<_c_CBLLog_SetConsoleLevel,
    _dart_CBLLog_SetConsoleLevel>('CBLLog_SetConsoleLevel');

final CBLLog_WillLogToConsole = _dylib.lookupFunction<
    _c_CBLLog_WillLogToConsole,
    _dart_CBLLog_WillLogToConsole>('CBLLog_WillLogToConsole');

final CBLLog_SetCallback_d =
    _dylib.lookupFunction<_c_CBLLog_SetCallback_d, _dart_CBLLog_SetCallback_d>(
        'CBLLog_SetCallback_d');

final CBLLog_FileConfig =
    _dylib.lookupFunction<_c_CBLLog_FileConfig, _dart_CBLLog_FileConfig>(
        'CBLLog_FileConfig');

final CBLLog_SetFileConfig =
    _dylib.lookupFunction<_c_CBLLog_SetFileConfig, _dart_CBLLog_SetFileConfig>(
        'CBLLog_SetFileConfig');

// -- Function types

typedef _c_CBLLog = ffi.Void Function(
  ffi.Uint8 domain,
  ffi.Uint8 level,
  ffi.Pointer<ffi.Int8> format,
);

typedef _dart_CBLLog = void Function(
  int domain,
  int level,
  ffi.Pointer<ffi.Int8> format,
);

typedef _c_CBLLog_s = ffi.Void Function(
  ffi.Uint8 domain,
  ffi.Uint8 level,
  ffi.Pointer<ffi.Int8> message,
);

typedef _dart_CBLLog_s = void Function(
  int domain,
  int level,
  ffi.Pointer<ffi.Int8> message,
);

typedef _c_CBLLog_ConsoleLevel = ffi.Int8 Function();

typedef _dart_CBLLog_ConsoleLevel = int Function();

typedef _c_CBLLog_SetConsoleLevel = ffi.Void Function(ffi.Int8);

typedef _dart_CBLLog_SetConsoleLevel = void Function(int);

typedef _c_CBLLog_WillLogToConsole = ffi.Int8 Function(
  ffi.Uint8 domain,
  ffi.Uint8 level,
);

typedef _dart_CBLLog_WillLogToConsole = int Function(
  int domain,
  int level,
);

typedef _c_CBLLog_SetCallback_d = ffi.Void Function(
  ffi.Uint64 cbl_log_port,
);

typedef _dart_CBLLog_SetCallback_d = void Function(
  int cbl_log_port,
);

typedef _c_CBLLog_FileConfig = ffi.Pointer<CBLLogFileConfiguration> Function();

typedef _dart_CBLLog_FileConfig = ffi.Pointer<CBLLogFileConfiguration>
    Function();

typedef _c_CBLLog_SetFileConfig = ffi.Int8 Function(
  ffi.Pointer<CBLLogFileConfiguration> config,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLLog_SetFileConfig = int Function(
  ffi.Pointer<CBLLogFileConfiguration> config,
  ffi.Pointer<CBLError> error,
);
