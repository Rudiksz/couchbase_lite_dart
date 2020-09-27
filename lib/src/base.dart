// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

ffi.Pointer<ffi.Int8> strToUtf8(String str) =>
    pffi.Utf8.toUtf8(str).cast<ffi.Int8>();

String utf8ToStr(ffi.Pointer<ffi.Int8> p) => pffi.Utf8.fromUtf8(p.cast());

final registerSendPort = _dylib?.lookupFunction<
    ffi.Void Function(ffi.Int64 sendPort),
    void Function(int sendPort)>('RegisterSendPort');

final registerDart_PostCObject = _dylib?.lookupFunction<
    ffi.Void Function(
        ffi.Pointer<
                ffi.NativeFunction<
                    ffi.Int8 Function(
                        ffi.Int64, ffi.Pointer<ffi.Dart_CObject>)>>
            functionPointer),
    void Function(
        ffi.Pointer<
                ffi.NativeFunction<
                    ffi.Int8 Function(
                        ffi.Int64, ffi.Pointer<ffi.Dart_CObject>)>>
            functionPointer)>('RegisterDart_PostCObject');

final registerDart_NewNativePort = _dylib?.lookupFunction<
    ffi.Void Function(
        ffi.Pointer<
                ffi.NativeFunction<
                    ffi.Int64 Function(
                        ffi.Pointer<ffi.Uint8>,
                        ffi.Pointer<
                            ffi.NativeFunction<ffi.Dart_NativeMessageHandler>>,
                        ffi.Int8)>>
            functionPointer),
    void Function(
        ffi.Pointer<
                ffi.NativeFunction<
                    ffi.Int64 Function(
                        ffi.Pointer<ffi.Uint8>,
                        ffi.Pointer<
                            ffi.NativeFunction<ffi.Dart_NativeMessageHandler>>,
                        ffi.Int8)>>
            functionPointer)>('RegisterDart_NewNativePort');

final registerDart_CloseNativePort = _dylib?.lookupFunction<
    ffi.Void Function(
        ffi.Pointer<ffi.NativeFunction<ffi.Int8 Function(ffi.Int64)>>
            functionPointer),
    void Function(
        ffi.Pointer<ffi.NativeFunction<ffi.Int8 Function(ffi.Int64)>>
            functionPointer)>('RegisterDart_CloseNativePort');

class DocumentChange {
  DocumentChange(this.database, this.documentID);

  /// The database
  final Database database;

  /// The ID of the document that changed
  final String documentID;
}

class DatabaseChange {
  DatabaseChange(this.database, this.documentIDs);

  /// The database
  final Database database;

  /// The IDs of the documents that changed.
  final List<String> documentIDs;
}
