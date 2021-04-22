// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

///  A Document is essentially a JSON object with an ID string that's unique
///  in its database.
class Document {
  Database? db;

  String ID = '';

  /// The revision ID, is a short opaque string that's guaranteed to be
  /// unique to every change made to the document.
  String revisionID = '';

  /// The document's current sequence in the local database.
  ///
  /// This number increases every time the document is saved, and a more recently saved document
  /// will have a greater sequence number than one saved earlier, so sequences may be used as an
  /// abstract 'clock' to tell relative modification times.
  int sequence = 0;

  bool isMutable = false;

  bool _new = false;

  /// Internal pointer to the C object
  Pointer<cbl.CBLDocument> _doc = nullptr;
  Pointer<cbl.CBLDocument> get doc => _doc;

  FLDict _properties = FLDict.empty();

  Document.empty();
  bool get isEmpty => _doc == nullptr || ID.isEmpty;

  /// Creates a document from a C pointer
  Document.fromPointer(this._doc, {this.isMutable = false, this.db}) {
    if (_doc != nullptr) {
      final id = CBLC.CBLDocument_ID(_doc);
      ID = id.cast<Utf8>().toDartString();

      final rev = CBLC.CBLDocument_RevisionID(_doc);
      revisionID = rev.cast<Utf8>().toDartString();

      sequence = CBLC.CBLDocument_Sequence(_doc);

      _properties = FLDict.fromPointer(CBLC.CBLDocument_Properties(_doc));

      // !Fix for (https://github.com/couchbaselabs/couchbase-lite-C/issues/88)
      if (isMutable) {
        properties = _properties.mutableCopy;
      }
    }
  }

  /// Creates a new, empty document in memory. It will not be added to a
  /// database until saved.
  ///
  /// [Data] can be any JSON encodable object
  Document(
    this.ID, {
    dynamic data,
    this.db,
    this.isMutable = true,
  }) {
    assert(ID.isNotEmpty, 'Document ID cannot be empty.');
    _doc = CBLC.CBLDocument_New(ID.toNativeUtf8().cast());
    _new = true;
    if (data is FLDict) {
      properties = data;
    } else {
      map = (data is String) ? jsonDecode(data) : (data ?? {});
    }
  }

  /// Returns a document's properties as a dictionary.
  ///
  /// This dictionary _reference_ is immutable, but if the document is mutable the
  /// underlying dictionary itself is mutable. You can obtain a mutable
  /// reference via [Document.mutableCopy].
  FLDict get properties => _properties;
  set properties(FLDict props) {
    CBLC.CBLDocument_SetProperties(_doc, props._value);
    _properties = props;
  }

  /// Returns the properties as JSON string.
  ///
  /// The same as `properties.json`
  String get json => _properties.json;

  /// Set properties using a JSON string.
  ///
  /// Throws a [DatabaseError] in case of invalid JSON.
  set json(String json) {
    final error = calloc<cbl.CBLError>();
    ;

    CBLC.CBLDocument_SetPropertiesAsJSON(
      _doc,
      json.toNativeUtf8().cast(),
      error,
    );

    validateError(error);

    _properties = FLDict.fromPointer(CBLC.CBLDocument_Properties(_doc));
  }

  /// Get the properties as a map.
  Map<dynamic, dynamic> get map => jsonDecode(json);

  /// Set properties using a JSON encodable value.
  ///
  /// Throws a [DatabaseError] in case of invalid JSON.
  set map(Map<dynamic, dynamic> data) {
    final error = calloc<cbl.CBLError>();

    CBLC.CBLDocument_SetPropertiesAsJSON(
      _doc,
      jsonEncode(data).toNativeUtf8().cast(),
      error,
    );

    validateError(error);

    _properties = FLDict.fromPointer(CBLC.CBLDocument_Properties(_doc));
  }

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
    db?.setDocumentExpiration(ID, expiration);
  }

  ///  Deletes a document from the database using [ConcurrencyControl]. Deletions are replicated.
  ///
  ///  Returns true if the document was deleted, throws [CouchbaseLiteException] if an error occurred.
  bool delete(
      {ConcurrencyControl concurrency = ConcurrencyControl.lastWriteWins}) {
    if (_doc == nullptr) return false;
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
    if (_doc == nullptr) return false;
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
    final result = CBLC.CBLDocument_MutableCopy(_doc);

    return result != nullptr
        ? Document.fromPointer(result, isMutable: true, db: db)
        : Document('');
  }
}
