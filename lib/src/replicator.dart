// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class Replicator {
  /// Pointer to the C replicator object
  Pointer<cbl.CBLReplicator> repl = nullptr;

  final String _id = Uuid().v1();

  Replicator.empty();
  bool get isEmpty => repl == nullptr;

  /// The database to replicate
  Database db = Database.empty();

  /// A callback that can decide whether a particular [document] should be pushed.
  ///
  /// It should not take a long time to return, or it will slow down the replicator.
  ///
  /// Return `true` if the document should be replicated, `false` to skip it.
  ReplicatorFilter? pushFilter;

  /// A callback that can decide whether a particular [document] should be pulled.
  ///
  /// It should not take a long time to return, or it will slow down the replicator.
  ///
  /// Return `true` if the document should be replicated, `false` to skip it.
  ReplicatorFilter? pullFilter;

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
  ConflictResolver? conflictResolver;

  //-- Internal

  static final Map<String, ReplicatorFilter> _pushReplicatorFilters = {};
  static final Map<String, ReplicatorFilter> _pullReplicatorFilters = {};

  static final Map<String, ConflictResolver> _conflictResolvers = {};

  //-- Replicator config structs. These need to be garbage collected

  FLSlice _c_url = FLSlice.fromString('');
  FLSlice _c_username = FLSlice.fromString('');
  FLSlice _c_password = FLSlice.fromString('');
  FLSlice _c_sessionId = FLSlice.fromString('');
  FLSlice _c_cookieName = FLSlice.fromString('');
  Pointer<cbl.CBLEndpoint> _c_endpoint = nullptr;
  Pointer<cbl.CBLAuthenticator> _c_authenticator = nullptr;

  FLArray _c_channels = FLArray.empty();
  FLArray _c_documentIDs = FLArray.empty();
  FLDict _c_headers = FLDict.empty();

  FLSlice _c_pinnedServerCertificate = FLSlice.fromString('');
  FLSlice _c_trustedRootCertificates = FLSlice.fromString('');

  ///  The endpoint representing a server-based database at the given URL.
  ///  The URL's scheme must be `ws` or `wss`, it must of course have a valid hostname,
  ///  and its path must be the name of the database on that server.
  ///  The port can be omitted; it defaults to 80 for `ws` and 443 for `wss`.
  ///  For example: `wss://example.org/dbname`
  String get endpointUrl => _c_url.toString();
  set endpointUrl(String url) {
    _c_url.free();
    _c_url = FLSlice.fromString(url);
  }

  String get username => _c_username.toString();
  set username(String username) {
    _c_username.free();
    _c_username =
        username.isNotEmpty ? FLSlice.fromString(username) : FLSlice.empty();
  }

  String get password => _c_password.toString();
  set password(String password) {
    _c_password.free();
    _c_password =
        password.isNotEmpty ? FLSlice.fromString(password) : FLSlice.empty();
  }

  String get sessionId => _c_sessionId.toString();
  set sessionId(String id) {
    _c_sessionId.free();
    _c_sessionId = id.isNotEmpty ? FLSlice.fromString(id) : FLSlice.empty();
  }

  String get cookieName => _c_cookieName.toString();
  set cookieName(String name) {
    _c_cookieName.free();
    _c_cookieName =
        name.isNotEmpty ? FLSlice.fromString(name) : FLSlice.empty();
  }

  /// Optional set of channels to pull from.
  List<String> get channels =>
      <String>[for (final c in _c_channels) c.asString];
  set channels(List<String> channels) {
    _c_channels.dispose();
    _c_channels = FLArray.fromList(channels);
  }

  /// Optional set of document IDs to replicate.
  List<String> get documentIDs =>
      <String>[for (final c in _c_documentIDs) c.asString];
  set documentIDs(List<String> ids) {
    _c_documentIDs.dispose();
    _c_documentIDs = FLArray.fromList(ids);
  }

  /// Optional set of document IDs to replicate.
  Map<String, String> get headers => <String, String>{
        for (final c in _c_headers.entries) c.key.asString: c.value.asString
      };
  set headers(Map<String, String> headers) {
    _c_headers.dispose();
    _c_headers = FLDict.fromMap(headers);
  }

  String get pinnedServerCertificate => _c_pinnedServerCertificate.toString();
  set pinnedServerCertificate(String cert) {
    _c_pinnedServerCertificate.free();
    _c_pinnedServerCertificate =
        cert.isNotEmpty ? FLSlice.fromString(cert) : FLSlice.empty();
  }

  String get trustedRootCertificates => _c_trustedRootCertificates.toString();
  set trustedRootCertificates(String certs) {
    _c_trustedRootCertificates.free();
    _c_trustedRootCertificates =
        certs.isNotEmpty ? FLSlice.fromString(certs) : FLSlice.empty();
  }

  final config = calloc<cbl.CBLReplicatorConfiguration>();

  /// A replicator is a background task that synchronizes changes between a local database and
  /// another database on a remote server (or on a peer device, or even another local database.)
  Replicator(
    this.db, {
    required String endpointUrl,
    String username = '',
    String password = '',
    String sessionId = '',
    String cookieName = '',
    replicatorType = ReplicatorType.pushAndPull,
    continuous = true,
    channels = const <String>[],
    documentIDs = const <String>[],
    headers = const <String, String>{},
    pinnedServerCertificate = '',
    trustedRootCertificates = '',
    this.pushFilter,
    this.pullFilter,
    this.conflictResolver,
  }) {
    assert(db._db != nullptr);
    assert(endpointUrl.isNotEmpty);

    this.endpointUrl = endpointUrl;
    this.username = username;
    this.password = password;
    this.sessionId = sessionId;
    this.cookieName = cookieName;

    _c_endpoint = CBLC.CBLEndpoint_CreateWithURL(_c_url.slice);

    if (username.isNotEmpty) {
      print(_c_password.toString());
      _c_authenticator = CBLC.CBLAuth_CreatePassword(
        _c_username.slice,
        _c_password.slice,
      );
    } else {
      _c_authenticator = CBLC.CBLAuth_CreateSession(
        _c_sessionId.slice,
        _c_cookieName.slice,
      );
    }

    config.ref
      ..context = _id.toNativeUtf8().cast()
      ..database = db._db
      ..endpoint = _c_endpoint
      ..authenticator = _c_authenticator
      ..continuous = continuous ? 1 : 0
      ..endpoint = _c_endpoint;

    if (channels.isNotEmpty) {
      this.channels = channels;
      config.ref.channels = _c_channels.ref;
    }

    if (documentIDs.isNotEmpty) {
      this.documentIDs = documentIDs;
      config.ref.documentIDs = _c_documentIDs.ref;
    }

    if (headers.isNotEmpty) {
      this.headers = headers;
      config.ref.headers = _c_headers.ref;
    }

    if (pinnedServerCertificate.isNotEmpty) {
      this.pinnedServerCertificate = pinnedServerCertificate;
      config.ref.pinnedServerCertificate = _c_pinnedServerCertificate.slice.ref;
    }

    if (trustedRootCertificates.isNotEmpty) {
      this.trustedRootCertificates = trustedRootCertificates;
      config.ref.trustedRootCertificates = _c_trustedRootCertificates.slice.ref;
    }

    if (pullFilter != null) {
      _pullReplicatorFilters[_id] = pullFilter!;
      config.ref.pullFilter = _CBLDart_PullReplicationFilter_ptr;
    }
    if (pushFilter != null) {
      _pushReplicatorFilters[_id] = pushFilter!;
      config.ref.pushFilter = _CBLDart_PushReplicationFilter_ptr;
    }

    if (conflictResolver != null) {
      _conflictResolvers[_id] = conflictResolver!;
      config.ref.conflictResolver = _CBLDart_conflictReplicationResolver_ptr;
    }
    config.ref.conflictResolver = CBLC.CBLDefaultConflictResolver;

    final error = calloc<cbl.CBLError>();
    repl = CBLC.CBLReplicator_Create(config, error);

    validateError(error);
  }

  /// Starts a replicator, asynchronously. Does nothing if it's already started.
  void start({bool resetCheckPoint = false}) =>
      CBLC.CBLReplicator_Start(repl, resetCheckPoint);

  /// Stops a running replicator, asynchronously. Does nothing if it's not already stopped.
  ///
  /// The replicator will call your [ReplicatorChangeListener] with an activity level of
  ///  [ReplicatorStopped] after it stops. Until then, consider it still active.
  void stop() => CBLC.CBLReplicator_Stop(repl);

  /// Puts the replicator in "suspended" state. Causes the replicator to disconnect
  /// and enter Offline state; it will not attempt to reconnect while it's suspended
  void suspend() => CBLC.CBLReplicator_SetSuspended(repl, true);

  /// Puts the replicator out of "suspended" state. Causes the replicator to attempt
  /// to reconnect, _if_ it was   connected when suspended, and is still in Offline state
  void resume() => CBLC.CBLReplicator_SetSuspended(repl, false);

  /// Informs the replicator whether it's considered possible to reach the remote host with
  /// the current network configuration. The default value is true. This only affects the
  ///    replicator's behavior while it's in the Offline state:
  ///    * Setting it to false will cancel any pending retry and prevent future automatic retries.
  ///    * Setting it back to true will initiate an immediate retry.*/
  void setHostReachable(bool reachable) =>
      CBLC.CBLReplicator_SetHostReachable(repl, reachable);

  // ++ Status and progress

  /// Registers a [callback] to be called when the replicator's status changes.
  ///
  /// Returns a token to be passed to [removeChangeListener] when it's time to remove
  /// the listener.
  String addChangeListener(Function(ReplicatorStatus) callback) {
    final token = ChangeListeners.addChangeListener<ReplicatorStatus>(
      addListener: (String token) => CBLC.CBLReplicator_AddChangeListener(
        repl,
        _CBLDart_ReplicatorChangeListener_ptr,
        token.toNativeUtf8().cast(),
      ),
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
    final result = CBLC.CBLReplicator_Status(repl);
    final _status = ReplicatorStatus.fromStatus(_id, result);

    return _status;
  }

  /// Internal listener to handle events from C
  static dynamic _changeListener(dynamic _change) {
    ChangeListeners.stream<ReplicatorStatus>()?.sink.add(
          ReplicatorStatus.fromJson(_change as String),
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
    final error = calloc<cbl.CBLError>();
    final response = CBLC.CBLReplicator_PendingDocumentIDs(
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
    final error = calloc<cbl.CBLError>();
    final pid = FLSlice.fromString(id);

    final result =
        CBLC.CBLReplicator_IsDocumentPending(repl, pid.slice.ref, error);
    pid.free();
    validateError(error);
    return result;
  }

  // ++ Push&pull filters

  /// The actual pull and push filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static int _cblReplicatorFilterCallback(
    int type,
    Pointer<Int8> replicatorId,
    Pointer<cbl.CBLDocument> document,
    int isDeleted,
  ) {
    final callback =
        (ReplicatorFilterType.values[type] == ReplicatorFilterType.push)
            ? _pushReplicatorFilters[replicatorId.cast<Utf8>().toDartString()]
            : _pullReplicatorFilters[replicatorId.cast<Utf8>().toDartString()];

    final result =
        callback?.call(Document._fromPointer(document), isDeleted != 0);

    return (result ?? false) ? 1 : 0;
  }

  // ++ Conflict Resolvers

  /// The actual pull and push filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static Pointer<cbl.CBLDocument> _cblReplicatorConflictCallback(
    Pointer<Int8> replicatorId,
    Pointer<Int8> documentId,
    Pointer<cbl.CBLDocument> localDocument,
    Pointer<cbl.CBLDocument> remoteDocument,
  ) {
    final callback =
        _conflictResolvers[replicatorId.cast<Utf8>().toDartString()];

    if (callback == null) {
      return nullptr;
    }

    final result = callback(
      documentId.cast<Utf8>().toDartString(),
      Document._fromPointer(localDocument),
      Document._fromPointer(remoteDocument),
    );

    return result._doc;
  }

  void dispose() {
    CBLC.CBL_Release(repl.cast());
    repl = nullptr;
    // TODO free all the _c fields here
  }
}

class ReplicatorStatus {
  ReplicatorStatus(this.id);
  String id;
  ActivityLevel activityLevel = ActivityLevel.offline;
  ReplicatorProgress progress = ReplicatorProgress(0, 0);
  CouchbaseLiteException? error;

  ReplicatorStatus.fromStatus(this.id, cbl.CBLReplicatorStatus status) {
    activityLevel = status.activity < ActivityLevel.values.length - 1
        ? ActivityLevel.values[status.activity]
        : ActivityLevel.offline;

    progress = ReplicatorProgress(
      status.progress.complete,
      status.progress.documentCount,
    );

    // Get the error message
    var errorMessage = '';
    if (status.error.domain > 0) {
      final error = calloc<cbl.CBLError>();
      error.ref
        ..code = status.error.code
        ..domain = status.error.domain
        ..internal_info = status.error.internal_info;
      final res = FLSlice.fromSliceResult(CBLC.CBLError_Message(error));

      errorMessage = res.toString();
      calloc.free(error);
      res.free();
    }

    error = CouchbaseLiteException(
      status.error.code,
      status.error.domain,
      errorMessage,
    );
  }

  ReplicatorStatus.fromData(this.id, FLDict data) {
    activityLevel = data['activity'].asInt < ActivityLevel.values.length - 1
        ? ActivityLevel.values[data['activity'].asInt]
        : ActivityLevel.offline;

    final prog = data['progress'].asDict;
    progress = ReplicatorProgress(
      prog['fractionComplete'].asDouble,
      prog['documentCount'].asInt,
    );

    final err = data['error'].asDict;
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
    Progress: (${progress.complete}, ${progress.documentCount})
    Error: (${error?.code}, ${error?.message})
    ''';
  }

  factory ReplicatorStatus.fromJson(String json) {
    var data = FLDict.fromJson(json);
    var status = ReplicatorStatus.fromData(data['id'].asString, data);
    data.dispose();
    return status;
  }
}

class ReplicatorProgress {
  ReplicatorProgress(this.complete, this.documentCount);

  /// Very-approximate completion, from 0.0 to 1.0
  double complete;

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

// -- C bindings for async callbacks

late final _CBLDart_ReplicatorChangeListener_ptr = Cbl.dylib
    .lookup<NativeFunction<_c_CBLDart_ReplicatorChangeListener>>(
        'CBLDart_ReplicatorChangeListener');

typedef _c_CBLDart_ReplicatorChangeListener = Void Function(
  Pointer<Void> id,
  Pointer<cbl.CBLReplicator> repl,
  Pointer<cbl.CBLReplicatorStatus> status,
);

late final _CBLDart_PushReplicationFilter_ptr = Cbl.dylib
    .lookup<NativeFunction<_c_CBLDart_PushReplicationFilter>>(
        'CBLDart_PushReplicationFilter');

typedef _c_CBLDart_PushReplicationFilter = Uint8 Function(
  Pointer<Void> context,
  Pointer<cbl.CBLDocument> document,
  Uint32 isDeleted,
);

late final _CBLDart_PullReplicationFilter_ptr = Cbl.dylib
    .lookup<NativeFunction<_c_CBLDart_PullReplicationFilter>>(
        'CBLDart_PullReplicationFilter');

typedef _c_CBLDart_PullReplicationFilter = Uint8 Function(
  Pointer<Void> context,
  Pointer<cbl.CBLDocument> document,
  Uint32 isDeleted,
);

late final _CBLDart_conflictReplicationResolver_ptr = Cbl.dylib
    .lookup<NativeFunction<_c_CBLDart_conflictReplicationResolver>>(
        'CBLDart_conflictReplicationResolver');

typedef _c_CBLDart_conflictReplicationResolver = Pointer<cbl.CBLDocument>
    Function(
  Pointer<Void> id,
  cbl.FLSlice documentID,
  Pointer<cbl.CBLDocument> localDocument,
  Pointer<cbl.CBLDocument> remoteDocument,
);
