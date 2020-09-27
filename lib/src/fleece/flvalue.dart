// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_c;

/// The core Fleece data type is FLValue: a reference to a value in Fleece-encoded data.
/// An FLValue can represent any JSON type (plus binary data).
///
/// - Scalar data types -- numbers, booleans, null, strings, data -- can be accessed
/// using individual functions of the form `as...`; these return the scalar value,
/// or a default zero/false/null value if the value is not of that type.
/// - Collections -- arrays and dictionaries -- have their own "subclasses": FLArray and
/// FLDict.
///
/// It's always safe to pass a null value to an accessor; that goes for FLDict and FLArray
/// as well as FLValue. The result will be a default value of that type, e.g. false or 0
/// or NULL, unless otherwise specified.
class FLValue {
  ffi.Pointer<_FLValue> _value;
  ffi.Pointer<_FLValue> get addressOf => _value;
  set value(FLValue value) => _value = value.addressOf;

  final error = pffi.allocate<ffi.Uint8>();

  FLValue() {
    _value = pffi.allocate<_FLValue>();
  }

  FLValue.fromPointer(this._value);

  /// Encodes a Fleece value as JSON (or a JSON fragment.)
  /// Any Data values will become base64-encoded JSON strings.
  String get json {
    final cstr = FLDump(_value.cast());
    final str = utf8ToStr(cstr);
    // Dart_Free(cstr);
    return str;
  }

  /// Evaluates a key-path from a specifier string, for a Fleece value.
  /// An FLKeyPath Describes a location in a Fleece object tree, as a path from the root that follows
  ///    dictionary properties and array elements.
  ///    It's similar to a JSONPointer or an Objective-C KeyPath, but simpler (so far.)
  ///    The path is compiled into an efficient form that can be traversed quickly.
  ///
  ///    It looks like `foo.bar[2][-3].baz` -- that is, properties prefixed with a `.`, and array
  ///    indexes in brackets. (Negative indexes count from the end of the array.)
  ///
  ///    A leading JSONPath-like `$.` is allowed but ignored.
  ///
  ///   A '\\' can be used to escape a special character ('.', '[' or '$') at the start of a
  ///   property name (but not yet in the middle of a name.)
  FLValue operator [](String keyPath) {
    // Some values are not supported
    if (keyPath.isEmpty || keyPath.contains('[]')) return null;

    error.value = 0;
    final val = FLKeyPath_EvalOnce(
      FLSlice.allocate(keyPath).addressOf,
      _value.cast(),
      error,
    );
    if (error.value != FLError.noError.index) return null;
    return FLValue.fromPointer(val);
  }

  /// Returns the data type of an arbitrary Value.
  /// (If the value is null, returns `FLValueType.undefined`.)
  FLValueType get type {
    // The C enum values start at -1
    final t = FLValue_GetType(_value) + 1;
    return t < FLValueType.values.length
        ? FLValueType.values[t]
        : FLValueType.Undefined;
  }

  /// Returns true if the value is non-NULL and represents an integer.
  bool get isInterger => FLValue_IsInteger(_value) != 0;

  /// Returns true if the value is non-NULL and represents an integer >= 2^63. Such a value can't
  /// be represented in C as an `int64_t`, only a `uint64_t`, so you should access it by calling
  /// `asUnsigned`, _not_asInt, which would return  an incorrect (negative) value.
  bool get isUnsigned => FLValue_IsUnsigned(_value) != 0;

  /// Returns true if the value is non-NULL and represents a 64-bit floating-point number.
  bool get isDouble => FLValue_IsDouble(_value) != 0;

  /// Returns a value coerced to boolean. This will be true unless the value
  /// is NULL (undefined), null, false, or zero.
  bool get asBool => FLValue_AsBool(_value) != 0;

  /// Returns a value coerced to an integer. True and false are returned as 1 and 0, and
  /// floating-point numbers are rounded. All other types are returned as 0.
  ///
  /// **Warning**  Large 64-bit unsigned integers (2^63 and above) will come out wrong. You can
  /// check for these by calling `isUnsigned`.
  int get asInt => FLValue_AsInt(_value);

  /// Returns a value coerced to an unsigned integer.
  ///
  /// This is the same as `asInt` except that it _can't_ handle negative numbers, but
  /// does correctly return large `uint64_t` values of 2^63 and up.
  int get asUnsinged => FLValue_AsUnsigned(_value);

  /// Returns a value coerced to a 32-bit floating point number.
  /// True and false are returned as 1.0 and 0.0, and integers are converted to float. All other
  /// types are returned as 0.0.
  ///
  /// **Warning**  Large integers (outside approximately +/- 2^23) will lose precision due to the
  /// limitations of IEEE 32-bit float format.
  double get asDouble => FLValue_AsDouble(_value);

  /// Returns the exact contents of a string value, or null for all other types.
  String get asString {
    final cstr = FLValue_AsString(_value);
    final result = utf8ToStr(cstr);
    // Dart_Free(cstr);
    return result;
  }

  /// If a FLValue represents an FLArray, returns it cast to FLArray, else NULL.
  FLArray get asList => type == FLValueType.Array
      ? FLArray.fromPointer(FLValue_AsArray(_value))
      : null;

  /// If a FLValue represents an map, returns it cast to FLDict, else NULL.
  FLDict get asMap => type == FLValueType.Dict
      ? FLDict.fromPointer(FLValue_AsDict(_value))
      : null;

  /// Returns a string representation of any scalar value. Data values are returned in raw form.
  /// Arrays and dictionaries don't have a representation and will return NULL.
  @override
  String toString() {
    final cstr = FLValue_ToString(_value);
    final result = utf8ToStr(cstr);
    // Dart_Free(cstr);
    return result;
  }

  /// Compares two values for equality. This is a deep recursive comparison.
  @override
  bool operator ==(other) =>
      other is FLValue && FLValue_IsEqual(_value, other._value) != 0;
}
