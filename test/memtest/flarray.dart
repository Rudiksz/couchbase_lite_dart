import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

void main() async {
  initializeCblC();
  final maxRunTime = 60 * 1000; // X seconds

  // Data for the tests
  final json = '[1, 2.5, true, "text", [1,2,3,4,5], {"foo":"bar"}]';
  final list = [
    1,
    2.5,
    true,
    'text',
    [1, 2, 3, 4, 5],
    {'foo': 'bar'}
  ];

  final value = FLArray.fromJson(json);
  final value2 = FLArray.fromJson(json);
  final mutableValue = value.mutableCopy;
  mutableValue[6] = 'test';

  // Which tests to run. The idea is that if you see memory usage climbing up,
  // you can enable/disable tests to find the culprit
  final activeTests = [
    'empty',
    'fromJson',
    'fromList',
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
    'iterator'
  ];

  // The tests. These should be as granular as possible, to test for memory leaks
  // in methods that call into the C api, or otherwise manipulate memory using ffi.
  // These are not meant to be unit tests
  final tests = <String, Function()>{
    'empty': () => FLArray.empty(),
    'fromJson': () => FLArray.fromJson(json).dispose(),
    'fromList': () => FLArray.fromList(list).dispose(),
    'json': () => value.json,
    'value': () => value.value,
    'length': () => value.length,
    'isMutable': () => value.isMutable,
    'mutable': () => value.mutable.dispose(),
    'mutableCopy': () => value.mutableCopy.dispose(),
    'changed': () => mutableValue.changed && value.changed,
    'isEmpty': () => mutableValue.isEmpty && value.isEmpty,
    'operator()': () => value('[4][4]'),
    'operator[]=': () {
      mutableValue[0] = 1;
      mutableValue[1] = 1.33;
      mutableValue[2] = true;
      mutableValue[3] = 'text1';
      mutableValue[4] = ['a', 'b'];
      mutableValue[5] = {'a': 'b'};
      mutableValue[6] = null;
    },
    'operator==': () => value == value2 && value == mutableValue,
    'equals': () => value.equals(value2) && value.equals(mutableValue),
    'iterator': () => [for (var item in value) item],
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
