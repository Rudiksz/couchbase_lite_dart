class Memtest {
  /// These should be as granular as possible, to test for memory leaks
  /// in methods that call into the C api, or otherwise manipulate memory using ffi.
  /// These are not meant to be unit tests
  final Map<String, Function()> tests;

  /// Which tests will be run. The idea is that if you see memory usage climbing up,
  /// you can enable/disable tests to find the culprit
  final List<String> activeTests;

  /// Maximum runtime in seconds
  final int maxRunTime;

  Memtest({
    this.activeTests = const [],
    required this.tests,
    this.maxRunTime = 60 * 1000,
  });

  void run() {
    final testsToRun = activeTests.isNotEmpty
        ? tests.entries.where((e) => activeTests.contains(e.key))
        : tests.entries;

    print('Running the following tests: ' +
        Map.fromEntries(testsToRun).keys.toString());

    final watch = Stopwatch()..start();
    while (watch.elapsedMilliseconds < maxRunTime) {
      testsToRun.forEach((t) => t.value());
    }
  }
}
