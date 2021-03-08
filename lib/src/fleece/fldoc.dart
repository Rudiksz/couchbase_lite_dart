// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class FLDoc {
  ffi.Pointer<cbl.FLDoc> _doc = ffi.nullptr;

  FLValue _root;

  FLError error;

  FLDoc.fromPointer(this._doc);

  FLDoc.fromJson(String json) {
    final error = pffi.calloc<ffi.Uint8>();
    error.value = 0;
    _doc = cbl.FLDoc_FromJSON(json.toNativeUtf8().cast(), error);
    this.error = error.value < FLError.values.length
        ? FLError.values[error.value]
        : FLError.unsupported;
  }

  FLValue get root => _root ??= FLValue.fromPointer(cbl.FLDoc_GetRoot(_doc));

  set root(FLValue value) => _root = value;

  void dispose() => cbl.FLDoc_Release(_doc);
}
