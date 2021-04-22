// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class FLSlice {
  Pointer<cbl.FLSlice> address = nullptr;

  FLSlice.empty();

  FLSlice.fromString([String string = '']) {
    address = calloc<cbl.FLSlice>();
    final nativeString = string.toNativeUtf8();
    address.ref
      ..buf = nativeString.cast()
      ..size = nativeString.length;
  }

  FLSlice.fromSlice(cbl.FLSlice slice) {
    address = calloc<cbl.FLSlice>();
    address.ref
      ..buf = slice.buf.cast()
      ..size = slice.size;
  }

  FLSlice.fromSliceResult(cbl.FLSliceResult slice) {
    address = calloc<cbl.FLSlice>();
    address.ref
      ..buf = slice.buf.cast()
      ..size = slice.size;
  }

  FLSlice.fromPointer(this.address, int length) {
    address.ref.size = length;
  }

  cbl.FLSlice get slice => address.ref;

  @override
  String toString() =>
      address.ref.buf.cast<Utf8>().toDartString(length: address.ref.size);

  Pointer<cbl.FLSliceResult> get toSliceResult => address.cast();

  void free() => calloc.free(address);
}
