// Copyright (c) 2020, Rudolf Martincsek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io';
import 'dart:typed_data';

import 'package:couchbase_lite_dart/couchbase_lite_dart.dart';
import 'package:test/test.dart';

import '_test_utils.dart';

const TESTDB = 'testdb';
const TESTDIR = '_tmp3';

void main() {
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

  test('createWithData', () async {
    var db = Database('blob1', directory: TESTDIR);

    var f = File('test/blob_test.png');
    var data = f.readAsBytesSync();
    var blob = Blob.createWithData('image/png', data);

    expect(blob.properties['@type'].asString, 'blob');
    expect(blob.properties['content_type'].asString, 'image/png');
    expect(blob.properties['digest'].asString,
        'sha1-mW5ohOy6VMoWgH3xP6J0e0IBjlQ=');
    expect(blob.properties['length'].asInt, 82);

    addTearDown(() => db.close());
  });

  test('createWithStream', () async {
    var db = Database('blob2', directory: TESTDIR);

    var f = File('test/blob_test.png');
    var stream = f.openRead();

    var blob = await Blob.createWithStream(
      db,
      'image/png',
      stream.cast<Uint8List>(),
    );

    expect(blob.properties['@type'].asString, 'blob');
    expect(blob.properties['content_type'].asString, 'image/png');
    expect(blob.properties['digest'].asString,
        'sha1-mW5ohOy6VMoWgH3xP6J0e0IBjlQ=');
    expect(blob.properties['length'].asInt, 82);

    blob.closeStream();

    addTearDown(() => db.close());
  });

  test('addToDocument', () async {
    var db = Database('blob3', directory: TESTDIR);

    var f = File('test/blob_test.png');
    var data = f.readAsBytesSync();
    var blob = Blob.createWithData('image/png', data);

    var doc = Document('testdoc');
    doc.properties['foo'] = 'bar';
    doc.properties['blob'] = blob.properties;
    var doc1 = db.saveDocument(doc);

    expect(doc1.properties('blob.@type').asString, 'blob');
    expect(doc1.properties('blob.content_type').asString, 'image/png');
    expect(doc1.properties('blob.length').asInt, 82);
    expect(doc1.properties('blob.digest').asString,
        'sha1-mW5ohOy6VMoWgH3xP6J0e0IBjlQ=');

    // Delete blob
    var doc4 = doc1.mutableCopy;
    doc4.properties['blob'] = null;
    var doc5 = db.saveDocument(doc4);

    expect(doc5.properties['blob'].type, FLValueType.Null);

    // Save blob in a nested property
    var doc2 = Document('testdoc');
    var blobs = FLDict();
    blobs['blob'] = blob.properties;
    doc2.properties['foo'] = 'bar';
    doc2.properties['blobs'] = blobs;
    var doc3 = db.saveDocument(doc2);

    expect(doc3.properties('blobs.blob.@type').asString, 'blob');
    expect(doc3.properties('blobs.blob.content_type').asString, 'image/png');
    expect(doc3.properties('blobs.blob.length').asInt, 82);
    expect(doc3.properties('blobs.blob.digest').asString,
        'sha1-mW5ohOy6VMoWgH3xP6J0e0IBjlQ=');

    // Read back the content
    var bl1 = Blob.fromValue(doc3.properties('blobs.blob').asMap);
    expect(await bl1.getContent(), data);

    addTearDown(() => db.close());
  });
}
