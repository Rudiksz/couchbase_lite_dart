import 'dart:ffi';
import 'dart:io';

import '../../couchbase_lite_dart.dart';
import 'bindings.dart';

CblCBindings? _CBLC;
CblCBindings get CBLC => _CBLC!;

class Cbl {
  static late DynamicLibrary dylib;
  static void init() {
    initializeCblC();
  }
}

DynamicLibrary? _lib;
void initializeCblC({Map<String, String> dylibs = const {}}) {
  if (_CBLC != null) {
    return;
  }
  _lib = null;
  var libName = 'CouchbaseLiteC';
  if (Platform.isWindows) {
    libName += '.dll';
    try {
      _lib = DynamicLibrary.open(libName);
    } on ArgumentError {
      libName = 'lib/' + libName;
    }
  } else if (Platform.isMacOS) {
    libName = 'lib' + libName + '.dylib';
    try {
      _lib = DynamicLibrary.open(libName);
    } on ArgumentError {
      libName = '/usr/local/lib/' + libName;
    }
  } else if (Platform.isAndroid) {
    libName = 'lib' + libName + '-jni.so';
  } else if (Platform.isLinux) {
    libName = 'lib' + libName + '.so';
  } else {
    return null;
  }
  _lib ??= DynamicLibrary.open(libName);

  ChangeListeners.initalize();
}

extension Dylib on CblCBindings {
  static DynamicLibrary? dylib;
}
