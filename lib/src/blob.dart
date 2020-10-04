// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class Blob {
  ffi.Pointer<cbl.CBLBlob> pointer;

  Database db;

  String _path;

  String get path {
    if (_path?.isEmpty ?? true) {
      final error = cbl.CBLError.allocate();
      try {
        final res = cbl.CBLBlob_GetFilePath(pointer, error.addressOf);
        databaseError(error.addressOf);
        if (res != ffi.nullptr) {
          _path = cbl.utf8ToStr(res);
          cbl.Dart_Free(res);
        }
      } catch (e) {
        _path = '';
      } finally {
        pffi.free(error.addressOf);
      }
    }

    return _path;
  }

  String get contentType => cbl.utf8ToStr(cbl.CBLBlob_ContentType(pointer));

  String get digest => cbl.utf8ToStr(cbl.CBLBlob_Digest(pointer));

  int get length => cbl.CBLBlob_Length(pointer);

  Blob.createWithData(String contentType, Uint8List data) {
    final error = cbl.CBLError.allocate();

    var buf = pffi.allocate<ffi.Uint8>(count: data.length);
    var list = buf.asTypedList(data.length);
    list.setAll(0, data);

    pointer = cbl.CBLBlob_CreateWithData_c(
      cbl.strToUtf8(contentType),
      buf,
      list.length,
      error.addressOf,
    );

    databaseError(error.addressOf);
  }

  Blob.fromValue(FLDict dict) {
    pointer = dict != null && dict.addressOf != ffi.nullptr
        ? cbl.CBLBlob_Get(dict.addressOf)
        : ffi.nullptr;
  }

  FLDict get properties => pointer != null
      ? FLDict.fromPointer(cbl.CBLBlob_Properties(pointer))
      : null;

  Future<Uint8List> getContent() {
    if (path?.isNotEmpty ?? false) {
      final file = File(path);
      if (file.existsSync()) {
        return file.readAsBytes();
      }
    }

    // Fall back to getting the content through the blob store
    final error = cbl.CBLError.allocate();
    final size = pffi.allocate<ffi.Uint64>();
    size.value = 0;
    var result = cbl.CBLBlob_LoadContent(pointer, size, error.addressOf);
    databaseError(error.addressOf);
    return Future.value(result.asTypedList(size.value));
  }

  Map<String, dynamic> asMap() => jsonDecode(properties.json);
}
