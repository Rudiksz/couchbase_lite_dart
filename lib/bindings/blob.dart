// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_c_bindings;

// -- Data types

class CBLBlob extends ffi.Struct {}

// -- Functions

final CBLBlob_Length = _dylib
    .lookupFunction<_c_CBLBlob_Length, _dart_CBLBlob_Length>('CBLBlob_Length');

/// Returns the cryptographic digest of a blob's content (from its `digest` property).
final CBLBlob_Digest = _dylib
    .lookupFunction<_c_CBLBlob_Digest, _dart_CBLBlob_Digest>('CBLBlob_Digest');

/// Returns a blob's MIME type, if its metadata has a `content_type` property.
final CBLBlob_ContentType =
    _dylib.lookupFunction<_c_CBLBlob_ContentType, _dart_CBLBlob_ContentType>(
        'CBLBlob_ContentType');

final CBLBlob_CreateWithData_c = _dylib.lookupFunction<
    _c_CBLBlob_CreateWithData_c,
    _dart_CBLBlob_CreateWithData_c>('CBLBlob_CreateWithData_c');

// -- Function types

typedef _c_CBLBlob_Length = ffi.Uint64 Function(ffi.Pointer<CBLBlob> blob);

typedef _dart_CBLBlob_Length = int Function(ffi.Pointer<CBLBlob> blob);

typedef _c_CBLBlob_Digest = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLBlob> blob,
);

typedef _dart_CBLBlob_Digest = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLBlob> blob,
);

typedef _c_CBLBlob_ContentType = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLBlob> blob,
);

typedef _dart_CBLBlob_ContentType = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLBlob> blob,
);

typedef _c_CBLBlob_CreateWithData_c = ffi.Pointer<CBLBlob> Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> contentType,
  ffi.Pointer<ffi.Uint8> contents,
  ffi.Uint64 length,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBLBlob_CreateWithData_c = ffi.Pointer<CBLBlob> Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> contentType,
  ffi.Pointer<ffi.Uint8> contents,
  int length,
  ffi.Pointer<CBLError> outError,
);
