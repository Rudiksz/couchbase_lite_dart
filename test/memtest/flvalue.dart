import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

void main() async {
  initializeCblC();
  final maxRunTime = 60 * 1000; // X seconds

  // Data for the tests
  final json = '{"int": 1, "double": 2.5, "bool": true, "string": "text"}';
  final value = FLValue.fromJson(json);
  final value2 = FLValue.fromJson(json);

  // Which tests to run. The idea is that if you see memory usage climbing up,
  // you can enable/disable tests to find the culprit
  final activeTests = [
    'empty',
    // 'fromPointer',
    'fromJson',
    'json',
    'type',
    'isInteger',
    'isDouble',
    'asBool',
    'asInt',
    'asUnsigned',
    'asDouble',
    'asString',
    'asArray',
    'asDict',
    'toString',
    'operator[]',
    'operator==',
  ];

  // The tests. These should be as granular as possible, to test for memory leaks
  // in methods that call into the C api, or otherwise manipulate memory using ffi.
  // These are not meant to be unit tests
  final tests = <String, Function()>{
    'empty': () => FLValue.empty(),
    'fromJson': () => FLValue.fromJson(json).dispose(),
    'json': () => value.json,
    'type': () => value.type,
    'isInteger': () => value.isInterger,
    'isDouble': () => value.isDouble,
    'asBool': () => value.asBool,
    'asInt': () => value.asInt,
    'asUnsigned': () => value.asUnsigned,
    'asDouble': () => value.asDouble,
    'asString': () => value.asString,
    'asArray': () => value.asArray,
    'asDict': () => value.asDict,
    'toString': () => value.toString(),
    'operator[]': () => value['int'],
    'operator==': () => value == value2,
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
