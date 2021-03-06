// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of couchbase_lite_dart;

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
  /// The C pointer to the FLValue
  final ffi.Pointer<cbl.FLValue> _value;
  ffi.Pointer<cbl.FLValue> get ref => _value;

  int error;

  FLValue.fromPointer(this._value);

  /// Encodes a Fleece value as JSON (or a JSON fragment.)
  /// Any Data values will become base64-encoded JSON strings.
  String get json {
    final cstr = cbl.FLDump(_value.cast());
    final str = cstr.cast<pffi.Utf8>().toDartString();
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

    final outError = pffi.calloc<ffi.Uint8>()..value = 0;
    final val = cbl.FLKeyPath_EvalOnce(
      keyPath.toNativeUtf8().cast(),
      _value,
      outError,
    );
    error = outError.value;
    pffi.calloc.free(outError);

    return error == FLError.noError.index ? FLValue.fromPointer(val) : null;
  }

  /// Returns the data type of an arbitrary Value.
  /// (If the value is null, returns `FLValueType.Undefined`.)
  FLValueType get type {
    // The C enum values start at -1
    final t = cbl.FLValue_GetType(_value) + 1;
    return t < FLValueType.values.length
        ? FLValueType.values[t]
        : FLValueType.Undefined;
  }

  /// Returns true if the value is non-NULL and represents an integer.
  bool get isInterger => cbl.FLValue_IsInteger(_value) != 0;

  /// Returns true if the value is non-NULL and represents an integer >= 2^63. Such a value can't
  /// be represented in C as an `int64_t`, only a `uint64_t`, so you should access it by calling
  /// `asUnsigned`, _not_asInt, which would return  an incorrect (negative) value.
  bool get isUnsigned => cbl.FLValue_IsUnsigned(_value) != 0;

  /// Returns true if the value is non-NULL and represents a 64-bit floating-point number.
  bool get isDouble => cbl.FLValue_IsDouble(_value) != 0;

  /// Returns a value coerced to boolean. This will be true unless the value
  /// is NULL (undefined), null, false, or zero.
  bool get asBool => cbl.FLValue_AsBool(_value) != 0;

  /// Returns a value coerced to an integer. True and false are returned as 1 and 0, and
  /// floating-point numbers are rounded. All other types are returned as 0.
  ///
  /// **Warning**  Large 64-bit unsigned integers (2^63 and above) will come out wrong. You can
  /// check for these by calling `isUnsigned`.
  int get asInt => cbl.FLValue_AsInt(_value);

  /// Returns a value coerced to an unsigned integer.
  ///
  /// This is the same as `asInt` except that it _can't_ handle negative numbers, but
  /// does correctly return large `uint64_t` values of 2^63 and up.
  int get asUnsigned => cbl.FLValue_AsUnsigned(_value);

  /// Returns a value coerced to a 32-bit floating point number.
  /// True and false are returned as 1.0 and 0.0, and integers are converted to float. All other
  /// types are returned as 0.0.
  ///
  /// **Warning**  Large integers (outside approximately +/- 2^23) will lose precision due to the
  /// limitations of IEEE 32-bit float format.
  double get asDouble => cbl.FLValue_AsDouble(_value);

  /// Returns the exact contents of a string value, or null for all other types.
  String get asString {
    final cstr = cbl.FLValue_AsString(_value);
    final result = cstr.cast<pffi.Utf8>().toDartString();
    return result;
  }

  /// If a FLValue represents an FLArray, returns it cast to FLArray, else NULL.
  FLArray get asList => type == FLValueType.Array
      ? FLArray.fromPointer(cbl.FLValue_AsArray(_value))
      : null;

  /// If a FLValue represents an map, returns it cast to FLDict, else NULL.
  FLDict get asMap => type == FLValueType.Dict
      ? FLDict.fromPointer(cbl.FLValue_AsDict(_value))
      : null;

  /// Returns a string representation of any scalar value. Data values are returned in raw form.
  /// Arrays and dictionaries don't have a representation and will return NULL.
  @override
  String toString() {
    final cstr = cbl.FLValue_ToString(_value);
    final result = cstr.cast<pffi.Utf8>().toDartString();
    return result;
  }

  /// Compares two values for equality. This is a deep recursive comparison.
  @override
  bool operator ==(other) =>
      other is FLValue && cbl.FLValue_IsEqual(_value, other._value) != 0;
}

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
