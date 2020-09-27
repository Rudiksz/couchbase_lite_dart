// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// coverage:ignore-file
part of couchbase_lite_c;

final FLDump = _dylib.lookupFunction<_c_FLDump, _dart_FLDump>('FLDump');

final FLDumpData =
    _dylib.lookupFunction<_c_FLDumpData, _dart_FLDumpData>('FLDumpData');

// -- FLSlice

final FLSlice_Equal = _dylib
    .lookupFunction<_c_FLSlice_Equal, _dart_FLSlice_Equal>('FLSlice_Equal');

final FLSlice_Compare =
    _dylib.lookupFunction<_c_FLSlice_Compare, _dart_FLSlice_Compare>(
        'FLSlice_Compare');

// -- FLDoc

final FLDoc_FromResultData =
    _dylib.lookupFunction<_c_FLDoc_FromResultData, _dart_FLDoc_FromResultData>(
        'FLDoc_FromResultData');

final FLDoc_FromJSON = _dylib
    .lookupFunction<_c_FLDoc_FromJSON, _dart_FLDoc_FromJSON>('FLDoc_FromJSON');

final FLDoc_GetData = _dylib
    .lookupFunction<_c_FLDoc_GetData, _dart_FLDoc_GetData>('FLDoc_GetData');

final FLDoc_GetRoot = _dylib
    .lookupFunction<_c_FLDoc_GetRoot, _dart_FLDoc_GetRoot>('FLDoc_GetRoot');

final FLDoc_Retain =
    _dylib.lookupFunction<_c_FLDoc_Retain, _dart_FLDoc_Retain>('FLDoc_Retain');

final FLDoc_Release = _dylib
    .lookupFunction<_c_FLDoc_Release, _dart_FLDoc_Release>('FLDoc_Release');

// -- FLValue

final FLData_ConvertJSON =
    _dylib.lookupFunction<_c_FLData_ConvertJSON, _dart_FLData_ConvertJSON>(
        'FLData_ConvertJSON');

final FLValue_FromData =
    _dylib.lookupFunction<_c_FLValue_FromData, _dart_FLValue_FromData>(
        'FLValue_FromData');

final FLValue_GetType =
    _dylib.lookupFunction<_c_FLValue_GetType, _dart_FLValue_GetType>(
        'FLValue_GetType');

final FLValue_IsEqual =
    _dylib.lookupFunction<_c_FLValue_IsEqual, _dart_FLValue_IsEqual>(
        'FLValue_IsEqual');

final FLValue_IsInteger =
    _dylib.lookupFunction<_c_FLValue_IsInteger, _dart_FLValue_IsInteger>(
        'FLValue_IsInteger');

final FLValue_IsUnsigned =
    _dylib.lookupFunction<_c_FLValue_IsUnsigned, _dart_FLValue_IsUnsigned>(
        'FLValue_IsUnsigned');

final FLValue_IsDouble =
    _dylib.lookupFunction<_c_FLValue_IsDouble, _dart_FLValue_IsDouble>(
        'FLValue_IsDouble');

final FLValue_AsBool = _dylib
    .lookupFunction<_c_FLValue_AsBool, _dart_FLValue_AsBool>('FLValue_AsBool');

final FLValue_AsInt = _dylib
    .lookupFunction<_c_FLValue_AsInt, _dart_FLValue_AsInt>('FLValue_AsInt');

final FLValue_AsUnsigned =
    _dylib.lookupFunction<_c_FLValue_AsUnsigned, _dart_FLValue_AsUnsigned>(
        'FLValue_AsUnsigned');

final FLValue_AsFloat =
    _dylib.lookupFunction<_c_FLValue_AsFloat, _dart_FLValue_AsFloat>(
        'FLValue_AsFloat');

final FLValue_AsDouble =
    _dylib.lookupFunction<_c_FLValue_AsDouble, _dart_FLValue_AsDouble>(
        'FLValue_AsDouble');

final FLValue_AsString =
    _dylib.lookupFunction<_c_FLValue_AsString_p, _dart_FLValue_AsString_p>(
        'FLValue_AsString_c');

final FLValue_AsArray =
    _dylib.lookupFunction<_c_FLValue_AsArray, _dart_FLValue_AsArray>(
        'FLValue_AsArray');

final FLValue_AsDict = _dylib
    .lookupFunction<_c_FLValue_AsDict, _dart_FLValue_AsDict>('FLValue_AsDict');

final FLValue_ToString =
    _dylib.lookupFunction<_c_FLValue_ToString, _dart_FLValue_ToString>(
        'FLValue_ToString_c');

final FLValue_ToJSON = _dylib
    .lookupFunction<_c_FLValue_ToJSON, _dart_FLValue_ToJSON>('FLValue_ToJSON');

// -- FLArray

final FLArray_AsMutable =
    _dylib.lookupFunction<_c_FLArray_AsMutable, _dart_FLArray_AsMutable>(
        'FLArray_AsMutable');

final FLArray_Count = _dylib
    .lookupFunction<_c_FLArray_Count, _dart_FLArray_Count>('FLArray_Count');

final FLArray_IsEmpty =
    _dylib.lookupFunction<_c_FLArray_IsEmpty, _dart_FLArray_IsEmpty>(
        'FLArray_IsEmpty');

final FLArray_Get =
    _dylib.lookupFunction<_c_FLArray_Get, _dart_FLArray_Get>('FLArray_Get');

final FLArrayIterator_New =
    _dylib.lookupFunction<_c_FLArrayIterator_New, _dart_FLArrayIterator_New>(
        'FLArrayIterator_New');

final FLArrayIterator_Begin = _dylib.lookupFunction<_c_FLArrayIterator_Begin,
    _dart_FLArrayIterator_Begin>('FLArrayIterator_Begin');

final FLArrayIterator_GetValue = _dylib.lookupFunction<
    _c_FLArrayIterator_GetValue,
    _dart_FLArrayIterator_GetValue>('FLArrayIterator_GetValue');

final FLArrayIterator_Next =
    _dylib.lookupFunction<_c_FLArrayIterator_Next, _dart_FLArrayIterator_Next>(
        'FLArrayIterator_Next');

// -- FLDict

final FLDict_AsMutable =
    _dylib.lookupFunction<_c_FLDict_AsMutable, _dart_FLDict_AsMutable>(
        'FLDict_AsMutable');

final FLDict_Count =
    _dylib.lookupFunction<_c_FLDict_Count, _dart_FLDict_Count>('FLDict_Count');

final FLDict_IsEmpty = _dylib
    .lookupFunction<_c_FLDict_IsEmpty, _dart_FLDict_IsEmpty>('FLDict_IsEmpty');

final FLDict_Get =
    _dylib.lookupFunction<_c_FLDict_Get, _dart_FLDict_Get>('FLDict_Get');

final FLDictIterator_New =
    _dylib.lookupFunction<_c_FLDictIterator_New, _dart_FLDictIterator_New>(
        'FLDictIterator_New');

final FLDictIterator_Begin =
    _dylib.lookupFunction<_c_FLDictIterator_Begin, _dart_FLDictIterator_Begin>(
        'FLDictIterator_Begin');

final FLDictIterator_GetKey = _dylib.lookupFunction<_c_FLDictIterator_GetKey,
    _dart_FLDictIterator_GetKey>('FLDictIterator_GetKey');

final FLDictIterator_GetValue = _dylib.lookupFunction<
    _c_FLDictIterator_GetValue,
    _dart_FLDictIterator_GetValue>('FLDictIterator_GetValue');

final FLDictIterator_Next =
    _dylib.lookupFunction<_c_FLDictIterator_Next, _dart_FLDictIterator_Next>(
        'FLDictIterator_Next');

// -- Mutable dictionary

final FLMutableDict_New =
    _dylib.lookupFunction<_c_FLMutableDict_New, _dart_FLMutableDict_New>(
        'FLMutableDict_New');

final FLDict_MutableCopy =
    _dylib.lookupFunction<_c_FLDict_MutableCopy, _dart_FLDict_MutableCopy>(
        'FLDict_MutableCopy');

final FLMutableDict_IsChanged = _dylib.lookupFunction<
    _c_FLMutableDict_IsChanged,
    _dart_FLMutableDict_IsChanged>('FLMutableDict_IsChanged');

final FLMutableDict_Set =
    _dylib.lookupFunction<_c_FLMutableDict_Set, _dart_FLMutableDict_Set>(
        'FLMutableDict_Set');

final FLMutableDict_Remove =
    _dylib.lookupFunction<_c_FLMutableDict_Remove, _dart_FLMutableDict_Remove>(
        'FLMutableDict_Remove');

final FLMutableDict_RemoveAll = _dylib.lookupFunction<
    _c_FLMutableDict_RemoveAll,
    _dart_FLMutableDict_RemoveAll>('FLMutableDict_RemoveAll');

// -- Mutable Array

final FLMutableArray_New =
    _dylib.lookupFunction<_c_FLMutableArray_New, _dart_FLMutableArray_New>(
        'FLMutableArray_New');

final FLArray_MutableCopy =
    _dylib.lookupFunction<_c_FLArray_MutableCopy, _dart_FLArray_MutableCopy>(
        'FLArray_MutableCopy');

final FLMutableArray_IsChanged = _dylib.lookupFunction<
    _c_FLMutableArray_IsChanged,
    _dart_FLMutableArray_IsChanged>('FLMutableArray_IsChanged');

final FLMutableArray_Set =
    _dylib.lookupFunction<_c_FLMutableArray_Set, _dart_FLMutableArray_Set>(
        'FLMutableArray_Set');

final FLMutableArray_Append = _dylib.lookupFunction<_c_FLMutableArray_Append,
    _dart_FLMutableArray_Append>('FLMutableArray_Append');

final FLMutableArray_Remove = _dylib.lookupFunction<_c_FLMutableArray_Remove,
    _dart_FLMutableArray_Remove>('FLMutableArray_Remove');

// -- FLSlot

final FLSlot_SetNull = _dylib
    .lookupFunction<_c_FLSlot_SetNull, _dart_FLSlot_SetNull>('FLSlot_SetNull');

final FLSlot_SetBool = _dylib
    .lookupFunction<_c_FLSlot_SetBool, _dart_FLSlot_SetBool>('FLSlot_SetBool');

final FLSlot_SetInt = _dylib
    .lookupFunction<_c_FLSlot_SetInt, _dart_FLSlot_SetInt>('FLSlot_SetInt');

final FLSlot_SetUInt = _dylib
    .lookupFunction<_c_FLSlot_SetUInt, _dart_FLSlot_SetUInt>('FLSlot_SetUInt');

final FLSlot_SetFloat =
    _dylib.lookupFunction<_c_FLSlot_SetFloat, _dart_FLSlot_SetFloat>(
        'FLSlot_SetFloat');

final FLSlot_SetDouble =
    _dylib.lookupFunction<_c_FLSlot_SetDouble, _dart_FLSlot_SetDouble>(
        'FLSlot_SetDouble');

final FLSlot_SetString =
    _dylib.lookupFunction<_c_FLSlot_SetString, _dart_FLSlot_SetString>(
        'FLSlot_SetString');

final FLSlot_SetData = _dylib
    .lookupFunction<_c_FLSlot_SetData, _dart_FLSlot_SetData>('FLSlot_SetData');

final FLSlot_SetValue =
    _dylib.lookupFunction<_c_FLSlot_SetValue, _dart_FLSlot_SetValue>(
        'FLSlot_SetValue');

// void FLSlot_SetNull(FLSlot FLNONNULL) FLAPI;             ///< Stores a JSON null into a slot.
// void FLSlot_SetBool(FLSlot FLNONNULL, bool) FLAPI;       ///< Stores a boolean into a slot.
// void FLSlot_SetInt(FLSlot FLNONNULL, int64_t) FLAPI;     ///< Stores an integer into a slot.
// void FLSlot_SetUInt(FLSlot FLNONNULL, uint64_t) FLAPI;   ///< Stores an unsigned integer into a slot.
// void FLSlot_SetFloat(FLSlot FLNONNULL, float) FLAPI;     ///< Stores a float into a slot.
// void FLSlot_SetDouble(FLSlot FLNONNULL, double) FLAPI;   ///< Stores a double into a slot.
// void FLSlot_SetString(FLSlot FLNONNULL, FLString) FLAPI; ///< Stores a string into a slot.
// void FLSlot_SetData(FLSlot FLNONNULL, FLSlice) FLAPI;    ///< Stores a data blob into a slot.
// void FLSlot_SetValue(FLSlot FLNONNULL, FLValue) FLAPI;

// -- Key paths

final FLKeyPath_New = _dylib
    .lookupFunction<_c_FLKeyPath_New, _dart_FLKeyPath_New>('FLKeyPath_New');

final FLKeyPath_Eval = _dylib
    .lookupFunction<_c_FLKeyPath_Eval, _dart_FLKeyPath_Eval>('FLKeyPath_Eval');

final FLKeyPath_EvalOnce =
    _dylib.lookupFunction<_c_FLKeyPath_EvalOnce, _dart_FLKeyPath_EvalOnce>(
        'FLKeyPath_EvalOnce');

// !
// ! Function types
// !

// -- FLSlice

typedef _c_FLSlice_Equal = ffi.Uint8 Function(
  ffi.Pointer<FLSlice> a,
  ffi.Pointer<FLSlice> b,
);

typedef _dart_FLSlice_Equal = int Function(
  ffi.Pointer<FLSlice> a,
  ffi.Pointer<FLSlice> b,
);

typedef _c_FLSlice_Compare = ffi.Uint32 Function(
  ffi.Pointer<FLSlice> a,
  ffi.Pointer<FLSlice> b,
);

typedef _dart_FLSlice_Compare = int Function(
  ffi.Pointer<FLSlice> a,
  ffi.Pointer<FLSlice> b,
);

// -- FLDoc

typedef _c_FLDoc_FromResultData = ffi.Pointer<_FLDoc> Function(
  ffi.Pointer<FLSliceResult> json,
  ffi.Uint8 trust,
  ffi.Pointer<FLSharedKeys> sharedKeys,
  ffi.Pointer<FLSlice> externData,
);

typedef _dart_FLDoc_FromResultData = ffi.Pointer<_FLDoc> Function(
  ffi.Pointer<FLSliceResult> json,
  int trust,
  ffi.Pointer<FLSharedKeys> sharedKeys,
  ffi.Pointer<FLSlice> externData,
);

typedef _c_FLDoc_FromJSON = ffi.Pointer<_FLDoc> Function(
  ffi.Pointer<FLSlice> json,
  ffi.Pointer<ffi.Uint8> error,
);

typedef _dart_FLDoc_FromJSON = ffi.Pointer<_FLDoc> Function(
  ffi.Pointer<FLSlice> json,
  ffi.Pointer<ffi.Uint8> error,
);

typedef _c_FLDoc_GetData = ffi.Pointer<FLSlice> Function(
  ffi.Pointer<_FLDoc> doc,
);

typedef _dart_FLDoc_GetData = ffi.Pointer<FLSlice> Function(
  ffi.Pointer<_FLDoc> doc,
);

typedef _c_FLDoc_GetRoot = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLDoc> doc,
);

typedef _dart_FLDoc_GetRoot = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLDoc> doc,
);

typedef _c_FLDoc_Retain = ffi.Pointer<_FLDoc> Function(
  ffi.Pointer<_FLDoc> doc,
);

typedef _dart_FLDoc_Retain = ffi.Pointer<_FLDoc> Function(
  ffi.Pointer<_FLDoc> doc,
);

typedef _c_FLDoc_Release = ffi.Void Function(
  ffi.Pointer<_FLDoc> doc,
);

typedef _dart_FLDoc_Release = void Function(
  ffi.Pointer<_FLDoc> doc,
);

// -- FLValue

typedef _c_FLData_ConvertJSON = ffi.Pointer<FLSliceResult> Function(
  ffi.Pointer<FLSlice> json,
  ffi.Pointer<ffi.Uint8> error,
);

typedef _dart_FLData_ConvertJSON = ffi.Pointer<FLSliceResult> Function(
  ffi.Pointer<FLSlice> value,
  ffi.Pointer<ffi.Uint8> error,
);

typedef _c_FLValue_FromData = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<FLSlice> json,
  ffi.Uint8 trust,
);

typedef _dart_FLValue_FromData = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<FLSlice> value,
  int trust,
);

typedef _c_FLDump = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLDump = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLDumpData = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<FLSlice> data,
);

typedef _dart_FLDumpData = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<FLSlice> data,
);

typedef _c_FLValue_GetType = ffi.Uint8 Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_GetType = int Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_IsEqual = ffi.Int8 Function(
  ffi.Pointer<_FLValue> value1,
  ffi.Pointer<_FLValue> value2,
);

typedef _dart_FLValue_IsEqual = int Function(
  ffi.Pointer<_FLValue> value1,
  ffi.Pointer<_FLValue> value2,
);

typedef _c_FLValue_IsInteger = ffi.Int8 Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_IsInteger = int Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_IsUnsigned = ffi.Int8 Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_IsUnsigned = int Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_IsDouble = ffi.Int8 Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_IsDouble = int Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_AsBool = ffi.Int8 Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_AsBool = int Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_AsInt = ffi.Int64 Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_AsInt = int Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_AsUnsigned = ffi.Uint64 Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_AsUnsigned = int Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_AsFloat = ffi.Float Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_AsFloat = double Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_AsDouble = ffi.Double Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_AsDouble = double Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_AsString_p = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_AsString_p = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_AsArray = ffi.Pointer<_FLArray> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_AsArray = ffi.Pointer<_FLArray> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_AsDict = ffi.Pointer<_FLDict> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_AsDict = ffi.Pointer<_FLDict> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_ToString = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_ToString = ffi.Pointer<ffi.Int8> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLValue_ToJSON = ffi.Pointer<FLStringResult> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLValue_ToJSON = ffi.Pointer<FLStringResult> Function(
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLKeyPath_New = ffi.Pointer<FLKeyPath> Function(
  ffi.Pointer<FLSlice> specifier,
  ffi.Pointer<ffi.Uint8> error,
);

typedef _dart_FLKeyPath_New = ffi.Pointer<FLKeyPath> Function(
  ffi.Pointer<FLSlice> specifier,
  ffi.Pointer<ffi.Uint8> error,
);

typedef _c_FLKeyPath_Eval = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<FLKeyPath> specifier,
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLKeyPath_Eval = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<FLKeyPath> specifier,
  ffi.Pointer<_FLValue> value,
);

typedef _c_FLKeyPath_EvalOnce = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<FLSlice> specifier,
  ffi.Pointer<_FLValue> value,
  ffi.Pointer<ffi.Uint8> error,
);

typedef _dart_FLKeyPath_EvalOnce = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<FLSlice> specifier,
  ffi.Pointer<_FLValue> value,
  ffi.Pointer<ffi.Uint8> error,
);

// -- FLArray
typedef _c_FLArray_AsMutable = ffi.Pointer<_FLMutableArray> Function(
  ffi.Pointer<_FLArray> dict,
);

typedef _dart_FLArray_AsMutable = ffi.Pointer<_FLMutableArray> Function(
  ffi.Pointer<_FLArray> array,
);

typedef _c_FLArray_Count = ffi.Int32 Function(
  ffi.Pointer<_FLArray> value,
);

typedef _dart_FLArray_Count = int Function(
  ffi.Pointer<_FLArray> value,
);

typedef _c_FLArray_IsEmpty = ffi.Uint8 Function(
  ffi.Pointer<_FLArray> value,
);

typedef _dart_FLArray_IsEmpty = int Function(
  ffi.Pointer<_FLArray> value,
);

typedef _c_FLArray_Get = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLArray> value,
  ffi.Uint32 index,
);

typedef _dart_FLArray_Get = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLArray> value,
  int index,
);

typedef _c_FLArrayIterator_New = ffi.Pointer<_FLArrayIterator> Function(
  ffi.Pointer<_FLArray> value,
);

typedef _dart_FLArrayIterator_New = ffi.Pointer<_FLArrayIterator> Function(
  ffi.Pointer<_FLArray> value,
);

typedef _c_FLArrayIterator_Begin = ffi.Void Function(
  ffi.Pointer<_FLArray> value,
  ffi.Pointer<_FLArrayIterator> iterator,
);

typedef _dart_FLArrayIterator_Begin = void Function(
  ffi.Pointer<_FLArray> value,
  ffi.Pointer<_FLArrayIterator> iterator,
);

typedef _c_FLArrayIterator_GetValue = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLArrayIterator> iterator,
);

typedef _dart_FLArrayIterator_GetValue = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLArrayIterator> iterator,
);

typedef _c_FLArrayIterator_Next = ffi.Uint8 Function(
  ffi.Pointer<_FLArrayIterator> iterator,
);

typedef _dart_FLArrayIterator_Next = int Function(
  ffi.Pointer<_FLArrayIterator> iterator,
);

// -- FLDict

typedef _c_FLDict_AsMutable = ffi.Pointer<_FLMutableDict> Function(
  ffi.Pointer<_FLDict> dict,
);

typedef _dart_FLDict_AsMutable = ffi.Pointer<_FLMutableDict> Function(
  ffi.Pointer<_FLDict> dict,
);

typedef _c_FLDict_Count = ffi.Int32 Function(
  ffi.Pointer<_FLDict> value,
);

typedef _dart_FLDict_Count = int Function(
  ffi.Pointer<_FLDict> value,
);

typedef _c_FLDict_IsEmpty = ffi.Uint8 Function(
  ffi.Pointer<_FLDict> value,
);

typedef _dart_FLDict_IsEmpty = int Function(
  ffi.Pointer<_FLDict> value,
);

typedef _c_FLDict_Get = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLDict> value,
  ffi.Pointer<FLSlice> key,
);

typedef _dart_FLDict_Get = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLDict> value,
  ffi.Pointer<FLSlice> key,
);

typedef _c_FLDictIterator_New = ffi.Pointer<_FLDictIterator> Function(
  ffi.Pointer<_FLDict> value,
);

typedef _dart_FLDictIterator_New = ffi.Pointer<_FLDictIterator> Function(
  ffi.Pointer<_FLDict> value,
);

typedef _c_FLDictIterator_Begin = ffi.Void Function(
  ffi.Pointer<_FLDict> value,
  ffi.Pointer<_FLDictIterator> iterator,
);

typedef _dart_FLDictIterator_Begin = void Function(
  ffi.Pointer<_FLDict> value,
  ffi.Pointer<_FLDictIterator> iterator,
);

typedef _c_FLDictIterator_GetKey = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLDictIterator> iterator,
);

typedef _dart_FLDictIterator_GetKey = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLDictIterator> iterator,
);

typedef _c_FLDictIterator_GetValue = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLDictIterator> iterator,
);

typedef _dart_FLDictIterator_GetValue = ffi.Pointer<_FLValue> Function(
  ffi.Pointer<_FLDictIterator> iterator,
);

typedef _c_FLDictIterator_Next = ffi.Uint8 Function(
  ffi.Pointer<_FLDictIterator> iterator,
);

typedef _dart_FLDictIterator_Next = int Function(
  ffi.Pointer<_FLDictIterator> iterator,
);

// -- Mutable Dictionary

typedef _c_FLDict_MutableCopy = ffi.Pointer<_FLMutableDict> Function(
  ffi.Pointer<_FLDict> source,
  ffi.Uint8 copyFlags,
);

typedef _dart_FLDict_MutableCopy = ffi.Pointer<_FLMutableDict> Function(
  ffi.Pointer<_FLDict> source,
  int copyFlags,
);

typedef _c_FLMutableDict_IsChanged = ffi.Int8 Function(
  ffi.Pointer<_FLMutableDict> dict,
);

typedef _dart_FLMutableDict_IsChanged = int Function(
  ffi.Pointer<_FLMutableDict> dict,
);

typedef _c_FLMutableDict_Set = ffi.Pointer<_FLSlot> Function(
  ffi.Pointer<_FLMutableDict> dict,
  ffi.Pointer<FLSlice> key,
);

typedef _dart_FLMutableDict_Set = ffi.Pointer<_FLSlot> Function(
  ffi.Pointer<_FLMutableDict> dict,
  ffi.Pointer<FLSlice> key,
);

typedef _c_FLMutableDict_Remove = ffi.Void Function(
  ffi.Pointer<_FLMutableDict> dict,
  ffi.Pointer<FLSlice> key,
);

typedef _dart_FLMutableDict_Remove = void Function(
  ffi.Pointer<_FLMutableDict> dict,
  ffi.Pointer<FLSlice> key,
);

typedef _c_FLMutableDict_RemoveAll = ffi.Void Function(
  ffi.Pointer<_FLMutableDict> dict,
);

typedef _dart_FLMutableDict_RemoveAll = void Function(
  ffi.Pointer<_FLMutableDict> dict,
);

typedef _c_FLMutableDict_New = ffi.Pointer<_FLMutableDict> Function();

typedef _dart_FLMutableDict_New = ffi.Pointer<_FLMutableDict> Function();

// -- Mutable Array

typedef _c_FLArray_MutableCopy = ffi.Pointer<_FLMutableArray> Function(
  ffi.Pointer<_FLArray> source,
  ffi.Uint8 copyFlags,
);

typedef _dart_FLArray_MutableCopy = ffi.Pointer<_FLMutableArray> Function(
  ffi.Pointer<_FLArray> source,
  int copyFlags,
);

typedef _c_FLMutableArray_IsChanged = ffi.Int8 Function(
  ffi.Pointer<_FLMutableArray> array,
);

typedef _dart_FLMutableArray_IsChanged = int Function(
  ffi.Pointer<_FLMutableArray> array,
);

typedef _c_FLMutableArray_Set = ffi.Pointer<_FLSlot> Function(
  ffi.Pointer<_FLMutableArray> array,
  ffi.Uint32 key,
);

typedef _dart_FLMutableArray_Set = ffi.Pointer<_FLSlot> Function(
  ffi.Pointer<_FLMutableArray> array,
  int key,
);

typedef _c_FLMutableArray_Append = ffi.Pointer<_FLSlot> Function(
  ffi.Pointer<_FLMutableArray> array,
);

typedef _dart_FLMutableArray_Append = ffi.Pointer<_FLSlot> Function(
  ffi.Pointer<_FLMutableArray> array,
);

typedef _c_FLMutableArray_Remove = ffi.Void Function(
  ffi.Pointer<_FLMutableArray> array,
  ffi.Pointer<FLSlice> key,
);

typedef _dart_FLMutableArray_Remove = void Function(
  ffi.Pointer<_FLMutableArray> array,
  ffi.Pointer<FLSlice> key,
);

typedef _c_FLMutableArray_New = ffi.Pointer<_FLMutableArray> Function();

typedef _dart_FLMutableArray_New = ffi.Pointer<_FLMutableArray> Function();

// -- FLSLot

typedef _c_FLSlot_SetNull = ffi.Void Function(
  ffi.Pointer<_FLSlot> slot,
);

typedef _dart_FLSlot_SetNull = void Function(
  ffi.Pointer<_FLSlot> slot,
);

typedef _c_FLSlot_SetBool = ffi.Void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Uint8 value,
);

typedef _dart_FLSlot_SetBool = void Function(
  ffi.Pointer<_FLSlot> slot,
  int value,
);

typedef _c_FLSlot_SetInt = ffi.Void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Int64 value,
);

typedef _dart_FLSlot_SetInt = void Function(
  ffi.Pointer<_FLSlot> slot,
  int value,
);

typedef _c_FLSlot_SetUInt = ffi.Void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Uint64 value,
);

typedef _dart_FLSlot_SetUInt = void Function(
  ffi.Pointer<_FLSlot> slot,
  int value,
);

typedef _c_FLSlot_SetFloat = ffi.Void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Float value,
);

typedef _dart_FLSlot_SetFloat = void Function(
  ffi.Pointer<_FLSlot> slot,
  double value,
);

typedef _c_FLSlot_SetDouble = ffi.Void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Double value,
);

typedef _dart_FLSlot_SetDouble = void Function(
  ffi.Pointer<_FLSlot> slot,
  double value,
);

typedef _c_FLSlot_SetString = ffi.Void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Pointer<FLSlice> value,
);

typedef _dart_FLSlot_SetString = void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Pointer<FLSlice> value,
);

typedef _c_FLSlot_SetData = ffi.Void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Pointer<FLSlice> value,
);

typedef _dart_FLSlot_SetData = void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Pointer<FLSlice> value,
);

typedef _c_FLSlot_SetValue = ffi.Void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Pointer<_FLValue> value,
);

typedef _dart_FLSlot_SetValue = void Function(
  ffi.Pointer<_FLSlot> slot,
  ffi.Pointer<_FLValue> value,
);

// !
// ! Data types
// !

class FLSlice extends ffi.Struct {
  ffi.Pointer<pffi.Utf8> buf;

  @ffi.Uint64()
  int size;

  factory FLSlice.allocate(String string) {
    return pffi.allocate<FLSlice>().ref
      ..buf = pffi.Utf8.toUtf8(string)
      ..size = string.length;
  }

  @override
  bool operator ==(dynamic other) =>
      other is FLSlice && FLSlice_Equal(addressOf, other.addressOf) != 0;
}

class FLSliceResult extends ffi.Struct {
  ffi.Pointer<ffi.Uint8> buf;

  @ffi.Uint64()
  int size;
}

/// Same as FLSlice
class FLStringResult extends ffi.Struct {
  ffi.Pointer<ffi.Int8> buf;

  @ffi.Int64()
  int size;

  factory FLStringResult.allocate(String string) {
    return pffi.allocate<FLStringResult>().ref
      ..buf = pffi.Utf8.toUtf8(string).cast()
      ..size = string.length ?? 0;
  }
}

class FLString extends ffi.Struct {
  ffi.Pointer<pffi.Utf8> buf;

  @ffi.Uint64()
  int size;

  factory FLString.allocate(String string) {
    return pffi.allocate<FLString>().ref
      ..buf = pffi.Utf8.toUtf8(string)
      ..size = string.length;
  }
}

class _FLDoc extends ffi.Struct {}

class _FLValue extends ffi.Struct {}

// ignore: unused_element
class _FLArray extends ffi.Struct {}

class _FLDict extends ffi.Struct {}

// ignore: unused_element
class _FLSlot extends ffi.Struct {}

// ignore: unused_element
class _FLMutableArray extends ffi.Struct {}

// ignore: unused_element
class _FLMutableDict extends ffi.Struct {}

class FLKeyPath extends ffi.Struct {}

class FLSharedKeys extends ffi.Struct {}

class _FLArrayIterator extends ffi.Struct {}

class _FLDictIterator extends ffi.Struct {}

enum FLTrust { untrusted, trusted }

enum FLCopyFlags {
  defaultCopy,
  deepCopy,
  copyImmutables,
}

enum FLError {
  noError,
  memoryError, // Out of memory, or allocation failed
  outOfRange, // Array index or iterator out of range
  invalidData, // Bad input data (NaN, non-string key, etc.)
  encodeError, // Structural error encoding (missing value, too many ends, etc.)
  jsonError, // Error parsing JSON
  unknownValue, // Unparseable data in a Value (corrupt? Or from some distant future?)
  internalError, // Something that shouldn't happen
  notFound, // Key not found
  sharedKeysStateError, // Misuse of shared keys (not in transaction, etc.)
  posixError,
  unsupported, // Operation is unsupported
}

enum FLValueType {
  /// Type of a NULL pointer, i.e. no such value, like JSON `undefined`.
  ///  Also the type of a value created by FLEncoder_WriteUndefined().
  Undefined,

  /// Equivalent to a JSON 'null'
  Null,

  /// A `true` or `false` value
  Bool,

  /// A numeric value, either integer or floating-point
  Number,

  /// A string
  String,

  /// Binary data (no JSON equivalent)
  Data,

  /// An array of values
  Array,

  /// A mapping of strings to values
  Dict
}
