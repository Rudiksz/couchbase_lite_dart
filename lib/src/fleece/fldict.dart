// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// FLDict is a "subclass" of FLValue, representing values that are dictionaries.
class FLDict extends IterableBase<FLValue> {
  /// The C pointer to the FLDict
  Pointer<cbl.FLDict> _value = nullptr;
  Pointer<cbl.FLDict> get ref => _value;

  /// True if the current value was retained beyond it's scope
  bool _retained = false;
  bool get retained => _retained;

  bool? _mutable;

  FLError error = FLError.noError;

  Pointer<cbl.FLDictIterator> _c_iter = nullptr;
  Iterator<FLValue>? _iter;
  FLDictValues? _values;
  FLDictKeys? _keys;
  FLDictEntries? _entries;

  FLDict() {
    _value = CBLC.FLMutableDict_New().cast<cbl.FLDict>();
  }

  FLDict.empty();
  FLDict.fromPointer(this._value);

  FLDict.fromMap(Map<dynamic, dynamic> map) {
    _fromData(jsonEncode(map));
  }

  FLDict.fromJson(String json) {
    _fromData(json);
  }

  void _fromData(String data) {
    final fldoc = FLDoc.fromJson(data);
    _value = fldoc.root.asMap.ref;
    error = fldoc.error;
    retain();
    CBLC.FLDoc_Release(fldoc._doc);
  }

  FLValue get value => FLValue.fromPointer(_value.cast());

  bool get isMutable => _mutable ??= (CBLC.FLDict_AsMutable(_value) != nullptr);

  /// Create a shallow mutable copy of this value
  FLDict get mutable => FLDict.fromPointer(
        CBLC.FLDict_MutableCopy(
          _value,
          cbl.FLCopyFlags.kFLDefaultCopy,
        ).cast<cbl.FLDict>(),
      );

  /// Creates a deep (recursive) mutable copy of this value
  FLDict get mutableCopy => FLDict.fromPointer(
        CBLC.FLDict_MutableCopy(
          _value,
          cbl.FLCopyFlags.kFLDeepCopyImmutables,
        ).cast<cbl.FLDict>(),
      );

  bool get changed => isMutable && CBLC.FLMutableDict_IsChanged(_value.cast());

  /// Encodes a Fleece value as JSON (or a JSON fragment.)
  /// Any Data values will become base64-encoded JSON strings.
  String get json {
    final slice = FLSlice.fromSliceResult(CBLC.FLValue_ToJSON(_value.cast()));
    final result = slice.toString();
    slice.free();
    return result;
  }

  @override
  String toString() => json;

  @override
  int get length => CBLC.FLDict_Count(_value);

  @override
  bool get isEmpty => CBLC.FLDict_IsEmpty(_value);

  @override
  bool get isNotEmpty => !isEmpty;

  FLValue call(String keyPath) {
    // Some values are not supported
    if (keyPath.isEmpty || keyPath.contains('[]')) {
      return FLValue.empty();
    }
    final outError = calloc<Int32>()..value = 0;
    final _keyPath = FLSlice.fromString(keyPath);

    final val = CBLC.FLKeyPath_EvalOnce(
      _keyPath.slice,
      _value.cast(),
      outError,
    );
    error = outError.value < FLError.values.length
        ? FLError.values[outError.value]
        : FLError.unsupported;
    calloc.free(outError);
    _keyPath.free();

    return error == FLError.noError
        ? FLValue.fromPointer(val)
        : FLValue.empty();
  }

  FLValue operator [](String key) {
    final _key = FLSlice.fromString(key);
    final value = FLValue.fromPointer(CBLC.FLDict_Get(
      _value.cast(),
      _key.slice,
    ));
    _key.free();
    return value;
  }

  /// Set the value of a key
  ///
  /// You can set scalar values (int, bool double, String), FLValue, FLDict, FLArray.
  /// Any other object will be JSON encoded if possible.
  void operator []=(dynamic index, dynamic value) {
    if (!isMutable) {
      throw CouchbaseLiteException(
        cbl.CBLFleeceDomain,
        cbl.CBLErrorNotWriteable,
        'Dictionary is not mutable',
      );
    }

    // !fix for: https://forums.couchbase.com/t/27825
    final _index = FLSlice.fromString(index);
    CBLC.FLDict_Get(_value, _index.slice);

    final slot = CBLC.FLMutableDict_Set(
      _value.cast<cbl.FLDict>(),
      _index.slice,
    );
    _index.free();

    if (value == null) return CBLC.FLSlot_SetNull(slot);

    switch (value.runtimeType) {
      case FLValue:
      case FLDict:
      case FLArray:
        CBLC.FLSlot_SetValue(slot, value.ref.cast<cbl.FLValue>());
        break;
      case bool:
        CBLC.FLSlot_SetBool(slot, value as bool);
        break;
      case int:
        CBLC.FLSlot_SetInt(slot, value as int);
        break;
      case double:
        CBLC.FLSlot_SetDouble(slot, value as double);
        break;
      case String:
        final _value = FLSlice.fromString(value);
        CBLC.FLSlot_SetString(slot, _value.slice);
        _value.free();
        break;
      default:
        // Create a value from the input
        final valueDoc = FLDoc.fromJson(jsonEncode(value));
        if (valueDoc.error != FLError.noError) return;
        CBLC.FLSlot_SetValue(slot, valueDoc.root.ref);
    }
  }

  FLDict retain() {
    if (_value != nullptr && !_retained) {
      CBLC.FLValue_Retain(_value.cast());
      _retained = true;
    }
    return this;
  }

  void dispose() {
    if (_value != nullptr && _retained) {
      CBLC.FLValue_Release(_value.cast());
    }
    _value = nullptr;
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
  Iterator<FLValue>? _iter;

  FLDictValues(this.dict);

  @override
  Iterator<FLValue> get iterator => _iter ??= FLDictValueIterator(dict);
}

class FLDictKeys extends IterableBase<String> {
  final FLDict dict;
  Iterator<String>? _iter;

  FLDictKeys(this.dict);

  @override
  Iterator<String> get iterator => _iter ??= FLDictKeyIterator(dict);
}

class FLDictEntries extends IterableBase<MapEntry<String, FLValue>> {
  final FLDict dict;
  Iterator<MapEntry<String, FLValue>>? _iter;

  FLDictEntries(this.dict);

  @override
  Iterator<MapEntry<String, FLValue>> get iterator =>
      _iter ??= FLDictEntryIterator(dict);
}

// -- FLDictValueIterator

class FLDictValueIterator implements Iterator<FLValue> {
  final FLDict _dict;
  bool first = true;

  FLDictValueIterator(this._dict) {
    if (_dict._c_iter == nullptr) {
      _dict._c_iter = calloc<cbl.FLDictIterator>();
      CBLC.FLDictIterator_Begin(_dict._value, _dict._c_iter);
    }
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first elemen.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  FLValue get current {
    return FLValue.fromPointer(CBLC.FLDictIterator_GetValue(_dict._c_iter));
  }

  @override
  bool moveNext() {
    if (_dict.isEmpty) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = CBLC.FLDictIterator_Next(_dict._c_iter);
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    CBLC.FLDictIterator_End(_dict._c_iter);
    _dict._c_iter = nullptr;
  }
}

// -- FLDictKeyInterator

class FLDictKeyIterator implements Iterator<String> {
  final FLDict _dict;
  bool first = true;

  FLDictKeyIterator(this._dict) {
    if (_dict._c_iter == nullptr) {
      _dict._c_iter = calloc<cbl.FLDictIterator>();
      CBLC.FLDictIterator_Begin(_dict._value, _dict._c_iter);
    }
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first elemen.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  String get current {
    return FLValue.fromPointer(CBLC.FLDictIterator_GetKey(_dict._c_iter))
        .asString;
  }

  @override
  bool moveNext() {
    if (_dict.isEmpty) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = CBLC.FLDictIterator_Next(_dict._c_iter);
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    CBLC.FLDictIterator_End(_dict._c_iter);
    _dict._c_iter = nullptr;
  }
}

// -- FLDictEntryIterator

class FLDictEntryIterator implements Iterator<MapEntry<String, FLValue>> {
  final FLDict _dict;
  bool first = true;

  FLDictEntryIterator(this._dict) {
    if (_dict._c_iter == nullptr) {
      _dict._c_iter = calloc<cbl.FLDictIterator>();
      CBLC.FLDictIterator_Begin(_dict._value, _dict._c_iter);
    }
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first elemen.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  MapEntry<String, FLValue> get current {
    final keyPointer = CBLC.FLDictIterator_GetKeyString(_dict._c_iter);
    final _key = FLSlice.fromSlice(keyPointer);

    final entry = MapEntry<String, FLValue>(
      _key.toString(),
      FLValue.fromPointer(CBLC.FLDictIterator_GetValue(_dict._c_iter)),
    );
    _key.free();

    return entry;
  }

  @override
  bool moveNext() {
    if (_dict.isEmpty) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = CBLC.FLDictIterator_Next(_dict._c_iter);
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    CBLC.FLDictIterator_End(_dict._c_iter);
    _dict._c_iter = nullptr;
  }
}
