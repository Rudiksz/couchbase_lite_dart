// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// A [Blob] is a binary data blob associated with a document.

/// The content of the blob is not stored in the document, but externally in the database.
/// It is loaded only on demand, and can be streamed. Blobs can be arbitrarily large, although
/// Sync Gateway will only accept blobs under 20MB.
///
/// The document contains only a blob reference: a dictionary with the special marker property
/// `"@type":"blob"`, and another property `digest` whose value is a hex SHA-1 digest of the
/// blob's data. This digest is used as the key to retrieve the blob data.
/// The dictionary usually also has the property `length`, containing the blob's length in bytes,
/// and it may have the property `content_type`, containing a MIME type.
///
/// A [Blob] object acts as a proxy for such a dictionary in a [Document]. Once
/// you've loaded a document and located the [FLDict] holding the blob reference, call
/// [Blob.fromValue] on it to create a [Blob] object.
/// The object has accessors for the blob's metadata and for loading the data itself.
///
/// To create a new blob from in-memory data, call [Blob.createWithData],
///
/// To create a new blob from a stream, call [Blob.createWithStream].
///
/// Once you have a blob created add the properties of the Blob to the document
/// (or to a dictionary or array property of the document.) and save the document.
///
///Example:
/// ```dart
/// var file = File('D:/blobtest.png');
/// var data = file.readAsBytesSync();
/// var blob = Blob.createWithData('image/png', data);
///
/// //or
/// var stream = file.openRead().cast<Uint8List>();
/// blob = await Blob.createWithStream(db, 'image/png', stream);
///
/// doc = db.getMutableDocument('testdoc');
/// doc.properties['logo'] = blob.properties;
/// db.saveDocument(doc);
/// ```
class Blob {
  Pointer<cbl.CBLBlob> pointer = nullptr;
  Pointer<cbl.CBLBlobWriteStream>? _blobStream;

  Blob.empty();
  bool get isEmpty => pointer == nullptr;

  Blob._internal(this.pointer, [this._blobStream]);

  /// Creates a new blob given its contents as a single block of data.
  Blob.createWithData(String contentType, Uint8List data) {
    final error = calloc<cbl.CBLError>();

    var buf = calloc<Uint8>(data.length);
    var list = buf.asTypedList(data.length);
    list.setAll(0, data);

    var slice = calloc<cbl.FLSlice>();

    slice.ref.buf = buf.cast();
    slice.ref.size = data.length;

    final _c_contentType = FLSlice.fromString(contentType);

    pointer = CBLC.CBLBlob_CreateWithData(
      _c_contentType.slice.ref,
      slice.ref,
    );

    _c_contentType.free();
    validateError(error);
  }

  /// Creates a new blob using data from the stream. Returns a future that will
  /// complete with a new [Blob] instance when the stream is closed or with
  /// a [CouchbaseLiteException] in case of error.
  static Future<Blob> createWithStream(
      Database db, String contentType, Stream<Uint8List> stream) async {
    final result = Completer<Blob>();

    final error = calloc<cbl.CBLError>();
    Pointer<cbl.CBLBlobWriteStream> _blobStream;
    try {
      _blobStream = CBLC.CBLBlobWriter_Create(db._db, error);
      validateError(error);
    } on CouchbaseLiteException catch (e) {
      result.completeError(e);
      return result.future;
    }

    stream.listen(
      (data) {
        error.ref
          ..code = 0
          ..domain = 0;
        ;

        var buf = calloc<Uint8>(data.length);
        var list = buf.asTypedList(data.length);
        list.setAll(0, data);

        CBLC.CBLBlobWriter_Write(_blobStream, buf.cast(), list.length, error);
        calloc.free(buf);
      },
      onDone: () {
        final _c_contentType = FLSlice.fromString(contentType);
        final blob = result.complete(
          Blob._internal(
            CBLC.CBLBlob_CreateWithStream(
                _c_contentType.slice.ref, _blobStream),
            _blobStream,
          ),
        );
        _c_contentType.free();
        return blob;
      },
      onError: (error) {
        CBLC.CBLBlobWriter_Close(_blobStream);
        result.completeError(CouchbaseLiteException(
          cbl.kCBLDomain,
          cbl.kCBLErrorNotFound,
          'Error writing blob from stream',
        ));
      },
      cancelOnError: true,
    );

    return result.future;
  }

  /// Create a [Blob] object corresponding to a blob dictionary in a document.
  factory Blob.fromValue(FLDict dict) {
    if (dict.ref == nullptr ||
        dict['@type'].asString.isEmpty ||
        dict['@type'].asString != 'blob') return Blob.empty();

    print(dict.ref);
    print(dict.json);
    print(CBLC.FLDict_GetBlob(dict.ref));
    print(CBLC.FLDict_IsBlob(dict.ref));

    return Blob._internal(CBLC.FLDict_GetBlob(dict.ref));
  }

  Uint8List? _content;

  /// A blob's MIME type, if its metadata has a `content_type` property.
  String get contentType => CBLC.CBLBlob_ContentType(pointer).asString();

  /// Returns the cryptographic digest of a blob's content (from its `digest` property).
  String get digest => CBLC.CBLBlob_Digest(pointer).asString();

  /// Returns the length in bytes of a blob's content (from its `length` property).
  int get length => CBLC.CBLBlob_Length(pointer);

  /// Convenience method to return the properties as a Dart map
  Map<String, dynamic> get asMap => jsonDecode(properties.json);

  /// Returns a blob's metadata. This includes the `digest`, `length` and `content_type`
  /// properties, as well as any custom ones that may have been added.
  FLDict get properties => pointer != nullptr
      ? FLDict.fromPointer(CBLC.CBLBlob_Properties(pointer))
      : FLDict.empty();

  /// Read a blob's content as a stream.
  Stream<Uint8List> getContentStream({int chunk = 10240}) async* {
    print(pointer);
    final error = calloc<cbl.CBLError>();
    final blobStream = CBLC.CBLBlob_OpenContentStream(pointer, error);

    print(pointer);

    if (error.ref.domain != 0) {
      calloc.free(error);
      return;
    }

    // We don't want to accidentally allocate gigs of memory
    chunk = max(0, min(chunk, 100240));

    var count = 0;
    do {
      error.ref
        ..code = 0
        ..domain = 0;
      final data = calloc<Uint8>(chunk);
      count = CBLC.CBLBlobReader_Read(blobStream, data.cast(), chunk, error);

      if (count > 0) {
        yield data.asTypedList(count);
      }
      calloc.free(data);
    } while (count > 0);

    CBLC.CBLBlobReader_Close(blobStream);
    // pfree(data);
    calloc.free(error);
  }

  void closeStream() => CBLC.CBLBlobWriter_Close(_blobStream!);

  /// Reads the blob's contents into memory and returns them.
  Future<Uint8List> getContent() async {
    if (_content != null) return _content!;

    _content = Uint8List(0);

    await for (var value in getContentStream()) {
      final _tmp = Uint8List(_content!.length + value.length);

      _tmp.setAll(0, _content!);
      _tmp.setAll(_content!.length, value);
      _content = _tmp;
    }
    return _content!;
  }
}
