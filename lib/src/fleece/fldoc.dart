// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class FLDoc {
  Pointer<cbl.FLDoc> _doc = nullptr;

  FLValue? _root;

  FLError error = FLError.noError;

  FLDoc.fromPointer(this._doc);

  FLDoc.fromJson(String json) {
    final error = calloc<Int32>()..value = 0;

    _doc = CBLC.FLDoc_FromJSON(FLSlice.fromString(json).slice, error);
    this.error = error.value < FLError.values.length
        ? FLError.values[error.value]
        : FLError.unsupported;
    calloc.free(error);
    //_json.free();
  }

  FLValue get root => _root ??= FLValue.fromPointer(CBLC.FLDoc_GetRoot(_doc));

  set root(FLValue value) => _root = value;

  void dispose() => CBLC.FLDoc_Release(_doc);
}
