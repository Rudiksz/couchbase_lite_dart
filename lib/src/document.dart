// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

///  A Document is essentially a JSON object with an ID string that's unique
///  in its database.
class Document {
  Database? db;

  bool _new = false;

  String get ID => _ID;
  String _ID = '';

  FLDict? _properties;

  FLDict get properties =>
      _properties ??= FLDict.fromPointer(CBLC.CBLDocument_Properties(_doc));
  set properties(FLDict props) {
    CBLC.CBLDocument_SetProperties(_doc, props._value);
    _properties = null;
  }

  /// Pointer to the C object backing this document
  Pointer<cbl.CBLDocument> _doc = nullptr;

  /// Creates a document from a C pointer
  Document._fromPointer(this._doc, {this.db}) {
    _ID = CBLC.CBLDocument_ID(_doc).cast<Utf8>().toDartString();
  }

  /// The empty value. Use it to initialize non-nullable variables that you
  /// later want to set. All operations are noop.
  ///
  /// Application logic should use [isEmpty] or [isNotEmpty] in place of null checks.
  Document.empty();
  bool get isEmpty => _doc == nullptr || ID.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Creates a new document in memory. It will not be added to a database until saved.
  ///
  /// [Data] can be an [FLDict], JSON encodable [Map] or a JSON encoded [String]
  Document(
    this._ID, {
    dynamic data,
    this.db,
  }) {
    assert(ID.isNotEmpty, 'Document ID cannot be empty.');
    final _c_id = ID.toNativeUtf8();
    _doc = CBLC.CBLDocument_New(_c_id.cast());
    calloc.free(_c_id);

    _new = true;

    if (data is FLDict) {
      properties = data;
    } else if (data is Map) {
      map = data;
    } else if (data is String) {
      json = data;
    }
  }

  /// Returns the properties as JSON string.
  ///
  /// The same as `properties.json`
  String get json {
    final _c_json = CBLC.CBLDocument_PropertiesAsJSON(_doc);
    final _json = _c_json.cast<Utf8>().toDartString();
    calloc.free(_c_json);
    return _json;
  }

  /// Set properties using a JSON string.
  ///
  /// Throws a [DatabaseError] in case of invalid JSON.
  set json(String json) {
    assert(!disposed, 'Documents cannot be used after beeing disposed.');
    if (disposed) return;
    final error = calloc<cbl.CBLError>();

    final _c_json = json.toNativeUtf8();

    CBLC.CBLDocument_SetPropertiesAsJSON(
      _doc,
      _c_json.cast(),
      error,
    );
    calloc.free(_c_json);

    validateError(error);
  }

  /// Get the properties as a map.
  Map<dynamic, dynamic> get map => jsonDecode(json);

  /// Set properties using a JSON encodable value.
  ///
  /// Throws a [DatabaseError] in case of invalid JSON.
  set map(Map<dynamic, dynamic> data) => json = jsonEncode(data);

  /// Saves the document.
  ///
  /// If a conflicting revision has been saved since [document] was loaded, the [concurrency]
  /// parameter specifies whether the save should fail, or the conflicting revision should
  /// be overwritten with the revision being saved.
  ///
  /// If you need finer-grained control, call [saveResolving] instead.
  /// Returns an updated Document reflecting the saved changes, or null on failure.
  ///
  /// If the document doesn't belong to any database, it's a noop
  Document save() {
    assert(db != null, 'This document doesn\'t belong to any database');
    assert(!disposed, 'Documents cannot be used after beeing disposed.');
    if (disposed) return Document.empty();
    return db?.saveDocument(this) ?? Document.empty();
  }

  /// Saves the document. This function is the same as
  /// [saveDocument], except that it allows for custom conflict handling
  /// in the event that the document has been updated since [doc] was loaded.
  ///
  /// The handler should return true to overwrite the existing document, or false
  /// to cancel the save. If the handler rejects the save a [CouchbaseLiteException] will be thrown.
  ///
  /// If the document doesn't belong to any database, it's a noop
  Document saveResolving(SaveConflictHandler conflictHandler) {
    assert(db != null, 'This document doesn\'t belong to any database');
    assert(!disposed, 'Documents cannot be used after beeing disposed.');
    if (disposed) return Document.empty();
    return db?.saveDocumentResolving(this, conflictHandler) ?? Document.empty();
  }

  ///  The time, if any, at which the document will expire and be purged.
  ///
  ///  Documents don't normally expire; you have to call [setDocumentExpiration]
  ///  to set a document's expiration time.
  ///
  /// Throws [CouchbaseLiteException] if the call failed.
  ///
  /// If the document doesn't belong to any database, it's a noop
  DateTime get expiration {
    assert(db != null, 'This document doesn\'t belong to any database');
    assert(!disposed, 'Documents cannot be used after beeing disposed.');
    if (disposed) return DateTime(0);
    return db?.documentExpiration(ID) ?? DateTime(0);
  }

  /// Sets or clears the [expiration] time of the document.
  ///
  /// Set [expiration] as null if the document should never expire
  ///
  /// Throws [CouchbaseLiteException] if the call failed.
  ///
  /// If the document doesn't belong to any database, it's a noop
  set expiration(DateTime expiration) {
    assert(db != null, 'This document doesn\'t belong to any database');
    assert(!disposed, 'Documents cannot be used after beeing disposed.');
    if (disposed) return;
    db?.setDocumentExpiration(ID, expiration);
  }

  ///  Deletes a document from the database using [ConcurrencyControl]. Deletions are replicated.
  ///
  ///  Returns true if the document was deleted, throws [CouchbaseLiteException] if an error occurred.
  bool delete(
      {ConcurrencyControl concurrency = ConcurrencyControl.lastWriteWins}) {
    assert(!disposed, 'Documents cannot be used after beeing disposed.');
    if (disposed) return false;
    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDocument_Delete(
      _doc,
      concurrency.index,
      error,
    );

    validateError(error);
    return result;
  }

  ///  Purges a document. This removes all traces of the document from the database.
  ///
  ///  Purges are _not_ replicated. If the document is changed on a server, it will be re-created when pulled.
  ///
  ///  If you don't have the document in memory already, [Database.purgeDocument] is a simpler shortcut.
  ///
  ///  Returns true if the document was purged, false if it doesn't exists and throws [CouchbaseLiteException] if the purge failed.
  bool purge() {
    assert(!disposed, 'Documents cannot be used after beeing disposed.');
    if (disposed) return false;
    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDocument_Purge(_doc, error);

    validateError(error);
    return result;
  }

  /// Creates a new mutable cblc.CBLDocument instance that refers to the same document as the original.
  ///
  /// If the original document has unsaved changes, the new one will also start out with the same
  /// changes; but mutating one document thereafter will not affect the other.
  Document get mutableCopy {
    assert(!disposed, 'Documents cannot be used after beeing disposed.');
    if (disposed) return Document.empty();

    final result = CBLC.CBLDocument_MutableCopy(_doc);

    if (result == nullptr) {
      return Document.empty();
    }

    final mutDoc = Document._fromPointer(result, db: db);
    // !Fix for (https://github.com/couchbaselabs/couchbase-lite-C/issues/88)
    mutDoc.properties = mutDoc.properties.mutableCopy;
    return mutDoc;
  }

  bool get disposed => _doc == nullptr;
  void dispose() {
    CBLC.CBL_Release(_doc.cast());
    _doc = nullptr;
  }
}
