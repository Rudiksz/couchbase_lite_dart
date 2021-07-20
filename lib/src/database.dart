// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// A Database is both a filesystem object and a container for documents.
class Database {
  final String _name;
  String get name => _name;

  /// The C database object
  Pointer<cbl.CBLDatabase> _db = nullptr;
  Pointer<cbl.CBLDatabase> get db => _db;

  Database.empty() : _name = '';
  bool get isEmpty => _db == nullptr || _name.isEmpty;

  DatabaseConfiguration? _config;

  static final Map<String, SaveConflictHandler> _saveConflictHandlers = {};

  /// Database instances that that have change listeners. Used to retrieve the
  /// correct database object when a database or document change event comes in the stream
  static final Map<String, Database> _liveDatabases = {};

  // TODO(rudiksz) check if this is thread safe (specially on Android)
  /// Callback that will be called when a notification is ready in buffered mode.
  void Function()? onNotificationsReady;

  static final Map<Pointer<cbl.CBLDatabase>, void Function()>
      _notificationsReadyCallbacks = {};

  String _path = '';
  String get path => _path;

  /// Creates database instance. To access documents the database must be opened.
  Database(
    this._name, {
    String directory = '',
    int flags = DatabaseFlags.create,
    bool doOpen = true,
  }) {
    _config = DatabaseConfiguration(directory, flags);
    if (doOpen) {
      open();
    }
  }

  bool get isOpen => _db != nullptr;

  //? FILE OPERATIONS

  /// Returns true if a database with the given [name] exists in the given [directory].
  ///
  /// The [name] must be without the ".cblite2" extension.
  ///
  /// If [directory] is `null`, [name] must be an absolute or relative path to the database.
  static bool exists(String name, {String directory = ''}) {
    final _c_name = FLSlice.fromString(name);
    final _c_dir = FLSlice.fromString(directory);
    final result = CBLC.CBL_DatabaseExists(
      _c_name.slice,
      _c_dir.slice,
    );
    _c_name.free();
    _c_dir.free();
    return result;
  }

  /// Copies a database file to a new location, and assigns it a new internal UUID to distinguish
  /// it from the original database when replicating.
  /// * [path]  The full filesystem path to the original database (including extension).
  /// * [toName]  The new database name (without the ".cblite2" extension.)
  /// * [directory]  The destination directory
  static bool Copy(String path, String toName, {String directory = ''}) {
    final outError = calloc<cbl.CBLError>();
    final config = calloc<cbl.CBLDatabaseConfiguration>();

    final _c_dir = FLSlice.fromString(directory);
    final _c_path = FLSlice.fromString(path);
    final _c_toName = FLSlice.fromString(toName);

    config.ref.directory = _c_dir.slice;

    final result = CBLC.CBL_CopyDatabase(
      _c_path.slice,
      _c_toName.slice,
      config,
      outError,
    );

    _c_dir.free();
    _c_path.free();
    _c_toName.free();

    validateError(outError);

    return result;
  }

  /// Copies the database file to a new location, and assigns it a new internal UUID to distinguish
  /// it from the original database when replicating.
  /// * [toName]  The new database name (without the ".cblite2" extension.)
  /// * [directory]  The destination
  bool copy(String toName, {String directory = ''}) {
    assert(isOpen, 'Database must be open to be able to copy with this method');
    return Copy(path, toName, directory: directory);
  }

  /// Deletes a database file. If the database file is open, an error is returned.
  /// * `name`  The database name (without the ".cblite2" extension.)
  /// * `inDirectory` The directory containing the database. If NULL, `name` must be an
  /// absolute or relative path to the database.
  ///
  /// Returns true if the database was deleted, false if it doesn't exist and throws `DatabaseException` if failed.
  static bool Delete(String name, {String directory = ''}) {
    assert(name.isNotEmpty, 'Name cannot be empty');

    final outError = calloc<cbl.CBLError>();

    final _c_name = FLSlice.fromString(name);
    final _c_dir = FLSlice.fromString(directory);

    final result = CBLC.CBL_DeleteDatabase(
      _c_name.slice,
      _c_dir.slice,
      outError,
    );

    _c_name.free();
    _c_dir.free();

    validateError(outError);
    return result;
  }

  /// Deletes a database file. If the database file is open, an error is returned.
  /// * `name`  The database name (without the ".cblite2" extension.)
  /// * `inDirectory` The directory containing the database. If NULL, `name` must be an
  /// absolute or relative path to the database.
  ///
  /// Returns true if the database was deleted, false if it doesn't exist and throws `DatabaseException` if failed.
  static Future<bool> DeleteAsync(String name, {String directory = ''}) async {
    assert(name.isNotEmpty, 'Name cannot be empty');
    final result =
        await Future<bool>.microtask(() => Delete(name, directory: directory));

    return result;
  }

  //? LIFE CYCLE

  /// Opens a database, or creates it if it doesn't exist yet.
  ///
  /// It's OK to open the same database file multiple times.
  /// Each Database instance is independent of the others (and must be separately closed and released.)
  ///
  /// Throws `DatabaseException` on failure.
  bool open() {
    if (isOpen) return true;
    final error = calloc<cbl.CBLError>();

    final _c_name = FLSlice.fromString(name);

    _db = CBLC.CBLDatabase_Open(
      _c_name.slice,
      _config?.addressOf ?? nullptr, // TODO nullsafety
      error,
    );
    _c_name.free();

    validateError(error);

    if (isOpen) {
      final _c_path = FLSlice.fromSliceResult(CBLC.CBLDatabase_Path(_db));
      _path = _c_path.toString();
      _c_path.free();
    }

    return isOpen;
  }

  /// Closes an open database
  bool close() {
    if (!isOpen) return true;

    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDatabase_Close(_db, error);

    validateError(error);
    _db = nullptr;

    return result;
  }

  /// Closes and deletes a database.
  ///
  /// Throws a `DatabaseException` if there are any other open connections to the database.
  bool delete() {
    if (_db == nullptr) return true;

    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDatabase_Delete(_db, error);

    validateError(error);
    _db = nullptr;

    return result;
  }

  /// Begins a batch operation, similar to a transaction. You **must** later call
  /// `endBatch` to end (commit) the batch.
  /// -  Multiple writes are much faster when grouped inside a single batch.
  /// -  Changes will not be visible to other database instances on the same database until the batch operation ends.
  /// -  Batch operations can nest. Changes are not committed until the outer batch ends.
  bool beginBatch() {
    if (_db == nullptr) return true;

    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDatabase_BeginTransaction(_db, error);

    validateError(error);

    return result;
  }

  /// Ends a batch operation. This **must** be called after `beginBatch`.
  bool endBatch() {
    if (_db == nullptr) return true;

    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDatabase_EndTransaction(_db, true, error);

    validateError(error);

    return result;
  }

  //? ACCESSORS

  /// Returns the number of documents in the database.
  int get count => _db != nullptr ? CBLC.CBLDatabase_Count(_db) : 0;

  //? Document lifecycle

  ///  Reads a document from the database
  Document getDocument(String id) {
    assert(id.isNotEmpty, 'ID cannot be empty');

    final error = calloc<cbl.CBLError>();
    final _c_id = FLSlice.fromString(id);

    final result = CBLC.CBLDatabase_GetDocument(_db, _c_id.slice, error);

    _c_id.free();
    validateError(error);

    return result != nullptr
        ? Document._fromPointer(result, db: this)
        : Document.empty();
  }

  ///  Reads a document from the database, in mutable form that can be updated and saved
  Document getMutableDocument(String id) {
    final error = calloc<cbl.CBLError>();
    final _c_id = FLSlice.fromString(id);
    assert(id.isNotEmpty, 'ID cannot be empty');

    final result = CBLC.CBLDatabase_GetMutableDocument(_db, _c_id.slice, error);

    _c_id.free();
    validateError(error);

    return result != nullptr
        ? Document._fromPointer(result, db: this)
        : Document.empty();
  }

  /// Saves a (mutable) [document] to the database.
  ///
  /// If a conflicting revision has been saved since [document] was loaded, the [concurrency]
  /// parameter specifies whether the save should fail, or the conflicting revision should
  /// be overwritten with the revision being saved.
  ///
  /// If you need finer-grained control, call [saveDocumentResolving] instead.
  /// Returns an updated Document reflecting the saved changes, or null on failure.
  bool saveDocument(Document document,
      {ConcurrencyControl concurrency = ConcurrencyControl.lastWriteWins}) {
    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDatabase_SaveDocument(
      _db,
      document.doc,
      error,
    );
    validateError(error);
    document.db = this;
    return result;
  }

  /// Saves a (mutable) document to the database. This function is the same as
  /// [saveDocument], except that it allows for custom conflict handling
  /// in the event that the document has been updated since [doc] was loaded.
  ///
  /// The handler should return true to overwrite the existing document, or false
  /// to cancel the save. If the handler rejects the save a [CouchbaseLiteException] will be thrown.
  bool saveDocumentWithConflictHandler(
    Document document,
    SaveConflictHandler conflictHandler,
  ) {
    if (document._new) {
      throw CouchbaseLiteException(
        cbl.CBLDomain,
        cbl.CBLErrorConflict,
        '''Only documents returned by the methods [getDocument], [getMutableDocument] 
        or [saveDocument] can be saved with a conflict handler.''',
      );
    }
    final token = Uuid().v1() + Uuid().v1();
    _saveConflictHandlers[token] = conflictHandler;

    final conflictHandler_ =
        Pointer.fromFunction<cbl.CBLConflictHandler>(_saveConflictCallback, 1);

    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDatabase_SaveDocumentWithConflictHandler(
      _db,
      document._doc,
      conflictHandler_,
      token.toNativeUtf8().cast(),
      error,
    );
    _saveConflictHandlers.remove(token);

    validateError(error);
    return result;
  }

  /// The actual conflict filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static int _saveConflictCallback(
    Pointer<Void> saveId,
    Pointer<cbl.CBLDocument> documentBeingSaved,
    Pointer<cbl.CBLDocument> conflictingDocument,
  ) {
    final callback = _saveConflictHandlers[saveId.cast<Utf8>().toDartString()];

    final result = callback?.call(
      Document._fromPointer(documentBeingSaved),
      Document._fromPointer(conflictingDocument),
    );

    return (result ?? false) ? 1 : 0;
  }

  ///  Purges a document with a given [id]. This removes all traces of the document from the database.
  ///
  ///  Purges are _not_ replicated. If the document is changed on a server, it will be re-created when pulled.
  ///
  ///  Returns true if the document was purged, false if it doesn't exists and throws [CouchbaseLiteException] if the purge failed.
  bool purgeDocument(String id) {
    assert(id.isNotEmpty, 'ID cannot be empty');

    final _c_id = FLSlice.fromString(id);

    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDatabase_PurgeDocumentByID(
      _db,
      _c_id.slice,
      error,
    );
    _c_id.free();
    validateError(error);
    return result;
  }

  ///  The time, if any, at which a document with a given [id] will expire and be purged.
  ///
  ///  Documents don't normally expire; you have to call [setDocumentExpiration]
  ///  to set a document's expiration time.
  ///
  /// Throws [CouchbaseLiteException] if the call failed.
  DateTime documentExpiration(String id) {
    final _c_id = FLSlice.fromString(id);

    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDatabase_GetDocumentExpiration(
      _db,
      _c_id.slice,
      error,
    );
    _c_id.free();
    validateError(error);
    return result != 0
        ? DateTime.fromMillisecondsSinceEpoch(result)
        : DateTime.fromMicrosecondsSinceEpoch(0);
  }

  /// Sets or clears the [expiration] time of a document.
  ///
  /// Set [expiration] as null if the document should never expire
  ///
  /// Throws [CouchbaseLiteException] if the call failed.
  bool setDocumentExpiration(String id, DateTime expiration) {
    final _c_id = FLSlice.fromString(id);

    final error = calloc<cbl.CBLError>();
    final result = CBLC.CBLDatabase_SetDocumentExpiration(
      _db,
      _c_id.slice,
      expiration.millisecondsSinceEpoch,
      error,
    );
    _c_id.free();
    validateError(error);
    return result;
  }

  // -- Database change listener

  ///  Registers a [callback] to be called after one or more documents are changed on disk.
  ///
  /// Returns a token to be passed to [removeChangeListener] when it's time to remove
  /// the listener.
  String addChangeListener(Function(DatabaseChange) callback) {
    return ChangeListeners.addChangeListener<DatabaseChange>(
      addListener: (String token) => CBLC.CBLDatabase_AddChangeListener(
        _db,
        _CBLDart_DatabaseChangeListener_ptr,
        token.toNativeUtf8().cast(), // TODO leak
      ),
      onListenerAdded: (Stream<DatabaseChange> stream, String token) {
        _liveDatabases[token] = this;
        return stream
            .where((data) => data.database == this)
            .listen((data) => callback(data));
      },
    );
  }

  /// Removes a previously registered listener using a [token] returned
  /// by [addChangeListener]
  void removeChangeListener(String token) =>
      ChangeListeners.removeChangeListener(
        token,
        onListenerRemoved: (token) {
          _liveDatabases.remove(token);
        },
      );

  /// Internal listener to handle events from C
  static dynamic _changeListener(dynamic _change) {
    final change = jsonDecode(_change as String);
    ChangeListeners.stream<DatabaseChange>()?.sink.add(
          DatabaseChange(
            _liveDatabases[change['databaseId']]!, // TODO nullsafety
            (change['docIDs'] as List).cast(),
          ),
        );
  }

  // -- Document change listener

  /// Registers a [callback] to be called after a document with a given [id] is
  /// changed on disk.
  ///
  /// Returns a token to be passed to [removeDocumentChangeListener] when it's time to remove
  /// the listener.
  String addDocumentChangeListener(
      String id, Function(DocumentChange) callback) {
    final _c_id = FLSlice.fromString(id);

    final token = ChangeListeners.addChangeListener<DocumentChange>(
      addListener: (String token) => CBLC.CBLDatabase_AddDocumentChangeListener(
        _db,
        _c_id.slice,
        _CBLDart_DocumentChangeListener_ptr,
        token.toNativeUtf8().cast(), // TODO leak?
      ),
      onListenerAdded: (Stream<DocumentChange> stream, String token) {
        _liveDatabases[token] = this;
        return stream
            .where((data) => data.database == this && data.documentID == id)
            .listen((data) => callback(data));
      },
    );

    _c_id.free();
    return token;
  }

  /// Removes a previously registered listener using a [token] returned
  /// by [addChangeListener]
  void removeDocumentChangeListener(String token) =>
      ChangeListeners.removeChangeListener(
        token,
        onListenerRemoved: (token) {
          _liveDatabases.remove(token);
        },
      );

  /// Internal listener to handle events from C
  static dynamic _documentChangeListener(dynamic _change) {
    final change = jsonDecode(_change as String);
    ChangeListeners.stream<DocumentChange>()?.sink.add(
          DocumentChange(
            _liveDatabases[change['databaseId']]!, // TODO nullsafety
            (change['documentId'] ?? '') as String,
          ),
        );
  }

  //? NOTIFICATION SCHEDULING

  /// Switches the database to buffered-notification mode. Notifications for objects belonging
  /// to this database (documents, queries, replicators, and of course the database) will not be
  /// called immediately; your [cblc.CBLNotificationsReadyCallback] will be called instead.
  ///
  /// Applications may want control over when Couchbase Lite notifications (listener callbacks)
  /// happen. They may want them called on a specific thread, or at certain times during an event
  /// loop. This behavior may vary by database, if for instance each database is associated with a
  /// separate thread.
  ///
  /// When notifications are "buffered" for a database, calls to listeners will be deferred until
  /// the application explicitly allows them. Instead, a single callback will be issued when the
  /// first notification becomes available; this gives the app a chance to schedule a time when
  /// the notifications should be sent and callbacks called.
  void bufferNotifications(void Function() onNotificationsReady) {
    this.onNotificationsReady = onNotificationsReady;
    _notificationsReadyCallbacks[_db] = onNotificationsReady;
    final listener = Pointer.fromFunction<_dart_NotificationsReadyCallback>(
        notificationsReadyCallback);

    CBLC.CBLDatabase_BufferNotifications(_db, listener, nullptr);
  }

  /// Callback indicating that the database (or an object belonging to it) is ready to call one
  /// or more listeners. You should call [cblc.CBLDatabase_SendNotifications] at your earliest
  /// convenience, in the context (thread, dispatch queue, etc.) you want them to run.
  ///
  /// This callback is called _only once_ until the next time [cblc.CBLDatabase_SendNotifications]
  /// is called. If you don't respond by (sooner or later) calling that function,
  /// you will not be informed that any listeners are ready.
  /// This should do as little work as possible, just scheduling a future call to [cblc.CBLDatabase_SendNotifications].
  static void notificationsReadyCallback(
    Pointer<Void> context,
    Pointer<cbl.CBLDatabase> db,
  ) {
    if (_notificationsReadyCallbacks[db] != null) {
      _notificationsReadyCallbacks[db]?.call();
    }
  }

  /// Immediately issues all pending notifications for this database, by calling their listener callbacks.
  void sendNotifications() => CBLC.CBLDatabase_SendNotifications(_db);

  // -- INDEXES
  /// Creates a database index.
  ///
  /// Indexes are persistent.
  /// If an identical index with that name already exists, nothing happens (and no error is returned.)
  /// If a non-identical index with that name already exists, it is deleted and re-created.
  bool createIndex(
    String name,
    List<String> keyExpressions, {
    CBLIndexType type = CBLIndexType.valueIndex,
    CBLQueryLanguage language = CBLQueryLanguage.n1ql,
    bool ignoreAccents = false,
  }) {
    assert(name.isNotEmpty, 'Name cannot be empty');
    assert(keyExpressions.isNotEmpty,
        'You must specify at least one key to index by');

    final _c_name = FLSlice.fromString(name);
    final _c_expressions = FLSlice.fromString(keyExpressions.join(','));

    final indexSpec = calloc<cbl.CBLValueIndexConfiguration>();
    indexSpec.ref
      ..expressionLanguage = language.index
      ..expressions = _c_expressions.slice;

    final error = calloc<cbl.CBLError>();

    final result = CBLC.CBLDatabase_CreateValueIndex(
      _db,
      _c_name.slice,
      indexSpec.ref,
      error,
    );

    _c_name.free();
    _c_expressions.free();
    calloc.free(indexSpec);

    validateError(error);

    return result;
  }

  /// Deletes an index given its name.
  bool deleteIndex(String name) {
    assert(name.isNotEmpty, 'Name cannot be empty');

    final _c_name = FLSlice.fromString(name);
    final error = calloc<cbl.CBLError>();

    final result = CBLC.CBLDatabase_DeleteIndex(
      _db,
      _c_name.slice,
      error,
    );

    _c_name.free();
    validateError(error);

    return result;
  }

  /// Returns the names of the indexes on this database, as a Fleece array of strings.
  List<String> indexNames() {
    final _c_indexes = FLArray.fromPointer(
        CBLC.CBLDatabase_GetIndexNames(_db).cast<cbl.FLArray>());
    final indexes = _c_indexes.map((e) => e.toString()).toList();
    _c_indexes.dispose();
    return indexes;
  }
}

enum ConcurrencyControl { lastWriteWins, failOnConflict }

/// Flags for how to open a database.
class DatabaseFlags {
  /// Create the database if it doesn't exist
  static const create = 1;

  /// Open file read-only
  static const readOnly = 2;

  /// Disable upgrading an older-version database
  static const noUpgrade = 4;
}

class DatabaseConfiguration {
  /// The parent directory of the database
  String directory;

  // Options for opening the database
  int flags;

  Pointer<cbl.CBLDatabaseConfiguration> _cbl_config = nullptr;
  Pointer<cbl.CBLDatabaseConfiguration> get addressOf => _cbl_config;

  DatabaseConfiguration(this.directory, this.flags) {
    _cbl_config = calloc<cbl.CBLDatabaseConfiguration>();
    final _c_dir = FLSlice.fromString(directory);

    _cbl_config.ref.directory = _c_dir.slice;
  }
}

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

/// Types of database indexes.
enum CBLIndexType {
  /// An index that stores property or expression values
  valueIndex,

  /// An index of strings, that enables searching for words with `MATCH`
  fullTextIndex
}

enum CBLQueryLanguage { json, n1ql }

/// A callback that can decide whether a [documentBeingSaved] should be saved in
/// case of conflict.
///
/// It should not take a long time to return.
///
/// Return `true` if the document should be saved, `false` to skip it.
typedef SaveConflictHandler = bool Function(
    Document documentBeingSaved, Document conflictingDocument);

typedef _dart_NotificationsReadyCallback = Void Function(
  Pointer<Void>,
  Pointer<cbl.CBLDatabase>,
);

late final _CBLDart_DatabaseChangeListener_ptr = Cbl.dylib
    .lookup<NativeFunction<_c_CBLDart_DatabaseChangeListener>>(
        'CBLDart_DatabaseChangeListener');

typedef _c_CBLDart_DatabaseChangeListener = Void Function(
  Pointer<Void> context,
  Pointer<cbl.CBLDatabase> db,
  Uint32 numDocs,
  Pointer<cbl.FLSlice> docIDs,
);

late final _CBLDart_DocumentChangeListener_ptr = Cbl.dylib
    .lookup<NativeFunction<_c_CBLDart_DocumentChangeListener>>(
        'CBLDart_DocumentChangeListener');

typedef _c_CBLDart_DocumentChangeListener = Void Function(
  Pointer<Void> context,
  Pointer<cbl.CBLDatabase> db,
  cbl.FLSlice docID,
);
