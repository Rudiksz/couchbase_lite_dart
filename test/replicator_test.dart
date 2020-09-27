// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:test/test.dart';

import '_test_utils.dart';

const TESTDIR = '_tmp1';

void main() {
  var endpointUrl = 'ws://localhost:4984/cblc_test/';
  var username = 'cblc_test';
  var password = 'cblc_test';

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
    var basicAuth = Authenticator.basic(username, password);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      authenticator: basicAuth,
    );

    expect(
      replicator.status(),
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel == ActivityLevel.stopped),
    );

    addTearDown(() => db.close());
  });

  test('start', () async {
    var db = Database('replstart', directory: TESTDIR);
    var basicAuth = Authenticator.basic(username, password);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      authenticator: basicAuth,
    );

    expect(
      replicator.status(),
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel == ActivityLevel.stopped),
    );

    replicator.start();
    await asyncSleep(1000);

    expect(
      replicator.status(),
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
    var basicAuth = Authenticator.basic(username, password);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      authenticator: basicAuth,
    );

    replicator.start();
    await asyncSleep(5000);

    expect(
      replicator.status(),
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel != ActivityLevel.stopped),
    );

    replicator.stop();
    await asyncSleep(5000);

    expect(
      replicator.status(),
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
    var basicAuth = Authenticator.basic(username, password);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      authenticator: basicAuth,
    );

    replicator.start();
    await asyncSleep(1000);

    expect(
      replicator.status(),
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel != ActivityLevel.stopped),
    );

    replicator.suspend();
    await asyncSleep(1000);

    expect(
      replicator.status(),
      predicate<ReplicatorStatus>(
          (e) => e.activityLevel == ActivityLevel.offline),
    );

    replicator.resume();
    await asyncSleep(1000);

    expect(
      replicator.status(),
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
    var basicAuth = Authenticator.basic(username, password);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      authenticator: basicAuth,
    );

    replicator.start();
    await asyncSleep(5000);
    replicator.suspend();
    await asyncSleep(5000);

    replicator.setHostReachable(false);

    expect(
      replicator.status(),
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
    var basicAuth = Authenticator.basic(username, password);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      authenticator: basicAuth,
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
    var basicAuth = Authenticator.basic(username, password);
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      authenticator: basicAuth,
    );

    var status_received = false;
    ReplicatorStatus status;

    replicator.addChangeListener((newStatus) {
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

    addTearDown(() {
      replicator.stop();
      db.close();
    });
  });

  test('pushFilter', () async {
    var db = Database('replpushfilter', directory: TESTDIR);
    var basicAuth = Authenticator.basic(username, password);

    var doc_received = false;
    Document doc_filtered;
    await asyncSleep(1000);
    var replicator = Replicator(
      db,
      endpointUrl: endpointUrl,
      authenticator: basicAuth,
      pushFilter: (document, _) {
        doc_received = true;
        doc_filtered = document;
        return true;
      },
    );

    replicator.start();
    await asyncSleep(5000);

    expect(doc_received, false);
    expect(doc_filtered, isNull);

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
}
