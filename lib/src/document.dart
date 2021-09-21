// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

///  A Document is essentially a JSON object with an ID string that's unique
///  in its database.
class Document {
  bool _new = false;

  String get ID => _ID;
  String _ID = '';

  /// Returns a document's properties as a dictionary.
  ///
  /// This dictionary _reference_ is immutable, but if the document is mutable the
  /// underlying dictionary itself is mutable. You can obtain a mutable
  /// reference via [Document.mutableCopy].
  FLDict get properties =>
      FLDict.fromPointer(CBLC.CBLDocument_Properties(_doc));
  set properties(FLDict props) =>
      CBLC.CBLDocument_SetProperties(_doc, props._value);

  /// Pointer to the C object backing this document
  Pointer<cbl.CBLDocument> _doc = nullptr;
  Pointer<cbl.CBLDocument> get doc => _doc;

  Document.empty();
  bool get isEmpty => _doc == nullptr || ID.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Creates a document from a C pointer
  Document.fromPointer(this._doc) {
    if (_doc != nullptr) {
      final _c_id = CBLC.CBLDocument_ID(_doc);
      _ID = _c_id.asString();
/*
      final _c_rev = FLSlice.fromSlice(CBLC.CBLDocument_RevisionID(_doc));
      revisionID = _c_rev.toString();
      _c_rev.free();

      sequence = CBLC.CBLDocument_Sequence(_doc);
*/
    }
  }

  /// Creates a new, empty document in memory. It will not be added to a
  /// database until saved.
  ///
  /// [Data] can be an [FLDict], JSON encodable [Map] or a JSON encoded [String]
  Document(this._ID, {dynamic data}) {
    assert(ID.isNotEmpty, 'Document ID cannot be empty.');
    final _c_id = FLSlice.fromString(ID);
    _doc = CBLC.CBLDocument_CreateWithID(_c_id.slice.ref);
    _c_id.free();

    _new = true;

    if (data is FLDict) {
      properties = data;
    } else if (data is Map) {
      map = data;
    } else if (data is String) {
      json = data;
    }
  }

  factory Document.fromJson({
    required String id,
    required String json,
  }) =>
      Document(id, data: json);

  factory Document.fromMap({
    required String id,
    required Map map,
  }) =>
      Document(id, data: map);

  /// Returns the properties as JSON string.
  ///
  /// The same as `properties.json`
  String get json {
    if (isEmpty) return '';
    final _c_json = CBLC.CBLDocument_CreateJSON(_doc);
    final _json = _c_json.asString();
    _c_json.free();
    return _json;
  }

  /// Set properties using a JSON string.
  ///
  /// Throws a [DatabaseError] in case of invalid JSON.
  set json(String json) {
    assert(isNotEmpty, 'Documents cannot be used after beeing disposed.');
    if (isEmpty) return;
    final error = calloc<cbl.CBLError>();
    final _c_json = FLSlice.fromString(json);

    CBLC.CBLDocument_SetJSON(_doc, _c_json.slice.ref, error);
    _c_json.free();
    validateError(error);
  }

  /// Get the properties as a map.
  Map<dynamic, dynamic> get map => jsonDecode(json);

  /// Set properties using a JSON encodable value.
  ///
  /// Throws a [DatabaseError] in case of invalid JSON.
  set map(Map<dynamic, dynamic> data) => json = jsonEncode(data);

  /// Creates a new mutable cblc.CBLDocument instance that refers to the same document as the original.
  ///
  /// If the original document has unsaved changes, the new one will also start out with the same
  /// changes; but mutating one document thereafter will not affect the other.
  Document get mutableCopy {
    assert(isNotEmpty, 'Documents cannot be used after beeing disposed.');
    if (isEmpty) return Document.empty();

    final mutDoc = Document.fromPointer(CBLC.CBLDocument_MutableCopy(_doc));

    // !Fix for (https://github.com/couchbaselabs/couchbase-lite-C/issues/88)
    if (mutDoc.isNotEmpty) {
      final mutProps = mutDoc.properties.mutableCopy;
      mutDoc.properties = mutProps;
      mutProps.dispose();
    }

    return mutDoc;
  }

  void dispose() {
    CBLC.CBL_Release(_doc.cast());
    _doc = nullptr;
  }
}
