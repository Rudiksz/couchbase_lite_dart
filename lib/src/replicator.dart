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

  /// Authentication credentials if needed
  Authenticator authenticator;

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
    this.authenticator,
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

    final error = pffi.allocate<cbl.CBLError>();
    repl = cbl.CBLReplicator_New_d(
      cbl.strToUtf8(_id),
      db._db,
      pffi.Utf8.toUtf8(endpointUrl).cast<ffi.Int8>(),
      authenticator?.auth ?? ffi.nullptr,
      replicatorType.index,
      continuous ? 1 : 0,
      channels.isNotEmpty ? cbl.strToUtf8(jsonEncode(channels)) : ffi.nullptr,
      documentIDs.isNotEmpty
          ? cbl.strToUtf8(jsonEncode(documentIDs))
          : ffi.nullptr,
      headers.isNotEmpty ? cbl.strToUtf8(jsonEncode(headers)) : ffi.nullptr,
      proxy?.pointer ?? ffi.nullptr,
      cbl.FLSlice.allocate(pinnedServerCertificate ?? '').addressOf,
      cbl.FLSlice.allocate(trustedRootCertificates ?? '').addressOf,
      pushFilter != null ? 1 : 0,
      pullFilter != null ? 1 : 0,
      _cblFilterCallback ?? ffi.nullptr,
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

  // ignore: todo
  // TODO(rudoka): Investigate flaky behaviour on C side. Sometimes it just hangs...
  // ignore: unused_element
  List get _pendingDocumentIds {
    final ids = [];

    // ! Hangs up on the C side
    // final error = pffi.allocate<cbl.CBLError>();
    // final response = cbl.CBLReplicator_PendingDocumentIDs(repl, error);

    return ids;
  }

  // ignore: todo
  // TODO(rudoka): Investigate flaky behaviour on C side. Sometimes it just hangs...
  // ignore: unused_element
  bool _isDocumentPending(String id) {
    final error = pffi.allocate<cbl.CBLError>();
    final result = cbl.CBLReplicator_IsDocumentPending(
        repl, cbl.FLString.allocate(id).addressOf, error);

    databaseError(error);

    return result != 0;
  }

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
    _statusStream.sink.add(ReplicatorStatus.fromJson(status));
  }

  // TODO
  // conflictResolver

  /// Returns the replicator's current status.
  ReplicatorStatus status() {
    final result = cbl.CBLReplicator_Status(repl);
    final json = cbl.utf8ToStr(result);
    cbl.Dart_Free(result);

    return ReplicatorStatus.fromJson(json);
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

/// Authentication credentials for the [Replicator]
class Authenticator {
  ffi.Pointer<cbl.CBLAuthenticator> auth;

  /// Creates an authenticator for HTTP Basic (username/password) auth.
  Authenticator.basic(String username, String password) {
    assert(
      username?.isNotEmpty ?? true,
      'Authenticator: username cannot be empty',
    );
    assert(
      password?.isNotEmpty ?? true,
      'Authenticator: password cannot be empty',
    );

    auth = cbl.CBLAuth_NewBasic(
      pffi.Utf8.toUtf8(username).cast<ffi.Int8>(),
      pffi.Utf8.toUtf8(password).cast<ffi.Int8>(),
    );
  }

  /// Creates an authenticator using a Couchbase Sync Gateway login [sessionID],
  ///  and optionally a [cookieName]
  Authenticator.session(String sessionId, {String cookieName}) {
    assert(
      sessionId?.isNotEmpty ?? true,
      'Authenticator: sessionId cannot be empty',
    );

    auth = cbl.CBLAuth_NewSession(
      pffi.Utf8.toUtf8(sessionId).cast<ffi.Int8>(),
      (cookieName?.isNotEmpty ?? false)
          ? pffi.Utf8.toUtf8(cookieName).cast<ffi.Int8>()
          : ffi.nullptr,
    );
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
  DatabaseException error;

  ReplicatorStatus.fromJson(String json) {
    final data = jsonDecode(json);
    id = data['id'] as String;
    activityLevel = ActivityLevel.values[data['activity']];

    progress = ReplicatorProgress(
      data['progress']['fractionComplete'],
      data['progress']['documentCount'],
    );

    error = DatabaseException(
      data['error']['domain'],
      data['error']['code'],
      data['error']['message'],
    );
  }

  @override
  String toString() {
    return '''ID: $id,
    Activity: $activityLevel,
    Progress: (${progress.fractionComplete * 100}%, ${progress.documentCount})
    Error: (${error.code}, ${error.message})
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
  busy
}
