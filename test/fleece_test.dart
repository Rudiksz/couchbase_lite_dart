// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:collection';
import 'dart:ffi';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:test/test.dart';

const TESTDIR = '_tmp';

void main() {
  initializeCblC();

  group('FLDoc', () {
    test('fromJson', () {
      expect(FLDoc.fromJson('{"foo"}').error, FLError.jsonError);
      expect(FLDoc.fromJson('{"foo"}').root.type, FLValueType.Undefined);
      expect(FLDoc.fromJson('{"foo": "bar"}').error, FLError.noError);
      expect(FLDoc.fromJson('{"foo": "bar"}').root.type, FLValueType.Dict);
    });
    test('root', () {
      expect(FLDoc.fromJson('{"foo"}').root.asString, '');
      expect(FLDoc.fromJson('{"foo": "bar"}').root['foo'].asString, 'bar');
    });
  });

  group('FLValue', () {
    final doc = FLDict.fromMap({
      'int': 1,
      'int1': 0,
      'double': 1.1,
      'double1': 0,
      'double2': 2.0,
      'string': 'text',
      'string1': null,
      'boolean': true,
      'boolean1': false,
      'list': [1, 2],
      'list1': null,
      'map': {'one': 'two'},
      'map1': null,
    });

    test('json', () {
      expect(doc['map'].json, '{"one":"two"}');
    });

    test('isInteger/isDouble', () {
      expect(doc['int'].isInterger, true);
      expect(doc['double'].isInterger, false);
      expect(doc['string'].isInterger, false);
      expect(doc['boolean'].isInterger, false);
      expect(doc['list'].isInterger, false);
      expect(doc['map'].isInterger, false);

      expect(doc['int'].isDouble, false);
      expect(doc['double'].isDouble, true);
      expect(doc['string'].isDouble, false);
      expect(doc['boolean'].isDouble, false);
      expect(doc['list'].isDouble, false);
      expect(doc['map'].isDouble, false);
    });

    test('asBool', () {
      expect(doc['boolean'].asBool.runtimeType, bool);
      expect(doc['boolean'].asBool, true);
      expect(doc['boolean1'].asBool, false);

      expect(doc['int'].asBool, true);
      expect(doc['double'].asBool, true);
      expect(doc['string'].asBool, true);
      expect(doc['list'].asBool, true);
      expect(doc['map'].asBool, true);

      expect(doc['int1'].asBool, false);
      expect(doc['double1'].asBool, false);
      expect(doc['string1'].asBool, false);
      expect(doc['list1'].asBool, false);
      expect(doc['map1'].asBool, false);
    });

    test('asInt', () {
      expect(doc['int'].asInt.runtimeType, int);
      expect(doc['int'].asInt, 1);
      expect(doc['double'].asInt, 1);
      expect(doc['string'].asInt, 0);
      expect(doc['boolean'].asInt, 1);
      expect(doc['boolean1'].asInt, 0);
      expect(doc['list'].asInt, 0);
      expect(doc['map'].asInt, 0);
    });

    test('asUnsigned', () {
      expect(doc['int'].asUnsigned.runtimeType, int);
      expect(doc['int'].asUnsigned, 1);
      expect(doc['double'].asUnsigned, 1);
      expect(doc['string'].asUnsigned, 0);
      expect(doc['boolean'].asUnsigned, 1);
      expect(doc['boolean1'].asUnsigned, 0);
      expect(doc['list'].asUnsigned, 0);
      expect(doc['map'].asUnsigned, 0);
    });

    test('asDouble', () {
      expect(doc['int'].asDouble.runtimeType, double);
      expect(doc['double'].asDouble, 1.1);

      expect(doc['int'].asDouble, 1);
      expect(doc['string'].asDouble, 0);
      expect(doc['boolean'].asDouble, 1);
      expect(doc['boolean1'].asDouble, 0);
      expect(doc['list'].asDouble, 0);
      expect(doc['map'].asDouble, 0);
    });

    test('asString', () {
      expect(doc['string'].asString.runtimeType, String);
      expect(doc['string'].asString, 'text');

      expect(doc['int'].asString, '');
      expect(doc['double'].asString, '');
      expect(doc['boolean'].asString, '');
      expect(doc['boolean1'].asString, '');
      expect(doc['list'].asString, '');
      expect(doc['map'].asString, '');
    });

    test('asList', () {
      expect(doc['list'].asList.runtimeType, FLArray);
      expect(doc['list'].asList.json, '[1,2]');

      expect(doc['int'].asList, FLArray());
      expect(doc['double'].asList, FLArray());
      expect(doc['string'].asList, FLArray());
      expect(doc['boolean'].asList, FLArray());
      expect(doc['map'].asList, FLArray());
    });

    test('asMap', () {
      expect(doc['map'].asMap.runtimeType, FLDict);
      expect(doc['map'].asMap.json, '{"one":"two"}');

      expect(doc['int'].asMap, FLDict());
      expect(doc['double'].asMap, FLDict());
      expect(doc['string'].asMap, FLDict());
      expect(doc['boolean'].asMap, FLDict());
      expect(doc['list'].asMap, FLDict());
    });

    test('toString', () {
      expect(doc['int'].toString(), '1');
      expect(doc['double'].toString(), '1.1');
      expect(doc['double1'].toString(), '0');
      expect(doc['double2'].toString(), '2.0');
      expect(doc['string'].toString(), 'text');
      expect(doc['boolean'].toString(), 'true');
      expect(doc['boolean1'].toString(), 'false');
      expect(doc['list'].toString(), '');
      expect(doc['map'].toString(), '');
    });

    test('==', () {
      final doc0 = FLDict.fromMap({
        'int': 1,
        'double': 1.1,
        'string': 'text',
        'boolean': true,
        'list': [1, 2],
        'map': {'one': 'two'},
      });

      final doc1 = FLDict.fromMap({
        'int': 1,
        'double': 1.1,
        'string': 'text',
        'boolean': true,
        'list': [1, 2],
        'map': {'one': 'two'},
      });

      final doc2 = FLDict.fromMap({
        'int': 1,
        'double': 1.1,
        'string': 'text',
        'boolean': true,
        'list': [1, 2, 3],
        'map': {'one': 'two', 'three': 'four'},
      });

      expect(doc0.value == doc1.value, true);
      expect(doc0.value == doc2.value, false);

      expect(doc0['map'] == doc1['map'], true);
      expect(doc0['map'] == doc2['map'], false);

      expect(doc0['list'] == doc1['list'], true);
      expect(doc0['list'] == doc2['list'], false);
    });

    test('keypath/type', () {
      expect(doc.value['int'].type, FLValueType.Number);
      expect(doc.value['double'].type, FLValueType.Number);
      expect(doc.value['boolean'].type, FLValueType.Bool);
      expect(doc.value['string'].type, FLValueType.String);
      expect(doc.value['map'].type, FLValueType.Dict);
      expect(doc.value['map.one'].type, FLValueType.String);
      expect(doc.value['map.notavalue'].type, FLValueType.Undefined);
      expect(doc.value['list[0]'].type, FLValueType.Number);
      expect(doc.value['list[-1]'].type, FLValueType.Number);
      expect(doc.value['list[1000]'].type, FLValueType.Undefined);
    });
  });

  group('FLDict', () {
    final dict = FLDict.fromMap({
      'int': 1,
      'double': 1.1,
      'string': 'text',
      'boolean': true,
      'list': [1, 2],
      'map': {'one': '1', 'two': 2},
    });

    test('fromMap', () {
      expect(FLDict.fromMap({'foo': 'bar'}).json, '{"foo":"bar"}');
    });

    test('fromJson', () {
      expect(FLDict.fromJson('{"foo":"bar"').error, FLError.jsonError);
      expect(FLDict.fromJson('{"foo":"bar"}').json, '{"foo":"bar"}');
      expect(FLDict.fromJson('[1,2]').value.type, FLValueType.Dict);
      expect(FLDict.fromJson('[1,2]').value.json, '{}');
    });

    test('dispose', () {
      final dict = FLDict.fromJson('{"foo":"bar"}');
      expect(dict.ref, isNot(nullptr));
      expect(dict.retained, true);
      dict.dispose();
      expect(dict.ref, nullptr);
      expect(dict.retained, false);
    });

    test('length', () {
      expect(dict.length, 6);
      expect(FLDict.fromMap({}).length, 0);
    });

    test('isEmpty', () {
      expect(dict.isEmpty, false);
      expect(FLDict.fromMap({}).isEmpty, true);
    });

    test('mutable', () {
      expect(dict.isMutable, false);
      expect(dict.mutable.isMutable, true);
      expect(dict.mutable['map'].asMap.isMutable, false);
    });

    test('mutableCopy', () {
      expect(dict.isMutable, false);
      expect(dict.mutableCopy.isMutable, true);
      expect(dict.mutableCopy['map'].asMap.isMutable, true);
    });

    test('isMutable', () {
      expect(dict.isMutable, false);
    });

    test('key access - []', () {
      expect(dict['int'].asInt, 1);
      expect(dict['list'].asList[0].asInt, 1);
      expect(dict['map'].asMap['one'].asString, '1');
    });

    test('key access - []=', () {
      expect(
        () => dict['value'] = 2,
        throwsA(predicate((e) =>
            e is CouchbaseLiteException &&
            e.domain == 4 && // TODO FIX
            e.code == 14)),
      );

      final mutDict = dict.mutableCopy;

      // The supported types are
      // 1. Int
      mutDict['value'] = 2;
      expect(mutDict['value'].asInt, 2);
      // 2. Double
      mutDict['value'] = 3.1415;
      expect(mutDict['value'].asDouble, 3.1415);
      // 3. Bool
      mutDict['value'] = true;
      expect(mutDict['value'].asBool, true);
      // 3. String
      mutDict['value'] = 'text';
      expect(mutDict['value'].asString, 'text');
      // 4. FLValue
      mutDict['value'] = mutDict['int'];
      expect(mutDict['value'].asInt, 1);
      // 5. FLDict
      mutDict['value'] = mutDict['map'].asMap;
      expect(mutDict['value'].json, '{"one":"1","two":2}');
      // 6. FLArray
      mutDict['value'] = mutDict['list'].asList;
      expect(mutDict['value'].json, '[1,2]');
      // 7. json-encodable objetc
      mutDict['value'] = {
        'one': [1, 2],
        'two': true,
        'three': 3.1415,
      };
      expect(mutDict['value'].json, '{"one":[1,2],"three":3.1415,"two":true}');
    });

    test('keypath - ()', () {
      expect(dict('list[0]').asString, dict['list'].asList[0].asString);
      expect(dict('list[-1]').asString, dict['list'].asList[1].asString);
      expect(dict('list[-1]').asString, dict['list'].asList[-1].asString);
      expect(dict('map.one').asString, dict['map'].asMap['one'].asString);
    });

    test('iterator', () {
      expect(dict, isA<IterableBase<FLValue>>());
      for (var value in dict) {
        expect(value, isA<FLValue>());
      }
    });

    test('values', () {
      expect(dict.values, isA<FLDictValues>());
      for (var value in dict.values) {
        expect(value, isA<FLValue>());
      }
    });

    test('keys', () {
      expect(dict.keys, isA<FLDictKeys>());
      for (var value in dict.keys) {
        expect(value, isA<String>());
      }
    });

    test('entries', () {
      expect(dict.entries, isA<FLDictEntries>());
      for (var entry in dict.entries) {
        expect(entry, isA<MapEntry<String, FLValue>>());
        expect(dict[entry.key].json, entry.value.json);
      }
    });
  });

  group('FLArray', () {
    final list = FLArray.fromList([
      1,
      1.1,
      'text',
      true,
      [1, 2],
      {'one': '1', 'two': 2},
    ]);

    test('fromList', () {
      expect(FLArray.fromList([]).json, '[]');
      expect(FLArray.fromList([1, 2]).json, '[1,2]');
    });

    test('fromJson', () {
      expect(FLArray.fromJson('[1, 2').error, FLError.jsonError);
      expect(FLArray.fromJson('[1,2]').json, '[1,2]');
      expect(FLArray.fromJson('{"1": 2}').value.type, FLValueType.Array);
      expect(FLArray.fromJson('{"1": 2}').value.json, '[]');
    });

    test('length', () {
      expect(list.length, 6);
      expect(FLArray.fromList([]).length, 0);
    });

    test('isEmpty', () {
      expect(list.isEmpty, false);
      expect(FLArray.fromList([]).isEmpty, true);
    });

    test('mutable', () {
      expect(list.isMutable, false);
      expect(list.mutable.isMutable, true);
      expect(list.mutable[5].asMap.isMutable, false);
    });

    test('mutableCopy', () {
      expect(list.isMutable, false);
      expect(list.mutableCopy.isMutable, true);
      expect(list.mutableCopy[5].asMap.isMutable, true);
    });

    test('isMutable', () {
      expect(list.isMutable, false);
    });

    test('key access - []', () {
      expect(list[0].asInt, 1);
      expect(list[4].asList[0].asInt, 1);
      expect(list[5].asMap['one'].asString, '1');
    });

    test('key access - []=', () {
      expect(
        () => list[0] = 2,
        throwsA(predicate((e) =>
            e is CouchbaseLiteException &&
            e.domain == 4 && // TODO FIX
            e.code == 14)),
      );

      final mutList = list.mutableCopy;

      // The supported types are
      // 1. Int
      mutList[6] = 2;
      expect(mutList[6].asInt, 2);
      // 2. Double
      mutList[6] = 3.1415;
      expect(mutList[6].asDouble, 3.1415);
      // 3. Bool
      mutList[6] = true;
      expect(mutList[6].asBool, true);
      // 3. String
      mutList[6] = 'text';
      expect(mutList[6].asString, 'text');
      // 4. FLValue
      mutList[6] = mutList[0];
      expect(mutList[6].asInt, 1);
      // 5. FLDict
      mutList[6] = mutList[5].asMap;
      expect(mutList[6].json, '{"one":"1","two":2}');
      // 6. FLArray
      mutList[6] = mutList[4].asList;
      expect(mutList[6].json, '[1,2]');
      // 7. json-encodable objetc
      mutList[6] = {
        'one': [1, 2],
        'two': true,
        'three': 3.1415,
      };
      expect(mutList[6].json, '{"one":[1,2],"three":3.1415,"two":true}');
    });

    test('keypath - ()', () {
      expect(list('[4][0]').asString, list[4].asList[0].asString);
      expect(list('[4][-1]').asString, list[4].asList[1].asString);
      expect(list('[-1].one').asString, list[5].asMap['one'].asString);
    });

    test('iterator', () {
      expect(list, isA<IterableBase<FLValue>>());
      for (var value in list) {
        expect(value, isA<FLValue>());
      }
    });
  });
}
