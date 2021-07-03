#include "Dart.h"
#include "fleece/Fleece.h"
#include <fleece/slice.hh>
#include "CouchbaseLite.h"
#include "CBLQuery.h"
#include "CBLQuery_Internal.hh"
#include "CBLReplicator_Internal.hh"


#ifdef __cplusplus
extern "C" {
#endif


Dart_NewNativePortType Dart_NewNativePort_;
Dart_PostCObjectType Dart_PostCObject_;
Dart_CloseNativePortType Dart_CloseNativePort_;
Dart_Print_ Dart_Print;

Dart_Port databaseListenerPort;
Dart_Port documentListenerPort;
Dart_Port queryListenerPort;

Dart_Port replicatorStatusPort;
CBLDart_ReplicatorStatusCallback replicatorStatusCallback;

Dart_Port replicatorFilterPort;
CBLDart_ReplicatorFilterCallback replicatorFilterCallback;

Dart_Port replicatorConflictPort;
CBLDart_ConflictResolverCallback replicatorConflictCallback;

  // ++ Listener setup
void CBLDart_RegisterPorts(
    uint64_t database_listener_port, 
    uint64_t document_listener_port, 
    uint64_t query_listener_port, 
    uint64_t replicator_status_port,
    uint64_t replicator_filter_port,
    uint64_t replicator_conflict_port,
    CBLDart_ReplicatorStatusCallback replicator_status_callback,
    CBLDart_ReplicatorFilterCallback replicator_filter_callback,
    CBLDart_ConflictResolverCallback replicator_conflict_callback
    ){
    databaseListenerPort = (Dart_Port) database_listener_port;
    documentListenerPort = (Dart_Port) document_listener_port;
    queryListenerPort = (Dart_Port) query_listener_port;
    replicatorStatusPort = (Dart_Port) replicator_status_port;
    replicatorFilterPort = (Dart_Port) replicator_filter_port;
    replicatorConflictPort = (Dart_Port) replicator_conflict_port;

    replicatorStatusCallback = replicator_status_callback;
    replicatorFilterCallback = replicator_filter_callback;
    replicatorConflictCallback = replicator_conflict_callback;
  }

// This will execute the closures we set up in our C handlers. Called by the Dart code.

typedef std::function<void()> Work;
void CBLDart_ExecuteCallback(Work *work_ptr) {
  const Work work = *work_ptr;
  work();
}


void CBLDart_PostCObject(Dart_PostCObjectType function_pointer) {
  Dart_PostCObject_ = function_pointer;
}

void CBLDart_NewNativePort(Dart_NewNativePortType function_pointer) {
  Dart_NewNativePort_ = function_pointer;
}

void CBLDart_CloseNativePort(Dart_CloseNativePortType function_pointer) {
  Dart_CloseNativePort_ = function_pointer;
}

  // ++ Database change listeners

DART_EXPORT void CBLDart_DatabaseChangeListener(void *context, const CBLDatabase* db, unsigned numDocs, FLString docIDs[]) {
  MutableArray _docIDs = MutableArray::newArray();
  for (unsigned idx=0; idx<numDocs; ++idx) {
      _docIDs.append(docIDs[idx]);
  }

  MutableDict change = MutableDict::newDict();
  change.set(slice("databaseId"), (char *)context);
  change.set(slice("docIDs"), _docIDs);

  const char *json = "test" ; //allocCString(change.toJSON());

  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kString;
  dart_object.value.as_string = (char *)json;
  Dart_PostCObject_(databaseListenerPort, &dart_object);
  //free(json);
}

DART_EXPORT void CBLDart_DocumentChangeListener(void *context,
                          const CBLDatabase* db,
                          const char *docID) {

  MutableDict change = MutableDict::newDict();
  change.set(slice("databaseId"), (char *)context);
  change.set(slice("docID"), docID);

  const char *json = "test";//allocCString(change.toJSON());

  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kString;
  dart_object.value.as_string = (char *)json;
  Dart_PostCObject_(documentListenerPort, &dart_object);
  //free(json);
}

  // -- Listener setup

  // -- CHANGE LISTENER

DART_EXPORT void CBLDart_QueryChangeListener(void *queryId, CBLQuery *query) {
  Dart_CObject message;
  message.type = Dart_CObject_kString;
  message.value.as_string = (char *)queryId;

  Dart_PostCObject_(queryListenerPort, &message);
}

  // -- Query

  // ++ Replicator status listener

DART_EXPORT void CBLDart_ReplicatorChangeListener(void *id, CBLReplicator *repl, const CBLReplicatorStatus *status) {
                                  
  MutableDict progress = MutableDict::newDict();
  progress.set(slice("documentCount"), status->progress.documentCount);
  progress.set(slice("fractionComplete"), status->progress.fractionComplete);

  MutableDict error = MutableDict::newDict();
  error.set(slice("code"), status->error.code);
  error.set(slice("domain"), status->error.domain);
  error.set(slice("internal_info"), status->error.internal_info);
  const char *message = "test"; //allocCString(CBLError_Message_s(&status->error));
  error.set(slice("message"), message);
  //free(message);


  MutableDict result = MutableDict::newDict();
  result.set(slice("type"), "status");
  result.set(slice("activity"), status->activity);
  result.set(slice("progress"), progress);
  result.set(slice("error"), error);
  result.set(slice("id"), (char *)id);

  const char *json = "test";//allocCString(result.toJSON());

  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kString;
  dart_object.value.as_string = (char *)json;
  Dart_PostCObject_(replicatorStatusPort, &dart_object);
  //free(json);
}

 // ++ Replicator conflict handler
DART_EXPORT const CBLDocument* CBLDart_conflictReplicationResolver(void *id,
                      const char *documentID,
                      const CBLDocument *localDocument,
                      const CBLDocument *remoteDocument) {
    std::mutex mutex;
    std::unique_lock<std::mutex> lock(mutex);
    std::condition_variable cv;

    auto callback = replicatorConflictCallback;
    const CBLDocument* result;
    bool notified = false;

    // This is a closure that wraps Dart's cblReplicatorFilterCallback to return a
    // value
    const Work work = [id, documentID, &localDocument, &remoteDocument, &result, callback, &cv,
                      &notified]() {
      result = callback((char *)id, documentID, localDocument, remoteDocument);
      notified = true;
      cv.notify_one();
    };

    // Here we notify Dart that an event happened and we pass the closure to call
    // back with
    Dart_CObject dart_object;
    dart_object.type = Dart_CObject_kInt64;
    dart_object.value.as_int64 = reinterpret_cast<intptr_t>(&work);
    Dart_PostCObject_(replicatorConflictPort, &dart_object);

    while (!notified) {
      cv.wait(lock);
    }

    return result;
  }

  // ++ Replicator push/pull filters

bool replicationFilter(CBLReplicatorFilterType type, void *id,
                        CBLDocument *document, bool isDeleted) {
  std::mutex mutex;
  std::unique_lock<std::mutex> lock(mutex);
  std::condition_variable cv;

  auto callback = replicatorFilterCallback;
  bool result = false;
  bool notified = false;

  // This is a closure that wraps Dart's cblReplicatorFilterCallback to return a
  // value
  const Work work = [type, id, &document, isDeleted, &result, callback, &cv,
                    &notified]() {
    result = callback(type, (char *)id, document, isDeleted);
    notified = true;
    cv.notify_one();
  };

  // Here we notify Dart that an event happened and we pass the closure to call
  // back with
  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kInt64;
  dart_object.value.as_int64 = reinterpret_cast<intptr_t>(&work);
  Dart_PostCObject_(replicatorFilterPort, &dart_object);

  while (!notified) {
    cv.wait(lock);
  }

  return result;
}

bool CBLDart_PushReplicationFilter(void *context, CBLDocument *document,
                          bool isDeleted) {

  return replicationFilter(kCBLReplicatorFilterTypePush, context, document,
                          isDeleted);
}

bool CBLDart_PullReplicationFilter(void *context, CBLDocument *document,
                          bool isDeleted) {
  return replicationFilter(kCBLReplicatorFilterTypePull, context, document,
                          isDeleted);
}

// -- Misc
/*
Dart_Port cblLogPort;

void CBLLogListener(CBLLogDomain domain, CBLLogLevel level,
                    const char *message _cbl_nonnull) {

  MutableDict log = MutableDict::newDict();
  log.set(slice("domain"), domain);
  log.set(slice("level"), level);
  log.set(slice("message"), message);

  char *json = allocCString(log.toJSON());

  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kString;
  dart_object.value.as_string = json;
  Dart_PostCObject_(cblLogPort, &dart_object);
  free(json);
}

void CBLLog_SetCallback_d(uint64_t cbl_log_port) {
  cblLogPort = (Dart_Port) cbl_log_port;
  CBLLog_SetCallback(cbl_log_port ? CBLLogListener : nullptr);
}


void CBL_Log_d(CBLLogDomain domain, CBLLogLevel level, const char *message) {
  CBL_Log_s(domain, level, slice(message));
}*/

#ifdef __cplusplus
}
#endif
