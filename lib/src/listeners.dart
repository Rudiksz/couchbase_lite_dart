// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

class ChangeListeners {
  static final List<String> _tokens = [];
  static final Map<String, Pointer<cbl.CBLListenerToken>> _cblTokens = {};

  static final Map<dynamic, StreamController> _streams = {};
  static final Map<String, StreamSubscription> _subscriptions = {};

  static final Map<dynamic, ReceivePort> _receivePorts = {};
  static final Map<dynamic, Function(dynamic)> _portListeners = {
    DatabaseChange: Database._changeListener,
    DocumentChange: Database._documentChangeListener,
    QueryChange: Query._cblQueryChangelistener,
    ReplicatorStatus: Replicator._changeListener,
    'replicatorfilter': _callbackListener,
    'replicatorconflict': _callbackListener,
  };

  static Pointer<cbl.CBLListenerToken>? cblToken(String token) =>
      _cblTokens[token];

  static StreamController<T>? stream<T>() =>
      _streams[T] as StreamController<T>?;

  /// Set up the comunications channel between C and Dart
  /// Registers the various ReceivePorts and Dart callback functions with the C code
  static void initalize() {
    _receivePorts[DatabaseChange] ??= ReceivePort()
      ..listen(_portListeners[DatabaseChange]);

    _receivePorts[DocumentChange] ??= ReceivePort()
      ..listen(_portListeners[DocumentChange]);

    _receivePorts[QueryChange] ??= ReceivePort()
      ..listen(_portListeners[QueryChange]);

    _receivePorts[ReplicatorStatus] ??= ReceivePort()
      ..listen(_portListeners[ReplicatorStatus]);

    _receivePorts['replicatorfilter'] ??= ReceivePort()
      ..listen(_portListeners['replicatorfilter']);

    _receivePorts['replicatorconflict'] ??= ReceivePort()
      ..listen(_portListeners['replicatorconflict']);

    // Register all the ports and callbacks with C
    CBLC.CBLDart_RegisterPorts(
      _receivePorts[DatabaseChange]?.sendPort.nativePort ?? 0,
      _receivePorts[DocumentChange]?.sendPort.nativePort ?? 0,
      _receivePorts[QueryChange]?.sendPort.nativePort ?? 0,
      _receivePorts[ReplicatorStatus]?.sendPort.nativePort ?? 0,
      _receivePorts['replicatorfilter']?.sendPort.nativePort ?? 0,
      _receivePorts['replicatorconflict']?.sendPort.nativePort ?? 0,
      nullptr, // remove this
      Pointer.fromFunction<cbl.CBLDart_ReplicatorFilterCallback>(
          Replicator._cblReplicatorFilterCallback, 1),
      Pointer.fromFunction<cbl.CBLDart_ConflictResolverCallback>(
          Replicator._cblReplicatorConflictCallback),
    );
  }

  /// This is listening to events sent by the C code.
  /// Its job is to call back C code with the provided closure, which in turn will
  /// execute the Dart callback inside the closure. Done this way
  /// to make sure the callback is executed on the same isolate.
  static void _callbackListener(dynamic message) async {
    final work = Pointer<CBLDart_Work>.fromAddress(message as int);
    CBLDart_ExecuteCallback(work.cast());
  }

  /// Registers a change listener of a given type.
  /// Pass the actual logic necessary to add a particular listener as the
  /// [addListener] callback, and in [onListenrAdded] work that needs to be done
  /// if the listener was succesfully added (like subscribing to the stream,
  /// or storing your listener object instances)
  static String addChangeListener<T>({
    required Pointer<cbl.CBLListenerToken> Function(String) addListener,
    StreamSubscription Function(Stream<T>, String)? onListenerAdded,
  }) {
    _streams[T] ??= StreamController<T>.broadcast();

    final token = Uuid().v1();
    _tokens.add(token);

    _cblTokens[token] = addListener(token);

    if (onListenerAdded != null &&
        _cblTokens[token] != null &&
        _cblTokens[token] != nullptr) {
      _subscriptions[token] = onListenerAdded(
        _streams[T]!.stream.cast<T>(),
        token,
      );
    }
    return token;
  }

  /// Remove a change listener using a token that was returned when it was added.
  /// You can use the [onListenerRemoved] callback to do cleanup work, if needed.
  static void removeChangeListener<T>(
    String token, {
    Function(String)? onListenerRemoved,
  }) {
    if (token.isEmpty) return;
    final listener = _subscriptions.remove(token);
    listener?.cancel();

    // Remove cbl listener
    if (_cblTokens[token] != null && _cblTokens[token] != nullptr) {
      CBLC.CBLListener_Remove(_cblTokens[token]!);
      _cblTokens.remove(token);
      if (onListenerRemoved != null) onListenerRemoved(token);
    }
  }
}
