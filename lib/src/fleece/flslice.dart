// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class FLSlice {
  Pointer<cbl.FLSlice> _slice = nullptr;
  cbl.FLSliceResult? sliceResult;
  FLSlice.empty();

  /// Create a slice from a string. You must call [free] when you are done using it.
  FLSlice.fromString([String string = '']) {
    _slice = calloc<cbl.FLSlice>();
    final nativeString = string.toNativeUtf8();
    _slice.ref
      ..buf = nativeString.cast()
      ..size = nativeString.length;
  }

  /// Create a slice from an FLSlice pointer returned by the C api methods.
  /// Calling [free] will free the memory, and invalidate the [slice] pointer.
  /// You should call [free] or otherwise free up the [slice] when done using it.
  FLSlice.fromSlice(Pointer<cbl.FLSlice> slice) {
    _slice = slice;
    _slice.ref.size = slice.ref.size;
  }

  /// Create a slice from an FLSliceResult pointer returned by C api methods.
  /// You must call [free] when you are done using it.
  FLSlice.fromSliceResult(this.sliceResult);

  Pointer<cbl.FLSlice> get slice =>
      Pointer<cbl.FLSlice>.fromAddress(_slice.address);

  int get _size => sliceResult?.size ?? _slice.ref.size;

  @override
  String toString() => (sliceResult?.buf ?? _slice.ref.buf)
      .cast<Utf8>()
      .toDartString(length: _size);

  Pointer<cbl.FLSliceResult> get toSliceResult => _slice.cast();

  void free() {
    if (_slice != nullptr) {
      calloc.free(_slice.ref.buf);
      calloc.free(_slice);
    } else if (sliceResult != null) {
      CBLC.FLBuf_Release(sliceResult!.buf);
      // FLSliceResult_Release(sliceResult!);
    }
  }
}
