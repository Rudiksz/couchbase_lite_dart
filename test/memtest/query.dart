import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

import 'memtest.dart';

void main() async {
  initializeCblC();

  // Data for the tests
  var db = Database('query5');

  db.saveDocument(Document('testdoc', data: {'foo': 'bar'}));
  db.saveDocument(Document('testdoc1', data: {'foo': 'baz'}));

  const queryStr = 'SELECT * FROM _default as doc WHERE foo LIKE "%bar%"';
  final query = Query(queryStr, db: db);
  final listener = (results) => results.allResults;

  Memtest(
    tests: {
      'query': () => Query(queryStr, db: db).dispose(),
      'explain': () => query.explain(),
      'execute': () => query.execute().dispose(),
      'parameters': () => query.parameters,
      'parameters=': () => query.parameters = {'BA': 'bar'},
      'allResults': () => query.execute().allResults,
      'resultSet': () {
        final results = query.execute();
        while (results.next()) {
          results.rowDict;
          results.rowArray;
        }
        results.dispose();
      },
      'changeListener': () {
        final token = query.addChangeListener(listener);
        query.removeChangeListener(token);
      }
    },
    activeTests: [
      'query',
      // 'explain',
      // 'execute',
      // 'parameters',
      // 'parameters=',
      // 'allResults',
      // 'resultSet',
      // 'changeListener',
    ],
  ).run();
}
