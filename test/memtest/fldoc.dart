import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

void main() async {
  initializeCblC();
  final maxRunTime = 60 * 1000; // X seconds

  // Data for the tests
  final json = '{"foo": "bar"}';
  final map = {'foo': 'bar'};
  final list = ['foo', 'bar'];

  // Which tests to run. The idea is that if you see memory usage climbing up,
  // you can enable/disable tests to find the culprit
  final activeTests = [
    'fromJson',
  ];

  // The tests. These should be as granular as possible, to test for memory leaks
  // in methods that call into the C api, or otherwise manipulate memory using ffi.
  // These are not meant to be unit tests
  final tests = <String, Function()>{
    'fromJson': () {
      var doc = FLDoc.fromJson(json);
      doc.root;
      doc.dispose();
      doc = FLDoc.fromMap(map);
      doc.root;
      doc.dispose();
      doc = FLDoc.fromList(list);
      doc.root;
      doc.dispose();
    },
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
