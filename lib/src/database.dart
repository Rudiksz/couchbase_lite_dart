// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

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

  cbl.CBLDatabaseConfiguration _cbl_config;
  cbl.CBLDatabaseConfiguration get ref => _cbl_config;
  ffi.Pointer<cbl.CBLDatabaseConfiguration> get addressOf =>
      _cbl_config.addressOf;

  DatabaseConfiguration(this.directory, this.flags) {
    _cbl_config = pffi.allocate<cbl.CBLDatabaseConfiguration>().ref
      ..directory = pffi.Utf8.toUtf8(directory ?? '').cast<ffi.Int8>()
      ..flags = flags
      ..encryptionKey = cbl.CBLEncryptionKey().addressOf;
  }
}

/// A callback that can decide whether a [documentBeingSaved] should be saved in
/// case of conflict.
///
/// It should not take a long time to return.
///
/// Return `true` if the document should be saved, `false` to skip it.
typedef SaveConflictHandler = bool Function(
    Document documentBeingSaved, Document conflictingDocument);

/// A Database is both a filesystem object and a container for documents.
class Database {
  final String _name;
  String get name => _name;

  ffi.Pointer<cbl.CBLDatabase> _db;
  DatabaseConfiguration _config;

  static final Map<String, SaveConflictHandler> _saveConflictHandlers = {};

  final Map<String, ffi.Pointer<cbl.CBLListenerToken>> _docListeners = {};
  final Map<String, ffi.Pointer<cbl.CBLListenerToken>> _dbListeners = {};

  final Map<String, StreamSubscription> _docListenerTokens = {};
  final Map<String, StreamSubscription> _dbListenerTokens = {};

  static final _docStream = StreamController<String>.broadcast();
  static final _dbStream = StreamController<List<String>>.broadcast();

  void Function() onNotificationsReady;
  static final Map<ffi.Pointer<cbl.CBLDatabase>, void Function()>
      _notificationsReadyCallbacks = {};

  // ignore: unused_field
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
    return cbl.CBL_DatabaseExists(pffi.Utf8.toUtf8(name).cast(),
            pffi.Utf8.toUtf8(directory ?? '').cast()) !=
        0;
  }

  /// Copies a database file to a new location, and assigns it a new internal UUID to distinguish
  /// it from the original database when replicating.
  /// * [path]  The full filesystem path to the original database (including extension).
  /// * [toName]  The new database name (without the ".cblite2" extension.)
  /// * [directory]  The destination directory
  static bool Copy(String path, String toName, {String directory}) {
    final error = pffi.allocate<cbl.CBLError>();
    final config = pffi.allocate<cbl.CBLDatabaseConfiguration>().ref
      ..directory = pffi.Utf8.toUtf8(directory ?? '').cast<ffi.Int8>()
      ..encryptionKey = cbl.CBLEncryptionKey().addressOf;

    final result = cbl.CBL_CopyDatabase(
      pffi.Utf8.toUtf8(path ?? '').cast(),
      pffi.Utf8.toUtf8(toName).cast(),
      config.addressOf,
      error,
    );

    databaseError(error);

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

    final error = pffi.allocate<cbl.CBLError>();

    final result = cbl.CBL_DeleteDatabase(
      pffi.Utf8.toUtf8(name ?? '').cast(),
      pffi.Utf8.toUtf8(directory ?? '').cast(),
      error,
    );

    databaseError(error);

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
    final error = pffi.allocate<cbl.CBLError>();

    _db = cbl.CBLDatabase_Open(
      pffi.Utf8.toUtf8(_name).cast(),
      _config.addressOf,
      error,
    );

    databaseError(error);

    if (isOpen) {
      final res = cbl.CBLDatabase_Path(_db);
      _path = pffi.Utf8.fromUtf8(res.cast());
    }

    return isOpen;
  }

  /// Closes an open database
  bool close() {
    if (!isOpen) return true;

    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_Close(_db, error);

    databaseError(error);

    _db = ffi.nullptr;

    return result != 0;
  }

  /// Compacts a database file. If the database is not open, it is a no-op.
  bool compact() {
    if (_db == null) return true;

    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_Compact(_db, error);

    databaseError(error);

    return result != 0;
  }

  /// Closes and deletes a database.
  ///
  /// Throws a `DatabaseException` if there are any other open connections to the database.
  bool delete() {
    if (_db == null) return true;

    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_Delete(_db, error);

    databaseError(error);
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

    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_BeginBatch(_db, error);

    databaseError(error);

    return result != 0;
  }

  /// Ends a batch operation. This **must** be called after `beginBatch`.
  bool endBatch() {
    if (_db == null) return true;

    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_EndBatch(_db, error);

    databaseError(error);

    return result != 0;
  }

  //? ACCESSORS

  /// Returns the number of documents in the database.
  int get count => _db != null ? cbl.CBLDatabase_Count(_db) : 0;

  //? Document lifecycle

  ///  Reads a document from the database
  Document getDocument(String id) {
    assert(id?.isNotEmpty ?? true, 'ID cannot be empty');

    final result =
        cbl.CBLDatabase_GetDocument(_db, pffi.Utf8.toUtf8(id).cast());

    return result.address != ffi.nullptr.address
        ? Document._internal(result)
        : null;
  }

  ///  Reads a document from the database, in mutable form that can be updated and saved
  Document getMutableDocument(String id) {
    assert(id?.isNotEmpty ?? true, 'ID cannot be empty');

    final result =
        cbl.CBLDatabase_GetMutableDocument(_db, pffi.Utf8.toUtf8(id).cast());

    return result.address != ffi.nullptr.address
        ? Document._internal(result)
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
    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_SaveDocument(
        _db, document.doc, concurrency.index, error);

    databaseError(error);
    return result.address != ffi.nullptr.address
        ? Document._internal(result)
        : null;
  }

  /// Saves a (mutable) document to the database. This function is the same as
  /// [saveDocument], except that it allows for custom conflict handling
  /// in the event that the document has been updated since [doc] was loaded.
  ///
  /// The handler should return true to overwrite the existing document, or false
  /// to cancel the save. If the handler rejects the save a [DatabaseException] will be thrown.
  Document saveDocumentResolving(
      Document document, SaveConflictHandler conflictHandler) {
    final token = Uuid().v1() + Uuid().v1();
    _saveConflictHandlers[token] = conflictHandler;

    final conflictHandler_ =
        ffi.Pointer.fromFunction<cbl.CBLSaveConflictHandler>(
            _saveConflictCallback, 1);

    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_SaveDocumentResolving(
      _db,
      document.doc,
      conflictHandler_,
      cbl.strToUtf8(token).cast(),
      error,
    );

    databaseError(error);
    _saveConflictHandlers.remove(token);
    return result != ffi.nullptr ? Document._internal(result) : null;
  }

  /// The actual conflict filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static int _saveConflictCallback(
    ffi.Pointer<ffi.Void> saveId,
    ffi.Pointer<cbl.CBLDocument> documentBeingSaved,
    ffi.Pointer<cbl.CBLDocument> conflictingDocument,
  ) {
    final callback = _saveConflictHandlers[cbl.utf8ToStr(saveId.cast())];

    final result = callback(
      Document._internal(documentBeingSaved),
      Document._internal(conflictingDocument),
    );

    return result ? 1 : 0;
  }

  ///  Purges a document with a given [id]. This removes all traces of the document from the database.
  ///
  ///  Purges are _not_ replicated. If the document is changed on a server, it will be re-created when pulled.
  ///
  ///  Returns true if the document was purged, false if it doesn't exists and throws [DatabaseException] if the purge failed.
  bool purgeDocument(String id) {
    assert(id?.isNotEmpty ?? true, 'ID cannot be empty');

    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_PurgeDocumentByID(
      _db,
      pffi.Utf8.toUtf8(id).cast(),
      error,
    );

    databaseError(error);
    return result != 0;
  }

  ///  The time, if any, at which a document with a given [id] will expire and be purged.
  ///
  ///  Documents don't normally expire; you have to call [setDocumentExpiration]
  ///  to set a document's expiration time.
  ///
  /// Throws [DatabaseException] if the call failed.
  DateTime documentExpiration(String id) {
    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_GetDocumentExpiration(
      _db,
      pffi.Utf8.toUtf8(id).cast(),
      error,
    );

    databaseError(error);
    return result != 0 ? DateTime.fromMillisecondsSinceEpoch(result) : null;
  }

  /// Sets or clears the [expiration] time of a document.
  ///
  /// Set [expiration] as null if the document should never expire
  ///
  /// Throws [DatabaseException] if the call failed.
  bool setDocumentExpiration(String id, DateTime expiration) {
    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLDatabase_SetDocumentExpiration(
      _db,
      pffi.Utf8.toUtf8(id).cast(),
      expiration?.millisecondsSinceEpoch ?? 0,
      error,
    );

    databaseError(error);
    return result != 0;
  }

  // -- Database change listener

  ///  Registers a [callback] to be called after one or more documents are changed on disk.
  ///
  /// Returns a token to be passed to [removeChangeListener] when it's time to remove
  /// the listener.
  String addChangeListener(Function(DatabaseChange) callback) {
    final token = Uuid().v1();
    final listener =
        ffi.Pointer.fromFunction<_dart_DatabaseChangeListener>(_changeListener);

    _dbListeners[token] ??= cbl.CBLDatabase_AddChangeListener(
      _db,
      listener,
      ffi.nullptr,
    );

    _dbListenerTokens[token] = _dbStream.stream.listen(
      (d) => callback(DatabaseChange(this, d)),
    );

    return token;
  }

  /// Removes a previously registered listener using a [token] returned
  /// by [addChangeListener]
  void removeChangeListener(String token) async {
    var streamListener = _dbListenerTokens.remove(token);

    await streamListener?.cancel();

    if (_dbListeners[token] != null &&
        _dbListeners[token].address != ffi.nullptr.address) {
      cbl.CBLListener_Remove(_dbListeners[token]);
      _dbListeners.remove(token);
    }
  }

  /// Internal listener to handle events from C
  static void _changeListener(
    ffi.Pointer<ffi.Void> context,
    ffi.Pointer<cbl.CBLDatabase> db,
    int count,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> docIds,
  ) {
    final ids = <String>[];
    for (var i = 0; i < count; i++) {
      ids.add(pffi.Utf8.fromUtf8(docIds[0].cast()));
    }

    _dbStream.sink.add(ids);
  }

  // -- Document change listener

  /// Registers a [callback] to be called after a document with a given [id] is
  /// changed on disk.
  ///
  /// Returns a token to be passed to [removeDocumentChangeListener] when it's time to remove
  /// the listener.
  String addDocumentChangeListener(
      String id, Function(DocumentChange) callback) {
    final token = Uuid().v1();
    final listener = ffi.Pointer.fromFunction<_dart_DocumentChangeListener>(
        _documentChangeListener);

    _docListeners[token] ??= cbl.CBLDatabase_AddDocumentChangeListener(
      _db,
      pffi.Utf8.toUtf8(id).cast(),
      listener,
      ffi.nullptr,
    );

    _docListenerTokens[token] = _docStream.stream
        .where((d) => d == id)
        .listen((d) => callback(DocumentChange(this, d)));

    return token;
  }

  /// Removes a previously registered listener using a [token] returned
  /// by [addChangeListener]
  void removeDocumentChangeListener(String token) async {
    var streamListener = _docListenerTokens.remove(token);

    await streamListener?.cancel();

    if (_docListeners[token] != null &&
        _docListeners[token].address != ffi.nullptr.address) {
      cbl.CBLListener_Remove(_docListeners[token]);
      _docListeners.remove(token);
    }
  }

  /// Internal listener to handle events from C
  static void _documentChangeListener(
    ffi.Pointer<ffi.Void> context,
    ffi.Pointer<cbl.CBLDatabase> db,
    ffi.Pointer<ffi.Int8> s,
  ) {
    _docStream.sink.add(pffi.Utf8.fromUtf8(s.cast()));
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

    final indexSpec = pffi.allocate<cbl.CBLIndexSpec>().ref
      ..type = type.index
      ..ignoreAccents = ignoreAccents ? 1 : 0
      ..language = language.isNotEmpty ? cbl.strToUtf8(language) : ffi.nullptr
      ..keyExpressionsJSON = cbl.strToUtf8(jsonEncode(keyExpressions));

    final error = cbl.CBLError.allocate();

    final result = cbl.CBLDatabase_CreateIndex(
      _db,
      cbl.strToUtf8(name),
      indexSpec.addressOf,
      error.addressOf,
    );

    databaseError(error.addressOf);

    return result != 0;
  }

  /// Deletes an index given its name.
  bool deleteIndex(String name) {
    assert(name.isNotEmpty, 'Name cannot be empty');

    final error = cbl.CBLError.allocate();

    final result = cbl.CBLDatabase_DeleteIndex(
      _db,
      cbl.strToUtf8(name),
      error.addressOf,
    );

    databaseError(error.addressOf);

    return result != 0;
  }

  /// Returns the names of the indexes on this database, as a Fleece array of strings.
  FLArray indexNames() =>
      FLArray.fromPointer(cbl.CBLDatabase_IndexNames(_db).cast<cbl.FLArray>());
}

typedef _dart_NotificationsReadyCallback = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<cbl.CBLDatabase>,
);

typedef _dart_DatabaseChangeListener = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<cbl.CBLDatabase>,
  ffi.Uint32,
  ffi.Pointer<ffi.Pointer<ffi.Int8>>,
);

typedef _dart_DocumentChangeListener = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<cbl.CBLDatabase>,
  ffi.Pointer<ffi.Int8>,
);
