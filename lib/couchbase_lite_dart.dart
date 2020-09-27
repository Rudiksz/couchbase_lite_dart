// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library couchbase_lite_dart;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'package:path/path.dart';

import 'package:ffi/ffi.dart' as pffi;
import 'dart:ffi' as ffi;

import 'package:uuid/uuid.dart';

part 'src/base.dart';
part 'src/database.dart';
part 'src/document.dart';
part 'src/query.dart';
part 'src/replicator.dart';
part 'src/blob.dart';
part 'src/database_error.dart';
part 'src/fleece/fldoc.dart';
part 'src/fleece/flvalue.dart';
part 'src/fleece/fldict.dart';
part 'src/fleece/flarray.dart';

part 'bindings/library.dart';
part 'bindings/database.dart';
part 'bindings/document.dart';
part 'bindings/query.dart';
part 'bindings/replicator.dart';
part 'bindings/blob.dart';
part 'bindings/listeners.dart';
part 'bindings/error.dart';
part 'bindings/fleece.dart';

final packagePath = findPackagePath(Directory.current.path);

// ffi.DynamicLibrary _dylib;
final _dylib = Platform.isWindows
    ? ffi.DynamicLibrary.open('$packagePath/dynlib/CouchbaseLiteC.dll')
    // ? ffi.DynamicLibrary.open(
    //     '../couchbase-lite-C_windows/Debug/CouchbaseLiteC.dll')
    : (Platform.isAndroid
        ? ffi.DynamicLibrary.open('libCouchbaseLiteC.so')
        : null);

class Cbl {
  static bool isPlatformSupported() => _dylib != null;
  static void init() {
    assert(isPlatformSupported());

    // Windows static linking workaround
    registerDart_PostCObject(ffi.NativeApi.postCObject);
    registerDart_NewNativePort(ffi.NativeApi.newNativePort);
    registerDart_CloseNativePort(ffi.NativeApi.closeNativePort);
  }
}

/// Build a file path.
String toFilePath(String parent, String path, {bool windows}) {
  var uri = Uri.parse(path);
  path = uri.toFilePath(windows: windows);
  if (isRelative(path)) {
    return normalize(join(parent, path));
  }
  return normalize(path);
}

/// Find our package path in the current project
String findPackagePath(String currentPath, {bool windows}) {
  String findPath(File file) {
    var lines = LineSplitter.split(file.readAsStringSync());
    for (var line in lines) {
      var parts = line.split(':');
      if (parts.length > 1) {
        if (parts[0] == 'couchbase_lite_dart') {
          var location = parts.sublist(1).join(':');
          return absolute(normalize(
              toFilePath(dirname(file.path), location, windows: windows)));
        }
      }
    }
    return null;
  }

  var file = File(join(currentPath, '.packages'));
  if (file.existsSync()) {
    return findPath(file);
  } else {
    var parent = dirname(currentPath);
    if (parent == currentPath) {
      return null;
    }
    return findPackagePath(parent);
  }
}
