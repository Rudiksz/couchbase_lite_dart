import 'dart:ffi';
import 'dart:io';

import '../../couchbase_lite_dart.dart';
import 'bindings.dart';

CblCBindings? _CBLC;
CblCBindings get CBLC => _CBLC!;

class Cbl {
  static late DynamicLibrary dylib;
  static void init() => initializeCblC();
  static int get instanceCount => CBLC.CBL_InstanceCount();
}

void initializeCblC({Map<String, String> dylibs = const {}}) {
  if (_CBLC != null) {
    return;
  }

  var dylibPath = 'vendor/cblite/';
  var libName = '';
  late DynamicLibrary dylib;

  if (Platform.isAndroid) {
    dylibPath = '';
    libName = 'CouchbaseLiteC.so';
  } else if (Platform.isMacOS) {
    libName = 'libCouchbaseLiteC.dylib';
  } else if (Platform.isWindows) {
    libName = 'CouchbaseLiteC.dll';
  } else if (Platform.isLinux) {
    throw Exception('Linux support is still work in progress');
    //libName = 'CouchbaseLiteC.so';
  }

  try {
    try {
      if (Platform.isIOS) {
        throw Exception('iOS support is still work in progress');
        //dylib = DynamicLibrary.process();
      } else {
        dylib = DynamicLibrary.open(dylibPath + libName);
      }
    } catch (e) {
      if (Platform.isIOS) {
        throw Exception('iOS support is still work in progress');
        //dylib = DynamicLibrary.process();
      } else {
        dylib = DynamicLibrary.open(libName);
      }
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
