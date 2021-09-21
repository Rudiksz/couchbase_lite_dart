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

  FLDict() {
    _value = CBLC.FLMutableDict_New().cast<cbl.FLDict>();
    _retained = true;
  }

  FLDict.empty();
  FLDict.fromPointer(this._value);

  FLDict.fromMap(Map<dynamic, dynamic> map, {bool retain = true}) {
    _fromData(jsonEncode(map), retain: retain);
  }

  FLDict.fromJson(String json, {bool retain = true}) {
    _fromData(json, retain: retain);
  }

  void _fromData(String data, {bool retain = true}) {
    final fldoc = FLDoc.fromJson(data);
    _value = fldoc.root.asDict.ref;
    error = fldoc.error;
    if (retain) this.retain();
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
      ).._retained = true;

  /// Creates a deep (recursive) mutable copy of this value
  FLDict get mutableCopy => FLDict.fromPointer(
        CBLC.FLDict_MutableCopy(
          _value,
          cbl.FLCopyFlags.kFLDeepCopyImmutables,
        ).cast<cbl.FLDict>(),
      ).._retained = true;

  bool get changed => isMutable && CBLC.FLMutableDict_IsChanged(_value.cast());

  /// Encodes a Fleece value as JSON (or a JSON fragment.)
  /// Any Data values will become base64-encoded JSON strings.
  String get json {
    final slice = CBLC.FLValue_ToJSON(_value.cast());
    final result = slice.asString();
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
      _keyPath.slice.ref,
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

  /// Two FLDicts are equal if they point to the same memory.
  /// This is a shallow comparison.
  @override
  bool operator ==(Object other) => other is FLArray && other._value == _value;

  /// A deep recursive comparison of two values
  bool equals(FLDict other) =>
      CBLC.FLValue_IsEqual(_value.cast(), other._value.cast());

  FLValue operator [](String key) {
    final _key = FLSlice.fromString(key);
    final value = FLValue.fromPointer(CBLC.FLDict_Get(
      _value.cast(),
      _key.slice.ref,
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
        cbl.kCBLFleeceDomain,
        cbl.kCBLErrorNotWriteable,
        'Dictionary is not mutable',
      );
    }

    // !fix for: https://forums.couchbase.com/t/27825
    final _index = FLSlice.fromString(index);
    CBLC.FLDict_Get(_value, _index.slice.ref);

    final slot = CBLC.FLMutableDict_Set(
      _value.cast<cbl.FLDict>(),
      _index.slice.ref,
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
        CBLC.FLSlot_SetString(slot, _value.slice.ref);
        _value.free();
        break;
      default:
        // Create a value from the input
        final valueDoc = FLDoc.fromJson(jsonEncode(value));
        if (valueDoc.error != FLError.noError) return;
        CBLC.FLSlot_SetValue(slot, valueDoc.root.ref);
        valueDoc.dispose();
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
  Iterator<FLValue> get iterator => FLDictValueIterator(this);

  FLDictValues get values => FLDictValues(this);

  FLDictKeys get keys => FLDictKeys(this);

  FLDictEntries get entries => FLDictEntries(this);
}

class FLDictValues extends IterableBase<FLValue> {
  final FLDict dict;

  FLDictValues(this.dict);

  @override
  Iterator<FLValue> get iterator => FLDictValueIterator(dict);
}

class FLDictKeys extends IterableBase<String> {
  final FLDict dict;

  FLDictKeys(this.dict);

  @override
  Iterator<String> get iterator => FLDictKeyIterator(dict);
}

class FLDictEntries extends IterableBase<MapEntry<FLValue, FLValue>> {
  final FLDict dict;

  FLDictEntries(this.dict);

  @override
  Iterator<MapEntry<FLValue, FLValue>> get iterator =>
      FLDictEntryIterator(dict);
}

// -- FLDictValueIterator

class FLDictValueIterator implements Iterator<FLValue> {
  Pointer<cbl.FLDictIterator> _iter = nullptr;
  final FLDict _dict;
  bool first = true;

  FLDictValueIterator(this._dict) {
    if (_iter == nullptr) {
      _iter = calloc<cbl.FLDictIterator>();
      CBLC.FLDictIterator_Begin(_dict._value, _iter);
    }
  }

  // Note: The FLDictIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first elemen.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  FLValue get current {
    if (_dict.isEmpty || _iter == nullptr) return FLValue.empty();
    return FLValue.fromPointer(CBLC.FLDictIterator_GetValue(_iter));
  }

  @override
  bool moveNext() {
    if (_dict.isEmpty) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = CBLC.FLDictIterator_Next(_iter);
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    CBLC.FLDictIterator_End(_iter);
    calloc.free(_iter);
    _iter = nullptr;
  }
}

// -- FLDictKeyInterator

class FLDictKeyIterator implements Iterator<String> {
  Pointer<cbl.FLDictIterator> _iter = nullptr;
  final FLDict _dict;
  bool first = true;

  FLDictKeyIterator(this._dict) {
    if (_iter == nullptr) {
      _iter = calloc<cbl.FLDictIterator>();
      CBLC.FLDictIterator_Begin(_dict._value, _iter);
    }
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first elemen.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  String get current {
    return FLValue.fromPointer(CBLC.FLDictIterator_GetKey(_iter)).asString;
  }

  @override
  bool moveNext() {
    if (_dict.isEmpty) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = CBLC.FLDictIterator_Next(_iter);
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    CBLC.FLDictIterator_End(_iter);
    calloc.free(_iter);
    _iter = nullptr;
  }
}

// -- FLDictEntryIterator

class FLDictEntryIterator implements Iterator<MapEntry<FLValue, FLValue>> {
  Pointer<cbl.FLDictIterator> _iter = nullptr;
  final FLDict _dict;
  bool first = true;

  FLDictEntryIterator(this._dict) {
    if (_iter == nullptr) {
      _iter = calloc<cbl.FLDictIterator>();
      CBLC.FLDictIterator_Begin(_dict._value, _iter);
    }
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first elemen.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  MapEntry<FLValue, FLValue> get current {
    // final keyPointer = CBLC.FLDictIterator_GetKeyString(_iter);
    final keyPointer = CBLC.FLDictIterator_GetKey(_iter);

    final entry = MapEntry<FLValue, FLValue>(
      FLValue.fromPointer(keyPointer),
      FLValue.fromPointer(CBLC.FLDictIterator_GetValue(_iter)),
    );

    return entry;
  }

  @override
  bool moveNext() {
    if (_dict.isEmpty) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = CBLC.FLDictIterator_Next(_iter);
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    CBLC.FLDictIterator_End(_iter);
    calloc.free(_iter);
    _iter = nullptr;
  }
}
