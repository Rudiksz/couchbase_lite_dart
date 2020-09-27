// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_dart;

// -- Data types

class CBLReplicator extends ffi.Struct {}

class CBLAuthenticator extends ffi.Struct {}

/// Proxy settings for the replicator.
class CBLProxySettings extends ffi.Struct {
  @ffi.Uint8()
  int type;

  ffi.Pointer<ffi.Int8> hostname;

  @ffi.Uint16()
  int port;

  ffi.Pointer<ffi.Int8> username;

  ffi.Pointer<ffi.Int8> password;
}

/// A fractional progress value, ranging from 0.0 to 1.0 as replication progresses.
/// The value is very approximate and may bounce around during replication; making it more
/// accurate would require slowing down the replicator and incurring more load on the server.
/// It's fine to use in a progress bar, though.
class CBLReplicatorProgress extends ffi.Struct {
  @ffi.Float()
  double fractionComplete;

  /// ///< Number of documents transferred so far
  @ffi.Uint64()
  int documentCount;
}

/// A replicator's current status.
class CBLReplicatorStatus extends ffi.Struct {
  @ffi.Uint8()
  int activityLevel;

  ffi.Pointer<CBLReplicatorProgress> progress;

  ffi.Pointer<CBLError> error;
}

// -- Functions

final CBLReplicator_New_d =
    _dylib.lookupFunction<_c_CBLReplicator_New_d, _dart_CBLReplicator_New_d>(
        'CBLReplicator_New_d');

/// Starts a replicator, asynchronously. Does nothing if it's already started.
final CBLReplicator_Start =
    _dylib.lookupFunction<_c_CBLReplicator_Start, _dart_CBLReplicator_Start>(
        'CBLReplicator_Start');

/// Stops a running replicator, asynchronously. Does nothing if it's not already started.
/// The replicator will call your \ref CBLReplicatorChangeListener with an activity level of
/// \ref kCBLReplicatorStopped after it stops. Until then, consider it still active.
final CBLReplicator_Stop =
    _dylib.lookupFunction<_c_CBLReplicator_Stop, _dart_CBLReplicator_Stop>(
        'CBLReplicator_Stop');

/// Informs the replicator whether it's considered possible to reach the remote host with
/// the current network configuration. The default value is true. This only affects the
/// replicator's behavior while it's in the Offline state:
/// Setting it to false will cancel any pending retry and prevent future automatic retries.
/// Setting it back to true will initiate an immediate retry.
final CBLReplicator_SetHostReachable = _dylib.lookupFunction<
    _c_CBLReplicator_SetHostReachable,
    _dart_CBLReplicator_SetHostReachable>('CBLReplicator_SetHostReachable');

/// Puts the replicator in or out of "suspended" state. The default is false.
/// Setting suspended=true causes the replicator to disconnect and enter Offline state;
/// it will not attempt to reconnect while it's suspended.
/// Setting suspended=false causes the replicator to attempt to reconnect, _if_ it was
/// connected when suspended, and is still in Offline state.
final CBLReplicator_SetSuspended = _dylib.lookupFunction<
    _c_CBLReplicator_SetSuspended,
    _dart_CBLReplicator_SetSuspended>('CBLReplicator_SetSuspended');

/// Instructs the replicator to ignore existing checkpoints the next time it runs.
/// This will cause it to scan through all the documents on the remote database, which takes
/// a lot longer, but it can resolve problems with missing documents if the client and
/// server have gotten out of sync somehow.
final CBLReplicator_ResetCheckpoint = _dylib.lookupFunction<
    _c_CBLReplicator_ResetCheckpoint,
    _dart_CBLReplicator_ResetCheckpoint>('CBLReplicator_ResetCheckpoint');

final CBLReplicator_AddChangeListener_d = _dylib.lookupFunction<
        _c_CBLReplicator_AddChangeListener_d,
        _dart_CBLReplicator_AddChangeListener_d>(
    'CBLReplicator_AddChangeListener_d');

final CBLReplicator_ExecuteCallback = _dylib.lookupFunction<
    ffi.Void Function(ffi.Pointer<Work>),
    void Function(ffi.Pointer<Work>)>('CBLReplicator_ExecuteCallback');

/// Returns the replicator's current status.
final CBLReplicator_Status =
    _dylib.lookupFunction<_c_CBLReplicator_Status, _dart_CBLReplicator_Status>(
        'CBLReplicator_Status_d');

/// Indicates which documents have local changes that have not yet been pushed to the server
/// by this replicator. This is of course a snapshot, that will go out of date as the replicator
/// makes progress and/or documents are saved locally.
///
/// The result is, effectively, a set of document IDs: a dictionary whose keys are the IDs and
/// values are `true`.
/// If there are no pending documents, the dictionary is empty.
/// On error, NULL is returned.
///
/// \note  This function can be called on a stopped or un-started replicator.
/// \note  Documents that would never be pushed by this replicator, due to its configuration's
/// `pushFilter` or `docIDs`, are ignored.
/// \warning  You are responsible for releasing the returned array via \ref FLValue_Release.
final CBLReplicator_PendingDocumentIDs = _dylib.lookupFunction<
        _c_CBLReplicator_PendingDocumentIDs_d,
        _dart_CBLReplicator_PendingDocumentIDs_d>(
    'CBLReplicator_PendingDocumentIDs_d');

/// Indicates whether the document with the given ID has local changes that have not yet been
/// pushed to the server by this replicator.
/// This is equivalent to, but faster than, calling \ref CBLReplicator_PendingDocumentIDs and
/// checking whether the result contains \p docID. See that function's documentation for details.
/// \note  A `false` result means the document is not pending, _or_ there was an error.
///        To tell the difference, compare the error code to zero. */
final CBLReplicator_IsDocumentPending = _dylib.lookupFunction<
    _c_CBLReplicator_IsDocumentPending,
    _dart_CBLReplicator_IsDocumentPending>('CBLReplicator_IsDocumentPending');

/// Creates an authenticator for HTTP Basic (username/password) auth.
final CBLAuth_NewBasic =
    _dylib.lookupFunction<_c_CBLAuth_NewBasic, _dart_CBLAuth_NewBasic>(
        'CBLAuth_NewBasic');

/// Creates an authenticator using a Couchbase Sync Gateway login session identifier,
/// and optionally a cookie name (pass NULL for the default.)
final CBLAuth_NewSession =
    _dylib.lookupFunction<_c_CBLAuth_NewSession, _dart_CBLAuth_NewSession>(
        'CBLAuth_NewSession');

// -- Function types

typedef _c_CBLReplicator_New_d = ffi.Pointer<CBLReplicator> Function(
  ffi.Pointer<ffi.Int8> replicatorId,
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> url,
  ffi.Pointer<CBLAuthenticator> auth,
  ffi.Int32 replicatorType,
  ffi.Uint8 continuous,
  ffi.Pointer<ffi.Int8> channels,
  ffi.Pointer<ffi.Int8> documentIDs,
  ffi.Pointer<ffi.Int8> headers,
  ffi.Pointer<CBLProxySettings> proxy,
  ffi.Pointer<FLSlice> pinnedServerCertificate,
  ffi.Pointer<FLSlice> trustedRootCertificates,
  ffi.Uint8 pushFilter,
  ffi.Uint8 pullFilter,
  ffi.Pointer<ffi.NativeFunction<FilterCallback>> filterCallback,
  ffi.Uint64 dart_port,
  ffi.Pointer<CBLError> outError,
);

typedef _dart_CBLReplicator_New_d = ffi.Pointer<CBLReplicator> Function(
  ffi.Pointer<ffi.Int8> replicatorId,
  ffi.Pointer<CBLDatabase> db,
  ffi.Pointer<ffi.Int8> url,
  ffi.Pointer<CBLAuthenticator> auth,
  int replicatorType,
  int continuous,
  ffi.Pointer<ffi.Int8> channels,
  ffi.Pointer<ffi.Int8> documentIDs,
  ffi.Pointer<ffi.Int8> headers,
  ffi.Pointer<CBLProxySettings> proxy,
  ffi.Pointer<FLSlice> pinnedServerCertificate,
  ffi.Pointer<FLSlice> trustedRootCertificates,
  int pushFilter,
  int pullFilter,
  ffi.Pointer<ffi.NativeFunction<FilterCallback>> filterCallback,
  int dart_port,
  ffi.Pointer<CBLError> outError,
);

typedef FilterCallback = ffi.Int8 Function(
  ffi.Int8,
  ffi.Pointer<ffi.Int8> replicatorId,
  ffi.Pointer<CBLDocument>,
  ffi.Int8,
);

typedef _c_CBLReplicator_Start = ffi.Void Function(
  ffi.Pointer<CBLReplicator> replicator,
);

typedef _dart_CBLReplicator_Start = void Function(
  ffi.Pointer<CBLReplicator> replicator,
);

typedef _c_CBLReplicator_Stop = ffi.Void Function(
  ffi.Pointer<CBLReplicator> replicator,
);

typedef _dart_CBLReplicator_Stop = void Function(
  ffi.Pointer<CBLReplicator> replicator,
);

typedef _c_CBLReplicator_SetHostReachable = ffi.Void Function(
  ffi.Pointer<CBLReplicator> replicator,
  ffi.Uint8 reachable,
);

typedef _dart_CBLReplicator_SetHostReachable = void Function(
  ffi.Pointer<CBLReplicator> replicator,
  int reachable,
);

typedef _c_CBLReplicator_SetSuspended = ffi.Void Function(
  ffi.Pointer<CBLReplicator> replicator,
  ffi.Uint8 suspended,
);

typedef _dart_CBLReplicator_SetSuspended = void Function(
  ffi.Pointer<CBLReplicator> replicator,
  int suspended,
);

typedef _c_CBLReplicator_ResetCheckpoint = ffi.Void Function(
  ffi.Pointer<CBLReplicator> replicator,
);

typedef _dart_CBLReplicator_ResetCheckpoint = void Function(
  ffi.Pointer<CBLReplicator> replicator,
);

typedef _c_CBLReplicator_AddChangeListener_d = ffi.Pointer<CBLListenerToken>
    Function(
  ffi.Pointer<CBLReplicator> query,
  ffi.Pointer<ffi.Int8> replicatorId,
  ffi.Uint64 dart_port,
);

typedef _dart_CBLReplicator_AddChangeListener_d = ffi.Pointer<CBLListenerToken>
    Function(
  ffi.Pointer<CBLReplicator> query,
  ffi.Pointer<ffi.Int8> replicatorId,
  int dart_port,
);

typedef _c_CBLAuth_NewBasic = ffi.Pointer<CBLAuthenticator> Function(
  ffi.Pointer<ffi.Int8> username,
  ffi.Pointer<ffi.Int8> password,
);

typedef _dart_CBLAuth_NewBasic = ffi.Pointer<CBLAuthenticator> Function(
  ffi.Pointer<ffi.Int8> username,
  ffi.Pointer<ffi.Int8> password,
);

typedef _c_CBLAuth_NewSession = ffi.Pointer<CBLAuthenticator> Function(
  ffi.Pointer<ffi.Int8> sessionID,
  ffi.Pointer<ffi.Int8> cookieName,
);

typedef _dart_CBLAuth_NewSession = ffi.Pointer<CBLAuthenticator> Function(
  ffi.Pointer<ffi.Int8> sessionID,
  ffi.Pointer<ffi.Int8> cookieName,
);

// ignore: unused_element
typedef _c_CBLReplicator_PendingDocumentIDs = ffi.Pointer<_FLDict> Function(
  ffi.Pointer<CBLReplicator> replicator,
  ffi.Pointer<CBLError> error,
);

// ignore: unused_element
typedef _dart_CBLReplicator_PendingDocumentIDs = ffi.Pointer<_FLDict> Function(
  ffi.Pointer<CBLReplicator> replicator,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLReplicator_PendingDocumentIDs_d = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLReplicator> replicator,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLReplicator_PendingDocumentIDs_d = ffi.Pointer<ffi.Int8>
    Function(
  ffi.Pointer<CBLReplicator> replicator,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLReplicator_IsDocumentPending = ffi.Uint8 Function(
  ffi.Pointer<CBLReplicator> replicator,
  ffi.Pointer<FLString> id,
  ffi.Pointer<CBLError> error,
);

typedef _dart_CBLReplicator_IsDocumentPending = int Function(
  ffi.Pointer<CBLReplicator> replicator,
  ffi.Pointer<FLString> id,
  ffi.Pointer<CBLError> error,
);

typedef _c_CBLReplicator_Status = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLReplicator> replicator,
);

typedef _dart_CBLReplicator_Status = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<CBLReplicator> replicator,
);
