// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_c;

/// Retrieves the error message from the library and throws a [DatabaseException]
///
/// Once the
void databaseError(ffi.Pointer<CBLError> error) {
  if (error == null || error.address == ffi.nullptr.address) return;
  if (error.ref.domain > 0 && error.ref.domain < CBLMaxErrorDomainPlus1) {
    final res = CBLError_Message(error);

    final domain = error.ref.domain;
    final code = error.ref.code;
    final message = pffi.Utf8.fromUtf8(res.cast());

    throw DatabaseException(domain, code, message);
  }
}

class DatabaseException implements Exception {
  int domain;
  int code;
  String message;

  DatabaseException(this.domain, this.code, this.message);

  @override
  String toString() => 'Domain: $domain, Code: $code, Message: $message';
}
