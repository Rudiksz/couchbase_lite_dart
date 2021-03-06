// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// Retrieves the error message from the library and throws a [CouchbaseLiteException]
///
/// In case of an error calls the [cleanup] closure, if provided
///
/// Frees the [error] object
void validateError(ffi.Pointer<cbl.CBLError> error, {Function cleanup}) {
  if (error == null) return;
  if (error.ref.domain > 0 &&
      error.ref.domain < cbl.CBLErrorDomain.CBLMaxErrorDomainPlus1.index) {
    final res = cbl.CBLError_Message(error);

    final domain = error.ref.domain;
    final code = error.ref.code;
    final message = res.cast<pffi.Utf8>().toDartString();

    if (cleanup != null) cleanup();
    pffi.calloc.free(error);

    throw CouchbaseLiteException(domain, code, message);
  }
  pffi.calloc.free(error);
}

class CouchbaseLiteException implements Exception {
  int domain;
  int code;
  String message;

  CouchbaseLiteException(this.domain, this.code, this.message);

  @override
  String toString() => 'Domain: $domain, Code: $code, Message: $message';
}
