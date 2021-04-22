// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io';

import 'package:couchbase_lite_dart/src/native/bindings.dart' as cbl;
import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:test/test.dart';

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

  test('create', () {
    var db = Database('document1', directory: TESTDIR);

    final doc = Document('testdoc');
    expect(doc.ID, 'testdoc');
    expect(doc.json, '{}');

    addTearDown(() => db.close());
  });

  test('createWithMap', () {
    var db = Database('document1', directory: TESTDIR);

    final doc = Document('testdoc1', data: {'foo': 'bar'});
    expect(doc.ID, 'testdoc1');
    expect(doc.json, '{"foo":"bar"}');
    expect(doc.properties['foo'].asString, 'bar');

    addTearDown(() => db.close());
  });

  test('createWithJson', () {
    var db = Database('document1', directory: TESTDIR);

    final doc = Document('testdoc1', data: '{"foo":"bar"}');
    expect(doc.ID, 'testdoc1');
    expect(doc.json, '{"foo":"bar"}');
    expect(doc.properties['foo'].asString, 'bar');

    addTearDown(() => db.close());
  });

  test('createWithFLDict', () {
    var db = Database('document1', directory: TESTDIR);

    final props = FLDict();
    props['foo'] = 'bar';

    final doc = Document('testdoc1', data: props);
    expect(doc.ID, 'testdoc1');
    expect(doc.json, '{"foo":"bar"}');
    expect(doc.properties['foo'].asString, 'bar');

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
    var db = Database('document1', directory: TESTDIR);

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
    expect(doc.properties['list'].asList[0].asInt, 1);
    expect(doc.properties['list'].asList[1].asInt, 2);
    expect(doc.properties['map'].asMap['one'].asString, 'two');

    doc.properties = FLDict();
    expect(doc.json, '{}');

    addTearDown(() => db.close());
  });

  test('save', () {
    var db = Database('savedoc', directory: '_tmp');
    expect(
      Document('testdoc', data: {'foo': 'bar'}, db: db).save(),
      predicate<Document>((doc) => doc.ID == 'testdoc'),
    );
    addTearDown(() => db.close());
  });

  test('saveResolving', () {
    var db = Database('savedoc', directory: '_tmp');

    // Conflict resolution not supported with "new" documents.
    expect(
      () => Document('newdoc', db: db).saveResolving((_, __) => false),
      throwsA(predicate((e) =>
          e is CouchbaseLiteException &&
          e.domain == cbl.CBLDomain &&
          e.code == cbl.CBLErrorConflict)),
    );

    db.saveDocument(Document('testdoc', data: {'foo': 'bar'}));
    {
      final mutDoc = db.getMutableDocument('testdoc');
      mutDoc.properties['foo'] = 'baz';

      // Save new document
      db.saveDocument(Document('testdoc', data: {'foo': 'bar1'}));
      mutDoc.saveResolving((newDoc, oldDoc) {
        expect(newDoc.properties['foo'].asString, 'baz');
        expect(oldDoc.properties['foo'].asString, 'bar1');
        return true;
      });
      expect(db.getDocument('testdoc').properties['foo'].asString, 'baz');
    }

    // Keep old document
    {
      final mutDoc = db.getMutableDocument('testdoc');
      mutDoc.properties['foo'] = 'baz';

      db.saveDocument(Document('testdoc', data: {'foo': 'bar1'}));
      expect(
        () => mutDoc.saveResolving((newDoc, oldDoc) {
          expect(newDoc.properties['foo'].asString, 'baz');
          expect(oldDoc.properties['foo'].asString, 'bar1');
          return false;
        }),
        throwsA(predicate((e) =>
            e is CouchbaseLiteException &&
            e.domain == cbl.CBLDomain &&
            e.code == cbl.CBLErrorConflict)),
      );
      expect(db.getDocument('testdoc').properties['foo'].asString, 'bar1');
    }

    addTearDown(() => db.close());
  });

  test('delete', () {
    var db = Database('document1', directory: TESTDIR);

    final doc = Document('testdoc3', data: '{"foo":"bar"}');
    expect(doc.ID, 'testdoc3');

    expect(
        () => doc.delete(),
        throwsA((e) =>
            e is CouchbaseLiteException &&
            e.domain == cbl.CBLDomain &&
            e.code == cbl.CBLErrorNotFound));

    final doc1 = db.saveDocument(doc);

    expect(doc1.delete(), true);
    expect(db.getDocument('testdoc3').isEmpty, true);

    addTearDown(() => db.close());
  });

  test('mutableCopy', () {
    var db = Database('document1', directory: TESTDIR);

    final doc = Document('testdoc4', data: {
      'foo': 'bar',
      'name': {'first': 'test1', 'last': 'test2'}
    });
    expect(doc.ID, 'testdoc4');

    final doc1 = db.saveDocument(doc);

    expect(
        () => doc1.properties['test'] = 'test',
        throwsA((e) =>
            e is CouchbaseLiteException &&
            e.domain == cbl.CBLFleeceDomain &&
            e.code == cbl.CBLErrorNotWriteable));

    final mutDoc = doc1.mutableCopy;
    expect(doc1.json, mutDoc.json);

    mutDoc.properties['foo'] = 'baz';
    mutDoc.properties['name'].asMap['first'] = 'test0';

    expect(doc1.json, isNot(mutDoc.json));
    expect(mutDoc.properties['foo'].asString, 'baz');
    expect(mutDoc.properties('name.first').asString, 'test0');

    addTearDown(() => db.close());
  });
}
