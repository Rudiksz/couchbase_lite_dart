// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// FLDict is a "subclass" of FLValue, representing values that are dictionaries.
class FLDict extends IterableBase<FLValue> {
  /// The C pointer to the FLDict
  ffi.Pointer<cbl.FLDict> _value;
  ffi.Pointer<cbl.FLDict> get ref => _value;

  /// True if the current value was retained beyond it's scope
  bool _retained = false;

  bool _mutable;

  FLError error;

  ffi.Pointer<cbl.FLDictIterator> _c_iter = ffi.nullptr;
  Iterator<FLValue> _iter;
  FLDictValues _values;
  FLDictKeys _keys;
  FLDictEntries _entries;

  FLDict() {
    _value = cbl.FLMutableDict_New().cast<cbl.FLDict>();
  }

  FLDict.fromPointer(this._value);

  FLDict.fromMap(Map<dynamic, dynamic> map) {
    _fromData(jsonEncode(map));
  }

  FLDict.fromJson(String json) {
    _fromData(json);
  }

  void _fromData(String data) {
    final fldoc = FLDoc.fromJson(data);
    _value = fldoc.root?.asMap?.ref ?? ffi.nullptr;
    error = fldoc.error;
    retain();
    cbl.FLDoc_Release(fldoc._doc);
  }

  FLValue get value => FLValue.fromPointer(_value.cast());

  bool get isMutable =>
      _mutable ??= (cbl.FLDict_AsMutable(_value) != ffi.nullptr);

  /// Create a shallow mutable copy of this value
  FLDict get mutable => FLDict.fromPointer(cbl.FLDict_MutableCopy(
        _value,
        cbl.FLCopyFlags.defaultCopy.index,
      ).cast<cbl.FLDict>());

  /// Creates a deep (recursive) mutable copy of this value
  FLDict get mutableCopy => FLDict.fromPointer(cbl.FLDict_MutableCopy(
        _value,
        cbl.FLCopyFlags.deepCopy.index | cbl.FLCopyFlags.copyImmutables.index,
      ).cast<cbl.FLDict>());

  bool get changed =>
      isMutable && cbl.FLMutableDict_IsChanged(_value.cast()) != 0;

  /// Encodes a Fleece value as JSON (or a JSON fragment.)
  /// Any Data values will become base64-encoded JSON strings.
  String get json {
    final cstr = cbl.FLDump(_value.cast<cbl.FLValue>());
    final str = cstr.cast<pffi.Utf8>().toDartString();
    return str;
  }

  @override
  String toString() => json;

  @override
  int get length => cbl.FLDict_Count(_value);

  @override
  bool get isEmpty => cbl.FLDict_IsEmpty(_value) != 0;

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

  FLValue operator [](String key) => FLValue.fromPointer(
      cbl.FLDict_Get(_value.cast(), key.toNativeUtf8().cast()));

  /// Set the value of a key
  ///
  /// You can set scalar values (int, bool double, String), FLValue, FLDict, FLArray.
  /// Any other object will be JSON encoded if possible.
  void operator []=(dynamic index, dynamic value) {
    if (!isMutable) {
      throw CouchbaseLiteException(
        cbl.CBLErrorDomain.CBLFleeceDomain.index,
        cbl.CBLErrorCode.CBLErrorNotWriteable.index,
        'Dictionary is not mutable',
      );
    }

    // !fix for: https://forums.couchbase.com/t/27825
    cbl.FLDict_Get(_value, (index as String).toNativeUtf8().cast());

    final slot = cbl.FLMutableDict_Set(_value.cast<cbl.FLMutableDict>(),
        (index as String).toNativeUtf8().cast());

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

  FLDict retain() {
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
  }

  @override
  Iterator<FLValue> get iterator => _iter ??= FLDictValueIterator(this);

  FLDictValues get values => _values ??= FLDictValues(this);

  FLDictKeys get keys => _keys ??= FLDictKeys(this);

  FLDictEntries get entries => _entries ??= FLDictEntries(this);
}

class FLDictValues extends IterableBase<FLValue> {
  final FLDict dict;
  Iterator<FLValue> _iter;

  FLDictValues(this.dict);

  @override
  Iterator<FLValue> get iterator => _iter ??= FLDictValueIterator(dict);
}

class FLDictKeys extends IterableBase<String> {
  final FLDict dict;
  Iterator<String> _iter;

  FLDictKeys(this.dict);

  @override
  Iterator<String> get iterator => _iter ??= FLDictKeyIterator(dict);
}

class FLDictEntries extends IterableBase<MapEntry<String, FLValue>> {
  final FLDict dict;
  Iterator<MapEntry<String, FLValue>> _iter;

  FLDictEntries(this.dict);

  @override
  Iterator<MapEntry<String, FLValue>> get iterator =>
      _iter ??= FLDictEntryIterator(dict);
}

class FLDictValueIterator implements Iterator<FLValue> {
  final FLDict _dict;
  bool first = true;

  FLDictValueIterator(this._dict) {
    if (_dict._c_iter == ffi.nullptr) {
      _dict._c_iter = cbl.FLDictIterator_New(_dict._value);
    }
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first elemen.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  FLValue get current {
    return FLValue.fromPointer(cbl.FLDictIterator_GetValue(_dict._c_iter));
  }

  @override
  bool moveNext() {
    if (_dict.isEmpty) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = cbl.FLDictIterator_Next(_dict._c_iter) != 0;
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    cbl.Dart_Free(_dict._c_iter);
    _dict._c_iter = ffi.nullptr;
  }
}

class FLDictKeyIterator implements Iterator<String> {
  final FLDict _dict;
  bool first = true;

  FLDictKeyIterator(this._dict) {
    if (_dict._c_iter == ffi.nullptr) {
      _dict._c_iter = cbl.FLDictIterator_New(_dict._value);
    }
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first elemen.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  String get current {
    return FLValue.fromPointer(cbl.FLDictIterator_GetKey(_dict._c_iter))
        .asString;
  }

  @override
  bool moveNext() {
    if (_dict.isEmpty) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = cbl.FLDictIterator_Next(_dict._c_iter) != 0;
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    cbl.Dart_Free(_dict._c_iter);
    _dict._c_iter = ffi.nullptr;
  }
}

class FLDictEntryIterator implements Iterator<MapEntry<String, FLValue>> {
  final FLDict _dict;
  bool first = true;

  FLDictEntryIterator(this._dict) {
    if (_dict._c_iter == ffi.nullptr) {
      _dict._c_iter = cbl.FLDictIterator_New(_dict._value);
    }
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first elemen.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  MapEntry<String, FLValue> get current {
    final keyPointer = cbl.FLDictIterator_GetKeyString(_dict._c_iter);
    final key = keyPointer.cast<pffi.Utf8>().toDartString();
    cbl.Dart_Free(keyPointer);

    return MapEntry<String, FLValue>(
      key,
      FLValue.fromPointer(cbl.FLDictIterator_GetValue(_dict._c_iter)),
    );
  }

  @override
  bool moveNext() {
    if (_dict.isEmpty) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = cbl.FLDictIterator_Next(_dict._c_iter) != 0;
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    cbl.Dart_Free(_dict._c_iter);
    _dict._c_iter = ffi.nullptr;
  }
}
