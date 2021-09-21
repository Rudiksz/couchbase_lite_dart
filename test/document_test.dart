// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@Timeout(Duration(seconds: 2000))

import 'dart:io';

import 'package:couchbase_lite_dart/src/native/bindings.dart' as cbl;
import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:test/test.dart';

import '_test_utils.dart';

const TESTDIR = '_tmp';

void main() {
  initializeCblC();

  setUpAll(() {
    if (!Directory(TESTDIR).existsSync()) {
      Directory(TESTDIR).createSync();
    }
  });

  tearDownAll(() {
    if (Directory(TESTDIR).existsSync()) {
      Directory(TESTDIR).delete(recursive: true);
    }
  });

  test('create', () async {
    var db = Database('document1', directory: TESTDIR);

    for (var i = 0; i < 10; i++) {
      await asyncSleep(10);
      final doc = Document('testdoc_$i', data: {
        '_id': '5973782bdb9a930533b05cb2',
        'isActive': true,
        'balance': '\$1,446.35',
        'age': 32,
        'eyeColor': 'green',
        'name': 'Logan Keller',
        'gender': 'male',
        'company': 'ARTIQ',
        'email': 'logankeller@artiq.com',
        'phone': '+1 (952) 533-2258',
        'friends': [
          {'id': 0, 'name': 'Colon Salazar'},
          {'id': 1, 'name': 'French Mcneil'},
          {'id': 2, 'name': 'Carol Martin'}
        ],
        'favoriteFruit': 'banana',
        'lorem': lorem,
      });

      expect(doc.ID, 'testdoc_$i');

      doc.dispose();
      expect(doc.isEmpty, true);

      expect(
        () => doc.json = '{"foo":"bar"}',
        throwsA(predicate((e) =>
            e is AssertionError &&
            e.message == 'Documents cannot be used after beeing disposed.')),
      );
    }

    addTearDown(() => db.close());
  });

  test('createWithMap', () {
    var db = Database('document1', directory: TESTDIR);

    var instanceCount = Cbl.instanceCount;

    final doc = Document('testdoc1', data: {'foo': 'bar'});
    expect(doc.ID, 'testdoc1');
    expect(doc.json, '{"foo":"bar"}');
    expect(doc.properties['foo'].asString, 'bar');

    expect(Cbl.instanceCount, instanceCount + 1);

    doc.dispose();

    expect(doc.isEmpty, true);

    expect(
      () => doc.json = '{"foo":"bar"}',
      throwsA(predicate((e) =>
          e is AssertionError &&
          e.message == 'Documents cannot be used after beeing disposed.')),
    );

    expect(Cbl.instanceCount, instanceCount);

    addTearDown(() => db.close());
  });

  test('createWithJson', () {
    var db = Database('document1', directory: TESTDIR);

    var instanceCount = Cbl.instanceCount;

    final doc = Document('testdoc1', data: '{"foo":"bar"}');
    expect(doc.ID, 'testdoc1');
    expect(doc.json, '{"foo":"bar"}');
    expect(doc.properties['foo'].asString, 'bar');

    expect(Cbl.instanceCount, instanceCount + 1);

    doc.dispose();

    expect(doc.isEmpty, true);

    expect(
      () => doc.json = '{"foo":"bar"}',
      throwsA(predicate((e) =>
          e is AssertionError &&
          e.message == 'Documents cannot be used after beeing disposed.')),
    );

    expect(Cbl.instanceCount, instanceCount);

    addTearDown(() => db.close());
  });

  test('createWithFLDict', () {
    var db = Database('document1', directory: TESTDIR);

    final props = FLDict();
    props['foo'] = 'bar';

    var instanceCount = Cbl.instanceCount;

    final doc = Document('testdoc1', data: props);
    expect(doc.ID, 'testdoc1');
    expect(doc.json, '{"foo":"bar"}');
    expect(doc.properties['foo'].asString, 'bar');

    expect(Cbl.instanceCount, instanceCount + 1);

    doc.dispose();

    expect(doc.isEmpty, true);

    expect(
      () => doc.json = '{"foo":"bar"}',
      throwsA(predicate((e) =>
          e is AssertionError &&
          e.message == 'Documents cannot be used after beeing disposed.')),
    );

    expect(Cbl.instanceCount, instanceCount);

    addTearDown(() => db.close());
  });

  test('map', () {
    var db = Database('document1', directory: TESTDIR);

    final doc = Document('testdoc2');
    expect(doc.ID, 'testdoc2');
    expect(doc.json, '{}');
    expect(doc.map, {});

    doc.map = {
      'int': 1,
      'string': 'text',
      'boolean': true,
      'list': [1, 2],
      'map': {'one': 'two'},
    };

    expect(doc.map, {
      'int': 1,
      'string': 'text',
      'boolean': true,
      'list': [1, 2],
      'map': {'one': 'two'},
    });

    doc.map = {};
    expect(doc.map, {});

    addTearDown(() => db.close());
  });

  test('json', () {
    var db = Database('document1', directory: TESTDIR);

    final doc = Document('testdoc2');
    expect(doc.ID, 'testdoc2');
    expect(doc.json, '{}');
    expect(doc.map, {});

    doc.json =
        '{"boolean":true,"int":1,"list":[1,2],"map":{"one":"two"},"string":"text"}';

    expect(doc.json,
        '{"boolean":true,"int":1,"list":[1,2],"map":{"one":"two"},"string":"text"}');

    doc.json = '{}';
    expect(doc.json, '{}');

    addTearDown(() => db.close());
  });

  test('properties', () {
    final doc = Document('testdoc2');
    expect(doc.ID, 'testdoc2');
    expect(doc.json, '{}');
    expect(doc.map, {});

    doc.properties = FLDict.fromMap({
      'int': 1,
      'string': 'text',
      'boolean': true,
      'list': [1, 2],
      'map': {'one': 'two'},
    });

    expect(doc.json,
        '{"boolean":true,"int":1,"list":[1,2],"map":{"one":"two"},"string":"text"}');

    expect(doc.properties['int'].asInt, 1);
    expect(doc.properties['string'].asString, 'text');
    expect(doc.properties['boolean'].asBool, true);
    expect(doc.properties['list'].asArray[0].asInt, 1);
    expect(doc.properties['list'].asArray[1].asInt, 2);
    expect(doc.properties['map'].asDict['one'].asString, 'two');

    doc.properties = FLDict();
    expect(doc.json, '{}');
  });

  test('mutableCopy', () {
    var db = Database('document1', directory: TESTDIR);

    final doc = Document('testdoc4', data: {
      'foo': 'bar',
      'name': {'first': 'test1', 'last': 'test2'}
    });
    expect(doc.ID, 'testdoc4');
    db.saveDocument(doc);

    final doc1 = db.getDocument('testdoc4');

    expect(
        () => doc1.properties['test'] = 'test',
        throwsA((e) =>
            e is CouchbaseLiteException &&
            e.domain == cbl.kCBLFleeceDomain &&
            e.code == cbl.kCBLErrorNotWriteable));

    final mutDoc = doc1.mutableCopy;
    expect(doc.json, mutDoc.json);

    mutDoc.properties['foo'] = 'baz';
    mutDoc.properties['name'].asMutableDict['first'] = 'test0';

    expect(doc1.json, isNot(mutDoc.json));
    expect(mutDoc.properties['foo'].asString, 'baz');
    expect(mutDoc.properties('name.first').asString, 'test0');

    addTearDown(() => db.close());
  });
}

String lorem =
    '''Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi accumsan neque vitae nisl sagittis, eleifend dapibus mi commodo. Cras et risus et leo elementum varius vitae ac lectus. Ut volutpat malesuada lorem, nec luctus leo blandit ac. Nam sit amet ultricies ipsum. Sed nec felis et tellus tempus cursus. Proin laoreet nunc ut felis ornare consectetur. Quisque blandit eros ligula. Aenean interdum, felis quis luctus hendrerit, est nibh ultrices eros, eu sagittis nulla risus vel tortor. Vestibulum nec rutrum felis, quis blandit velit. Cras aliquet magna vulputate eleifend laoreet. Etiam mollis magna sit amet libero posuere fermentum. Proin justo justo, sodales vitae sollicitudin ut, accumsan id sem. Fusce quis efficitur tortor.

Etiam faucibus volutpat lacus quis euismod. Morbi finibus sem sit amet elit mattis feugiat. Ut eleifend facilisis metus et mattis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Interdum et malesuada fames ac ante ipsum primis in faucibus. Morbi nec vulputate tellus, id dapibus dui. Proin sed purus et ante sollicitudin varius vestibulum a leo. Sed sit amet elementum justo. Proin eu posuere leo.

Nulla tempor laoreet ipsum, in semper erat. Pellentesque pharetra, sem sit amet hendrerit eleifend, mauris metus sagittis leo, nec tincidunt leo orci vel magna. Integer non nisl in sem ullamcorper condimentum et et dolor. Fusce tristique elit et nunc porttitor molestie tempus ut tortor. Praesent interdum nulla a turpis lobortis, a rhoncus turpis ultricies. Aliquam accumsan, nulla sit amet ultricies imperdiet, nibh odio lacinia velit, quis auctor mi dui sollicitudin enim. Integer sed augue eu ligula sodales ultrices. Sed ante lectus, semper sed odio in, maximus lacinia nunc. Quisque placerat ornare erat vel venenatis. Aliquam at mauris tincidunt, condimentum purus vel, viverra libero. Donec hendrerit, velit sed consectetur sagittis, tellus purus pellentesque ipsum, a blandit risus nibh nec lacus.

Sed ullamcorper suscipit ultricies. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Curabitur vulputate, metus non semper laoreet, augue dui tempus nunc, ultrices malesuada orci lectus eget augue. Integer tempus tempor enim ut eleifend. Donec sit amet purus scelerisque, bibendum dolor nec, pretium leo. Nullam hendrerit turpis ut urna dictum laoreet. In finibus in augue ac iaculis. Ut non nisl tortor. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Cras vehicula quam nisl, id placerat sem tincidunt non. Praesent lorem mi, mattis iaculis feugiat malesuada, bibendum nec tortor. Sed at dolor iaculis est pellentesque euismod.

In bibendum eu ipsum a sollicitudin. Nam rhoncus imperdiet nisl. Interdum et malesuada fames ac ante ipsum primis in faucibus. Ut condimentum, ipsum vel scelerisque tempus, magna mauris imperdiet velit, quis tristique mauris elit ac dui. Nam at elit ligula. Vestibulum fringilla in justo et suscipit. In semper a lorem commodo blandit. Praesent aliquam tempor turpis, ac elementum risus ultrices vitae. Quisque sit amet finibus risus. Donec ex risus, tristique a lobortis non, tempor a erat. Nunc et magna nibh.
''';
