import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

import '../memtest.dart';

void main() async {
  initializeCblC();

  // Data for the tests
  final json = '{"int": 1, "double": 2.5, "bool": true, "string": "text"}';
  final value = FLValue.fromJson(json);
  final value2 = FLValue.fromJson(json);

  Memtest(
    tests: {
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
    },
    activeTests: [
      'empty',
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
    ],
  ).run();
}
