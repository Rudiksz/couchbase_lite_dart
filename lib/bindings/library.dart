// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
library couchbase_lite_c_bindings;

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:ffi/ffi.dart' as pffi;
import 'package:path/path.dart';

part 'blob.dart';
part 'database.dart';
part 'document.dart';
part 'fleece.dart';
part 'listeners.dart';
part 'query.dart';
part 'replicator.dart';
part 'log.dart';

final packagePath = findPackagePath(Directory.current.path);
final winLibPath = packagePath.isNotEmpty
    ? '$packagePath/dynlib/CouchbaseLiteC.dll'
    : 'CouchbaseLiteC.dll';

// ffi.DynamicLibrary _dylib;
final _dylib = Platform.isWindows
    ? (File(winLibPath).existsSync()
        ? ffi.DynamicLibrary.open(winLibPath)
        : null)
    : (Platform.isAndroid
        ? ffi.DynamicLibrary.open('libCouchbaseLiteC.so')
        : null);

class CblC {
  String get package => packagePath.isNotEmpty
      ? '$packagePath/CouchbaseLiteC.dll'
      : 'CouchbaseLiteC.dll';

  static bool isPlatformSupported() => _dylib != null;
  void init() {
    // FIXME: the test is failing at this line
    assert(isPlatformSupported());

    // Windows static linking workaround
    registerDart_PostCObject(ffi.NativeApi.postCObject);
    registerDart_NewNativePort(ffi.NativeApi.newNativePort);
    registerDart_CloseNativePort(ffi.NativeApi.closeNativePort);
    registerDartPrint(wrappedPrintPointer);

    ChangeListeners.initalize();
  }

  int instanceCount() => CBL_InstanceCount();
}

//ffi.Pointer<ffi.Int8> strToUtf8(String str) =>
//    pffi.Utf8.toUtf8(str).cast<ffi.Int8>();

//String utf8ToStr(ffi.Pointer<ffi.Int8> p) => pffi.Utf8.fromUtf8(p.cast());

final registerSendPort = _dylib?.lookupFunction<
    ffi.Void Function(ffi.Int64 sendPort),
    void Function(int sendPort)>('RegisterSendPort');

final registerDart_PostCObject = _dylib.lookupFunction<
    ffi.Void Function(
        ffi.Pointer<
                ffi.NativeFunction<
                    ffi.Int8 Function(
                        ffi.Int64, ffi.Pointer<ffi.Dart_CObject>)>>
            functionPointer),
    void Function(
        ffi.Pointer<
                ffi.NativeFunction<
                    ffi.Int8 Function(
                        ffi.Int64, ffi.Pointer<ffi.Dart_CObject>)>>
            functionPointer)>('RegisterDart_PostCObject');

final registerDart_NewNativePort = _dylib.lookupFunction<
    ffi.Void Function(
        ffi.Pointer<
                ffi.NativeFunction<
                    ffi.Int64 Function(
                        ffi.Pointer<ffi.Uint8>,
                        ffi.Pointer<
                            ffi.NativeFunction<ffi.Dart_NativeMessageHandler>>,
                        ffi.Int8)>>
            functionPointer),
    void Function(
        ffi.Pointer<
                ffi.NativeFunction<
                    ffi.Int64 Function(
                        ffi.Pointer<ffi.Uint8>,
                        ffi.Pointer<
                            ffi.NativeFunction<ffi.Dart_NativeMessageHandler>>,
                        ffi.Int8)>>
            functionPointer)>('RegisterDart_NewNativePort');

final registerDart_CloseNativePort = _dylib?.lookupFunction<
    ffi.Void Function(
        ffi.Pointer<ffi.NativeFunction<ffi.Int8 Function(ffi.Int64)>>
            functionPointer),
    void Function(
        ffi.Pointer<ffi.NativeFunction<ffi.Int8 Function(ffi.Int64)>>
            functionPointer)>('RegisterDart_CloseNativePort');

void wrappedPrint(ffi.Pointer<pffi.Utf8> arg) {
  print(arg.toDartString());
}

typedef _dart_Print = ffi.Void Function(ffi.Pointer<pffi.Utf8> a);
final wrappedPrintPointer = ffi.Pointer.fromFunction<_dart_Print>(wrappedPrint);

final void Function(ffi.Pointer) registerDartPrint = _dylib.lookupFunction<
    ffi.Void Function(ffi.Pointer),
    void Function(ffi.Pointer)>('RegisterDart_Print');

/// Build a file path.
String toFilePath(String parent, String path, {bool windows}) {
  var uri = Uri.parse(path);
  path = uri.toFilePath(windows: windows);
  if (isRelative(path)) {
    return normalize(join(parent, path));
  }
  return normalize(path);
}

/// Find our package path in the current project
String findPackagePath(String currentPath, {bool windows}) {
  String findPath(File file) {
    var lines = LineSplitter.split(file.readAsStringSync());
    for (var line in lines) {
      var parts = line.split(':');
      if (parts.length > 1) {
        if (parts[0] == 'couchbase_lite_dart') {
          var location = parts.sublist(1).join(':');
          return absolute(normalize(
              toFilePath(dirname(file.path), location, windows: windows)));
        }
      }
    }
    return '';
  }

  var file = File(join(currentPath, '.packages'));
  if (file.existsSync()) {
    return findPath(file);
  } else {
    var parent = dirname(currentPath);
    if (parent == currentPath) {
      return '';
    }
    return findPackagePath(parent);
  }
}

/// Returns a message describing an error.
///
///  It is the caller's responsibility to free the returned C string by calling `free`.

final RegisterDartPorts =
    _dylib.lookupFunction<_c_RegisterDartPorts, _dart_RegisterDartPorts>(
        'RegisterDartPorts');

final CBLError_Message =
    _dylib.lookupFunction<_c_CBLError_Message, _dart_CBLError_Message>(
        'CBLError_Message');

final CBL_Release =
    _dylib.lookupFunction<_c_CBL_Release, _dart_CBL_Release>('CBL_Release');

final CBL_InstanceCount =
    _dylib.lookupFunction<_c_CBL_InstanceCount, _dart_CBL_InstanceCount>(
        'CBL_InstanceCount');

final Dart_Free =
    _dylib.lookupFunction<_c_Dart_Free, _dart_Dart_Free>('Dart_Free');

final Dart_ExecuteCallback = _dylib.lookupFunction<
    ffi.Void Function(ffi.Pointer<Work>),
    void Function(ffi.Pointer<Work>)>('Dart_ExecuteCallback');

// --- Data types

/// A struct holding information about an error. It's declared on the stack by a caller, and
/// its address is passed to an API function. If the function's return value indicates that
/// there was an error (usually by returning NULL or false), then the CBLError will have been
/// filled in with the details.
class CBLError extends ffi.Struct {
  /// Domain of errors; a namespace for the `code`.
  @ffi.Uint32()
  int domain;

  /// Error code, specific to the domain. 0 always means no error.
  @ffi.Int32()
  int code;

  @ffi.Int32()
  int internal_info;

  static ffi.Pointer<CBLError> allocate([
    int domain = 0,
    int code = 0,
    int internal_info = 0,
  ]) {
    final err = pffi.calloc<CBLError>();

    err.ref
      ..domain = domain
      ..code = code
      ..internal_info = internal_info;

    return err;
  }

  void reset() => domain = code = internal_info = 0;

  //void free() => pffi.free();
}

// --- Function types

typedef _c_CBLError_Message = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLError_Message = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLError> error,
);

typedef _c_RegisterDartPorts = ffi.Void Function(
  ffi.Uint64 database_listener_port,
  ffi.Uint64 document_listener_port,
  ffi.Uint64 query_listener_port,
  ffi.Uint64 replicator_status_port,
  ffi.Uint64 replicator_filter_port,
  ffi.Uint64 replicator_conflict_port,
  ffi.Pointer<ffi.NativeFunction<StatusCallback>> statusCallback,
  ffi.Pointer<ffi.NativeFunction<FilterCallback>> filterCallback,
  ffi.Pointer<ffi.NativeFunction<ConflictCallback>> conflictCallback,
);

typedef _dart_RegisterDartPorts = void Function(
  int database_listener_port,
  int document_listener_port,
  int query_listener_port,
  int replicator_status_port,
  int replicator_filter_port,
  int replicator_conflict_port,
  ffi.Pointer<ffi.NativeFunction<StatusCallback>> statusCallback,
  ffi.Pointer<ffi.NativeFunction<FilterCallback>> filterCallback,
  ffi.Pointer<ffi.NativeFunction<ConflictCallback>> conflictCallback,
);

typedef _c_Dart_Free = ffi.Void Function(ffi.Pointer pointer);

typedef _dart_Dart_Free = void Function(ffi.Pointer pointer);

typedef _c_CBL_Release = ffi.Void Function(ffi.Pointer pointer);

typedef _dart_CBL_Release = void Function(ffi.Pointer pointer);

typedef _c_CBL_InstanceCount = ffi.Uint64 Function();

typedef _dart_CBL_InstanceCount = int Function();

/// Error domains, serving as namespaces for numeric error codes. */
enum CBLErrorDomain {
  /// Dummay value, because the C enum index starts at 1
  dummy,

  ///< code is a Couchbase Lite error code; see \ref CBLErrorCode
  CBLDomain,

  ///< code is a POSIX `errno`; see "errno.h"
  CBLPOSIXDomain,

  ///< code is a SQLite error; see "sqlite3.h"
  CBLSQLiteDomain,

  ///< code is a Fleece error; see "FleeceException.h"
  CBLFleeceDomain,

  ///< code is a network error; see \ref CBLNetworkErrorCode
  CBLNetworkDomain,

  ///< code is a WebSocket close code (1000...1015) or HTTP error (300..599)
  CBLWebSocketDomain,

// Because the C enum starts at 1
  CBLMaxErrorDomainPlus1
}

/// Couchbase Lite error codes, in the CBLDomain. */
enum CBLErrorCode {
  /// Dummay value, because the C enum index starts at 1
  dummy,

  /*1*/ ///< Internal assertion failure
  CBLErrorAssertionFailed,

  ///< Oops, an unimplemented API call
  CBLErrorUnimplemented,

  ///< Unsupported encryption algorithm
  CBLErrorUnsupportedEncryption,

  ///< Invalid revision ID syntax
  CBLErrorBadRevisionID,

  ///< Revision contains corrupted/unreadable data
  CBLErrorCorruptRevisionData,

  ///< Database/KeyStore/index is not open
  CBLErrorNotOpen,

  ///< Document not found
  CBLErrorNotFound,

  ///< Document update conflict
  CBLErrorConflict,

  ///< Invalid function parameter or struct value
  CBLErrorInvalidParameter,

  /*10*/ ///< Internal unexpected C++ exception
  CBLErrorUnexpectedError,

  ///< Database file can't be opened; may not exist
  CBLErrorCantOpenFile,

  ///< File I/O error
  CBLErrorIOError,

  ///< Memory allocation failed (out of memory?)
  CBLErrorMemoryError,

  ///< File is not writeable
  CBLErrorNotWriteable,

  ///< Data is corrupted
  CBLErrorCorruptData,

  ///< Database is busy/locked
  CBLErrorBusy,

  ///< Function must be called while in a transaction
  CBLErrorNotInTransaction,

  ///< Database can't be closed while a transaction is open
  CBLErrorTransactionNotClosed,

  ///< Operation not supported in this database
  CBLErrorUnsupported,

  /*20*/ ///< File is not a database, or encryption key is wrong
  CBLErrorNotADatabaseFile,

  ///< Database exists but not in the format/storage requested
  CBLErrorWrongFormat,

  ///< Encryption/decryption error
  CBLErrorCrypto,

  ///< Invalid query
  CBLErrorInvalidQuery,

  ///< No such index, or query requires a nonexistent index
  CBLErrorMissingIndex,

  ///< Unknown query param name, or param number out of range
  CBLErrorInvalidQueryParam,

  ///< Unknown error from remote server
  CBLErrorRemoteError,

  ///< Database file format is older than what I can open
  CBLErrorDatabaseTooOld,

  ///< Database file format is newer than what I can open
  CBLErrorDatabaseTooNew,

  ///< Invalid document ID
  CBLErrorBadDocID,

  /*30*/ ///< DB can't be upgraded (might be unsupported dev version)
  CBLErrorCantUpgradeDatabase,

  CBLNumErrorCodesPlus1
}

/// Network error codes, in the CBLNetworkDomain.
enum CBLNetworkErrorCode {
  /*1*/ ///< DNS lookup failed
  CBLNetErrDNSFailure,

  ///< DNS server doesn't know the hostname
  CBLNetErrUnknownHost,

  ///< No response received before timeout
  CBLNetErrTimeout,

  ///< Invalid URL
  CBLNetErrInvalidURL,

  ///< HTTP redirect loop
  CBLNetErrTooManyRedirects,

  ///< Low-level error establishing TLS
  CBLNetErrTLSHandshakeFailed,

  ///< Server's TLS certificate has expired
  CBLNetErrTLSCertExpired,

  ///< Cert isn't trusted for other reason
  CBLNetErrTLSCertUntrusted,

  ///< Server requires client to have a TLS certificate
  CBLNetErrTLSClientCertRequired,

  ///< Server rejected my TLS client certificate
  CBLNetErrTLSClientCertRejected,

  ///< Self-signed cert, or unknown anchor cert
  CBLNetErrTLSCertUnknownRoot,

  ///< Attempted redirect to invalid URL
  CBLNetErrInvalidRedirect,

  ///< Unknown networking error
  CBLNetErrUnknown,

  ///< Server's cert has been revoked
  CBLNetErrTLSCertRevoked,

  ///< Server cert's name does not match DNS name
  CBLNetErrTLSCertNameMismatch,
}
