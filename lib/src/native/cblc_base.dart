import 'dart:ffi';
import 'dart:io';

import '../../couchbase_lite_dart.dart';
import 'bindings.dart';

CblCBindings? _CBLC;
CblCBindings get CBLC => _CBLC!;

class Cbl {
  static late DynamicLibrary dylib;
  static void init() => initializeCblC();
}

void initializeCblC({Map<String, String> dylibs = const {}}) {
  if (_CBLC != null) {
    return;
  }

  late String dylibPath;
  late var dylib;
  if (Platform.isAndroid) {
    throw Exception('Android support is still work in progress');
    //dylibPath = dylibs['android'] ?? 'CouchbaseLiteC.so';
  } else if (Platform.isMacOS) {
    dylibPath = dylibs['macos'] ?? 'dynlib/libCouchbaseLiteC.dylib';
  } else if (Platform.isWindows) {
    dylibPath = dylibs['windows'] ?? 'dynlib/CouchbaseLiteC.dll';
  } else if (Platform.isLinux) {
    throw Exception('Linux support is still work in progress');
    dylibPath = dylibs['linux'] ?? 'CouchbaseLiteC.so';
  }
  try {
    if (Platform.isIOS) {
      throw Exception('iOS support is still work in progress');
      dylib = DynamicLibrary.process();
    } else {
      dylib = DynamicLibrary.open(dylibPath);
    }

    _CBLC = CblCBindings(dylib);
    Cbl.dylib = dylib;

    _CBLC?.CBLDart_PostCObject(NativeApi.postCObject.cast());
  } catch (e) {
    throw Exception('Could not initialize CouchbaseLiteC library.');
  }

  ChangeListeners.initalize();
}

extension Dylib on CblCBindings {
  static DynamicLibrary? dylib;
}
