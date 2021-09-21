import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

import '../memtest.dart';

void main() async {
  initializeCblC();

  // Data for the tests
  final slice = FLSlice.fromString('a');

  Memtest(
    tests: {
      'empty': () => FLSlice.empty().free(),
      'fromString': () => FLSlice.fromString('a').free(),
      'toString': () => slice.toString(),
    },
    activeTests: [
      'empty',
      'fromString',
      'toString',
    ],
  ).run();
}
