- **[Introduction](#introduction)**
- **[Feature checklist](#feature-checklist)**
- **[Platform support](#platform-support)**
- **[Examples](#examples)**
- **[Resources](#resources)**
- **[Contributing](#contributing)**

# Introduction

### LIGHTWEIGHT NOSQL MOBILE APP DATABASE
A full-featured embedded NoSQL database
that runs locally on mobile devices

This is a Dart port of the Couchbase Lite database, built on top of the Couchbase Lite C library ([CBL_C]) using dart.ffi.

**Warning: This project is still in early development stage, the API is still fluid and breaking changes might still happen!**
Help with testing, documentation and development is welcome. Here's how you can [contribute](#contributing)

# Feature checklist

* **Database**
    _A Database is both a filesystem object and a container for documents._
    * [x] Open, Close, Copy, Compact, Delete
    * [x] Batch operations, similar to a transaction
    * [x] Change notifications, document change notifications
    * [x] Buffered notifications
* **Document**
    _A Document is essentially a JSON object with an ID string that's unique in its database._
    * [x] CRUD - Create, Read, Udpdate, Delete
    * [x] Save conflict handler
    * [x] Document expiration, with automatic purge
    * [x] [Fleece][FLEECE] API for direct access to the binary data
* **Queries**
    * [x] Query language based on the [N1QL](https://www.couchbase.com/products/n1ql) language
    from Couchbase Server, which you can think of as "SQL for JSON" or "SQL++".
    * [x] Query parameters
    * [x] Explain
    * [x] Change listener - turns a query into "live query"
    * [x] Indexes: value index or Full-text Search (FTS)
* **Replication**
    _A replicator is a background task that synchronizes changes between a local database and
    another database on a remote server_
    * [x] Authentication: Basic and Session based
    * [x] Pull/push filters
    * [x] Status listeners
    * [ ] Replicated document listeners
    * [x] Conflict-resolution callbacks ([See issue #86](https://github.com/couchbaselabs/couchbase-lite-C/issues/86))
* **Blobs**
    * [x] Create, read through content based API
    * [x] Stream based API

# Platform support

* **Windows:** Bundled with the package. Beta status.
* **Android:** 
    Some assembly is required. You can either 
    
    * build the shared libraries yourself from the repository:
    https://github.com/Rudiksz/couchbase-lite-C.git using the `feature/dart` branch or the tag with the matching version
    
    * download the prebuilt libraries from [BUILDS]

    Once you have the shared libraries place them in your project's
    `\android\app\src\main\jniLibs\` folder

* **iOS, macOS:** N/A


# Examples and how to use
Important in your main.dart call to initialize Dart<->C callbacks.
```
Cbl.init();
```
* **(!!)** Deprecated methods and codes. on (v0.4.0)
- jsonProperties deprecated to json
```
    q.parameters = {'VALUE': AppTables.variation};
    q.addChangeListener((List results) {
      for (Map map in results) {
    q.addChangeListener(( results) {
      for (Map map in results.allResults) {
        map.forEach((key, value) {
          _variation.add(Variation.fromMap(value));
        });
```
- TO
```
    q.parameters = {'VALUE': AppTables.variation,};
    q.addChangeListener((List results) {
    for (Map map in results) {
    q.addChangeListener(( results) {
    for (Map map in results.allResults) {
        map.forEach((key, value) {
        _stocks.add(Variation.fromMap(value));
        });
```

* **(!!)** New setter and getter on Document
- map 
- json The same as `properties.json`

then

```dart
/// Create/open a databse
var db = Database('name', directory: 'path/to directory');

// Documents
var doc = Document("docid", data: {'name': 'John Doe'});
db.saveDocument(doc);

// Read immutable document
doc1 = db.getDocument('docid');
doc1.properties = {'foo': 'bar'}; //<- throws a DatabaseException

// Get a mutable copy
var mutDoc = doc1.mutableCopy;
mutDoc.json = {'foo': 'bar'}; // <- OK>
db.saveDocument(mutDoc);

// or retrieve
var doc2 = db.getMutableDocument('testdoc3');
doc2.json = {'foo': 'bar8'};
db.saveDocument(doc2);

// Query

// Compile a query
final q = Query(db, 'SELECT * WHERE foo=\$VALUE');

q.setParameters = {'VALUE': 'bar'};

// Optionally Turn it into a "live query"
q.addChangeListener((ResultSet results) {
    print('New query results: ');
    while(results.next()){
        final row = results.rowDict;
        print(row.json);
    }
});

// Execute the query
var results = q.execute();

// Replicator

// Create a replicator
var replicator = Replicator(
    db,
    endpointUrl: 'ws://localhost:4984/remoteDB/',
    username: 'testuser',
    password: 'password', // or
    // 'sessionId': 'dfhfsdyf8dfenfajfoadnf83c4dfhdfad3228yrsefd',
);

// Set up a status listener
replicator.addChangeListener((status) {
    print('Replicator status: ' + status.activityLevel.toString());
});

// Start the replicator
replicator.start();
```

See the example folder for a more complete example, including the Fleece API.

# Contributing
Current milestones for versioning are:
* 0.5.0 - consolidate and document the core API for idiomatic Dart.  Breaking changes after that should be deprecated first, if possible.
* 1.0.0 
    - Align the API to the official SDK's as much as possible and where it makes sense.
    - Implement solid memory management to eliminate memory leaks - a mix of automatic and manual disposal of objects
    - make the library "production ready"
    - Documentation beyond what dart docs has: best practices, tips, caveats, N1SQL features, extensive examples
* post 1.0.0
    - JSONQuery language support for queries, with a QueryBuilder API like the official SDK has

There are couple of ways in which you can contribute:

* Testing
* Adding/testing iOS/macOs. I have the C library source code and some custom wrapper code to make it work with Dart's ffi.
* Fixing bugs
* Improve documentation
* Write examples

# Resources

* Couchbase Lite mobile [CBL]
* Couchbase Lite C [CBL_C]
* N1QL [N1QL]
* Prebuilt libraries (Android, Win) [BUILDS]

[CBL]: https://www.couchbase.com/nosql-databases/couchbase-mobile
[CBL_C]: https://github.com/couchbaselabs/couchbase-lite-C
[N1QL]: https://www.couchbase.com/n1ql
[FLEECE]: https://github.com/couchbaselabs/fleece
[BUILDS]: https://drive.google.com/drive/folders/1qiLdB64kq-IEsp6hFgvSqG80bzaI33Jf
