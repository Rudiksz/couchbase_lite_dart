import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';

import '../memtest.dart';

void main() async {
  initializeCblC();

  // Data for the tests
  final json = '{"foo": "bar"}';
  final map = {'foo': 'bar'};
  final list = ['foo', 'bar'];
  Memtest(tests: {
    'fromJson': () {
      var doc = FLDoc.fromJson(json);
      doc.root;
      doc.dispose();
      doc = FLDoc.fromMap(map);
      doc.root;
      doc.dispose();
      doc = FLDoc.fromList(list);
      doc.root;
      doc.dispose();
    },
  }).run();
}
