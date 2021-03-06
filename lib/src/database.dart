// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// A Database is both a filesystem object and a container for documents.
class Database {
  String id;

  final String _name;
  String get name => _name;

  /// The C database object
  ffi.Pointer<cbl.CBLDatabase> _db;
  ffi.Pointer<cbl.CBLDatabase> get db => _db;

  DatabaseConfiguration _config;

  static final Map<String, SaveConflictHandler> _saveConflictHandlers = {};

  /// Database instances that that have change listeners. Used to retrieve the
  /// correct database object when a database or document change event comes in the stream
  static final Map<String, Database> _liveDatabases = {};

  // TODO(rudiksz) check if this is thread safe (specially on Android)
  /// Callback that will be called when a notification is ready in buffered mode.
  void Function() onNotificationsReady;

  static final Map<ffi.Pointer<cbl.CBLDatabase>, void Function()>
      _notificationsReadyCallbacks = {};

  String _path;
  String get path => _path;

  /// Creates database instance. To access documents the database must be opened.
  Database(
    this._name, {
    String directory,
    int flags = DatabaseFlags.create,
    bool doOpen = true,
  }) {
    _config = DatabaseConfiguration(directory, flags);
    if (doOpen) {
      open();
    }
  }

  bool get isOpen => _db != null && _db != ffi.nullptr;

  //? FILE OPERATIONS

  /// Returns true if a database with the given [name] exists in the given [directory].
  ///
  /// The [name] must be without the ".cblite2" extension.
  ///
  /// If [directory] is `null`, [name] must be an absolute or relative path to the database.
  static bool exists(String name, {String directory}) {
    return cbl.CBL_DatabaseExists(name.toNativeUtf8().cast(),
            (directory ?? '').toNativeUtf8().cast()) !=
        0;
  }

  /// Copies a database file to a new location, and assigns it a new internal UUID to distinguish
  /// it from the original database when replicating.
  /// * [path]  The full filesystem path to the original database (including extension).
  /// * [toName]  The new database name (without the ".cblite2" extension.)
  /// * [directory]  The destination directory
  static bool Copy(String path, String toName, {String directory}) {
    final error = cbl.CBLError.allocate();
    final config = pffi.calloc<cbl.CBLDatabaseConfiguration>();

    config.ref
      ..directory = (directory ?? '').toNativeUtf8().cast()
      ..encryptionKey = ffi.nullptr;

    final result = cbl.CBL_CopyDatabase(
      (path ?? '').toNativeUtf8().cast(),
      (toName).toNativeUtf8().cast(),
      config,
      error,
    );

    validateError(error);

    return result != 0;
  }

  /// Copies the database file to a new location, and assigns it a new internal UUID to distinguish
  /// it from the original database when replicating.
  /// * [toName]  The new database name (without the ".cblite2" extension.)
  /// * [directory]  The destination
  bool copy(String toName, {String directory}) {
    assert(isOpen, 'Database must be open to be able to copy with this method');
    return Copy(path, toName, directory: directory);
  }

  /// Deletes a database file. If the database file is open, an error is returned.
  /// * `name`  The database name (without the ".cblite2" extension.)
  /// * `inDirectory` The directory containing the database. If NULL, `name` must be an
  /// absolute or relative path to the database.
  ///
  /// Returns true if the database was deleted, false if it doesn't exist and throws `DatabaseException` if failed.
  static bool Delete(String name, {String directory}) {
    // assert(name?.isNotEmpty ?? true, "Name cannot be empty");

    final error = cbl.CBLError.allocate();

    final result = cbl.CBL_DeleteDatabase(
      (name ?? '').toNativeUtf8().cast(),
      (directory ?? '').toNativeUtf8().cast(),
      error,
    );

    validateError(error);

    return result != 0;
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
    final error = cbl.CBLError.allocate();

    _db = cbl.CBLDatabase_Open(
      (_name).toNativeUtf8().cast(),
      _config.addressOf,
      error,
    );

    validateError(error);

    if (isOpen) {
      final res = cbl.CBLDatabase_Path(_db);
      _path = res.cast<pffi.Utf8>().toDartString();
    }

    return isOpen;
  }

  /// Closes an open database
  bool close() {
    if (!isOpen) return true;

    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_Close(_db, error);

    validateError(error);

    _db = ffi.nullptr;

    return result != 0;
  }

  /// Compacts a database file. If the database is not open, it is a no-op.
  bool compact() {
    if (_db == null) return true;

    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_Compact(_db, error);

    validateError(error);

    return result != 0;
  }

  /// Closes and deletes a database.
  ///
  /// Throws a `DatabaseException` if there are any other open connections to the database.
  bool delete() {
    if (_db == null) return true;

    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_Delete(_db, error);

    validateError(error);
    _db = null;

    return result != 0;
  }

  /// Begins a batch operation, similar to a transaction. You **must** later call
  /// `endBatch` to end (commit) the batch.
  /// -  Multiple writes are much faster when grouped inside a single batch.
  /// -  Changes will not be visible to other database instances on the same database until the batch operation ends.
  /// -  Batch operations can nest. Changes are not committed until the outer batch ends.
  bool beginBatch() {
    if (_db == null) return true;

    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_BeginBatch(_db, error);

    validateError(error);

    return result != 0;
  }

  /// Ends a batch operation. This **must** be called after `beginBatch`.
  bool endBatch() {
    if (_db == null) return true;

    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_EndBatch(_db, error);

    validateError(error);

    return result != 0;
  }

  //? ACCESSORS

  /// Returns the number of documents in the database.
  int get count => _db != null ? cbl.CBLDatabase_Count(_db) : 0;

  //? Document lifecycle

  ///  Reads a document from the database
  Document getDocument(String id) {
    assert(id?.isNotEmpty ?? true, 'ID cannot be empty');

    final result = cbl.CBLDatabase_GetDocument(_db, id.toNativeUtf8().cast());

    return result.address != ffi.nullptr.address
        ? Document.fromPointer(result, db: this)
        : null;
  }

  ///  Reads a document from the database, in mutable form that can be updated and saved
  Document getMutableDocument(String id) {
    assert(id?.isNotEmpty ?? true, 'ID cannot be empty');

    final result =
        cbl.CBLDatabase_GetMutableDocument(_db, id.toNativeUtf8().cast());

    return result.address != ffi.nullptr.address
        ? Document.fromPointer(result, db: this)
        : null;
  }

  /// Saves a (mutable) [document] to the database.
  ///
  /// If a conflicting revision has been saved since [document] was loaded, the [concurrency]
  /// parameter specifies whether the save should fail, or the conflicting revision should
  /// be overwritten with the revision being saved.
  ///
  /// If you need finer-grained control, call [saveDocumentResolving] instead.
  /// Returns an updated Document reflecting the saved changes, or null on failure.
  Document saveDocument(Document document,
      {ConcurrencyControl concurrency = ConcurrencyControl.lastWriteWins}) {
    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_SaveDocument(
        _db, document.doc, concurrency.index, error);

    validateError(error);
    return result.address != ffi.nullptr.address
        ? Document.fromPointer(result, db: this)
        : null;
  }

  /// Saves a (mutable) document to the database. This function is the same as
  /// [saveDocument], except that it allows for custom conflict handling
  /// in the event that the document has been updated since [doc] was loaded.
  ///
  /// The handler should return true to overwrite the existing document, or false
  /// to cancel the save. If the handler rejects the save a [CouchbaseLiteException] will be thrown.
  Document saveDocumentResolving(
      Document document, SaveConflictHandler conflictHandler) {
    if (document._new) {
      throw CouchbaseLiteException(
        cbl.CBLErrorDomain.CBLDomain.index,
        cbl.CBLErrorCode.CBLErrorConflict.index,
        '''Only documents returned by the methods [getDocument], [getMutableDocument] 
        or [saveDocument] can be saved with a conflict handler.''',
      );
    }

    final token = Uuid().v1() + Uuid().v1();
    _saveConflictHandlers[token] = conflictHandler;

    final conflictHandler_ =
        ffi.Pointer.fromFunction<cbl.CBLSaveConflictHandler>(
            _saveConflictCallback, 1);

    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_SaveDocumentResolving(
      _db,
      document.doc,
      conflictHandler_,
      token.toNativeUtf8().cast(),
      error,
    );

    validateError(error);
    _saveConflictHandlers.remove(token);
    return result != ffi.nullptr ? Document.fromPointer(result) : null;
  }

  /// The actual conflict filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static int _saveConflictCallback(
    ffi.Pointer<ffi.Void> saveId,
    ffi.Pointer<cbl.CBLDocument> documentBeingSaved,
    ffi.Pointer<cbl.CBLDocument> conflictingDocument,
  ) {
    final callback =
        _saveConflictHandlers[saveId.cast<pffi.Utf8>().toDartString()];

    final result = callback(
      Document.fromPointer(documentBeingSaved),
      Document.fromPointer(conflictingDocument),
    );

    return result ? 1 : 0;
  }

  ///  Purges a document with a given [id]. This removes all traces of the document from the database.
  ///
  ///  Purges are _not_ replicated. If the document is changed on a server, it will be re-created when pulled.
  ///
  ///  Returns true if the document was purged, false if it doesn't exists and throws [CouchbaseLiteException] if the purge failed.
  bool purgeDocument(String id) {
    assert(id?.isNotEmpty ?? true, 'ID cannot be empty');

    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_PurgeDocumentByID(
      _db,
      id.toNativeUtf8().cast(),
      error,
    );

    validateError(error);
    return result != 0;
  }

  ///  The time, if any, at which a document with a given [id] will expire and be purged.
  ///
  ///  Documents don't normally expire; you have to call [setDocumentExpiration]
  ///  to set a document's expiration time.
  ///
  /// Throws [CouchbaseLiteException] if the call failed.
  DateTime documentExpiration(String id) {
    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_GetDocumentExpiration(
      _db,
      id.toNativeUtf8().cast(),
      error,
    );

    validateError(error);
    return result != 0 ? DateTime.fromMillisecondsSinceEpoch(result) : null;
  }

  /// Sets or clears the [expiration] time of a document.
  ///
  /// Set [expiration] as null if the document should never expire
  ///
  /// Throws [CouchbaseLiteException] if the call failed.
  bool setDocumentExpiration(String id, DateTime expiration) {
    final error = cbl.CBLError.allocate();
    final result = cbl.CBLDatabase_SetDocumentExpiration(
      _db,
      id.toNativeUtf8().cast(),
      expiration?.millisecondsSinceEpoch ?? 0,
      error,
    );

    validateError(error);
    return result != 0;
  }

  // -- Database change listener

  ///  Registers a [callback] to be called after one or more documents are changed on disk.
  ///
  /// Returns a token to be passed to [removeChangeListener] when it's time to remove
  /// the listener.
  String addChangeListener(Function(DatabaseChange) callback) =>
      ChangeListeners.addChangeListener<DatabaseChange>(
        addListener: (String token) =>
            cbl.CBLDatabase_AddChangeListener(_db, token.toNativeUtf8().cast()),
        onListenerAdded: (Stream<DatabaseChange> stream, String token) {
          _liveDatabases[token] = this;
          return stream
              .where((data) => data.database == this)
              .listen((data) => callback(data));
        },
      );

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
    ChangeListeners.stream<DatabaseChange>().sink.add(
          DatabaseChange(
            _liveDatabases[change['databaseId']],
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
          String id, Function(DocumentChange) callback) =>
      ChangeListeners.addChangeListener<DocumentChange>(
        addListener: (String token) =>
            cbl.CBLDatabase_AddDocumentChangeListener(
          _db,
          id.toNativeUtf8().cast(),
          token.toNativeUtf8().cast(),
        ),
        onListenerAdded: (Stream<DocumentChange> stream, String token) {
          _liveDatabases[token] = this;
          return stream
              .where((data) => data.database == this)
              .listen((data) => callback(data));
        },
      );

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
    ChangeListeners.stream<DocumentChange>().sink.add(
          DocumentChange(
            _liveDatabases[change['databaseId']],
            change['docID'] as String,
          ),
        );
  }

  //? NOTIFICATION SCHEDULING

  /// Switches the database to buffered-notification mode. Notifications for objects belonging
  /// to this database (documents, queries, replicators, and of course the database) will not be
  /// called immediately; your [cbl.CBLNotificationsReadyCallback] will be called instead.
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
    final listener = ffi.Pointer.fromFunction<_dart_NotificationsReadyCallback>(
        notificationsReadyCallback);

    cbl.CBLDatabase_BufferNotifications(_db, listener, ffi.nullptr);
  }

  /// Callback indicating that the database (or an object belonging to it) is ready to call one
  /// or more listeners. You should call [cbl.CBLDatabase_SendNotifications] at your earliest
  /// convenience, in the context (thread, dispatch queue, etc.) you want them to run.
  ///
  /// This callback is called _only once_ until the next time [cbl.CBLDatabase_SendNotifications]
  /// is called. If you don't respond by (sooner or later) calling that function,
  /// you will not be informed that any listeners are ready.
  /// This should do as little work as possible, just scheduling a future call to [cbl.CBLDatabase_SendNotifications].
  static void notificationsReadyCallback(
    ffi.Pointer<ffi.Void> context,
    ffi.Pointer<cbl.CBLDatabase> db,
  ) {
    if (_notificationsReadyCallbacks[db] != null) {
      _notificationsReadyCallbacks[db]();
    }
  }

  /// Immediately issues all pending notifications for this database, by calling their listener callbacks.
  void sendNotifications() => cbl.CBLDatabase_SendNotifications(_db);

  // -- INDEXES
  /// Creates a database index.
  ///
  /// Indexes are persistent.
  /// If an identical index with that name already exists, nothing happens (and no error is returned.)
  /// If a non-identical index with that name already exists, it is deleted and re-created.
  bool createIndex(
    String name,
    List<String> keyExpressions, {
    cbl.CBLIndexType type = cbl.CBLIndexType.valueIndex,
    String language = '',
    bool ignoreAccents = false,
  }) {
    assert(name.isNotEmpty, 'Name cannot be empty');
    assert(keyExpressions.isNotEmpty,
        'You must specify at least one key to index by');

    final indexSpec = pffi.calloc<cbl.CBLIndexSpec>();

    indexSpec.ref
      ..type = type.index
      ..ignoreAccents = ignoreAccents ? 1 : 0
      ..language =
          language.isNotEmpty ? language.toNativeUtf8().cast() : ffi.nullptr
      ..keyExpressionsJSON = jsonEncode(keyExpressions).toNativeUtf8().cast();

    final error = cbl.CBLError.allocate();

    final result = cbl.CBLDatabase_CreateIndex(
      _db,
      name.toNativeUtf8().cast(),
      indexSpec,
      error,
    );

    validateError(error);

    return result != 0;
  }

  /// Deletes an index given its name.
  bool deleteIndex(String name) {
    assert(name.isNotEmpty, 'Name cannot be empty');

    final error = cbl.CBLError.allocate();

    final result = cbl.CBLDatabase_DeleteIndex(
      _db,
      name.toNativeUtf8().cast(),
      error,
    );

    validateError(error);

    return result != 0;
  }

  /// Returns the names of the indexes on this database, as a Fleece array of strings.
  FLArray indexNames() =>
      FLArray.fromPointer(cbl.CBLDatabase_IndexNames(_db).cast<cbl.FLArray>());
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

  ffi.Pointer<cbl.CBLDatabaseConfiguration> _cbl_config;
  ffi.Pointer<cbl.CBLDatabaseConfiguration> get addressOf => _cbl_config;

  DatabaseConfiguration(this.directory, this.flags) {
    _cbl_config = pffi.calloc<cbl.CBLDatabaseConfiguration>();

    _cbl_config.ref
      ..directory = (directory ?? '').toNativeUtf8().cast()
      ..flags = flags
      ..encryptionKey = ffi.nullptr;
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

/// A callback that can decide whether a [documentBeingSaved] should be saved in
/// case of conflict.
///
/// It should not take a long time to return.
///
/// Return `true` if the document should be saved, `false` to skip it.
typedef SaveConflictHandler = bool Function(
    Document documentBeingSaved, Document conflictingDocument);

typedef _dart_NotificationsReadyCallback = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<cbl.CBLDatabase>,
);
