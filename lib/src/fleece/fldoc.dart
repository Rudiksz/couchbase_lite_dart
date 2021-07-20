// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class FLDoc {
  Pointer<cbl.FLDoc> _doc = nullptr;

  FLError error = FLError.noError;

  FLValue? _root;
  FLValue get root => _root ??= FLValue.fromPointer(CBLC.FLDoc_GetRoot(_doc));

  FLDoc.fromJson(String json) {
    _fromJson(json);
  }

  FLDoc.fromMap(Map map) {
    _fromJson(jsonEncode(map));
  }

  FLDoc.fromList(List list) {
    _fromJson(jsonEncode(list));
  }

  void _fromJson(String json) {
    final error = calloc<Int32>()..value = 0;
    final _c_json = FLSlice.fromString(json);
    _doc = CBLC.FLDoc_FromJSON(_c_json.slice.ref, error);
    this.error = error.value < FLError.values.length
        ? FLError.values[error.value]
        : FLError.unsupported;
    calloc.free(error);
    _c_json.free();
  }

  void dispose() => CBLC.FLDoc_Release(_doc);
}
