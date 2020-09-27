// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_dart;

/// Returns a message describing an error.
///
///  It is the caller's responsibility to free the returned C string by calling `free`.
final CBLError_Message =
    _dylib.lookupFunction<_c_CBLError_Message, _dart_CBLError_Message>(
        'CBLError_Message');

final Dart_Free =
    _dylib.lookupFunction<_c_Dart_Free, _dart_Dart_Free>('Dart_Free');

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

  factory CBLError.allocate([
    int domain = 0,
    int code = 0,
    int internal_info = 0,
  ]) =>
      pffi.allocate<CBLError>().ref
        ..domain = domain
        ..code = code
        ..internal_info = internal_info;
}

// --- Function types

typedef _c_CBLError_Message = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLError_Message = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLError> error,
);

typedef _c_Dart_Free = ffi.Void Function(ffi.Pointer pointer);

typedef _dart_Dart_Free = void Function(ffi.Pointer pointer);
