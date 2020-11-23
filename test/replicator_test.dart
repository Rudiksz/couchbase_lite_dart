// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:test/test.dart';

import '_test_utils.dart';

const TESTDIR = '_tmp1';

void main() {
  var endpointUrl = 'ws://localhost:4984/cbltest/';
  var username = 'cbltest';
  var password = 'cbltest';

  setUp(() => ChangeListeners.initalize());

  setUpAll(() {
    Cbl.init();
    if (!Directory(TESTDIR).existsSync()) {
      Directory(TESTDIR).createSync();
    }
  });

  tearDownAll(() async {
    await asyncSleep(1000);
    if (Directory(TESTDIR).existsSync()) {
      await Directory(TESTDIR).delete(recursive: true);
    }
  });

  test('create', () async {
    var db = Database('replcreate', directory: TESTDIR);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
    );

    expect(
      replicator.status,
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel == ActivityLevel.stopped),
    );

    addTearDown(() => db.close());
  });

  test('start', () async {
    var db = Database('replstart', directory: TESTDIR);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
    );

    expect(
      replicator.status,
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel == ActivityLevel.stopped),
    );

    replicator.start();
    await asyncSleep(1000);

    expect(
      replicator.status,
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel != ActivityLevel.stopped),
    );

    addTearDown(() {
      replicator.stop();
      db.close();
    });
  });

  test('stop', () async {
    var db = Database('replstop', directory: TESTDIR);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
    );

    replicator.start();
    await asyncSleep(1000);

    expect(
      replicator.status,
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel != ActivityLevel.stopped),
    );

    replicator.stop();
    await asyncSleep(1000);

    expect(
      replicator.status,
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel == ActivityLevel.stopped),
    );

    addTearDown(() {
      replicator.stop();
      db.close();
    });
  });

  test('suspend/resume', () async {
    var db = Database('replssuspend', directory: TESTDIR);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
    );

    replicator.start();
    await asyncSleep(1000);

    expect(
      replicator.status,
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel != ActivityLevel.stopped),
    );

    replicator.suspend();
    await asyncSleep(1000);

    expect(
      replicator.status,
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel == ActivityLevel.offline),
    );

    replicator.resume();
    await asyncSleep(1000);

    expect(
      replicator.status,
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel != ActivityLevel.offline),
    );

    addTearDown(() async {
      replicator.stop();
      await asyncSleep(500);
      db.close();
    });
  });

  test('setHostReachable', () async {
    var db = Database('replhostreach', directory: TESTDIR);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
    );

    replicator.start();
    await asyncSleep(1000);
    replicator.suspend();
    await asyncSleep(1000);

    replicator.setHostReachable(false);

    expect(
      replicator.status,
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel == ActivityLevel.offline),
    );

    addTearDown(() {
      replicator.stop();
      db.close();
    });
  });

  test('resetCheckPoint', () async {
    var db = Database('replcheckp', directory: TESTDIR);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
    );

    replicator.start();
    await asyncSleep(5000);
    replicator.resetCheckpoint();

    await asyncSleep(5000);

    addTearDown(() {
      replicator.stop();
      db.close();
    });
  });

  test('addChangeListener', () async {
    await asyncSleep(500);
    var db = Database('replchangelistener', directory: TESTDIR);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
    );

    var status_received = false;
    ReplicatorStatus status;

    final token = replicator.addChangeListener((newStatus) {
      status_received = true;
      status = newStatus;
    });

    replicator.start();
    await asyncSleep(1000);

    expect(status_received, true);
    expect(status.activityLevel, isNot(ActivityLevel.stopped));

    await asyncSleep(5000);
    status_received = false;
    replicator.stop();

    await asyncSleep(5000);
    expect(status_received, true);
    expect(status.activityLevel, ActivityLevel.stopped);

    await asyncSleep(5000);

    status_received = false;

    replicator.removeChangeListener(token);
    await asyncSleep(500);
    replicator.start();

    expect(status_received, false);

    addTearDown(() async {
      replicator.stop();
      await asyncSleep(500);
      db.close();
    });
  });

  test('pushFilter', () async {
    var db = Database('replpushfilter', directory: TESTDIR);

    var doc_received = false;
    Document doc_filtered;
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
      pushFilter: (document, _) {
        doc_received = true;
        doc_filtered = document;
        return true;
      },
    );

    replicator.start();
    await asyncSleep(1000);

    expect(doc_received, false);
    expect(doc_filtered, isNull);
    await asyncSleep(1000);
    db.saveDocument(Document(
      'testdoc',
      data: {'foo': 'bar', 'dt': 'test'},
    ));

    await asyncSleep(5000);

    expect(doc_received, true);
    expect(doc_filtered.ID, 'testdoc');

    addTearDown(() {
      replicator.stop();
      db.close();
    });
  });

  test('isDocumentPending', () async {
    var db = Database('pendingdoc', directory: TESTDIR);

    await asyncSleep(100);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
    );

    db.saveDocument(Document(
      'testdoc',
      data: {'foo': 'bar', 'dt': 'test'},
    ));

    expect(replicator.isDocumentPending('testdoc'), true);
    await asyncSleep(500);
    replicator.start();
    await asyncSleep(5000);
    expect(replicator.isDocumentPending('testdoc'), false);

    addTearDown(() {
      replicator.stop();
      db.close();
    });
  });

  test('pendingDocumentIds', () async {
    var db = Database('pendingDocumentIds', directory: TESTDIR);

    await asyncSleep(100);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      username: username,
      password: password,
    );

    db.saveDocument(Document(
      'testdoc',
      data: {'foo': 'bar', 'dt': 'test'},
    ));

    expect(replicator.pendingDocumentIds.length, 1);
    expect(replicator.pendingDocumentIds.json, '{"testdoc":true}');
    await asyncSleep(500);
    replicator.start();
    await asyncSleep(5000);

    expect(replicator.pendingDocumentIds.length, 0);
    expect(replicator.pendingDocumentIds.json, '');

    addTearDown(() {
      replicator.stop();
      db.close();
    });
  });
}
