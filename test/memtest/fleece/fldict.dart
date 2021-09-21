import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

import '../memtest.dart';

void main() async {
  initializeCblC();

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

  final value = FLDict.fromJson(json);
  final value2 = FLDict.fromJson(json);
  final mutableValue = value.mutableCopy;
  mutableValue['g'] = 'test';

  Memtest(
    tests: {
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
    },
    activeTests: [
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
    ],
  ).run();
}
