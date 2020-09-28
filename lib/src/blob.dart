// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class Blob {
  ffi.Pointer<cbl.CBLBlob> pointer;

  Database db;

  String get contentType => cbl.utf8ToStr(cbl.CBLBlob_ContentType(pointer));

  String get digest => cbl.utf8ToStr(cbl.CBLBlob_Digest(pointer));

  int get length => cbl.CBLBlob_Length(pointer);

  Blob.createWithData(Database db, String contentType, Uint8List data) {
    final error = pffi.allocate<cbl.CBLError>();

    var buf = pffi.allocate<ffi.Uint8>(count: data.length);
    var list = buf.asTypedList(data.length);
    list.setAll(0, data);

    pointer = cbl.CBLBlob_CreateWithData_c(
      db._db,
      cbl.strToUtf8(contentType),
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
