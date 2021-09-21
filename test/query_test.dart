// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io';

import 'package:couchbase_lite_dart/src/native/bindings.dart' as cbl;
import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:test/test.dart';

import '_test_utils.dart';

const TESTDIR = '_tmp2';

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

  test('query - compiles a query', () {
    var db = Database('query1', directory: TESTDIR);

    expect(
      () => Query('', db: db),
      throwsA(predicate(
        (p) =>
            p is CouchbaseLiteException && p.code == cbl.kCBLErrorInvalidQuery,
      )),
    );

    addTearDown(() => db.close());
  });

  test('explain', () {
    var db = Database('query2', directory: TESTDIR);

    final query = Query('SELECT * FROM _default', db: db);
    expect(query.explain(), isA<String>());

    addTearDown(() => db.close());
  });

  test('execute', () async {
    var db = Database('query3', directory: TESTDIR);
    final query = Query('SELECT * FROM _default as doc', db: db);
    expect(query.execute().allResults, []);

    await asyncSleep(500);

    db.saveDocument(Document('testdoc', data: {'foo': 'bar'}));
    db.saveDocument(Document('testdoc1', data: {'foo': 'baz'}));

    expect(
      query.execute().allResults,
      [
        {
          'doc': {'foo': 'bar'}
        },
        {
          'doc': {'foo': 'baz'}
        }
      ],
    );

    addTearDown(() => db.delete());
  });

  test('parameters', () {
    var db = Database('query4', directory: TESTDIR);
    db.saveDocument(Document('testdoc', data: {'foo': 'bar'}));
    db.saveDocument(Document('testdoc1', data: {'foo': 'baz'}));

    final query = Query('SELECT * FROM _default WHERE foo LIKE \$BAR', db: db);

    expect(query.parameters, {});

    // Correct parameters set = the query should return a list
    query.parameters = {'BAR': 'bar'};
    expect(query.parameters, {'BAR': 'bar'});
    expect(query.execute().allResults, isA<List>());

    // Wrong parameters == executing the query throws an error
    query.parameters = {'BA': 'bar'};
    expect(
      () => query.execute(),
      throwsA(predicate(
        (e) =>
            e is CouchbaseLiteException &&
            e.code == cbl.kCBLErrorInvalidQueryParam,
      )),
    );

    addTearDown(() => db.close());
  });

  test('ResultSet', () async {
    var db = Database('query3', directory: TESTDIR);
    final query = Query('SELECT foo FROM _default', db: db);
    expect(query.execute().next(), false);

    await asyncSleep(500);

    db.saveDocument(Document('testdoc', data: {'foo': 'bar'}));
    db.saveDocument(Document('testdoc1', data: {'foo': 'baz'}));

    final result = query.execute();
    expect(result.next(), true);
    expect(result.rowDict, isA<FLDict>());
    expect(result.rowDict['foo'].asString, 'bar');

    expect(result.rowArray, isA<FLArray>());
    expect(result.rowArray[0].asString, 'bar');

    expect(result.next(), true);
    expect(result.rowDict, isA<FLDict>());
    expect(result.rowDict['foo'].asString, 'baz');

    expect(result.rowArray, isA<FLArray>());
    expect(result.rowArray[0].asString, 'baz');

    expect(result.next(), false);

    addTearDown(() => db.delete());
  });

  test('changeListener', () async {
    var db = Database('query5', directory: TESTDIR);

    db.saveDocument(Document('testdoc1', data: {'foo': 'bar'}));

    final query =
        Query('SELECT * FROM _default as doc WHERE foo LIKE "%ba%"', db: db);
    var changes_received = false;
    var rows = [];

    var token = query.addChangeListener((results) {
      changes_received = true;
      rows = results.allResults;
    });

    await asyncSleep(500);
    expect(token, isA<String>());
    expect(changes_received, true);

    expect(rows, [
      {
        'doc': {'foo': 'bar'}
      }
    ]);

    changes_received = false;
    db.saveDocument(Document('testdoc2', data: {'foo': 'baz'}));

    await asyncSleep(2000);
    expect(changes_received, true);
    expect(rows, [
      {
        'doc': {'foo': 'bar'}
      },
      {
        'doc': {'foo': 'baz'}
      }
    ]);

    query.removeChangeListener(token);

    await asyncSleep(100);
    changes_received = false;
    db.saveDocument(Document('testdoc2', data: {'foo': 'bat'}));

    await asyncSleep(1000);
    expect(changes_received, false);
    expect(rows, [
      {
        'doc': {'foo': 'bar'}
      },
      {
        'doc': {'foo': 'baz'}
      }
    ]);

    addTearDown(() => db.close());
  });
}
