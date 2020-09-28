// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class FLDoc {
  ffi.Pointer<cbl.FLDoc> _doc;

  FLValue _root;

  cbl.FLError error;

  FLDoc() {
    _doc = pffi.allocate<cbl.FLDoc>();
  }

  FLDoc.fromPointer(this._doc);

  FLDoc.fromJson(String json) {
    final _json = cbl.FLSlice.allocate(json);
    final error = pffi.allocate<ffi.Uint8>();
    error.value = 0;
    _doc = cbl.FLDoc_Retain(cbl.FLDoc_FromJSON(_json.addressOf, error));

    this.error = error.value < cbl.FLError.values.length
        ? cbl.FLError.values[error.value]
        : cbl.FLError.unsupported;
  }

  FLValue get root => _root ??= FLValue.fromPointer(cbl.FLDoc_GetRoot(_doc));
  set root(FLValue value) => _root = value;

  void dispose() => pffi.free(_doc);
}
