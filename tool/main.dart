import 'dart:async';
import 'dart:io';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:couchbase_lite_dart/src/native/cblc_base.dart';

const TESTDIR = '_tmp1';
Future asyncSleep(int millis) => Future.delayed(Duration(milliseconds: millis));
void main() async {
  initializeCblC();
  if (!Directory(TESTDIR).existsSync()) {
    Directory(TESTDIR).createSync();
  }
  var endpointUrl = 'ws://192.168.0.240:4984/cbltest/';
  var username = 'cbltest';
  var password = 'cbltest';

  var db = Database('query5', directory: TESTDIR);

  db.saveDocument(Document('testdoc1', data: {'foo': 'bar', 'version': '1'}));

  final query = Query(db, 'SELECT * WHERE foo LIKE "%ba%"');

  final changesStreamController = StreamController<String>();
  final changesStream = changesStreamController.stream.asBroadcastStream();
  asyncListener(changesStream);
  changesStream.asBroadcastStream().listen((change) {
    print('------inline listener----');
    print(change);
  });

  var token = query.addChangeListener((results) {
    while (results.next()) {
      changesStreamController.sink.add(results.rowDict.json);
    }
  });

  await Future.delayed(Duration(seconds: 2));
  db.saveDocument(Document('testdoc2', data: {'foo': 'baz', 'version': '1'}));

  await Future.delayed(Duration(seconds: 3));
  db.saveDocument(Document('testdoc2', data: {'foo': 'baz', 'version': '2'}));

  await Future.delayed(Duration(seconds: 1));
  db.saveDocument(Document('testdoc1', data: {'foo': 'baz', 'version': '2'}));
}

asyncListener(Stream<String> stream) async {
  await for (String queryChange in stream) {
    print('------listener function----');
    print(queryChange);
  }
}
