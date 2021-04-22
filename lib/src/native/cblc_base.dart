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

  print(File('lib/dynlib/CouchbaseLiteC.dll').absolute.path);

  late String dylibPath;
  late var dylib;
  if (Platform.isAndroid) {
    dylibPath = dylibs['android'] ?? 'CouchbaseLiteC.so';
  } else if (Platform.isMacOS) {
    dylibPath = dylibs['macos'] ?? 'dynlib/CouchbaseLiteC.dylib';
  } else if (Platform.isWindows) {
    dylibPath = dylibs['windows'] ?? 'lib/dynlib/CouchbaseLiteC.dll';
  } else if (Platform.isLinux) {
    dylibPath = dylibs['linux'] ?? 'CouchbaseLiteC.so';
  }
  try {
    if (Platform.isIOS) {
      dylib = DynamicLibrary.process();
    } else {
      dylib = DynamicLibrary.open(dylibPath);
    }

    _CBLC = CblCBindings(dylib);
    Cbl.dylib = dylib;

    _CBLC?.CBLDart_PostCObject(NativeApi.postCObject.cast());
    /*registerDart_NewNativePort(NativeApi.newNativePort);
  registerDart_CloseNativePort(NativeApi.closeNativePort);*/

  } catch (e) {
    print(e.toString());
    throw Exception('Could not initialize CouchbaseLiteC library.');
  }

  // final registerSendPort =
  //     dylib.lookup<Void Function(Int64 sendPort), void Function(int sendPort)>(
  //         'RegisterSendPort');
/*
  final registerDart_PostCObject_ptr = dylib.lookup<
      Void Function(
          NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>
              functionPointer)>('RegisterDart_PostCObject');

  final registerDart_PostCObject = registerDart_PostCObject_ptr.asFunction<
      void Function(
          Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
              functionPointer)>();

  final registerDart_NewNativePort = dylib.lookupFunction<
      Void Function(
          Pointer<
                  NativeFunction<
                      Int64 Function(
                          Pointer<Uint8>,
                          Pointer<NativeFunction<Dart_NativeMessageHandler>>,
                          Int8)>>
              functionPointer),
      void Function(
          Pointer<
                  NativeFunction<
                      Int64 Function(
                          Pointer<Uint8>,
                          Pointer<NativeFunction<Dart_NativeMessageHandler>>,
                          Int8)>>
              functionPointer)>('RegisterDart_NewNativePort');

  final registerDart_CloseNativePort = dylib?.lookupFunction<
          Void Function(
              Pointer<NativeFunction<Int8 Function(Int64)>> functionPointer),
          void Function(
              Pointer<NativeFunction<Int8 Function(Int64)>> functionPointer)>(
      'RegisterDart_CloseNativePort');

  // Windows static linking workaround
  registerDart_PostCObject(NativeApi.postCObject);
  registerDart_NewNativePort(NativeApi.newNativePort);
  registerDart_CloseNativePort(NativeApi.closeNativePort);*/

  ChangeListeners.initalize();
}

extension Dylib on CblCBindings {
  static DynamicLibrary? dylib;
}
