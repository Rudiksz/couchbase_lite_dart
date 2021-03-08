// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// FLArray is a "subclass" of FLValue, representing values that are arrays.
class FLArray extends IterableBase<FLValue> {
  /// The C pointer to the FLArray
  ffi.Pointer<cbl.FLArray> _value;
  ffi.Pointer<cbl.FLArray> get ref => _value;

  bool _mutable;

  /// True if the current value was retained beyond it's scope
  bool _retained = false;

  // final error = pffi.allocate<ffi.Uint8>();
  FLError error;

  FLArrayIterator _iter;

  FLArray() {
    _value = cbl.FLMutableArray_New().cast<cbl.FLArray>();
  }

  FLArray.fromPointer(this._value);

  FLArray.fromList(List<dynamic> list) {
    _fromData(jsonEncode(list));
  }

  FLArray.fromJson(String json) {
    _fromData(json);
  }

  void _fromData(String data) {
    final fldoc = FLDoc.fromJson(data);
    _value = fldoc.root?.asList?.ref ?? ffi.nullptr;
    error = fldoc.error;
    retain();
    cbl.FLDoc_Release(fldoc._doc);
  }

  /// Cast the FLArray as a FLValue
  FLValue get value => FLValue.fromPointer(_value.cast());

  bool get isMutable =>
      _mutable ??= cbl.FLArray_AsMutable(_value) != ffi.nullptr;

  /// Creates a shallow mutable copy of this dictionary
  FLArray get mutable => FLArray.fromPointer(cbl.FLArray_MutableCopy(
        _value,
        cbl.FLCopyFlags.defaultCopy.index,
      ).cast<cbl.FLArray>());

  /// Creates a deep (recursive) mutable copy of this dictionary
  FLArray get mutableCopy => FLArray.fromPointer(cbl.FLArray_MutableCopy(
        _value,
        cbl.FLCopyFlags.deepCopy.index | cbl.FLCopyFlags.copyImmutables.index,
      ).cast<cbl.FLArray>());

  bool get changed =>
      isMutable && cbl.FLMutableDict_IsChanged(_value.cast()) != 0;

  /// Encodes the array value as JSON (or a JSON fragment.)
  /// Any Data values will become base64-encoded JSON strings.
  String get json {
    final cstr = cbl.FLDump(_value.cast());
    final str = cstr.cast<pffi.Utf8>().toDartString();
    return str;
  }

  @override
  String toString() => json;

  @override
  int get length => cbl.FLArray_Count(_value);

  @override
  bool get isEmpty => cbl.FLArray_IsEmpty(_value) != 0;

  @override
  bool get isNotEmpty => !isEmpty;

  FLValue call(String keyPath) {
    // Some values are not supported
    if (keyPath.isEmpty || keyPath.contains('[]')) return null;
    final outError = pffi.calloc<ffi.Uint8>();
    outError.value = 0;
    final val = cbl.FLKeyPath_EvalOnce(
      keyPath.toNativeUtf8().cast(),
      _value.cast(),
      outError,
    );
    error = outError.value < FLError.values.length
        ? FLError.values[outError.value]
        : FLError.unsupported;
    pffi.calloc.free(outError);

    return error == FLError.noError ? FLValue.fromPointer(val) : null;
  }

  /// Returns an value at an array index, or NULL if the index is out of range.
  FLValue operator [](int index) =>
      FLValue.fromPointer(cbl.FLArray_Get(_value, index));

  /// Set the value at an array index
  ///
  /// If the index is out of bounds, the value will be appended to the list.
  /// You can set scalar values (int, bool double, String), FLValue, FLDict, FLArray.
  /// Any other object will be JSON encoded if possible.
  void operator []=(int index, dynamic value) {
    if (!isMutable) {
      throw CouchbaseLiteException(
        cbl.CBLErrorDomain.CBLFleeceDomain.index,
        cbl.CBLErrorCode.CBLErrorNotWriteable.index,
        'List is not mutable',
      );
    }

    final slot = index > length - 1
        ? cbl.FLMutableArray_Append(_value.cast())
        : cbl.FLMutableArray_Set(_value.cast(), index);

    if (value == null) return cbl.FLSlot_SetNull(slot);

    switch (value.runtimeType) {
      case FLValue:
      case FLDict:
      case FLArray:
        cbl.FLSlot_SetValue(slot, value.ref.cast<cbl.FLValue>());
        break;
      case bool:
        cbl.FLSlot_SetBool(slot, (value as bool) ? 1 : 0);
        break;
      case int:
        cbl.FLSlot_SetInt(slot, value as int);
        break;
      case double:
        cbl.FLSlot_SetDouble(slot, value as double);
        break;
      case String:
        cbl.FLSlot_SetString(slot, (value as String).toNativeUtf8().cast());
        break;
      default:
        // Create a value from the input
        final valueDoc = FLDoc.fromJson(jsonEncode(value));
        if (valueDoc.error != FLError.noError) return;
        cbl.FLSlot_SetValue(slot, valueDoc.root.ref);
    }
  }

  FLArray retain() {
    if (_value != null && _value != ffi.nullptr && !_retained) {
      cbl.FLValue_Retain(_value.cast());
      _retained = true;
    }
    return this;
  }

  void dispose() {
    if (_value != null && _value != ffi.nullptr && _retained) {
      cbl.FLValue_Release(_value.cast());
    }
    _value = ffi.nullptr;
    _retained = false;
    _iter?.end();
    _iter = null;
  }

  @override
  Iterator<FLValue> get iterator => _iter ??= FLArrayIterator(this);
}

class FLArrayIterator implements Iterator<FLValue> {
  ffi.Pointer<cbl.FLArrayIterator> _iter = ffi.nullptr;
  final FLArray _array;
  bool first = true;
  int count = 0;

  FLArrayIterator(this._array) {
    if (_iter == ffi.nullptr) _iter = cbl.FLArrayIterator_New(_array._value);
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first element.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  FLValue get current {
    if (_array.isEmpty || _iter == ffi.nullptr) return null;

    return FLValue.fromPointer(cbl.FLArrayIterator_GetValue(_iter));
  }

  @override
  bool moveNext() {
    if (_array.isEmpty || _iter == ffi.nullptr) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = cbl.FLArrayIterator_Next(_iter) != 0;

    // Release the C iterator
    if (!next) end();

    return next;
  }

  /// Releases the C iterator
  void end() {
    cbl.Dart_Free(_iter);
    _iter = ffi.nullptr;
  }
}
