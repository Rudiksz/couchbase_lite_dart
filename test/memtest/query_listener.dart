import 'dart:math';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

import 'memtest.dart';

void main() async {
  initializeCblC();

  // Data for the tests
  var db = Database('query5');

  db.saveDocument(Document('testdoc', data: {'foo': 'bar'}));
  db.saveDocument(Document('testdoc1', data: {'foo': 'baz'}));
  final mutDoc = db.getDocument('testdoc1').mutableCopy;

  const queryStr = 'SELECT * FROM _default as doc WHERE foo LIKE "%bar"';
  final query = Query(queryStr, db: db);
  query.addChangeListener((results) => true);

  Memtest(
    tests: {
      'changeListener': () {
        mutDoc.properties['foo'] = 'bar' + Random().nextInt(10000).toString();
        db.saveDocument(mutDoc);
      }
    },
    activeTests: [
      'changeListener',
    ],
  ).run();
}
