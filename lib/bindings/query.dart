// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_c_bindings;

// -- Data types

class CBLQuery extends ffi.Struct {}

class CBLResultSet extends ffi.Struct {}

// -- Functions

/// Creates a new query by compiling the input string.
///
/// This is fast, but not instantaneous. If you need to run the same query many times, keep the
/// [CBLQuery] around instead of compiling it each time. If you need to run related queries
/// with only some values different, create one query with placeholder parameter(s), and substitute
/// the desired value(s) with [CBLQuery_SetParameters] each time you run the query.
///
/// You must release the [CBLQuery] when you're finished with it.
///
/// Supported query languages are [JSON](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema) or
///  [N1QL](https://docs.couchbase.com/server/4.0/n1ql/n1ql-language-reference/index.html).
final CBLQuery_New =
    _dylib.lookupFunction<_c_CBLQuery_New, _dart_CBLQuery_New>('CBLQuery_New');

/// Runs the query, returning the results.
/// To obtain the results you'll typically call \ref CBLResultSet_Next in a `while` loop,
/// examining the values in the \ref CBLResultSet each time around.
///
/// You must release the result set when you're finished with it.
final CBLQuery_Execute =
    _dylib.lookupFunction<_c_CBLQuery_Execute, _dart_CBLQuery_Execute>(
        'CBLQuery_Execute');

/// Returns information about the query, including the translated SQLite form, and the search
/// strategy. You can use this to help optimize the query: the word `SCAN` in the strategy
/// indicates a linear scan of the entire database, which should be avoided by adding an index.
/// The strategy will also show which index(es), if any, are used.
final CBLQuery_Explain_c =
    _dylib.lookupFunction<_c_CBLQuery_Explain_c, _dart_CBLQuery_Explain_c>(
        'CBLQuery_Explain_c');

/// Returns the query's current parameter bindings as a JSON string, if any.
final CBLQuery_ParametersAsJSON = _dylib.lookupFunction<
    _c_CBLQuery_ParametersAsJSON,
    _dart_CBLQuery_ParametersAsJSON>('CBLQuery_ParametersAsJSON');

/// Assigns values to the query's parameters, from JSON data.
/// See [CBLQuery_SetParameters] for details.
final CBLQuery_SetParametersAsJSON = _dylib.lookupFunction<
    _c_CBLQuery_SetParametersAsJSON,
    _dart_CBLQuery_SetParametersAsJSON>('CBLQuery_SetParametersAsJSON');

/// Moves the result-set iterator to the next result.
/// Returns false if there are no more results.
///
/// This **must** be called _before_ examining the first result.
final CBLResultSet_Next =
    _dylib.lookupFunction<_c_CBLResultSet_Next, _dart_CBLResultSet_Next>(
        'CBLResultSet_Next');

/// Returns the current result as Array.
final CBLResultSet_RowArray = _dylib.lookupFunction<_c_CBLResultSet_RowArray,
    _dart_CBLResultSet_RowArray>('CBLResultSet_RowArray');

/// Returns the current result as Dict.
final CBLResultSet_RowDict =
    _dylib.lookupFunction<_c_CBLResultSet_RowDict, _dart_CBLResultSet_RowDict>(
        'CBLResultSet_RowDict');

/// Returns the current result as a JSON string mapping column names to values.
final CBLResultSet_RowJSON =
    _dylib.lookupFunction<_c_CBLResultSet_RowJSON, _dart_CBLResultSet_RowJSON>(
        'CBLResultSet_RowJSON');

/// Registers a change listener callback with a query, turning it into a "live query" until
/// the listener is removed (via  [CBLListener_Remove]).
///
/// When the first change listener is added, the query will run (in the background) and notify
/// the listener(s) of the results when ready. After that, it will run in the background after
/// the database changes, and only notify the listeners when the result set changes.
final CBLQuery_AddChangeListener_d = _dylib.lookupFunction<
    _c_CBLQuery_AddChangeListener_d,
    _dart_CBLQuery_AddChangeListener_d>('CBLQuery_AddChangeListener_d');

final CBLQuery_CopyCurrentResults = _dylib.lookupFunction<
    _c_CBLQuery_CopyCurrentResults,
    _dart_CBLQuery_CopyCurrentResults>('CBLQuery_CopyCurrentResults');

// -- Function types

typedef _c_CBLQuery_New = ffi.Pointer<CBLQuery> Function(
  ffi.Pointer<CBLDatabase> db,
  ffi.Uint32 language,
  ffi.Pointer<ffi.Int8> queryString,
  ffi.Pointer<ffi.Int32> outErrorPos,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLQuery_New = ffi.Pointer<CBLQuery> Function(
  ffi.Pointer<CBLDatabase> db,
  int language,
  ffi.Pointer<ffi.Int8> queryString,
  ffi.Pointer<ffi.Int32> outErrorPos,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLQuery_Execute = ffi.Pointer<CBLResultSet> Function(
  ffi.Pointer<CBLQuery> query,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLQuery_Execute = ffi.Pointer<CBLResultSet> Function(
  ffi.Pointer<CBLQuery> query,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLQuery_Explain_c = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLQuery> query,
);

typedef _dart_CBLQuery_Explain_c = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLQuery> query,
);

typedef _c_CBLQuery_ParametersAsJSON = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLQuery> query,
);

typedef _dart_CBLQuery_ParametersAsJSON = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLQuery> query,
);

typedef _c_CBLQuery_SetParametersAsJSON = ffi.Uint8 Function(
  ffi.Pointer<CBLQuery> query,
  ffi.Pointer<ffi.Int8> json,
);

typedef _dart_CBLQuery_SetParametersAsJSON = int Function(
  ffi.Pointer<CBLQuery> query,
  ffi.Pointer<ffi.Int8> json,
);

typedef _c_CBLResultSet_Next = ffi.Uint8 Function(
  ffi.Pointer<CBLResultSet> resultSet,
);

typedef _dart_CBLResultSet_Next = int Function(
  ffi.Pointer<CBLResultSet> resultSet,
);

typedef _c_CBLResultSet_RowArray = ffi.Pointer<FLArray> Function(
  ffi.Pointer<CBLResultSet> resultSet,
);

typedef _dart_CBLResultSet_RowArray = ffi.Pointer<FLArray> Function(
  ffi.Pointer<CBLResultSet> resultSet,
);

typedef _c_CBLResultSet_RowDict = ffi.Pointer<FLDict> Function(
  ffi.Pointer<CBLResultSet> resultSet,
);

typedef _dart_CBLResultSet_RowDict = ffi.Pointer<FLDict> Function(
  ffi.Pointer<CBLResultSet> resultSet,
);

typedef _c_CBLResultSet_RowJSON = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLResultSet> resultSet,
);

typedef _dart_CBLResultSet_RowJSON = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLResultSet> resultSet,
);

typedef _c_CBLQuery_AddChangeListener_d = ffi.Pointer<CBLListenerToken>
    Function(
  ffi.Pointer<CBLQuery> query,
  ffi.Pointer<ffi.Int8> queryId,
);

typedef _dart_CBLQuery_AddChangeListener_d = ffi.Pointer<CBLListenerToken>
    Function(
  ffi.Pointer<CBLQuery> query,
  ffi.Pointer<ffi.Int8> queryId,
);

typedef _c_CBLQuery_CopyCurrentResults = ffi.Pointer<CBLResultSet> Function(
  ffi.Pointer<CBLQuery> query,
  ffi.Pointer<CBLListenerToken> listener,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLQuery_CopyCurrentResults = ffi.Pointer<CBLResultSet> Function(
  ffi.Pointer<CBLQuery> query,
  ffi.Pointer<CBLListenerToken> listener,
  ffi.Pointer<CBLError> error,
);
