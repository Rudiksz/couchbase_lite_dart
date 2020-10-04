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

**Warning: This project is still in early development stage and breaking API changes might still happen!**
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
    * [ ] Conflict-resolution callbacks
* **Blobs**
    * [x] Create, read through content based API
    * [ ] Stream based API

# Platform support

* **Windows:** Bundled with the package. Beta status.
* **Android:** Experimental, in testing phase. Currently the libraries are not bundled with the package. Contact me, if you would like to test it.
* **iOS, macOS:** N/A


# Examples and how to use
Important in your main.dart call to initialize Windows specific bindings.
```
Cbl.init();
```

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
mutDoc.properties = {'foo': 'bar'}; // <- OK>
db.saveDocument(mutDoc);

// or retrieve
var doc2 = db.getMutableDocument('testdoc3');
doc2.properties = {'foo': 'bar8'};
db.saveDocument(doc2);

// Query

// Compile a query
final q = Query(db, 'SELECT * WHERE foo=\$VALUE');

q.setParameters = {'VALUE': 'bar'};

// Optionally Turn it into a "live query"
q.addChangeListener((List results) {
    print('New query results: ');
    print(results);
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
There are couple of ways in which you can contribute:

* Testing - current status is: it runs on my computer
* Help with building the dynamic libraries for Android/iOS. I have the C library source code and some custom wrapper code to make it work with Dart's ffi. Currently I have only managed to build it for Windows. In particular iOS/macOS is welcome.
* Fixing bugs
* Improve documentation
* Write examples

# Resources

* Couchbase Lite mobile [CBL]
* Couchbase Lite C [CBL_C]
* N1QL [N1QL]

[CBL]: https://www.couchbase.com/nosql-databases/couchbase-mobile
[CBL_C]: https://github.com/couchbaselabs/couchbase-lite-C
[N1QL]: https://www.couchbase.com/n1ql
[FLEECE]: https://github.com/couchbaselabs/fleece
