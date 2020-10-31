// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// Retrieves the error message from the library and throws a [CouchbaseLiteException]
void databaseError(ffi.Pointer<cbl.CBLError> error) {
  if (error == null || error == ffi.nullptr) return;
  if (error.ref.domain > 0 &&
      error.ref.domain < cbl.CBLErrorDomain.CBLMaxErrorDomainPlus1.index - 1) {
    final res = cbl.CBLError_Message(error);

    final domain = error.ref.domain;
    final code = error.ref.code;
    final message = pffi.Utf8.fromUtf8(res.cast());

    pffi.free(error);

    throw CouchbaseLiteException(domain, code, message);
  }
  pffi.free(error);
}

class CouchbaseLiteException implements Exception {
  int domain;
  int code;
  String message;

  CouchbaseLiteException(this.domain, this.code, this.message);

  @override
  String toString() => 'Domain: $domain, Code: $code, Message: $message';
}
