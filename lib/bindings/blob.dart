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

/// Returns a blob's metadata. This includes the `digest`, `length` and `content_type`
/// properties, as well as any custom ones that may have been added.
final CBLBlob_Properties =
    _dylib.lookupFunction<_c_CBLBlob_Properties, _dart_CBLBlob_Properties>(
        'CBLBlob_Properties');

final CBLBlob_CreateWithData_c = _dylib.lookupFunction<
    _c_CBLBlob_CreateWithData_c,
    _dart_CBLBlob_CreateWithData_c>('CBLBlob_CreateWithData_c');

final CBLBlob_Get =
    _dylib.lookupFunction<_c_CBLBlob_Get, _dart_CBLBlob_Get>('CBLBlob_Get');

final CBLBlob_LoadContent =
    _dylib.lookupFunction<_c_CBLBlob_LoadContent, _dart_CBLBlob_LoadContent>(
        'CBLBlob_LoadContent_c');

final CBLBlob_GetFilePath =
    _dylib.lookupFunction<_c_CBLBlob_GetFilePath, _dart_CBLBlob_GetFilePath>(
        'CBLBlob_GetFilePath_c');

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

typedef _c_CBLBlob_Properties = ffi.Pointer<FLDict> Function(
  ffi.Pointer<CBLBlob> blob,
);

typedef _dart_CBLBlob_Properties = ffi.Pointer<FLDict> Function(
  ffi.Pointer<CBLBlob> blob,
);

typedef _c_CBLBlob_CreateWithData_c = ffi.Pointer<CBLBlob> Function(
  ffi.Pointer<ffi.Int8> contentType,
  ffi.Pointer<ffi.Uint8> contents,
  ffi.Uint64 length,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBLBlob_CreateWithData_c = ffi.Pointer<CBLBlob> Function(
  ffi.Pointer<ffi.Int8> contentType,
  ffi.Pointer<ffi.Uint8> contents,
  int length,
  ffi.Pointer<CBLError> outError,
);

typedef _c_CBLBlob_Get = ffi.Pointer<CBLBlob> Function(
  ffi.Pointer<FLDict> blobDict,
);

typedef _dart_CBLBlob_Get = ffi.Pointer<CBLBlob> Function(
  ffi.Pointer<FLDict> blobDict,
);

typedef _c_CBLBlob_LoadContent = ffi.Pointer<ffi.Uint8> Function(
  ffi.Pointer<CBLBlob> blob,
  ffi.Pointer<ffi.Uint64> size,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBLBlob_LoadContent = ffi.Pointer<ffi.Uint8> Function(
  ffi.Pointer<CBLBlob> blob,
  ffi.Pointer<ffi.Uint64> size,
  ffi.Pointer<CBLError> outError,
);

typedef _c_CBLBlob_GetFilePath = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLBlob> blob,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBLBlob_GetFilePath = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLBlob> blob,
  ffi.Pointer<CBLError> outError,
);
