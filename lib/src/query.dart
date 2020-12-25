// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// A Query represents a compiled database query. The query language is a large subset of
/// the [N1QL](https://www.couchbase.com/products/n1ql) language from Couchbase Server, which
/// you can think of as "SQL for JSON" or "SQL++".
class Query {
  /// Internal pointer to the C object
  ffi.Pointer<cbl.CBLQuery> _query;

  /// Internal pointer to the C object
  ffi.Pointer<cbl.CBLQuery> get ref => _query;

  Database db;

  QueryLanguage language;

  String queryString;

  ffi.Pointer<ffi.Int32> outErrorPos = pffi.allocate<ffi.Int32>();

  /// Queries that are being listened to. Used to retrieve new results
  /// when a query change event comes in the stream.
  static final Map<String, ffi.Pointer<cbl.CBLQuery>> _liveQueries = {};

  // Tokens belonging to this specific query. Used to remove listeners when disposing a query.
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

    _query = cbl.CBLQuery_New(
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
  /// To obtain the results you'll typically call [ResultSet.next()] in a `while` loop,
  /// examining the values in the [ResultSet] each time around.
  ///
  /// You must release the result set when you're finished with it.
  ResultSet execute() {
    assert(_query != ffi.nullptr,
        'The query was either not compiled yet or was already disposed.');
    // error.reset();
    final error = cbl.CBLError.allocate();
    final result = cbl.CBLQuery_Execute(_query, error.addressOf);

    validateError(error, cleanup: () => cbl.CBL_Release(result));

    return ResultSet(result);
  }

  /// Returns information about the query, including the translated SQLite form, and the search
  /// strategy. You can use this to help optimize the query: the word `SCAN` in the strategy
  /// indicates a linear scan of the entire database, which should be avoided by adding an index.
  /// The strategy will also show which index(es), if any, are used.
  String explain() {
    final result = cbl.CBLQuery_Explain_c(_query);
    return pffi.Utf8.fromUtf8(result.cast());
  }

  /// Returns the query's current parameter bindings, if any.
  Map get parameters {
    final result = cbl.CBLQuery_ParametersAsJSON(_query);
    if (result == ffi.nullptr) return {};

    return jsonDecode(cbl.utf8ToStr(result));
  }

  /// Assigns values to the query's parameters.
  ///
  /// These values will be substited for those parameters whenever the query is executed,
  /// until they are next assigned.
  ///
  /// Parameters are specified in the query source as e.g. `$PARAM`. In this example,
  /// the `parameters` dictionary to this call should have a key `PARAM` that maps to
  /// the value of the parameter.
  set parameters(Map parameters) {
    final json = jsonEncode(parameters);
    cbl.CBLQuery_SetParametersAsJSON(_query, cbl.strToUtf8(json)) != 0;
  }

  // ++ Query change listener

  /// Registers a [callback] to be called after one or more documents are changed on disk.
  ///
  /// When the first change listener is added, the query will run (in the background) and notify
  /// the listener(s) of the results when ready. After that, it will run in the background after
  /// the database changes, and only notify the listeners when the result set changes.
  ///
  /// Returns a token to be passed to [removeChangeListener] when it's time to remove
  /// the listener.
  String addChangeListener(Function(ResultSet) callback) =>
      ChangeListeners.addChangeListener<QueryChange>(
        addListener: (String token) =>
            cbl.CBLQuery_AddChangeListener_d(_query, cbl.strToUtf8(token)),
        onListenerAdded: (Stream<QueryChange> stream, String token) {
          _liveQueries[token] = _query;
          _listenerTokens.add(token);
          return stream
              .where((data) => data.id == token)
              .listen((data) => callback(data.results));
        },
      );

  /// Removes a change listener, given the [token] that was returned when it was added.
  void removeChangeListener(String token) =>
      ChangeListeners.removeChangeListener(
        token,
        onListenerRemoved: (token) {
          _listenerTokens.remove(token);
          _liveQueries.remove(token);
        },
      );

  /// Internal listener to handle change events from C
  static void _cblQueryChangelistener(dynamic queryId) {
    // Find the query and the listener
    final liveQuery = _liveQueries[queryId];
    final listener = ChangeListeners.cblToken(queryId);

    if (liveQuery == null || listener == null) return;

    final error = cbl.CBLError.allocate();
    final results = cbl.CBLQuery_CopyCurrentResults(
      liveQuery,
      listener,
      error.addressOf,
    );

    validateError(error);

    //Emit an event on the stream
    ChangeListeners.stream<QueryChange>()
        .sink
        .add(QueryChange(queryId, ResultSet(results)));
  }

  /// Disposes the query by freeing up the memory. You can't execute the
  /// query once it's disposed.
  void dispose() {
    _listenerTokens.toList().forEach(removeChangeListener);
    cbl.CBL_Release(_query);
    _query = ffi.nullptr;
  }
}

/// A [ResultSet] is an iterator over the results returned by a query. It exposes one
/// result at a time -- as a collection of values indexed either by position or by name --
/// and can be stepped from one result to the next.

/// It's important to note that the initial position of the iterator is _before_ the first
/// result, so [ResultSet.next()] must be called _first_. Example:

/// ```
/// ResultSet rs = q.execute();
/// while (rs.next()) {
///     FLDict rowAsMap = rs.rowDict;
///     FLArray rowAsList = rs.rowArray;
///     ...
/// }
/// rs.dispose();
/// ```
class ResultSet {
  ffi.Pointer<cbl.CBLResultSet> _results;
  bool _hasRow = false;
  ResultSet(this._results);

  /// Moves the result-set iterator to the next result.
  /// Returns false if there are no more results.
  /// This must be called _before_ examining the first result.
  bool next() =>
      _hasRow = _results != ffi.nullptr && cbl.CBLResultSet_Next(_results) != 0;

  ///Returns the current result as a dictionary mapping column names to values.
  ///
  /// **Note**: The dictionary reference is only valid until the result-set is advanced or disposed.
  /// If you want to keep it for longer, call `FLDict.retain()`, and `FLDict.dispose()` when done.
  FLDict get rowDict =>
      _hasRow ? FLDict.fromPointer(cbl.CBLResultSet_RowDict(_results)) : null;

  /// Returns the current result as an array of column values.
  ///
  /// **Note**: The array reference is only valid until the result-set is advanced or disposed.
  /// If you want to keep it for longer, call `FLArray.retain()`, and `FLArray.dispose()` when done.
  FLArray get rowArray =>
      _hasRow ? FLArray.fromPointer(cbl.CBLResultSet_RowArray(_results)) : null;

  /// Returns the results as a List.
  ///
  /// The result set is disposed and cannot be used after calling this method.
  List get allResults {
    final rows = [];
    while (next()) {
      rows.add(jsonDecode(rowDict.json));
    }
    dispose();
    return rows;
  }

  /// Releases the result set, freeing up memory
  void dispose() {
    if (_results != ffi.nullptr) {
      cbl.CBL_Release(_results);
      _results = ffi.nullptr;
    }
  }
}

/// Contains the information about the query result changes reported by a query object.
class QueryChange {
  String id;
  ResultSet results;
  QueryChange(this.id, this.results);
}

/// Query languages
enum QueryLanguage {
  /// [JSON query schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema)
  json,

  /// [N1QL syntax](https://docs.couchbase.com/server/6.0/n1ql/n1ql-language-reference/index.html)
  n1ql
}
