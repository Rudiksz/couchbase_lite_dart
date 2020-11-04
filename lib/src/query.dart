// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// A Query represents a compiled database query. The query language is a large subset of
/// the [N1QL](https://www.couchbase.com/products/n1ql) language from Couchbase Server, which
/// you can think of as "SQL for JSON" or "SQL++".
class Query {
  /// Internal pointer to the C object
  ffi.Pointer<cbl.CBLQuery> _q;
  ffi.Pointer<cbl.CBLQuery> get ref => _q;

  Database db;

  QueryLanguage language;

  String queryString;

  ffi.Pointer<ffi.Int32> outErrorPos = pffi.allocate();

  // ??? Query change listeners

  /// Receiver and port for events sent by the C threads
  static ReceivePort _cblListener;
  static int _nativePort;

  /// Listeners tokens used by cbl.CBL in C
  static final Map<String, ffi.Pointer<cbl.CBLListenerToken>>
      _cblListenerTokens = {};

  /// Listeners listening to the Dart stream
  static final Map<String, StreamSubscription> _queryChangeListeners = {};

  /// Queries that are being listened to. Used to retrieve new results
  /// when a query change event comes in the stream
  static final Map<String, ffi.Pointer<cbl.CBLQuery>> _liveQueries = {};

  /// Stream where query change events will be posted
  static final _queryChangeStream = StreamController<QueryChange>.broadcast();

  // Tokens belonging to this specific query
  final List<String> _listenerTokens = [];

  /// Creates a new query by compiling the input string.
  ///
  /// This is fast, but not instantaneous. If you need to run the same query many times, keep the
  /// [Query] around instead of compiling it each time. If you need to run related queries
  /// with only some values different, create one query with placeholder parameter(s), and substitute
  /// the desired value(s) with [setParameters] each time you run the query.
  ///
  /// You must [dispose] the [Query] when you're finished with it.
  Query(this.db, this.queryString, {this.language = QueryLanguage.n1ql}) {
    final error = cbl.CBLError.allocate();

    _q = cbl.CBLQuery_New(
      db._db,
      language.index,
      cbl.strToUtf8(queryString.replaceAll('\n', '')),
      outErrorPos,
      error.addressOf,
    );

    validateError(error);
  }

  /// Runs the query, returning the results.
  ///
  /// Throws [DatabaseError].
  List execute() {
    assert(_q != ffi.nullptr,
        'The query was either not compiled yet or was already disposed.');
    // error.reset();
    final error = cbl.CBLError.allocate();
    final result = cbl.CBLQuery_Execute(_q, error.addressOf);

    validateError(error, cleanup: () => cbl.CBL_Release(result));

    final rows = [];
    while (cbl.CBLResultSet_Next(result) != 0) {
      final row = cbl.CBLResultSet_RowDict(result);
      final json = FLDict.fromPointer(row).json;
      rows.add(jsonDecode(json));
    }

    cbl.CBL_Release(result);

    return rows;
  }

  /// Returns information about the query, including the translated SQLite form, and the search
  ///  strategy. You can use this to help optimize the query: the word `SCAN` in the strategy
  ///  indicates a linear scan of the entire database, which should be avoided by adding an index.
  ///  The strategy will also show which index(es), if any, are used.
  String explain() {
    final result = cbl.CBLQuery_Explain_c(_q);
    return pffi.Utf8.fromUtf8(result.cast());
  }

  /// Returns the query's current parameter bindings, if any.
  Map get parameters {
    final result = cbl.CBLQuery_ParametersAsJSON(_q);
    if (result == ffi.nullptr) return {};

    return jsonDecode(cbl.utf8ToStr(result));
  }

  /// Assigns values to the query's parameters.
  ///
  /// These values will be substited for those parameters whenever the query is executed,
  ///  until they are next assigned.
  ///
  ///  Parameters are specified in the query source as e.g. `$PARAM`. In this example,
  /// the `parameters` dictionary to this call should have a key `PARAM` that maps to
  /// the value of the parameter.
  set setParameters(Map parameters) {
    final json = jsonEncode(parameters);
    cbl.CBLQuery_SetParametersAsJSON(_q, cbl.strToUtf8(json)) != 0;
  }

  // ? Query change listener

  ///  Registers a [callback] to be called after one or more documents are changed on disk.
  ///
  /// When the first change listener is added, the query will run (in the background) and notify
  /// the listener(s) of the results when ready. After that, it will run in the background after
  /// the database changes, and only notify the listeners when the result set changes.
  ///
  /// Returns a token to be passed to [removeChangeListener] when it's time to remove
  /// the listener.
  String addChangeListener(Function(List) callback) {
    // Initialize the native port to receive the asynchronous messages from C
    _cblListener ??= ReceivePort()..listen(_cblQueryChangelistener);
    _nativePort ??= _cblListener.sendPort.nativePort;

    final token = Uuid().v1();
    final cblToken = cbl.CBLQuery_AddChangeListener_d(
      _q,
      cbl.strToUtf8(token),
      _nativePort,
    );

    if (cblToken == ffi.nullptr) {
      return null;
    }

    _liveQueries[token] = _q;

    _listenerTokens.add(token);
    _cblListenerTokens[token] = cblToken;
    _queryChangeListeners[token] = _queryChangeStream.stream
        .where((data) => data.id == token)
        .listen((data) => callback(data.results));

    return token;
  }

  /// Removes a listener with the [token] returned by [addChangeListener].
  void removeChangeListener(String token) async {
    if (token?.isEmpty ?? true) return;
    var streamListener = _queryChangeListeners.remove(token);

    await streamListener?.cancel();
    if (_cblListenerTokens[token] != null &&
        _cblListenerTokens[token] != ffi.nullptr) {
      cbl.CBLListener_Remove(_cblListenerTokens[token]);
      _cblListenerTokens.remove(token);
      _liveQueries.remove(token);
      _listenerTokens.remove(token);
    }
  }

  /// Internal listener to handle events from C
  void _cblQueryChangelistener(dynamic queryId) {
    // Find the query and the listener

    final query = _liveQueries[queryId];
    final listener = _cblListenerTokens[queryId];

    // This should never happen, but it did once...
    // assert(query != null && listener != null);
    if (query == null && listener == null) return;

    final error = cbl.CBLError.allocate();

    final results = cbl.CBLQuery_CopyCurrentResults(
      query,
      listener,
      error.addressOf,
    );

    validateError(error);

    final rows = [];
    while (cbl.CBLResultSet_Next(results) != 0) {
      final row = cbl.CBLResultSet_RowDict(results);
      final json = FLDict.fromPointer(row).json;
      rows.add(jsonDecode(json));
    }

    cbl.CBL_Release(results);

    //Emit an event on the stream
    _queryChangeStream.sink.add(QueryChange(queryId, rows));
  }

  /// Disposes the query by freeing up the memory. You can't execute the
  ///  query once it's disposed.
  void dispose() {
    _listenerTokens.toList().forEach(removeChangeListener);
    cbl.CBL_Release(_q);
    _q = ffi.nullptr;
  }
}

class QueryChange {
  String id;
  List results;
  QueryChange(this.id, this.results);
}

/// Query languages
enum QueryLanguage {
  /// [JSON query schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema)
  json,

  /// [N1QL syntax](https://docs.couchbase.com/server/6.0/n1ql/n1ql-language-reference/index.html)
  n1ql
}
