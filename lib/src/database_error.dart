// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// Retrieves the error message from the library and throws a [CouchbaseLiteException]
///
/// In case of an error calls the [cleanup] closure, if provided
///
/// Frees the [error] object
void validateError(cbl.CBLError error, {Function cleanup}) {
  if (error == null || error.addressOf == ffi.nullptr) return;
  if (error.domain > 0 &&
      error.domain < cbl.CBLErrorDomain.CBLMaxErrorDomainPlus1.index) {
    final res = cbl.CBLError_Message(error.addressOf);

    final domain = error.domain;
    final code = error.code;
    final message = cbl.utf8ToStr(res);

    if (cleanup != null) cleanup();
    pffi.free(error.addressOf);

    throw CouchbaseLiteException(domain, code, message);
  }
  pffi.free(error.addressOf);
}

class CouchbaseLiteException implements Exception {
  int domain;
  int code;
  String message;

  CouchbaseLiteException(this.domain, this.code, this.message);

  @override
  String toString() => 'Domain: $domain, Code: $code, Message: $message';
}
