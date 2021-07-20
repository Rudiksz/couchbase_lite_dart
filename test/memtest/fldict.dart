import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

void main() async {
  initializeCblC();
  final maxRunTime = 60 * 1000; // X seconds

  // Data for the tests
  final json =
      '{"a" : 1, "b": 2.5, "c": true, "d": "text", "e": [1,2,3,4,5], "f": {"foo":"bar"}}';
  final map = {
    'a': 1,
    'b': 2.5,
    'c': true,
    'd': 'text',
    'e': [1, 2, 3, 4, 5],
    'f': {'foo': 'bar'}
  };
  ;

  final value = FLDict.fromJson(json);
  final value2 = FLDict.fromJson(json);
  final mutableValue = value.mutableCopy;
  mutableValue['g'] = 'test';

  // Which tests to run. The idea is that if you see memory usage climbing up,
  // you can enable/disable tests to find the culprit
  final activeTests = [
    'empty',
    'fromJson',
    'fromMap',
    'json',
    'value',
    'length',
    'isMutable',
    'mutable',
    'mutableCopy',
    'changed',
    'isEmpty',
    'operator()',
    'operator[]',
    'operator[]=',
    'operator==',
    'equals',
    'iterator',
    'values',
    'keys',
    'entries',
  ];

  // The tests. These should be as granular as possible, to test for memory leaks
  // in methods that call into the C api, or otherwise manipulate memory using ffi.
  // These are not meant to be unit tests
  final tests = <String, Function()>{
    'empty': () => FLDict.empty(),
    'fromJson': () => FLDict.fromJson(json).dispose(),
    'fromMap': () => FLDict.fromMap(map).dispose(),
    'json': () => value.json,
    'value': () => value.value,
    'length': () => value.length,
    'isMutable': () => value.isMutable,
    'mutable': () => value.mutable.dispose(),
    'mutableCopy': () => value.mutableCopy.dispose(),
    'changed': () => mutableValue.changed && value.changed,
    'isEmpty': () => mutableValue.isEmpty && value.isEmpty,
    'operator()': () => value('e[4]'),
    'operator[]=': () {
      mutableValue['a'] = 1;
      mutableValue['b'] = 1.33;
      mutableValue['c'] = true;
      mutableValue['d'] = 'text1';
      mutableValue['e'] = ['a', 'b'];
      mutableValue['f'] = {'a': 'b'};
      mutableValue['g'] = null;
    },
    'operator==': () => value == value2 && value == mutableValue,
    'equals': () => value.equals(value2) && value.equals(mutableValue),
    'iterator': () => [for (var item in value) item],
    'values': () => [for (var item in value.values) item],
    'keys': () => [for (var item in value.keys) item],
    'entries': () => {for (var item in value.entries) item.key: item.value},
  };

  final testsToRun = tests.entries.where((e) => activeTests.contains(e.key));
  print('Running the following tests: ' +
      Map.fromEntries(testsToRun).keys.toString());

  final watch = Stopwatch()..start();
  while (watch.elapsedMilliseconds < maxRunTime) {
    testsToRun.forEach((t) => t.value());
  }
  exit(1);
}
