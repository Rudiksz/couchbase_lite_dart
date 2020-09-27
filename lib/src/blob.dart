// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_c;

class Blob {
  ffi.Pointer<CBLBlob> pointer;

  Database db;

  String get contentType => utf8ToStr(CBLBlob_ContentType(pointer));

  String get digest => utf8ToStr(CBLBlob_Digest(pointer));

  int get length => CBLBlob_Length(pointer);

  Blob.createWithData(Database db, String contentType, Uint8List data) {
    final error = pffi.allocate<CBLError>();

    var buf = pffi.allocate<ffi.Uint8>(count: data.length);
    var list = buf.asTypedList(data.length);
    list.setAll(0, data);

    pointer = CBLBlob_CreateWithData_c(
      db._db,
      strToUtf8(contentType),
      buf,
      list.length,
      error,
    );

    databaseError(error);
  }

  Map<String, dynamic> toMap() {
    return {
      '@type': 'blob',
      'content_type': contentType,
      'length': length,
      'digest': digest,
    };
  }
}
