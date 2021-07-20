import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

void main() async {
  initializeCblC();
  final maxRunTime = 60 * 1000; // X seconds

  // Data for the tests
  final slice = FLSlice.fromString('a');
  final dict = FLDict.fromMap({'foo': 'bar'});
  final sliceResult = CBLC.FLValue_ToJSON(dict.value.ref);

  // Which tests to run. The idea is that if you see memory usage climbing up,
  // you can enable/disable tests to find the culprit
  final activeTests = [
    'empty',
    'fromString',
    'fromSlice',
    'fromSliceResult',
    'slice',
    'toString',
    'toSliceResult',
  ];

  // The tests. These should be as granular as possible, to test for memory leaks
  // in methods that call into the C api, or otherwise manipulate memory using ffi
  final tests = <String, Function()>{
    'empty': () => FLValue.empty(),
    'fromString': () => FLSlice.fromString('a').free(),
    'fromSlice': () => FLSlice.fromSlice(slice.slice),
    'fromSliceResult': () {
      final dict1 = FLDict.fromMap({'foo': 'bar'});
      final sliceResult1 = CBLC.FLValue_ToJSON(dict1.value.ref);
      final slice1 = FLSlice.fromSliceResult(sliceResult1);
      slice1.free();
      dict1.dispose();

      return FLSlice.fromSliceResult(sliceResult);
    },
    'slice': () => slice.slice,
    'toString': () => slice.toString(),
    'toSliceResult': () => slice.toSliceResult,
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
