// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ffi';
import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:test/test.dart';

import '_test_utils.dart';

const TESTDIR = '_tmp2';

void main() {
  setUpAll(() {
    Cbl.init();
    if (!Directory(TESTDIR).existsSync()) {
      Directory(TESTDIR).createSync();
    }
  });

  tearDownAll(() {
    if (Directory('test/_tmp/').existsSync()) {
      Directory('test/_tmp/').delete(recursive: true);
    }
  });

  test('query - compiles a query', () {
    var db = Database('query1', directory: TESTDIR);

    expect(
      Query(db, 'SELECT *'),
      predicate<Query>((q) => q.error.code == 0),
    );

    expect(
      () => Query(db, ''),
      throwsA(predicate((p) => p is CouchbaseLiteException && p.code == 23)),
    );

    addTearDown(() => db.close());
  });

  test('explain', () {
    var db = Database('query2', directory: TESTDIR);

    final query = Query(db, 'SELECT *');
    expect(query.explain(), isA<String>());

    addTearDown(() => db.close());
  });

  test('execute', () async {
    var db = Database('query3', directory: TESTDIR);
    final query = Query(db, 'SELECT *');
    expect(query.execute(), []);

    db.saveDocument(Document('testdoc', data: {'foo': 'bar'}));
    db.saveDocument(Document('testdoc1', data: {'foo': 'baz'}));

    expect(
      query.execute(),
      [
        {
          '*': {'foo': 'bar'}
        },
        {
          '*': {'foo': 'baz'}
        }
      ],
    );

    addTearDown(() => db.delete());
  });

  test('parameters', () {
    var db = Database('query4', directory: TESTDIR);
    db.saveDocument(Document('testdoc', data: {'foo': 'bar'}));
    db.saveDocument(Document('testdoc1', data: {'foo': 'baz'}));

    final query = Query(db, 'SELECT * WHERE foo LIKE \$BAR');

    expect(query.parameters, {});

    // Correct parameters set = the query should return a list
    query.setParameters = {'BAR': 'bar'};
    expect(query.parameters, {'BAR': 'bar'});
    expect(query.execute(), isA<List>());

    // Wrong parameters == executing the query throws an error
    query.setParameters = {'BA': 'bar'};
    expect(
      () => query.execute(),
      throwsA(predicate((e) => e is CouchbaseLiteException && e.code == 25)),
    );

    addTearDown(() => db.close());
  });

  test('changeListener', () async {
    var db = Database('query5', directory: TESTDIR);

    db.saveDocument(Document('testdoc1', data: {'foo': 'bar'}));

    final query = Query(db, 'SELECT * WHERE foo LIKE "%ba%"');
    var changes_received = false;
    var results = [];

    var token = query.addChangeListener((items) {
      changes_received = true;
      results = items;
    });

    await asyncSleep(500);
    expect(token, isA<String>());
    expect(changes_received, true);
    expect(results, [
      {
        '*': {'foo': 'bar'}
      }
    ]);

    changes_received = false;
    db.saveDocument(Document('testdoc2', data: {'foo': 'baz'}));

    await asyncSleep(2000);
    expect(changes_received, true);
    expect(results, [
      {
        '*': {'foo': 'bar'}
      },
      {
        '*': {'foo': 'baz'}
      }
    ]);

    query.removeChangeListener(token);

    await asyncSleep(100);
    changes_received = false;
    db.saveDocument(Document('testdoc2', data: {'foo': 'bat'}));

    await asyncSleep(1000);
    expect(changes_received, false);
    expect(results, [
      {
        '*': {'foo': 'bar'}
      },
      {
        '*': {'foo': 'baz'}
      }
    ]);

    addTearDown(() => db.close());
  });
}
