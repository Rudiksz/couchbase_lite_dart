// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_c_bindings;

// -- Data types

class CBLListenerToken extends ffi.Opaque {}

// -- Functions

final CBLListener_Remove =
    _dylib.lookupFunction<_c_CBLListener_Remove, _dart_CBLListener_Remove>(
        'CBLListener_Remove');

// -- Function types

typedef _c_CBLListener_Remove = ffi.Void Function(
  ffi.Pointer<CBLListenerToken> arg0,
);

typedef _dart_CBLListener_Remove = void Function(
  ffi.Pointer<CBLListenerToken> arg0,
);
