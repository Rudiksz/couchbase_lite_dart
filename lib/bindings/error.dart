// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_c;

const int CBLDomain = 1;
const int CBLPOSIXDomain = 2;
const int CBLSQLiteDomain = 3;
const int CBLFleeceDomain = 4;
const int CBLNetworkDomain = 5;
const int CBLWebSocketDomain = 6;
const int CBLMaxErrorDomainPlus1 = 7;

const int CBLErrorAssertionFailed = 1;
const int CBLErrorUnimplemented = 2;
const int CBLErrorUnsupportedEncryption = 3;
const int CBLErrorBadRevisionID = 4;
const int CBLErrorCorruptRevisionData = 5;
const int CBLErrorNotOpen = 6;
const int CBLErrorNotFound = 7;
const int CBLErrorConflict = 8;
const int CBLErrorInvalidParameter = 9;
const int CBLErrorUnexpectedError = 10;
const int CBLErrorCantOpenFile = 11;
const int CBLErrorIOError = 12;
const int CBLErrorMemoryError = 13;
const int CBLErrorNotWriteable = 14;
const int CBLErrorCorruptData = 15;
const int CBLErrorBusy = 16;
const int CBLErrorNotInTransaction = 17;
const int CBLErrorTransactionNotClosed = 18;
const int CBLErrorUnsupported = 19;
const int CBLErrorNotADatabaseFile = 20;
const int CBLErrorWrongFormat = 21;
const int CBLErrorCrypto = 22;
const int CBLErrorInvalidQuery = 23;
const int CBLErrorMissingIndex = 24;
const int CBLErrorInvalidQueryParam = 25;
const int CBLErrorRemoteError = 26;
const int CBLErrorDatabaseTooOld = 27;
const int CBLErrorDatabaseTooNew = 28;
const int CBLErrorBadDocID = 29;
const int CBLErrorCantUpgradeDatabase = 30;
const int CBLNumErrorCodesPlus1 = 31;

const int CBLNetErrDNSFailure = 1;
const int CBLNetErrUnknownHost = 2;
const int CBLNetErrTimeout = 3;
const int CBLNetErrInvalidURL = 4;
const int CBLNetErrTooManyRedirects = 5;
const int CBLNetErrTLSHandshakeFailed = 6;
const int CBLNetErrTLSCertExpired = 7;
const int CBLNetErrTLSCertUntrusted = 8;
const int CBLNetErrTLSClientCertRequired = 9;
const int CBLNetErrTLSClientCertRejected = 10;
const int CBLNetErrTLSCertUnknownRoot = 11;
const int CBLNetErrInvalidRedirect = 12;
const int CBLNetErrUnknown = 13;
const int CBLNetErrTLSCertRevoked = 14;
const int CBLNetErrTLSCertNameMismatch = 15;
