import 'dart:ffi';

import 'cblc_base.dart';

class CBLDart_Work extends Opaque {}

void CBLDart_ExecuteCallback(
  Pointer<Int32> work_ptr,
) {
  return _CBLDart_ExecuteCallback(
    work_ptr,
  );
}

final _CBLDart_ExecuteCallback_ptr = Cbl.dylib
    .lookup<NativeFunction<_c_CBLDart_ExecuteCallback>>(
        'CBLDart_ExecuteCallback');

final _dart_CBLDart_ExecuteCallback _CBLDart_ExecuteCallback =
    _CBLDart_ExecuteCallback_ptr.asFunction<_dart_CBLDart_ExecuteCallback>();

typedef _c_CBLDart_ExecuteCallback = Void Function(
  Pointer<Int32> work_ptr,
);
typedef _dart_CBLDart_ExecuteCallback = void Function(
  Pointer<Int32> work_ptr,
);
