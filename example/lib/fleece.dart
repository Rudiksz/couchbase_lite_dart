// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:flutter/material.dart';

class FleeceView extends StatefulWidget {
  final String docId;
  final Database db;

  const FleeceView({Key key, this.docId, this.db}) : super(key: key);

  @override
  _FleeceViewState createState() => _FleeceViewState();
}

class _FleeceViewState extends State<FleeceView> {
  Document _doc;

  final _textId = TextEditingController(text: '');
  final _textDoc = TextEditingController(text: '');
  final _textKey = TextEditingController(text: '');
  final _newValue = TextEditingController(text: '');

  ValueNotifier update = ValueNotifier<bool>(true);
  ValueNotifier _idError = ValueNotifier<String>('');
  ValueNotifier _docError = ValueNotifier<String>('');

  String highlightSection = '';

  FLDoc doc;
  FLDict mutableDoc;
  String docText = '';
  String keyPath = '';
  FLValueType valueType;

  Map<String, String> details = {
    'doc.root': '',
    'key': '',
    'type': '',
    'value': '',
  };

  Map<String, String> flvalue = {
    'IsInteger': '',
    'isDouble': '',
    'asInteger': '',
    'asDouble': '',
    'asBool': '',
    'asString': ''
  };

  Map<String, String> fllist = {
    'asList': '',
    'length': '',
    'for (var v in value.asList)': '',
  };

  Map<String, String> flmap = {
    'asMap': '',
    'length': '',
    'for (var v in value.asMap)': '',
    'for (var k in value.asMap.keys)': '',
    'for (var v in value.asMap.values)': '',
    'for (var v in value.asMap.entries)': '',
  };

  @override
  void initState() {
    super.initState();
    _textId.text = widget.docId ?? "";
    _textDoc.addListener(parseJsonString);
    _textKey.addListener(parseJsonString);
    loadDocument();
  }

  @override
  void didUpdateWidget(covariant FleeceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.docId != widget.docId) {
      _textId.text = oldWidget.docId;
      loadDocument();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ValueListenableBuilder(
                        valueListenable: _idError,
                        builder: (_, error, __) => TextField(
                          decoration: InputDecoration(
                            labelText: 'Document ID',
                            errorText: error.isNotEmpty ? error : null,
                          ),
                          controller: _textId,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.save),
                    onPressed: saveDocument,
                  )
                ],
              ),
              Expanded(
                child: Card(
                  child: ValueListenableBuilder(
                    valueListenable: _docError,
                    builder: (_, error, __) => TextField(
                      decoration: InputDecoration(
                        labelText: 'Document body',
                        errorText: error.isNotEmpty ? error : null,
                      ),
                      controller: _textDoc,
                      minLines: 30,
                      maxLines: 30,
                    ),
                  ),
                ),
              ),
              Divider(),
              Card(
                child: TextField(
                  decoration:
                      InputDecoration(labelText: 'Search value by json path'),
                  controller: _textKey,
                  maxLines: 1,
                ),
              ),
              Text('just type in any of the boxes')
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ValueTile('doc.root', details['doc.root']),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ValueTile('Key', details['key']),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ValueTile('Type', details['type']),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ValueTile('JSON string', details['value']),
                  ),
                  Divider(),
                  Container(
                    color:
                        highlightSection == 'details' ? Colors.grey[300] : null,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 40,
                      children: flvalue.entries
                          .map((e) => ValueTile(
                                e.key,
                                e.value,
                              ))
                          .toList(),
                    ),
                  ),
                  Divider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              color: highlightSection == 'listview'
                                  ? Colors.grey[300]
                                  : null,
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: fllist.length,
                                itemBuilder: (_, int i) => ValueTile(
                                  fllist.keys.elementAt(i),
                                  fllist.values.elementAt(i),
                                ),
                                separatorBuilder: (_, __) => Divider(),
                              ),
                            ),
                            Divider(),
                            Text("Change value",
                                style: Theme.of(context).textTheme.headline6),
                            Card(
                              child: TextField(
                                controller: _newValue,
                                minLines: 3,
                                maxLines: 3,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                RaisedButton.icon(
                                  onPressed: () => changeValue('int'),
                                  icon: Icon(Icons.save),
                                  label: Text("int"),
                                ),
                                RaisedButton.icon(
                                  onPressed: () => changeValue('bool'),
                                  icon: Icon(Icons.save),
                                  label: Text("bool"),
                                ),
                                RaisedButton.icon(
                                  onPressed: () => changeValue('double'),
                                  icon: Icon(Icons.save),
                                  label: Text("double"),
                                ),
                                RaisedButton.icon(
                                  onPressed: () => changeValue('string'),
                                  icon: Icon(Icons.save),
                                  label: Text("string"),
                                ),
                                RaisedButton.icon(
                                  onPressed: () => changeValue('json'),
                                  icon: Icon(Icons.save),
                                  label: Text("json (map/list)"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(),
                      Expanded(
                        child: Container(
                          color: highlightSection == 'mapview'
                              ? Colors.grey[300]
                              : null,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: flmap.length,
                            itemBuilder: (_, int i) => ValueTile(
                              flmap.keys.elementAt(i),
                              flmap.values.elementAt(i),
                            ),
                            separatorBuilder: (_, __) => Divider(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  loadDocument() {
    if (widget.docId?.isNotEmpty ?? false) {
      _doc = widget.db.getDocument(widget.docId);
      _textId.text = widget.docId;

      // pretty print the json
      JsonEncoder encoder = new JsonEncoder.withIndent('  ');
      String prettyprint = encoder.convert(jsonDecode(_doc.jsonProperties));

      //doc = _doc.properties;
      _textDoc.text = prettyprint;

      setState(() {});
    }
  }

  saveDocument() {
    _idError.value = '';
    _docError.value = '';
    if (_textId.text.isEmpty) return _idError.value = 'cannot be empty';
    if (_textDoc.text.isEmpty) return _docError.value = 'cannot be empty';

    FLDoc doc = FLDoc.fromJson(_textDoc.text);
    if (doc.error != FLError.noError)
      return _docError.value = doc.error.toString();

    // Are we creating a new document?
    if (_doc == null || _doc.ID != _textId.text) {
      _doc = Document(_textId.text);
      _doc.jsonProperties = _textDoc.text;
      widget.db.saveDocument(_doc);
    }
    // Or updating the existing one
    else {
      final mutDoc = _doc.mutableCopy;
      mutDoc.jsonProperties = _textDoc.text;
      widget.db.saveDocument(mutDoc);
    }
  }

  changeValue(String type) {
    String parent;
    dynamic element;

    // Get array index
    var regexp = new RegExp('\\[\\d*\\]?\$');
    var index = regexp.stringMatch(keyPath);
    if (index != null) {
      parent = keyPath.replaceFirst(regexp, '');
      element = index.replaceAll('\[', '').replaceAll('\]', '');
      element = int.tryParse(element);
    }
    // Or map key
    else {
      element = keyPath.split('.').last;
      parent = keyPath.replaceFirst(new RegExp('\.$element\$'), '');
    }

    // Figure out the value
    dynamic value;
    if (type == 'int') {
      value = int.tryParse(_newValue.text);
    } else if (type == 'double') {
      value = double.tryParse(_newValue.text);
    } else if (type == 'bool') {
      value = _newValue.text.isNotEmpty && _newValue.text != 'false';
    } else if (type == 'string') {
      value = _newValue.text;
    } else {
      try {
        value = jsonDecode(_newValue.text);
      } catch (e) {}
    }
    final parentValue = mutableDoc.value[parent];

    switch (parentValue.type) {
      case FLValueType.Array:
        mutableDoc.value[parent].asList[element as int] = value;
        break;
      case FLValueType.Dict:
        mutableDoc.value[parent].asMap[element] = value;
        break;
    }
    // pretty print the json
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    String prettyprint = encoder.convert(jsonDecode(mutableDoc.json));

    _textDoc.text = prettyprint;

    setState(() {});
  }

  parseJsonString() {
    if (docText == _textDoc.text && keyPath == _textKey.text) return;

    keyPath = _textKey.text;

    details = {
      'doc.root': '',
      'key': '',
      'type': '',
      'value': '',
    };

    flvalue = {
      'IsInteger': '',
      'isDouble': '',
      'asInteger': '',
      'asDouble': '',
      'asBool': '',
      'asString': ''
    };

    fllist = {
      'asList': '',
      'length': '',
      'for (var v in value.asList)': '',
    };

    flmap = {
      'asMap': '',
      'length': '',
      'for (var v in value.asMap)': '',
      'for (var k in value.asMap.keys)': '',
      'for (var v in value.asMap.values)': '',
      'for (var v in value.asMap.entries)': '',
    };

    if (docText != _textDoc.text) {
      doc = FLDoc.fromJson(_textDoc.text);
      docText = _textDoc.text;
      if (doc.error != FLError.noError) {
        details['doc.root'] = doc.error.toString();
        return setState(() {});
      }

      mutableDoc = doc.root.asMap.mutableCopy;
    }

    highlightSection = '';
    details['doc.root'] = doc.root.json;

    if (_textKey.text.isEmpty) return setState(() {});

    details['key'] = _textKey.text;

    final value = doc.root[_textKey.text];
    details['value'] = value?.json ?? "null";
    _newValue.text = details['value'];

    if (value == null) return setState(() {});

    final type = value?.type;

    if (type != FLValueType.Undefined) highlightSection = 'details';

    details['type'] = type?.toString() ?? "";
    valueType = type;

    flvalue['IsInteger'] = value.isInterger.toString();
    flvalue['isDouble'] = value.isDouble.toString();

    flvalue['asInteger'] = value.asInt.toString();
    flvalue['asDouble'] = value.asDouble.toString();
    flvalue['asBool'] = value.asBool.toString();
    flvalue['asString'] = value.asString;

    fllist['asList'] = value.asList?.json ?? "N/A";
    fllist['length'] = value.asList?.length?.toString() ?? "N/A";

    final l = [];
    final list = value.asList;
    if (list != null) {
      highlightSection = 'listview';
      for (var v in value.asList) {
        l.add(v.json);
      }
    }
    fllist['for (var v in value.asList)'] = l.isNotEmpty ? l.join(', ') : "N/A";
    flmap['asMap'] = value.asMap?.json ?? "N/A";

    flmap['length'] = value.asMap?.length?.toString() ?? "N/A";

    final map = [];
    final values = [];
    final keys = [];
    final entries = [];
    if (value.asMap != null) {
      highlightSection = 'mapview';
      for (var v in value.asMap) {
        map.add(v.json);
      }

      for (var k in value.asMap.keys) {
        keys.add(k);
      }

      for (var v in value.asMap.values) {
        values.add(v.json);
      }

      for (var v in value.asMap.entries) {
        entries.add("(${v.key}, ${v.value.json})");
      }
    }

    flmap['for (var v in value.asMap)'] =
        map.isNotEmpty ? map.join(', ') : "N/A";

    flmap['for (var k in value.asMap.keys)'] =
        keys.isNotEmpty ? keys.join(', ') : "N/A";

    flmap['for (var v in value.asMap.values)'] =
        values.isNotEmpty ? values.join(', ') : "N/A";

    flmap['for (var v in value.asMap.entries)'] =
        entries.isNotEmpty ? entries.join(', ') : "N/A";

    return setState(() {});
  }
}

class ValueTile extends StatelessWidget {
  final String label;
  final String value;
  const ValueTile(
    this.label,
    this.value, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label ?? "", style: TextStyle(fontWeight: FontWeight.bold)),
        Text(value ?? ""),
      ],
    );
  }
}
