// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

///  A Document is essentially a JSON object with an ID string that's unique
///  in its database.
class Document {
  String ID;

  /// The revision ID, is a short opaque string that's guaranteed to be
  /// unique to every change made to the document.
  String revisionID;

  /// The document's current sequence in the local database.
  ///
  /// This number increases every time the document is saved, and a more recently saved document
  /// will have a greater sequence number than one saved earlier, so sequences may be used as an
  /// abstract 'clock' to tell relative modification times.
  int sequence;

  /// Internal pointer to the C object
  ffi.Pointer<CBLDocument> _doc;
  ffi.Pointer<CBLDocument> get doc => _doc;

  /// Creates a document from a C pointer
  Document._internal(this._doc) {
    if (_doc != ffi.nullptr) {
      final id = CBLDocument_ID(_doc);
      ID = pffi.Utf8.fromUtf8(id.cast());

      final rev = CBLDocument_RevisionID(_doc);
      revisionID = pffi.Utf8.fromUtf8(rev.cast());

      sequence = CBLDocument_Sequence(_doc);
    }
  }

  /// Creates a new, empty document in memory. It will not be added to a
  /// database until saved.
  ///
  /// [Data] can be any JSON encodable object
  Document(this.ID, {dynamic data}) {
    assert(ID?.isNotEmpty ?? true, 'Document ID cannot be empty.');
    _doc = CBLDocument_New(pffi.Utf8.toUtf8(ID).cast());
    if (data != null) {
      properties = data;
    }
  }

  /// Returns a document's properties as a dictionary.
  ///
  /// This dictionary _reference_ is immutable, but if the document is mutable the
  /// underlying dictionary itself is mutable. You can obtain a mutable
  /// reference via [Document.mutableCopy].
  FLDict get properties {
    if (_doc == ffi.nullptr) return null;

    return FLDict.fromPointer(CBLDocument_Properties(_doc));
  }

  /// Sets properties by encoding [data] using [jsonEncode]
  set properties(dynamic data) => jsonProperties = jsonEncode(data);

  /// Returns the properties as JSON encoded
  String get jsonProperties {
    if (_doc == ffi.nullptr) return '';

    final result = CBLDocument_PropertiesAsJSON(_doc);
    return pffi.Utf8.fromUtf8(result.cast());
  }

  /// Set properties using a JSON string.
  ///
  /// Throws a [DatabaseError] in case of invalid JSON.
  set jsonProperties(String data) {
    final error = pffi.allocate<CBLError>();
    CBLDocument_SetPropertiesAsJSON(
      _doc,
      pffi.Utf8.toUtf8(data).cast(),
      error,
    );

    databaseError(error);
  }

  ///  Deletes a document from the database using [ConcurrencyControl]. Deletions are replicated.
  ///
  ///  Returns true if the document was deleted, throws [DatabaseException] if an error occurred.
  bool delete(
      {ConcurrencyControl concurrency = ConcurrencyControl.lastWriteWins}) {
    if (_doc.address == ffi.nullptr.address) return false;
    final error = pffi.allocate<CBLError>();
    final result = CBLDocument_Delete(_doc, concurrency.index, error);

    databaseError(error);
    return result != 0;
  }

  ///  Purges a document. This removes all traces of the document from the database.
  ///
  ///  Purges are _not_ replicated. If the document is changed on a server, it will be re-created when pulled.
  ///
  ///  If you don't have the document in memory already, [Database.purgeDocument] is a simpler shortcut.
  ///
  ///  Returns true if the document was purged, false if it doesn't exists and throws [DatabaseException] if the purge failed.
  bool purge() {
    if (_doc.address == ffi.nullptr.address) return false;
    final error = pffi.allocate<CBLError>();
    final result = CBLDocument_Purge(_doc, error);

    databaseError(error);
    return result != 0;
  }

  /// Creates a new mutable CBLDocument instance that refers to the same document as the original.
  ///
  /// If the original document has unsaved changes, the new one will also start out with the same
  /// changes; but mutating one document thereafter will not affect the other.
  Document get mutableCopy {
    final result = CBLDocument_MutableCopy(_doc);

    return result != ffi.nullptr ? Document._internal(result) : null;
  }
}
