// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// FLArray is a "subclass" of FLValue, representing values that are arrays.
class FLArray extends IterableBase<FLValue> {
  /// The C pointer to the FLArray
  Pointer<cbl.FLArray> _value = nullptr;
  Pointer<cbl.FLArray> get ref => _value;

  bool? _mutable;

  /// True if the current value was retained beyond it's scope
  bool _retained = false;

  FLError error = FLError.noError;

  FLArray.empty();
  FLArray() : _value = CBLC.FLMutableArray_New().cast<cbl.FLArray>();

  FLArray.fromPointer(this._value);

  FLArray.fromList(List<dynamic> list, {bool retain = true}) {
    _fromData(jsonEncode(list), retain: retain);
  }

  FLArray.fromJson(String json, {bool retain = true}) {
    _fromData(json, retain: retain);
  }

  void _fromData(String data, {bool retain = true}) {
    final fldoc = FLDoc.fromJson(data);
    _value = fldoc.root.asArray.ref;
    error = fldoc.error;
    if (retain) this.retain();
    CBLC.FLDoc_Release(fldoc._doc);
  }

  /// Cast the FLArray as a FLValue
  FLValue get value => FLValue.fromPointer(_value.cast());

  bool get isMutable => _mutable ??= CBLC.FLArray_AsMutable(_value) != nullptr;

  /// Creates a shallow mutable copy of this dictionary
  FLArray get mutable => FLArray.fromPointer(CBLC.FLArray_MutableCopy(
        _value,
        cbl.FLCopyFlags.kFLDefaultCopy,
      ).cast<cbl.FLArray>())
        .._retained = true;

  /// Creates a deep (recursive) mutable copy of this dictionary
  FLArray get mutableCopy => FLArray.fromPointer(CBLC.FLArray_MutableCopy(
        _value,
        cbl.FLCopyFlags.kFLDeepCopyImmutables,
      ).cast<cbl.FLArray>())
        .._retained = true;

  bool get changed => isMutable && CBLC.FLMutableDict_IsChanged(_value.cast());

  /// Encodes the array value as JSON (or a JSON fragment.)
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
  int get length => CBLC.FLArray_Count(_value);

  @override
  bool get isEmpty => CBLC.FLArray_IsEmpty(_value);

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

  /// Two FLArrays are equal if they point to the same memory.
  /// This is a shallow comparison.
  @override
  bool operator ==(Object other) => other is FLArray && other._value == _value;

  /// A deep recursive comparison of two values
  bool equals(FLArray other) =>
      CBLC.FLValue_IsEqual(_value.cast(), other._value.cast());

  /// Returns an value at an array index, or NULL if the index is out of range.
  FLValue operator [](int index) =>
      FLValue.fromPointer(CBLC.FLArray_Get(_value, index));

  /// Set the value at an array index
  ///
  /// If the index is out of bounds, the value will be appended to the list.
  /// You can set scalar values (int, bool double, String), FLValue, FLDict, FLArray.
  /// Any other object will be JSON encoded if possible.
  void operator []=(int index, dynamic value) {
    if (!isMutable) {
      throw CouchbaseLiteException(
        cbl.kCBLFleeceDomain,
        cbl.kCBLErrorNotWriteable,
        'List is not mutable',
      );
    }

    final slot = index > length - 1
        ? CBLC.FLMutableArray_Append(_value.cast())
        : CBLC.FLMutableArray_Set(_value.cast(), index);

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

  FLArray retain() {
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
  Iterator<FLValue> get iterator => FLArrayIterator(this);
}

class FLArrayIterator implements Iterator<FLValue> {
  Pointer<cbl.FLArrayIterator> _iter = nullptr;
  final FLArray _array;
  bool first = true;

  FLArrayIterator(this._array) {
    if (_iter == nullptr) {
      _iter = calloc<cbl.FLArrayIterator>();
      CBLC.FLArrayIterator_Begin(_array._value, _iter);
    }
  }

  // Note: The FLArrayIterator_Begin method positions the iterator at the first element,
  // as opposed to Dart which expects new iterators to be 'before' the first element.
  // This causes for loops to skip the first element, unless we "lazy" initialize the
  // FLArrayIterator
  @override
  FLValue get current {
    if (_array.isEmpty || _iter == nullptr) return FLValue.empty();

    return FLValue.fromPointer(CBLC.FLArrayIterator_GetValue(_iter));
  }

  @override
  bool moveNext() {
    if (_array.isEmpty || _iter == nullptr) return false;
    if (first) {
      first = false;
      return true;
    }

    final next = CBLC.FLArrayIterator_Next(_iter);

    // Release the C iterator
    if (!next) end();
    return next;
  }

  /// Releases the C iterator
  void end() {
    //CBLC.FLArrayIterator_End(_iter); // TODO bindings
    calloc.free(_iter);
    _iter = nullptr;
  }
}
