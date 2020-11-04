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
  ffi.Pointer<cbl.CBLDocument> _doc;
  ffi.Pointer<cbl.CBLDocument> get doc => _doc;

  FLDict _properties;

  /// Creates a document from a C pointer
  Document._internal(this._doc) {
    if (_doc != ffi.nullptr) {
      final id = cbl.CBLDocument_ID(_doc);
      ID = pffi.Utf8.fromUtf8(id.cast());

      final rev = cbl.CBLDocument_RevisionID(_doc);
      revisionID = pffi.Utf8.fromUtf8(rev.cast());

      sequence = cbl.CBLDocument_Sequence(_doc);

      _properties = FLDict.fromPointer(cbl.CBLDocument_Properties(_doc));
    }
  }

  /// Creates a new, empty document in memory. It will not be added to a
  /// database until saved.
  ///
  /// [Data] can be any JSON encodable object
  Document(this.ID, {dynamic data}) {
    assert(ID?.isNotEmpty ?? true, 'Document ID cannot be empty.');
    _doc = cbl.CBLDocument_New(pffi.Utf8.toUtf8(ID).cast());
    if (data != null) {
      jsonProperties = data;
    }
  }

  /// Returns a document's properties as a dictionary.
  ///
  /// This dictionary _reference_ is immutable, but if the document is mutable the
  /// underlying dictionary itself is mutable. You can obtain a mutable
  /// reference via [Document.mutableCopy].
  FLDict get properties => _properties;
  set properties(FLDict props) {
    cbl.CBLDocument_SetProperties(_doc, props._value);
    _properties = props;
  }

  /// Returns the properties as JSON encoded
  Map<dynamic, dynamic> get jsonProperties {
    if (_doc == ffi.nullptr) return {};

    final result = cbl.CBLDocument_PropertiesAsJSON(_doc);
    return jsonDecode(cbl.utf8ToStr(result));
  }

  /// Set properties using a JSON string.
  ///
  /// Throws a [DatabaseError] in case of invalid JSON.
  set jsonProperties(Map<dynamic, dynamic> data) {
    final error = cbl.CBLError.allocate();

    cbl.CBLDocument_SetPropertiesAsJSON(
      _doc,
      cbl.strToUtf8(jsonEncode(data)),
      error.addressOf,
    );

    validateError(error);

    _properties = FLDict.fromPointer(cbl.CBLDocument_Properties(_doc));
  }

  ///  Deletes a document from the database using [ConcurrencyControl]. Deletions are replicated.
  ///
  ///  Returns true if the document was deleted, throws [CouchbaseLiteException] if an error occurred.
  bool delete(
      {ConcurrencyControl concurrency = ConcurrencyControl.lastWriteWins}) {
    if (_doc.address == ffi.nullptr.address) return false;
    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDocument_Delete(
      _doc,
      concurrency.index,
      error.addressOf,
    );

    validateError(error);
    return result != 0;
  }

  ///  Purges a document. This removes all traces of the document from the database.
  ///
  ///  Purges are _not_ replicated. If the document is changed on a server, it will be re-created when pulled.
  ///
  ///  If you don't have the document in memory already, [Database.purgeDocument] is a simpler shortcut.
  ///
  ///  Returns true if the document was purged, false if it doesn't exists and throws [CouchbaseLiteException] if the purge failed.
  bool purge() {
    if (_doc.address == ffi.nullptr.address) return false;
    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDocument_Purge(_doc, error.addressOf);

    validateError(error);
    return result != 0;
  }

  /// Creates a new mutable cbl.CBLDocument instance that refers to the same document as the original.
  ///
  /// If the original document has unsaved changes, the new one will also start out with the same
  /// changes; but mutating one document thereafter will not affect the other.
  Document get mutableCopy {
    final result = cbl.CBLDocument_MutableCopy(_doc);

    return result != ffi.nullptr ? Document._internal(result) : null;
  }
}
