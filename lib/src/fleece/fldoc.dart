// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_c;

class FLDoc {
  ffi.Pointer<_FLDoc> _doc;

  FLValue _root;

  FLError error;

  FLDoc() {
    _doc = pffi.allocate<_FLDoc>();
  }

  FLDoc.fromPointer(this._doc);

  FLDoc.fromJson(String json) {
    final _json = FLSlice.allocate(json);
    final error = pffi.allocate<ffi.Uint8>();
    error.value = 0;
    _doc = FLDoc_Retain(FLDoc_FromJSON(_json.addressOf, error));

    this.error = error.value < FLError.values.length
        ? FLError.values[error.value]
        : FLError.unsupported;
  }

  FLValue get root => _root ??= FLValue.fromPointer(FLDoc_GetRoot(_doc));
  set root(FLValue value) => _root = value;

  void dispose() => pffi.free(_doc);
}
