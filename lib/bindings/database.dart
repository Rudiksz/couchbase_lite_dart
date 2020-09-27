// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_c;

// --- Data types

class CBLDatabase extends ffi.Struct {}

/// Encryption key specified in a \ref CBLDatabaseConfiguration.
class CBLEncryptionKey extends ffi.Struct {}

/// Database configuration options.
class CBLDatabaseConfiguration extends ffi.Struct {
  /// The parent directory of the database
  ffi.Pointer<ffi.Int8> directory;

  /// Options for opening the database
  @ffi.Uint32()
  int flags;

  /// The database's encryption key (if any)
  ffi.Pointer<CBLEncryptionKey> encryptionKey;
}

/// Types of database indexes.
enum CBLIndexType {
  /// An index that stores property or expression values
  valueIndex,

  /// An index of strings, that enables searching for words with `MATCH`
  fullTextIndex
}

/// Parameters for creating a database index.
class CBLIndexSpec extends ffi.Struct {
  /// The type of index to create.
  @ffi.Uint32()
  int type;

  /// A JSON array describing each column of the index. */
  ffi.Pointer<ffi.Int8> keyExpressionsJSON;

  /// In a full-text index, should diacritical marks (accents) be ignored?
  /// Defaults to false. Generally this should be left `false` for non-English text. */
  @ffi.Uint8()
  int ignoreAccents;

  ///  In a full-text index, the dominant language. Setting this enables word stemming, i.e.
  ///  matching different cases of the same word ("big" and "bigger", for instance) and ignoring
  ///  common "stop-words" ("the", "a", "of", etc.)
  ///  Can be an ISO-639 language code or a lowercase (English) language name; supported
  ///  languages are: da/danish, nl/dutch, en/english, fi/finnish, fr/french, de/german,
  ///  hu/hungarian, it/italian, no/norwegian, pt/portuguese, ro/romanian, ru/russian,
  ///  es/spanish, sv/swedish, tr/turkish.
  ///  If left null,  or set to an unrecognized language, no language-specific behaviors
  ///  such as stemming and stop-word removal occur.
  ffi.Pointer<ffi.Int8> language;
}

// -- Functions

/// Returns true if a database with the given [name] exists in the given [directory].
///
/// If [directory] is null, `name` must be an absolute or relative path to the database.
///
/// The database name should be provided without the ".cblite2" extension.
final CBL_DatabaseExists =
    _dylib.lookupFunction<_c_CBL_DatabaseExists, _dart_CBL_DatabaseExists>(
        'CBL_DatabaseExists');

/// Opens a database, or creates it if it doesn't exist yet, returning a new [CBLDatabase]
/// instance.
///
/// It's OK to open the same database file multiple times. Each [CBLDatabase] instance is
/// independent of the others (and must be separately closed and released.)
///
/// The database name should be provided without the ".cblite2" extension.
final CBLDatabase_Open =
    _dylib.lookupFunction<_c_CBLDatabase_Open, _dart_CBLDatabase_Open>(
        'CBLDatabase_Open');

/// Closes an open database.
final CBLDatabase_Close =
    _dylib.lookupFunction<_c_CBLDatabase_Close, _dart_CBLDatabase_Close>(
        'CBLDatabase_Close');

/// Closes and deletes a database. If there are any other connections to the
/// database, an error is returned.
final CBLDatabase_Delete =
    _dylib.lookupFunction<_c_CBLDatabase_Delete, _dart_CBLDatabase_Delete>(
        'CBLDatabase_Delete');

/// Deletes a database file with the given [name] exists in the given [directory].
///
/// If [directory] is null, `name` must be an absolute or relative path to the database.
///
/// The database name should be provided without the ".cblite2" extension.
///
/// If the database file is open, an error is returned.
/// Returns true if the database was deleted, false if it doesn't exist or deletion failed.
/// (You can tell the last two cases apart by looking at \p outError.)
final CBL_DeleteDatabase =
    _dylib.lookupFunction<_c_CBL_DeleteDatabase, _dart_CBL_DeleteDatabase>(
        'CBL_DeleteDatabase');

/// Copies a database file to a new location, and assigns it a new internal UUID to distinguish
/// it from the original database when replicating.
///
/// The source path is the full filesystem path to the original database (including extension).
///
/// The [toName]  is the new database name (without the ".cblite2" extension.)
final CBL_CopyDatabase =
    _dylib.lookupFunction<_c_CBL_CopyDatabase, _dart_CBL_CopyDatabase>(
        'CBL_CopyDatabase');

/// Compacts a database file.
final CBLDatabase_Compact =
    _dylib.lookupFunction<_c_CBLDatabase_Compact, _dart_CBLDatabase_Compact>(
        'CBLDatabase_Compact');

/// Returns the database's full filesystem path.
final CBLDatabase_Path =
    _dylib.lookupFunction<_c_CBLDatabase_Path, _dart_CBLDatabase_Path>(
        'CBLDatabase_Path');

/// Returns the number of documents in the database.
final CBLDatabase_Count =
    _dylib.lookupFunction<_c_CBLDatabase_Count, _dart_CBLDatabase_Count>(
        'CBLDatabase_Count');

/// Begins a batch operation, similar to a transaction. You **must** later call
/// [CBLDatabase_EndBatch] to end (commit) the batch.
///
/// - Multiple writes are much faster when grouped inside a single batch.
/// -  Changes will not be visible to other CBLDatabase instances on the same database until
/// the batch operation ends.
/// -  Batch operations can nest. Changes are not committed until the outer batch ends.
final CBLDatabase_BeginBatch = _dylib.lookupFunction<_c_CBLDatabase_BeginBatch,
    _dart_CBLDatabase_BeginBatch>('CBLDatabase_BeginBatch');

/// Ends a batch operation. This **must** be called after [CBLDatabase_BeginBatch].
final CBLDatabase_EndBatch =
    _dylib.lookupFunction<_c_CBLDatabase_EndBatch, _dart_CBLDatabase_EndBatch>(
        'CBLDatabase_EndBatch');

/// Reads a document from the [database], creating a new (immutable) [CBLDocument] object.
///  Each call to this function creates a new object (which must later be released.)
///
/// If you are reading the document in order to make changes to it, call
/// [CBLDatabase_GetMutableDocument] instead.
final CBLDatabase_GetDocument = _dylib.lookupFunction<
    _c_CBLDatabase_GetDocument,
    _dart_CBLDatabase_GetDocument>('CBLDatabase_GetDocument');

/// Reads a document from the database, in mutable form that can be updated and saved.
/// This function is otherwise identical to [CBLDatabase_GetDocument].
///
/// You must release the document when you're done with it.
final CBLDatabase_GetMutableDocument = _dylib.lookupFunction<
    _c_CBLDatabase_GetMutableDocument,
    _dart_CBLDatabase_GetMutableDocument>('CBLDatabase_GetMutableDocument');

/// Saves a (mutable) document to the database.
///
/// If a conflicting revision has been saved since the [doc] was loaded, the [concurrency]
/// parameter specifies whether the save should fail, or the conflicting revision should
/// be overwritten with the revision being saved.
///
/// If you need finer-grained control, call [CBLDatabase_SaveDocumentResolving] instead.
///
/// Returns an updated document reflecting the saved changes, or NULL on failure.
final CBLDatabase_SaveDocument = _dylib.lookupFunction<
    _c_CBLDatabase_SaveDocument,
    _dart_CBLDatabase_SaveDocument>('CBLDatabase_SaveDocument');

/// Saves a (mutable) document to the database. This function is the same as
/// [CBLDatabase_SaveDocument], except that it allows for custom conflict handling
/// in the event that the document has been updated since [doc] was loaded.
final CBLDatabase_SaveDocumentResolving = _dylib.lookupFunction<
        _c_CBLDatabase_SaveDocumentResolving,
        _dart_CBLDatabase_SaveDocumentResolving>(
    'CBLDatabase_SaveDocumentResolving');

/// Purges a document, given only its ID.
///
/// If no document with that ID exists, this function will return false but the error
/// code will be zero.
///
/// Returns `true` if the document was purged, `false` if it doesn't exist or the purge failed.
final CBLDatabase_PurgeDocumentByID = _dylib.lookupFunction<
    _c_CBLDatabase_PurgeDocumentByID,
    _dart_CBLDatabase_PurgeDocumentByID>('CBLDatabase_PurgeDocumentByID');

/// Returns the time, if any, at which a given document will expire and be purged.
///
/// Documents don't normally expire; you have to call [CBLDatabase_SetDocumentExpiration]
/// to set a document's expiration time.
///
/// Returns the expiration time as a CBLTimestamp (milliseconds since Unix epoch),
/// or 0 if the document does not have an expiration,
/// or -1 if the call failed.
final CBLDatabase_GetDocumentExpiration = _dylib.lookupFunction<
        _c_CBLDatabase_GetDocumentExpiration,
        _dart_CBLDatabase_GetDocumentExpiration>(
    'CBLDatabase_GetDocumentExpiration');

/// Sets or clears the expiration time of a document.
/// The [expiration] time is a CBLTimestamp (milliseconds since Unix epoch),
/// or 0 if the document should never expire.
final CBLDatabase_SetDocumentExpiration = _dylib.lookupFunction<
        _c_CBLDatabase_SetDocumentExpiration,
        _dart_CBLDatabase_SetDocumentExpiration>(
    'CBLDatabase_SetDocumentExpiration');

/// Registers a database change listener callback. It will be called after one or more
/// documents are changed on disk.
final CBLDatabase_AddChangeListener = _dylib.lookupFunction<
    _c_CBLDatabase_AddChangeListener,
    _dart_CBLDatabase_AddChangeListener>('CBLDatabase_AddChangeListener');

/// Registers a document change listener callback. It will be called after a specific document
/// is changed on disk.
final CBLDatabase_AddDocumentChangeListener = _dylib.lookupFunction<
        _c_CBLDatabase_AddDocumentChangeListener,
        _dart_CBLDatabase_AddDocumentChangeListener>(
    'CBLDatabase_AddDocumentChangeListener');

/// Switches the database to buffered-notification mode. Notifications for objects belonging
/// to this database (documents, queries, replicators, and of course the database) will not be
/// called immediately; your [CBLNotificationsReadyCallback] will be called instead.
final CBLDatabase_BufferNotifications = _dylib.lookupFunction<
    _c_CBLDatabase_BufferNotifications,
    _dart_CBLDatabase_BufferNotifications>('CBLDatabase_BufferNotifications');

/// Immediately issues all pending notifications for this database, by calling their listener
/// callbacks.
final CBLDatabase_SendNotifications = _dylib.lookupFunction<
    _c_CBLDatabase_SendNotifications,
    _dart_CBLDatabase_SendNotifications>('CBLDatabase_SendNotifications');

// -- Database indexes

/// Creates a database index.
///
/// Indexes are persistent.
/// If an identical index with that name already exists, nothing happens (and no error is returned.)
/// If a non-identical index with that name already exists, it is deleted and re-created.
final CBLDatabase_CreateIndex = _dylib.lookupFunction<
    _c_CBLDatabase_CreateIndex,
    _dart_CBLDatabase_CreateIndex>('CBLDatabase_CreateIndex');

/// Deletes an index given its name.
final CBLDatabase_DeleteIndex = _dylib.lookupFunction<
    _c_CBLDatabase_DeleteIndex,
    _dart_CBLDatabase_DeleteIndex>('CBLDatabase_DeleteIndex');

/// Returns the names of the indexes on this database, as a Fleece array of strings.
final CBLDatabase_IndexNames = _dylib.lookupFunction<_c_CBLDatabase_IndexNames,
    _dart_CBLDatabase_IndexNames>('CBLDatabase_IndexNames');

// --- Function types

typedef _c_CBL_DatabaseExists = ffi.Uint8 Function(
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<ffi.Int8> inDirectory,
);

typedef _dart_CBL_DatabaseExists = int Function(
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<ffi.Int8> inDirectory,
);

typedef _c_CBLDatabase_Open = ffi.Pointer<CBLDatabase> Function(
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<CBLDatabaseConfiguration> config,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_Open = ffi.Pointer<CBLDatabase> Function(
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<CBLDatabaseConfiguration> config,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_Close = ffi.Uint8 Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_Close = int Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_Delete = ffi.Uint8 Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_Delete = int Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBL_DeleteDatabase = ffi.Uint8 Function(
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<ffi.Int8> inDirectory,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBL_DeleteDatabase = int Function(
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<ffi.Int8> inDirectory,
  ffi.Pointer<CBLError> outError,
);

typedef _c_CBL_CopyDatabase = ffi.Uint8 Function(
  ffi.Pointer<ffi.Int8> fromPath,
  ffi.Pointer<ffi.Int8> toName,
  ffi.Pointer<CBLDatabaseConfiguration> config,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBL_CopyDatabase = int Function(
  ffi.Pointer<ffi.Int8> fromPath,
  ffi.Pointer<ffi.Int8> toName,
  ffi.Pointer<CBLDatabaseConfiguration> config,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_Compact = ffi.Uint8 Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_Compact = int Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_Path = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLDatabase> db,
);

typedef _dart_CBLDatabase_Path = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLDatabase> db,
);

typedef _c_CBLDatabase_Count = ffi.Uint64 Function(ffi.Pointer<CBLDatabase> db);

typedef _dart_CBLDatabase_Count = int Function(ffi.Pointer<CBLDatabase> db);

typedef _c_CBLDatabase_BeginBatch = ffi.Uint8 Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_BeginBatch = int Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_EndBatch = ffi.Uint8 Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_EndBatch = int Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_GetDocument = ffi.Pointer<CBLDocument> Function(
  ffi.Pointer<CBLDatabase> database,
  ffi.Pointer<ffi.Int8> docID,
);

typedef _dart_CBLDatabase_GetDocument = ffi.Pointer<CBLDocument> Function(
  ffi.Pointer<CBLDatabase> database,
  ffi.Pointer<ffi.Int8> docID,
);

typedef _c_CBLDatabase_GetMutableDocument = ffi.Pointer<CBLDocument> Function(
  ffi.Pointer<CBLDatabase> database,
  ffi.Pointer<ffi.Int8> docID,
);

typedef _dart_CBLDatabase_GetMutableDocument = ffi.Pointer<CBLDocument>
    Function(
  ffi.Pointer<CBLDatabase> database,
  ffi.Pointer<ffi.Int8> docID,
);

typedef _c_CBLDatabase_SaveDocument = ffi.Pointer<CBLDocument> Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLDocument> doc,
  ffi.Uint8 concurrency,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_SaveDocument = ffi.Pointer<CBLDocument> Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLDocument> doc,
  int concurrency,
  ffi.Pointer<CBLError> error,
);

typedef CBLSaveConflictHandler = ffi.Int8 Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<CBLDocument>,
  ffi.Pointer<CBLDocument>,
);

typedef _c_CBLDatabase_SaveDocumentResolving = ffi.Pointer<CBLDocument>
    Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLDocument> doc,
  ffi.Pointer<ffi.NativeFunction<CBLSaveConflictHandler>> conflictHandler,
  ffi.Pointer<ffi.Void> context,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_SaveDocumentResolving = ffi.Pointer<CBLDocument>
    Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<CBLDocument> doc,
  ffi.Pointer<ffi.NativeFunction<CBLSaveConflictHandler>> conflictHandler,
  ffi.Pointer<ffi.Void> context,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_PurgeDocumentByID = ffi.Uint8 Function(
  ffi.Pointer<CBLDatabase> database,
  ffi.Pointer<ffi.Int8> docID,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_PurgeDocumentByID = int Function(
  ffi.Pointer<CBLDatabase> database,
  ffi.Pointer<ffi.Int8> docID,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_GetDocumentExpiration = ffi.Int64 Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> docID,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_GetDocumentExpiration = int Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> docID,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_SetDocumentExpiration = ffi.Uint8 Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> docID,
  ffi.Int64 expiration,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_SetDocumentExpiration = int Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> docID,
  int expiration,
  ffi.Pointer<CBLError> error,
);

typedef _dart_NotificationsReadyCallback = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<CBLDatabase>,
);

typedef _dart_DatabaseChangeListener = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<CBLDatabase>,
  ffi.Uint32,
  ffi.Pointer<ffi.Pointer<ffi.Int8>>,
);

typedef _dart_DocumentChangeListener = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<CBLDatabase>,
  ffi.Pointer<ffi.Int8>,
);

typedef CBLDatabaseChangeListener = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<CBLDatabase>,
  ffi.Uint32,
  ffi.Pointer<ffi.Pointer<ffi.Int8>>,
);

typedef _c_CBLDatabase_AddChangeListener = ffi.Pointer<CBLListenerToken>
    Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.NativeFunction<CBLDatabaseChangeListener>> listener,
  ffi.Pointer<ffi.Void> context,
);

typedef _dart_CBLDatabase_AddChangeListener = ffi.Pointer<CBLListenerToken>
    Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.NativeFunction<CBLDatabaseChangeListener>> listener,
  ffi.Pointer<ffi.Void> context,
);

typedef CBLDocumentChangeListener = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<CBLDatabase>,
  ffi.Pointer<ffi.Int8>,
);

typedef _c_CBLDatabase_AddDocumentChangeListener = ffi.Pointer<CBLListenerToken>
    Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> docID,
  ffi.Pointer<ffi.NativeFunction<CBLDocumentChangeListener>> listener,
  ffi.Pointer<ffi.Void> context,
);

typedef _dart_CBLDatabase_AddDocumentChangeListener
    = ffi.Pointer<CBLListenerToken> Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> docID,
  ffi.Pointer<ffi.NativeFunction<CBLDocumentChangeListener>> listener,
  ffi.Pointer<ffi.Void> context,
);

typedef CBLNotificationsReadyCallback = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<CBLDatabase>,
);

typedef _c_CBLDatabase_BufferNotifications = ffi.Void Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.NativeFunction<CBLNotificationsReadyCallback>> callback,
  ffi.Pointer<ffi.Void> context,
);

typedef _dart_CBLDatabase_BufferNotifications = void Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.NativeFunction<CBLNotificationsReadyCallback>> callback,
  ffi.Pointer<ffi.Void> context,
);

typedef _c_CBLDatabase_SendNotifications = ffi.Void Function(
  ffi.Pointer<CBLDatabase> db,
);

typedef _dart_CBLDatabase_SendNotifications = void Function(
  ffi.Pointer<CBLDatabase> db,
);

// -- Database indexes

typedef _c_CBLDatabase_CreateIndex = ffi.Uint8 Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<CBLIndexSpec> spec,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_CreateIndex = int Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<CBLIndexSpec> spec,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_DeleteIndex = ffi.Uint8 Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLDatabase_DeleteIndex = int Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> name,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLDatabase_IndexNames = ffi.Pointer<_FLMutableArray> Function(
  ffi.Pointer<CBLDatabase> db,
);

typedef _dart_CBLDatabase_IndexNames = ffi.Pointer<_FLMutableArray> Function(
  ffi.Pointer<CBLDatabase> db,
);
