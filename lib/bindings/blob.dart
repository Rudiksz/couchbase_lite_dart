// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_c_bindings;

// -- Data types

class CBLBlob extends ffi.Opaque {}

class CBLBlobReadStream extends ffi.Opaque {}

class CBLBlobWriteStream extends ffi.Opaque {}

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

final CBLBlob_OpenContentStream = _dylib.lookupFunction<
    _c_CBLBlob_OpenContentStream,
    _dart_CBLBlob_OpenContentStream>('CBLBlob_OpenContentStream');

final CBLBlobReader_Read =
    _dylib.lookupFunction<_c_CBLBlobReader_Read, _dart_CBLBlobReader_Read>(
        'CBLBlobReader_Read');

final CBLBlobReader_Close =
    _dylib.lookupFunction<_c_CBLBlobReader_Close, _dart_CBLBlobReader_Close>(
        'CBLBlobReader_Close');

final CBLBlobWriter_New =
    _dylib.lookupFunction<_c_CBLBlobWriter_New, _dart_CBLBlobWriter_New>(
        'CBLBlobWriter_New');

final CBLBlobWriter_Write =
    _dylib.lookupFunction<_c_CBLBlobWriter_Write, _dart_CBLBlobWriter_Write>(
        'CBLBlobWriter_Write');

final CBLBlobWriter_Close =
    _dylib.lookupFunction<_c_CBLBlobWriter_Close, _dart_CBLBlobWriter_Close>(
        'CBLBlobWriter_Close');

final CBLBlob_CreateWithStream = _dylib.lookupFunction<
    _c_CBLBlob_CreateWithStream,
    _dart_CBLBlob_CreateWithStream>('CBLBlob_CreateWithStream');

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

// -- Stream API

typedef _c_CBLBlob_OpenContentStream = ffi.Pointer<CBLBlobReadStream> Function(
  ffi.Pointer<CBLBlob> blob,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBLBlob_OpenContentStream = ffi.Pointer<CBLBlobReadStream>
    Function(
  ffi.Pointer<CBLBlob> blob,
  ffi.Pointer<CBLError> outError,
);

typedef _c_CBLBlobReader_Read = ffi.Uint64 Function(
  ffi.Pointer<CBLBlobReadStream> stream,
  ffi.Pointer dst,
  ffi.Uint64 max_length,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBLBlobReader_Read = int Function(
  ffi.Pointer<CBLBlobReadStream> stream,
  ffi.Pointer dst,
  int max_length,
  ffi.Pointer<CBLError> outError,
);

typedef _c_CBLBlobReader_Close = ffi.Void Function(
  ffi.Pointer<CBLBlobReadStream> stream,
);

typedef _dart_CBLBlobReader_Close = void Function(
  ffi.Pointer<CBLBlobReadStream> stream,
);

typedef _c_CBLBlobWriter_New = ffi.Pointer<CBLBlobWriteStream> Function(
  ffi.Pointer<CBLDatabase> blob,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBLBlobWriter_New = ffi.Pointer<CBLBlobWriteStream> Function(
  ffi.Pointer<CBLDatabase> blob,
  ffi.Pointer<CBLError> outError,
);

typedef _c_CBLBlobWriter_Write = ffi.Uint64 Function(
  ffi.Pointer<CBLBlobWriteStream> stream,
  ffi.Pointer data,
  ffi.Uint64 length,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBLBlobWriter_Write = int Function(
  ffi.Pointer<CBLBlobWriteStream> stream,
  ffi.Pointer data,
  int length,
  ffi.Pointer<CBLError> outError,
);

typedef _c_CBLBlobWriter_Close = ffi.Void Function(
  ffi.Pointer<CBLBlobWriteStream> stream,
);

typedef _dart_CBLBlobWriter_Close = void Function(
  ffi.Pointer<CBLBlobWriteStream> stream,
);

typedef _c_CBLBlob_CreateWithStream = ffi.Pointer<CBLBlob> Function(
  ffi.Pointer<ffi.Int8> contentType,
  ffi.Pointer<CBLBlobWriteStream> stream,
);

typedef _dart_CBLBlob_CreateWithStream = ffi.Pointer<CBLBlob> Function(
  ffi.Pointer<ffi.Int8> contentType,
  ffi.Pointer<CBLBlobWriteStream> stream,
);
