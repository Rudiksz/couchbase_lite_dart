// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// A callback that can decide whether a particular [document] should be pushed or pulled.
///
/// It should not take a long time to return, or it will slow down the replicator.
///
/// Return `true` if the document should be replicated, `false` to skip it.
typedef ReplicatorFilter = bool Function(Document document, bool isDeleted);

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

  /// HTTP client proxy settings
  ReplicatorProxySettings proxy;

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

  //-- Internal

  /// Receiver,port and callback for filter events sent by the C threads
  static ReceivePort _cblFilterListener;
  static int _filterNativePort;
  static var _cblFilterCallback;
  static var _cblStatusCallback;

  static final Map<String, ReplicatorFilter> _pushReplicatorFilters = {};
  static final Map<String, ReplicatorFilter> _pullReplicatorFilters = {};

  /// Receiver and port for status events sent by the C threads
  static ReceivePort _cblListener;
  static int _nativePort;

  /// Replicators that have active listeners.
  static final Map<String, ffi.Pointer<cbl.CBLReplicator>> _replicators = {};

  /// Stream where status change events will be posted for the Dart listeners to consume.
  static final _statusStream = StreamController<ReplicatorStatus>.broadcast();

  /// Listeners listening to the Dart stream
  static final Map<String, StreamSubscription> _statusListeners = {};

  /// Listener tokens used by cbl.CBL (in C)
  static final Map<String, ffi.Pointer<cbl.CBLListenerToken>>
      _cblListenerTokens = {};

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
    this.proxy,
  }) {
    assert(db != null && db._db != ffi.nullptr);
    assert(endpointUrl != null && endpointUrl.isNotEmpty);

    // Set up comunication protocol between Dart and C
    if (pullFilter != null || pushFilter != null) {
      _cblFilterListener ??= ReceivePort()
        ..listen(_cblReplicatorFilterListener);
      _filterNativePort ??= _cblFilterListener.sendPort.nativePort;

      _cblFilterCallback = ffi.Pointer.fromFunction<cbl.FilterCallback>(
          _cblReplicatorFilterCallback, 1);

      _pushReplicatorFilters[_id] = pushFilter;
      _pullReplicatorFilters[_id] = pullFilter;
    }

    _cblStatusCallback = ffi.Pointer.fromFunction<cbl.StatusCallback>(
        _cblReplicatorStatusCallback);

    final error = pffi.allocate<cbl.CBLError>();
    repl = cbl.CBLReplicator_New_d(
      cbl.strToUtf8(_id),
      db._db,
      cbl.strToUtf8(endpointUrl),
      username.isNotEmpty ? cbl.strToUtf8(username) : ffi.nullptr,
      password.isNotEmpty ? cbl.strToUtf8(password) : ffi.nullptr,
      sessionId.isNotEmpty ? cbl.strToUtf8(sessionId) : ffi.nullptr,
      cookieName.isNotEmpty ? cbl.strToUtf8(cookieName) : ffi.nullptr,
      replicatorType.index,
      continuous ? 1 : 0,
      channels.isNotEmpty ? cbl.strToUtf8(jsonEncode(channels)) : ffi.nullptr,
      documentIDs.isNotEmpty
          ? cbl.strToUtf8(jsonEncode(documentIDs))
          : ffi.nullptr,
      headers.isNotEmpty ? cbl.strToUtf8(jsonEncode(headers)) : ffi.nullptr,
      proxy?.pointer ??
          ffi.nullptr, // todo(rudoka): refactor into basic C types
      pinnedServerCertificate.isNotEmpty
          ? cbl.strToUtf8(pinnedServerCertificate)
          : ffi.nullptr,
      trustedRootCertificates.isNotEmpty
          ? cbl.strToUtf8(trustedRootCertificates)
          : ffi.nullptr,
      pushFilter != null ? 1 : 0,
      pullFilter != null ? 1 : 0,
      _cblFilterCallback ?? ffi.nullptr,
      _cblStatusCallback ?? ffi.nullptr,
      _filterNativePort ?? 0,
      error,
    );

    databaseError(error);
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

  // -- Status and progress

  /// Registers a [callback] to be called when the replicator's status changes.
  ///
  /// Returns a token to be passed to [removeChangeListener] when it's time to remove
  /// the listener.
  String addChangeListener(Function(ReplicatorStatus) callback) {
    // Initialize the native port to receive the asynchronous messages from C
    _cblListener ??= ReceivePort()..listen(_cblStatusChangelistener);
    _nativePort ??= _cblListener.sendPort.nativePort;

    final token = Uuid().v1();
    final cblToken = cbl.CBLReplicator_AddChangeListener_d(
      repl,
      cbl.strToUtf8(token),
      _nativePort,
    );

    if (cblToken == ffi.nullptr) {
      return null;
    }

    _replicators[token] = repl;
    _cblListenerTokens[token] = cblToken;
    _statusListeners[token] = _statusStream.stream
        .where((data) => data.id == token)
        .listen((data) => callback(data));

    return token;
  }

  /// Removes a listener callback, given the [token] that was returned when it was added.
  void removeChangeListener(String token) async {
    var streamListener = _statusListeners.remove(token);

    await streamListener?.cancel();

    if (_cblListenerTokens[token] != null &&
        _cblListenerTokens[token] != ffi.nullptr) {
      cbl.CBLListener_Remove(_cblListenerTokens[token]);
      _cblListenerTokens.remove(token);
    }
  }

  /// This is listening to events sent by C replicators
  void _cblStatusChangelistener(dynamic status) async {
    final work = ffi.Pointer<cbl.Work>.fromAddress(status as int);
    cbl.CBLReplicator_ExecuteCallback(work);
  }

  /// The actual pull and push filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static void _cblReplicatorStatusCallback(
    ffi.Pointer<ffi.Int8> replicatorId,
    ffi.Pointer<cbl.FLDict> status,
  ) {
    _statusStream.sink.add(ReplicatorStatus.fromData(
      cbl.utf8ToStr(replicatorId),
      FLDict.fromPointer(status),
    ));
  }

  // TODO
  // conflictResolver

  /// Returns the replicator's current status.
  ReplicatorStatus get status {
    final result = cbl.CBLReplicator_Status(repl);
    final status = ReplicatorStatus.fromData(
      null,
      FLDict.fromPointer(result),
    );
    cbl.FLValue_Release(result.cast());
    return status;
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
    final error = pffi.allocate<cbl.CBLError>();
    final response = cbl.CBLReplicator_PendingDocumentIDs(repl, error);
    databaseError(error);
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
    final error = pffi.allocate<cbl.CBLError>();
    final pid = cbl.strToUtf8(id);
    final result = cbl.CBLReplicator_IsDocumentPending(repl, pid, error);
    databaseError(error);
    return result != 0;
  }

  // -- Push&pull filters

  /// This is listening to push and pull filter events sent by the C replicators.
  /// Its job is to call back C code with the provided closure, which in turn will
  /// execute the [_cblReplicatorFilterCallback] inside the closure. Done this way
  /// to make sure the callback is executed on the same isolate.
  void _cblReplicatorFilterListener(dynamic message) async {
    final work = ffi.Pointer<cbl.Work>.fromAddress(message as int);
    cbl.CBLReplicator_ExecuteCallback(work);
  }

  /// The actual pull and push filter handler. Calls the registered Dart listeners
  /// and returns the value they produce.
  static int _cblReplicatorFilterCallback(
    int type,
    ffi.Pointer<ffi.Int8> replicatorId,
    ffi.Pointer<cbl.CBLDocument> document,
    int isDeleted,
  ) {
    final callback =
        (ReplicatorFilterType.values[type] == ReplicatorFilterType.push)
            ? _pushReplicatorFilters[cbl.utf8ToStr(replicatorId)]
            : _pullReplicatorFilters[cbl.utf8ToStr(replicatorId)];

    final result = callback(Document._internal(document), isDeleted != 0);

    return result ? 1 : 0;
  }
}

enum ReplicatorFilterType { push, pull }

/// Authentication credentials for the [Replicator]
class ReplicatorProxySettings {
  ffi.Pointer<cbl.CBLProxySettings> pointer;

  /// Creates an authenticator for HTTP Basic (username/password) auth.
  ReplicatorProxySettings({
    String hostname,
    int port,
    String username = '',
    String password = '',
    ReplicatorProxyType type = ReplicatorProxyType.http,
  }) {
    pointer = pffi.allocate<cbl.CBLProxySettings>();
    pointer.ref
      ..type = type.index
      ..hostname = cbl.strToUtf8(hostname)
      ..port = port
      ..username = cbl.strToUtf8(username)
      ..password = cbl.strToUtf8(password);
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

enum ReplicatorType { pushAndPull, push, pull }

enum ReplicatorProxyType { http, https }

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

enum CBLDocumentFlags {
  none,
  none1,
  deleted,
  accessRemoved,
}
