// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

/// FLArray is a "subclass" of FLValue, representing values that are arrays.
class FLArray extends IterableBase<FLValue> {
  ffi.Pointer<cbl.FLArray> _value;
  FLArrayIterator _iter;
  ffi.Pointer<cbl.FLMutableArray> _mutable;
  FLArray.fromPointer(this._value);

  FLArray() {
    _value = cbl.FLMutableArray_New().cast<cbl.FLArray>();
  }

  ffi.Pointer<cbl.FLArray> get addressOf => _value;
  FLValue get value => FLValue.fromPointer(_value.cast());

  bool get isMutable =>
      (_mutable ??= cbl.FLArray_AsMutable(_value)) != ffi.nullptr;

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
    final str = cbl.utf8ToStr(cstr);
    // Dart_Free(cstr);
    return str;
  }

  @override
  String toString() {
    final cstr = cbl.FLValue_ToString(_value.cast<cbl.FLValue>());
    final result = cbl.utf8ToStr(cstr);
    // Dart_Free(cstr);
    return result;
  }

  @override
  int get length => cbl.FLArray_Count(_value);

  @override
  bool get isEmpty => cbl.FLArray_IsEmpty(_value) != 0;

  @override
  bool get isNotEmpty => !isEmpty;

  /// Returns an value at an array index, or NULL if the index is out of range.
  FLValue operator [](int index) =>
      FLValue.fromPointer(cbl.FLArray_Get(_value, index));

  /// Set the value at an array index
  ///
  /// If the index is out of bounds, the value will be appended to the list.
  /// You can set scalar values (int, bool double, String), FLValue, FLDict, FLArray.
  /// Any other object will be JSON encoded if possible.
  void operator []=(int index, dynamic value) {
    _mutable ??= cbl.FLArray_AsMutable(_value);

    if (_mutable == ffi.nullptr) {
      return print('dictionary is not mutable');
    }

    final slot = index > length - 1
        ? cbl.FLMutableArray_Append(_mutable)
        : cbl.FLMutableArray_Set(_mutable, index);

    if (value == null) return cbl.FLSlot_SetNull(slot);

    switch (value.runtimeType) {
      case FLValue:
      case FLDict:
      case FLArray:
        // case FLMutableArray:
        cbl.FLSlot_SetValue(slot, value.addressOf.cast<cbl.FLValue>());
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
        cbl.FLSlot_SetString(slot, cbl.FLSlice.allocate(value).addressOf);
        break;
      default:
        // Create a value from the input
        final valueDoc = FLDoc.fromJson(jsonEncode(value));
        if (valueDoc.error != FLError.noError) return;
        cbl.FLSlot_SetValue(slot, valueDoc.root.addressOf);
    }
  }

  @override
  Iterator<FLValue> get iterator => _iter ??= FLArrayIterator(this);

  void dispose() {
    _iter?.end();
    _iter = null;
  }
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
