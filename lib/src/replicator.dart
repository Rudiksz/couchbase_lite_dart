// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class Replicator {
  /// Pointer to the C replicator object
  ffi.Pointer<cbl.CBLReplicator> repl;

  final String _id = Uuid().v1();

  /// The database to replicate
  Database db;

  ///  The endpoint representing a server-based database at the given URL.
  ///  The URL's scheme must be `ws` or `wss`, it must of course have a valid hostname,
  ///  and its path must be the name of the database on that server.
  ///  The port can be omitted; it defaults to 80 for `ws` and 443 for `wss`.
  ///  For example: `wss://example.org/dbname`
  String endpointUrl;

  /// Push, pull, or both
  ReplicatorType replicatorType;

  bool continuous;

  /// Optional set of channels to pull from.
  List<String> channels = [];

  /// Optional set of document IDs to replicate.
  List<String> documentIDs = [];

  /// Extra HTTP headers to add to the WebSocket request.
  Map<String, String> headers = {};

  String pinnedServerCertificate;
  String trustedRootCertificates;

  /// A callback that can decide whether a particular [document] should be pushed.
  ///
  /// It should not take a long time to return, or it will slow down the replicator.
  ///
  /// Return `true` if the document should be replicated, `false` to skip it.
  ReplicatorFilter pushFilter;

  /// A callback that can decide whether a particular [document] should be pulled.
  ///
  /// It should not take a long time to return, or it will slow down the replicator.
  ///
  /// Return `true` if the document should be replicated, `false` to skip it.
  ReplicatorFilter pullFilter;

  /// Conflict-resolution callback for use in replications. This callback will be invoked
  /// when the replicator finds a newer server-side revision of a document that also has local
  /// changes. The local and remote changes must be resolved before the document can be pushed
  /// to the server.
  ///
  /// Unlike a filter callback, it does not need to return quickly. If it needs to prompt for
  /// user input, that's OK.
  ///
  /// [localDocument] is the current revision of the document in the local database,
  /// or NULL if the local document has been deleted.
  ///
  /// [remoteDocument] is the revision of the document found on the server,
  /// or NULL if the document has been deleted on the server.
  ///
  /// Return the resolved document to save locally (and push, if the replicator is pushing.)
  /// This can be the same as [localDocument] or [remoteDocument], or you can create
  /// a mutable copy of either one and modify it appropriately.
  /// Or return NULL if the resolution is to delete the document.
  ConflictResolver conflictResolver;

  //-- Internal

  static final Map<String, ReplicatorFilter> _pushReplicatorFilters = {};
  static final Map<String, ReplicatorFilter> _pullReplicatorFilters = {};

  static final Map<String, ConflictResolver> _conflictResolvers = {};

  /// A replicator is a background task that synchronizes changes between a local database and
  /// another database on a remote server (or on a peer device, or even another local database.)
  Replicator(
    this.db, {
    @required this.endpointUrl,
    String username = '',
    String password = '',
    String sessionId = '',
    String cookieName = '',
    this.replicatorType = ReplicatorType.pushAndPull,
    this.continuous = true,
    this.channels = const [],
    this.documentIDs = const [],
    this.headers = const {},
    this.pinnedServerCertificate = '',
    this.trustedRootCertificates = '',
    this.pushFilter,
    this.pullFilter,
    this.conflictResolver,
  }) {
    assert(db != null && db._db != ffi.nullptr);
    assert(endpointUrl != null && endpointUrl.isNotEmpty);

    // Set up comunication protocol between Dart and C for pull/push filters
    if (pullFilter != null || pushFilter != null) {
      _pushReplicatorFilters[_id] = pushFilter;
      _pullReplicatorFilters[_id] = pullFilter;
    }

    // Set up comunication protocol between Dart and C for the conflict handler
    if (conflictResolver != null) {
      _conflictResolvers[_id] = conflictResolver;
    }

    final error = cbl.CBLError.allocate();
    repl = cbl.CBLReplicator_New_d(
      _id.toNativeUtf8().cast(),
      db._db,
      endpointUrl.toNativeUtf8().cast(),
      username.isNotEmpty ? username.toNativeUtf8().cast() : ffi.nullptr,
      password.isNotEmpty ? password.toNativeUtf8().cast() : ffi.nullptr,
      sessionId.isNotEmpty ? sessionId.toNativeUtf8().cast() : ffi.nullptr,
      cookieName.isNotEmpty ? cookieName.toNativeUtf8().cast() : ffi.nullptr,
      replicatorType.index,
      continuous ? 1 : 0,
      channels.isNotEmpty
          ? jsonEncode(channels).toNativeUtf8().cast()
          : ffi.nullptr,
      documentIDs.isNotEmpty
          ? jsonEncode(documentIDs).toNativeUtf8().cast()
          : ffi.nullptr,
      headers.isNotEmpty
          ? jsonEncode(headers).toNativeUtf8().cast()
          : ffi.nullptr,
      ffi.nullptr, // todo(rudoka): implement proxy config
      pinnedServerCertificate.isNotEmpty
          ? pinnedServerCertificate.toNativeUtf8().cast()
          : ffi.nullptr,
      trustedRootCertificates.isNotEmpty
          ? trustedRootCertificates.toNativeUtf8().cast()
          : ffi.nullptr,
      pushFilter != null ? 1 : 0,
      pullFilter != null ? 1 : 0,
      conflictResolver != null ? 1 : 0,
      error,
    );

    validateError(error);
  }

  /// Starts a replicator, asynchronously. Does nothing if it's already started.
  void start() => cbl.CBLReplicator_Start(repl);

  /// Stops a running replicator, asynchronously. Does nothing if it's not already stopped.
  ///
  /// The replicator will call your [ReplicatorChangeListener] with an activity level of
  ///  [ReplicatorStopped] after it stops. Until then, consider it still active.
  void stop() => cbl.CBLReplicator_Stop(repl);

  /// Puts the replicator in "suspended" state. Causes the replicator to disconnect
  /// and enter Offline state; it will not attempt to reconnect while it's suspended
  void suspend() => cbl.CBLReplicator_SetSuspended(repl, 1);

  /// Puts the replicator out of "suspended" state. Causes the replicator to attempt
  /// to reconnect, _if_ it was   connected when suspended, and is still in Offline state
  void resume() => cbl.CBLReplicator_SetSuspended(repl, 0);

  /// Informs the replicator whether it's considered possible to reach the remote host with
  /// the current network configuration. The default value is true. This only affects the
  ///    replicator's behavior while it's in the Offline state:
  ///    * Setting it to false will cancel any pending retry and prevent future automatic retries.
  ///    * Setting it back to true will initiate an immediate retry.*/
  void setHostReachable(bool reachable) =>
      cbl.CBLReplicator_SetHostReachable(repl, reachable ? 1 : 0);

  /// Instructs the replicator to ignore existing checkpoints the next time it runs.
  ///
  /// This will cause it to scan through all the documents on the remote database, which takes
  /// a lot longer, but it can resolve problems with missing documents if the client and
  /// server have gotten out of sync somehow.
  void resetCheckpoint() => cbl.CBLReplicator_ResetCheckpoint(repl);

  // ++ Status and progress

  /// Registers a [callback] to be called when the replicator's status changes.
  ///
  /// Returns a token to be passed to [removeChangeListener] when it's time to remove
  /// the listener.
  String addChangeListener(Function(ReplicatorStatus) callback) {
    final token = ChangeListeners.addChangeListener<ReplicatorStatus>(
      addListener: (String token) => cbl.CBLReplicator_AddChangeListener_d(
          repl, token.toNativeUtf8().cast()),
      onListenerAdded: (Stream stream, String token) => stream
          .where((data) => data.id == token)
          .listen((data) => callback(data)),
    );

    return token;
  }

  /// Removes a listener callback, given the [token] that was returned when it was added.
  void removeChangeListener(String token) =>
      ChangeListeners.removeChangeListener(token);

  /// Returns the replicator's current status.
  ReplicatorStatus get status {
    final result = cbl.CBLReplicator_Status(repl);
    final status = ReplicatorStatus.fromData(
      _id,
      FLDict.fromPointer(result),
    );
    cbl.FLValue_Release(result.cast());
    return status;
  }

  /// The actual pull and push filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static void _cblReplicatorStatusCallback(
    ffi.Pointer<ffi.Int8> replicatorId,
    ffi.Pointer<cbl.FLDict> status,
  ) {
    ChangeListeners.stream<ReplicatorStatus>().sink.add(
          ReplicatorStatus.fromData(
            replicatorId.cast<pffi.Utf8>().toDartString(),
            FLDict.fromPointer(status),
          ),
        );
  }

  /// Indicates which documents have local changes that have not yet been pushed to the server
  /// by this replicator. This is of course a snapshot, that will go out of date as the replicator
  /// makes progress and/or documents are saved locally.
  ///
  /// The result is, effectively, a set of document IDs: a dictionary whose keys are the IDs and
  /// values are `true`.
  /// If there are no pending documents, the dictionary is empty.
  /// On error, NULL is returned.
  ///
  /// This function can be called on a stopped or un-started replicator.
  ///
  /// Documents that would never be pushed by this replicator, due to its configuration's
  /// `pushFilter` or `docIDs`, are ignored.
  ///
  /// Throws [CouchbaseLiteException] in case of an error.
  ///
  /// **Note: you must call dispose on the dictionary once you are done with it.**
  FLDict get pendingDocumentIds {
    final error = cbl.CBLError.allocate();
    final response = cbl.CBLReplicator_PendingDocumentIDs(
      repl,
      error,
    );
    validateError(error);
    return FLDict.fromPointer(response);
  }

  /// Indicates whether the document with the given ID has local changes that
  /// have not yet been pushed to the server by this replicator.
  ///
  /// This is equivalent to, but faster than, calling [pendingDocumentIDs] and
  /// checking whether the result contains `docID`. See that function's documentation for details.
  ///
  /// Throws [CouchbaseLiteException] in case of an error.
  bool isDocumentPending(String id) {
    final error = cbl.CBLError.allocate();
    final pid = id.toNativeUtf8().cast<ffi.Int8>();
    final result = cbl.CBLReplicator_IsDocumentPending(repl, pid, error);
    validateError(error);
    return result != 0;
  }

  // ++ Push&pull filters

  /// The actual pull and push filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static int _cblReplicatorFilterCallback(
    int type,
    ffi.Pointer<ffi.Int8> replicatorId,
    ffi.Pointer<cbl.CBLDocument> document,
    int isDeleted,
  ) {
    final callback = (ReplicatorFilterType.values[type] ==
            ReplicatorFilterType.push)
        ? _pushReplicatorFilters[replicatorId.cast<pffi.Utf8>().toDartString()]
        : _pullReplicatorFilters[replicatorId.cast<pffi.Utf8>().toDartString()];

    final result = callback(Document.fromPointer(document), isDeleted != 0);

    return result ? 1 : 0;
  }

  // ++ Conflict Resolvers

  /// The actual pull and push filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static ffi.Pointer<cbl.CBLDocument> _cblReplicatorConflictCallback(
    ffi.Pointer<ffi.Int8> replicatorId,
    ffi.Pointer<ffi.Int8> documentId,
    ffi.Pointer<cbl.CBLDocument> localDocument,
    ffi.Pointer<cbl.CBLDocument> remoteDocument,
  ) {
    final callback =
        _conflictResolvers[replicatorId.cast<pffi.Utf8>().toDartString()];

    if (callback == null) {
      return ffi.nullptr;
    }

    final result = callback(
      documentId.cast<pffi.Utf8>().toDartString(),
      Document.fromPointer(localDocument),
      Document.fromPointer(remoteDocument),
    );

    return result._doc ?? ffi.nullptr;
  }

  void dispose() {
    cbl.CBL_Release(repl);
    repl = ffi.nullptr;
  }
}

class ReplicatorStatus {
  ReplicatorStatus(this.id);
  String id;
  ActivityLevel activityLevel;
  ReplicatorProgress progress;
  CouchbaseLiteException error;

  ReplicatorStatus.fromData(this.id, FLDict data) {
    activityLevel = data['activity'].asInt < ActivityLevel.values.length - 1
        ? ActivityLevel.values[data['activity'].asInt]
        : ActivityLevel.offline;

    final prog = data['progress'].asMap;
    progress = ReplicatorProgress(
      prog['fractionComplete'].asDouble,
      prog['documentCount'].asInt,
    );

    final err = data['error'].asMap;
    error = CouchbaseLiteException(
      err['domain'].asInt,
      err['code'].asInt,
      err['message'].asString,
    );
  }

  @override
  String toString() {
    return '''ID: $id,
    Activity: $activityLevel,
    Progress: (${progress?.fractionComplete}, ${progress?.documentCount})
    Error: (${error?.code}, ${error?.message})
    ''';
  }
}

class ReplicatorProgress {
  ReplicatorProgress(this.fractionComplete, this.documentCount);

  /// Very-approximate completion, from 0.0 to 1.0
  double fractionComplete;

  /// Number of documents transferred so far
  int documentCount;
}

/// A callback that can decide whether a particular [document] should be pushed or pulled.
///
/// It should not take a long time to return, or it will slow down the replicator.
///
/// Return `true` if the document should be replicated, `false` to skip it.
typedef ReplicatorFilter = bool Function(Document document, bool isDeleted);

typedef ConflictResolver = Document Function(
  String documentID,
  Document localDocument,
  Document remoteDocument,
);

enum ReplicatorFilterType { push, pull }

enum ReplicatorType { pushAndPull, push, pull }

enum ReplicatorProxyType { http, https }

enum CBLDocumentFlags { none, none1, deleted, accessRemoved }

enum ActivityLevel {
  /// The replicator is unstarted, finished, or hit a fatal error.
  stopped,

  /// The replicator is offline, as the remote host is unreachable.
  offline,

  /// The replicator is connecting to the remote host.
  connecting,

  /// The replicator is inactive, waiting for changes to sync.
  idle,

  /// The replicator is actively transferring data.
  busy,

  suspended,
}
