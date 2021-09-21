// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class FLSlice {
  late Pointer<cbl.FLSlice> slice;
  late Pointer<Utf8> nativeString;

  /// Create a slice from a string. You must call [free] when you are done using it.
  FLSlice.fromString([String string = '']) {
    slice = calloc<cbl.FLSlice>();
    nativeString = string.toNativeUtf8();

    slice.ref
      ..buf = nativeString.cast()
      ..size = nativeString.length;
  }

  factory FLSlice.empty() => FLSlice.fromString('');

  void free() {
    calloc.free(nativeString);
    calloc.free(slice);
  }

  @override
  String toString() =>
      slice.ref.buf.cast<Utf8>().toDartString(length: slice.ref.size);
}

extension FLSliceUtils on cbl.FLSlice {
  String asString() => buf != nullptr && size > 0
      ? buf.cast<Utf8>().toDartString(length: size)
      : '';

  void free() => CBLC.FLBuf_Release(buf);
}

extension FLSliceResultUtils on cbl.FLSliceResult {
  String asString() => buf != nullptr && size > 0
      ? buf.cast<Utf8>().toDartString(length: size)
      : '';

  void free() => CBLC.FLBuf_Release(buf);
}
