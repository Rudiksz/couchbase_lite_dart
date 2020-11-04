// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_c_bindings;

// -- Data types

class CBLDocument extends ffi.Struct {}

/// Returns a document's ID.
final CBLDocument_ID = _dylib
    .lookupFunction<_c_CBLDocument_ID, _dart_CBLDocument_ID>('CBLDocument_ID');

/// Returns a document's revision ID, which is a short opaque string that's guaranteed to be
/// unique to every change made to the document.
/// If the document doesn't exist yet, this function returns NULL.
final CBLDocument_RevisionID = _dylib.lookupFunction<_c_CBLDocument_RevisionID,
    _dart_CBLDocument_RevisionID>('CBLDocument_RevisionID');

/// Returns a document's current sequence in the local database.
/// This number increases every time the document is saved, and a more recently saved document
/// will have a greater sequence number than one saved earlier, so sequences may be used as an
/// abstract 'clock' to tell relative modification times.
final CBLDocument_Sequence =
    _dylib.lookupFunction<_c_CBLDocument_Sequence, _dart_CBLDocument_Sequence>(
        'CBLDocument_Sequence');

/// Creates a new, empty document in memory. It will not be added to a database until saved.
final CBLDocument_New =
    _dylib.lookupFunction<_c_CBLDocument_New, _dart_CBLDocument_New>(
        'CBLDocument_New');

/// Creates a new mutable CBLDocument instance that refers to the same document as the original.
/// If the original document has unsaved changes, the new one will also start out with the same
/// changes; but mutating one document thereafter will not affect the other.
///
///   You must release the new reference when you're done with it.
final CBLDocument_MutableCopy = _dylib.lookupFunction<
    _c_CBLDocument_MutableCopy,
    _dart_CBLDocument_MutableCopy>('CBLDocument_MutableCopy');

/// Deletes a document from the database. Deletions are replicated.
///
/// You are still responsible for releasing the CBLDocument.
final CBLDocument_Delete =
    _dylib.lookupFunction<_c_CBLDocument_Delete, _dart_CBLDocument_Delete>(
        'CBLDocument_Delete');

/// Purges a document. This removes all traces of the document from the database.
/// Purges are _not_ replicated. If the document is changed on a server, it will be re-created
/// when pulled.
///
/// @warning  You are still responsible for releasing the [CBLDocument] reference.
///
/// If you don't have the document in memory already, [CBLDatabase_PurgeDocumentByID] is a
/// simpler shortcut.
final CBLDocument_Purge =
    _dylib.lookupFunction<_c_CBLDocument_Purge, _dart_CBLDocument_Purge>(
        'CBLDocument_Purge');

/// Returns a document's properties.
final CBLDocument_Properties = _dylib.lookupFunction<_c_CBLDocument_Properties,
    _dart_CBLDocument_Properties>('CBLDocument_Properties');

/// Set a document's properties.
final CBLDocument_SetProperties = _dylib.lookupFunction<
    _c_CBLDocument_SetProperties,
    _dart_CBLDocument_SetProperties>('CBLDocument_SetProperties');

/// Returns a document's properties as a null-terminated JSON string.
///
/// You are responsible for calling `free()` on the returned string.
final CBLDocument_PropertiesAsJSON = _dylib.lookupFunction<
    _c_CBLDocument_PropertiesAsJSON,
    _dart_CBLDocument_PropertiesAsJSON>('CBLDocument_PropertiesAsJSON');

/// Sets a mutable document's properties from a JSON string.
final CBLDocument_SetPropertiesAsJSON = _dylib.lookupFunction<
    _c_CBLDocument_SetPropertiesAsJSON,
    _dart_CBLDocument_SetPropertiesAsJSON>('CBLDocument_SetPropertiesAsJSON');

// -- Function types

typedef _c_CBLDocument_ID = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLDocument> arg0,
);

typedef _dart_CBLDocument_ID = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLDocument> arg0,
);

typedef _c_CBLDocument_RevisionID = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLDocument> arg0,
);

typedef _dart_CBLDocument_RevisionID = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLDocument> arg0,
);

typedef _c_CBLDocument_Sequence = ffi.Uint64 Function(
  ffi.Pointer<CBLDocument> arg0,
);

typedef _dart_CBLDocument_Sequence = int Function(
  ffi.Pointer<CBLDocument> arg0,
);

typedef _c_CBLDocument_New = ffi.Pointer<CBLDocument> Function(
  ffi.Pointer<ffi.Int8> docID,
);

typedef _dart_CBLDocument_New = ffi.Pointer<CBLDocument> Function(
  ffi.Pointer<ffi.Int8> docID,
);

typedef _c_CBLDocument_Delete = ffi.Uint8 Function(
  ffi.Pointer<CBLDocument> document,
  ffi.Uint8 concurrency,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDocument_Delete = int Function(
  ffi.Pointer<CBLDocument> document,
  int concurrency,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDocument_Purge = ffi.Uint8 Function(
  ffi.Pointer<CBLDocument> document,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDocument_Purge = int Function(
  ffi.Pointer<CBLDocument> document,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDocument_MutableCopy = ffi.Pointer<CBLDocument> Function(
  ffi.Pointer<CBLDocument> original,
);

typedef _dart_CBLDocument_MutableCopy = ffi.Pointer<CBLDocument> Function(
  ffi.Pointer<CBLDocument> original,
);

typedef _c_CBLDocument_Properties = ffi.Pointer<FLDict> Function(
  ffi.Pointer<CBLDocument> doc,
);

typedef _dart_CBLDocument_Properties = ffi.Pointer<FLDict> Function(
  ffi.Pointer<CBLDocument> doc,
);

typedef _c_CBLDocument_SetProperties = ffi.Void Function(
  ffi.Pointer<CBLDocument> doc,
  ffi.Pointer<FLDict> properties,
);

typedef _dart_CBLDocument_SetProperties = void Function(
  ffi.Pointer<CBLDocument> doc,
  ffi.Pointer<FLDict> properties,
);

typedef _c_CBLDocument_PropertiesAsJSON = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLDocument> doc,
);

typedef _dart_CBLDocument_PropertiesAsJSON = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLDocument> doc,
);

typedef _c_CBLDocument_SetPropertiesAsJSON = ffi.Uint8 Function(
  ffi.Pointer<CBLDocument> doc,
  ffi.Pointer<ffi.Int8> json,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDocument_SetPropertiesAsJSON = int Function(
  ffi.Pointer<CBLDocument> doc,
  ffi.Pointer<ffi.Int8> json,
  ffi.Pointer<CBLError> error,
);
