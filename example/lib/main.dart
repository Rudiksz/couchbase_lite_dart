// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:math';

import 'package:cblc_flutter/fleece.dart';
import 'package:couchbase_lite_c/couchbase_lite_c.dart';
import 'package:flutter/material.dart';

void main() async {
  Cbl.init();

  var db = Database("testdb");

  print(db.isOpen);
  await Future.delayed(Duration(seconds: 1));
  var doc = Document("testdoc");
  doc.jsonProperties = testjson;
  db.saveDocument(doc);

  runApp(MaterialApp(
    title: 'Couchbase Lite Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    // home: Placeholder(),
    home: DatabaseView(db),
  ));
}

class DatabaseView extends StatefulWidget {
  final Database db;

  const DatabaseView(this.db, {Key key}) : super(key: key);
  @override
  _DatabaseViewState createState() => _DatabaseViewState();
}

class _DatabaseViewState extends State<DatabaseView> {
  ValueNotifier<String> _explain = ValueNotifier<String>('');
  ValueNotifier<bool> _queryChanged = ValueNotifier<bool>(false);
  ValueNotifier<bool> _resultsChanged = ValueNotifier(false);

  var _results = [];
  var _selectedDoc = '';
  static const _select = 'SELECT meta.id, * ';

  var queryText = TextEditingController(text: "");
  String prevQueryText;
  Query query;

  List documents = [1];

  @override
  void initState() {
    super.initState();

    // widget.db.saveDocument(Document("test1", data: {"name": "Rudolf"}));
    // widget.db.saveDocument(
    //     Document("test2", data: {"name": "Rudolf", "email": "example.com"}));

    explain();
    queryText.addListener(
      () => _queryChanged.value = queryText.text != query?.queryString,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CBL - c'),
      ),
      body: Row(
        children: [
          sideBar(),
          Expanded(
            child: ValueListenableBuilder(
              builder: (_, __, ___) => FleeceView(
                docId: _selectedDoc,
                db: widget.db,
              ),
              valueListenable: _resultsChanged,
            ),
          ),
        ],
      ),
    );
  }

  sideBar() {
    return SizedBox(
      width: 300,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: Text("Query: SELECT meta.id, *",
                  style: Theme.of(context).textTheme.headline5)),
          queryBox(),
          SliverToBoxAdapter(
            child: Card(
              child: ValueListenableBuilder(
                valueListenable: _explain,
                builder: (_, value, __) => Text(value),
              ),
            ),
          ),
          SliverToBoxAdapter(
              child: Text("Results",
                  style: Theme.of(context).textTheme.headline5)),
          buildDocumentList(),
        ],
      ),
    );
  }

  queryBox() {
    return SliverToBoxAdapter(
      child: Card(
        elevation: 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: queryText,
                    minLines: 4,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: "WHERE, ORDER, LIMIT, etc",
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Spacer(),
                OutlineButton(child: Text("Explain"), onPressed: explain),
                Spacer(flex: 4),
                ValueListenableBuilder(
                  builder: (_, value, __) => OutlineButton(
                    child: Text("Execute"),
                    onPressed: value ? execute : null,
                  ),
                  valueListenable: _queryChanged,
                ),
                Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  buildDocumentList() {
    return ValueListenableBuilder(
      valueListenable: _resultsChanged,
      builder: (_, __, ___) => (_results?.isNotEmpty ?? false)
          ? SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Card(
                  child: ListTile(
                    selected: _results[i]['id'] == _selectedDoc,
                    title: Text(_results[i].toString()),
                    dense: true,
                    onTap: () {
                      _selectedDoc = _results[i]['id'];
                      _resultsChanged.value = !_resultsChanged.value;
                    },
                  ),
                ),
                childCount: _results.length,
              ),
            )
          : SliverToBoxAdapter(child: Icon(Icons.dashboard)),
    );
  }

  updateQuery() {
    if (prevQueryText != queryText.text) {
      //query?.dispose();
      prevQueryText = queryText.text;
      try {
        query = Query(widget.db, _select + queryText.text);
        query.addChangeListener(updateItems);
      } on DatabaseException catch (e) {
        _explain.value = e.message;
        query = null;
      }
    }
  }

  explain() {
    updateQuery();

    _explain.value = query?.explain() ?? _explain.value;
  }

  execute() {
    updateQuery();
    if (query != null) {
      query.execute();

      _queryChanged.value = false;
    }
  }

  updateItems(List change) {
    print("************* CHANGES RECEIVED*************");
    print(change);
    _results = change ?? [];
    _resultsChanged.value = !_resultsChanged.value;
  }
}

class SliverListHeaderDelegate extends SliverPersistentHeaderDelegate {
  SliverListHeaderDelegate({
    @required this.minHeight,
    @required this.maxHeight,
    @required this.child,
    this.shrunkChild,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;
  final Widget shrunkChild;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      shrinkOffset < 100
          ? SizedBox.expand(child: child)
          : (shrunkChild ?? child);

  @override
  bool shouldRebuild(SliverListHeaderDelegate oldDelegate) => false;
}

const testjson = '''
{
  "TESTDOC": "THIS DOCUMENT IS RECREATED EVERY TIME THE APP RUNS",
    "int": 10,
    "double": 2.2,
    "bool": true,
    "string": "hello world!",
    "list": [
        1,
        "2",
        3.3
    ],
    "map": {
        "first": [1, 2,3],
        "second": "hello again",
        "third": false,
        "dart": {"is": "cool"}
    },
    "map1": {
        "list": [
            {"first": [1, 2, 3, 4]},
            {"second": [6, 7, 8]},
            true,
            10,
            2.5
        ]
    }
}
''';
