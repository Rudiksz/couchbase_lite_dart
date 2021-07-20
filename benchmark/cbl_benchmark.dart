import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

typedef CBLBenchmarkCallback = void Function();

class CBLBenchmark extends BenchmarkBase {
  final Function(BenchmarkData)? fn;

  final BenchmarkData data = BenchmarkData();

  late final ScoreEmitter cblEmitter = CBLEmitter(data);

  final bool active;

  final CBLBenchmarkCallback? setUp;
  final CBLBenchmarkCallback? tearDown;

  CBLBenchmark(
    String name,
    this.fn, {
    this.setUp,
    this.tearDown,
    this.active = true,
  }) : super(name);

  @override
  void setup() => data.startInstanceCount = Cbl.instanceCount;

  @override
  void teardown() => data.endInstanceCount = Cbl.instanceCount;

  @override
  void run() => fn?.call(data);

  @override
  void report() => cblEmitter.emit(name, measure());
}

class CBLEmitter implements ScoreEmitter {
  final BenchmarkData data;

  const CBLEmitter(this.data);

  @override
  void emit(String testName, double value) => printMap({
        'Test': testName,
        'RunTime': value,
        'Instances': {
          'start': data.startInstanceCount,
          'end': data.endInstanceCount,
          'diff': data.endInstanceCount - data.startInstanceCount,
        }
      });

  static String color(String message, int color, {bool bg = false}) {
    return stdout.supportsAnsiEscapes
        ? '\x1B[${bg ? 48 : 38};5;${color}m$message\x1B[0m'
        : message;
  }

  static String black(String message, {bool bg = false}) =>
      color(message, 0, bg: bg);
  static String white(String message, {bool bg = false}) =>
      color(message, 15, bg: bg);
  static String red(String message, {bool bg = false}) =>
      color(message, 1, bg: bg);
  static String green(String message, {bool bg = false}) =>
      color(message, 2, bg: bg);
  static String yellow(String message, {bool bg = false}) =>
      color(message, 3, bg: bg);
  static String grey(String message, {bool bg = false}) =>
      color(message, 8, bg: bg);

  static void debug(String message) => print(grey(message));
  static void info(String message) => print(message);
  static void warn(String message) => print(yellow(message));
  static void error(String message) => print(red(message));

  static void printMap(Map<String, dynamic> map, [int indenting = 0]) {
    final padding = ''.padRight(indenting, ' ');
    for (final key in map.keys) {
      var message = '$key: ' + (map[key] is Map ? '' : map[key]).toString();
      switch (key) {
        case 'Test':
          message = green(message);
          break;
        case 'diff':
          message =
              grey(message) + ' ' + (map[key] == 0 ? green('✓') : red('×'));
          break;
        default:
          message = grey(message);
      }
      info(padding + message);

      if (map[key] is Map) {
        printMap(map[key], indenting + 1);
      }
    }
  }
}

class BenchmarkData {
  int startInstanceCount = 0;
  int endInstanceCount = 0;
}
