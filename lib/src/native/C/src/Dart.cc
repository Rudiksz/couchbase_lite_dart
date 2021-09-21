#include "Dart.h"
#include <fleece/slice.hh>
#include "fleece/Fleece.h"

Dart_NewNativePortType Dart_NewNativePort_;
Dart_PostCObjectType Dart_PostCObject_;
Dart_CloseNativePortType Dart_CloseNativePort_;

void CBLDart_PostCObject(Dart_PostCObjectType function_pointer) {
  Dart_PostCObject_ = function_pointer;
}

void CBLDart_NewNativePort(Dart_NewNativePortType function_pointer) {
  Dart_NewNativePort_ = function_pointer;
}

void CBLDart_CloseNativePort(Dart_CloseNativePortType function_pointer) {
  Dart_CloseNativePort_ = function_pointer;
}

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


static char* allocCString(FLSlice result) {
    if (result.buf == nullptr)
        return nullptr;
    char* str = (char*) malloc(result.size + 1);
    if (!str)
        return nullptr;
    memcpy(str, result.buf, result.size);
    str[result.size] = '\0';
    return str;
}


static char* allocCString(FLSliceResult result) {
    char *str = allocCString(FLSlice{result.buf, result.size});
    FLSliceResult_Release(result);
    return str;
}

// This will execute the closures we set up in our C handlers. Called by the Dart code.
void CBLDart_ExecuteCallback(Work *work_ptr) {
  const Work work = *work_ptr;
  work();
}

  // ++ Database change listeners
  
DART_EXPORT void CBLDart_DatabaseChangeListener(void* _cbl_nullable context,
                                          const CBLDatabase* db,
                                          unsigned numDocs,
                                          FLString docIDs[_cbl_nonnull]) {                      
    FLMutableArray _docIDs = FLMutableArray_New();
    for (unsigned idx=0; idx<numDocs; ++idx) {
      FLSlot_SetString(FLMutableArray_Append(_docIDs), docIDs[idx]);
    }
    FLMutableDict change = FLMutableDict_New();
    FLSlot_SetString(FLMutableDict_Set(change, fleece::slice("databaseId")), fleece::slice((const char *)context));
    FLSlot_SetArray(FLMutableDict_Set(change, fleece::slice("docIDs")), _docIDs);

    char *json = allocCString(FLValue_ToJSON((FLValue)change));
    Dart_CObject dart_object;
    dart_object.type = Dart_CObject_kString;
    dart_object.value.as_string = json;
    Dart_PostCObject_(databaseListenerPort, &dart_object);
    free(json);

}

DART_EXPORT void CBLDart_DocumentChangeListener(void *context,
                                                const CBLDatabase* db,
                                                FLString docID) {
  
    FLMutableDict change = FLMutableDict_New();
    FLSlot_SetString(FLMutableDict_Set(change, fleece::slice("databaseId")), fleece::slice((const char *)context));
    FLSlot_SetString(FLMutableDict_Set(change, fleece::slice("documentId")), docID);
    
    char *json = allocCString(FLValue_ToJSON((FLValue)change));
    
    Dart_CObject dart_object;
    dart_object.type = Dart_CObject_kString;
    dart_object.value.as_string = json;
    Dart_PostCObject_(documentListenerPort, &dart_object);
    free(json);
}

DART_EXPORT void CBLDart_QueryChangeListener(void *queryId, CBLQuery *query, CBLListenerToken* token) {
  Dart_CObject message;
  message.type = Dart_CObject_kString;
  message.value.as_string = (char *)queryId;
  Dart_PostCObject_(queryListenerPort, &message);
}


DART_EXPORT void CBLDart_ReplicatorChangeListener(void *id, CBLReplicator *repl _cbl_nonnull,
                                const CBLReplicatorStatus *status) {
                                  
  FLMutableDict progress = FLMutableDict_New();
  FLSlot_SetUInt(FLMutableDict_Set(progress, fleece::slice("documentCount")),  status->progress.documentCount);
  FLSlot_SetFloat(FLMutableDict_Set(progress, fleece::slice("fractionComplete")),  status->progress.complete);

  FLMutableDict error = FLMutableDict_New();
  FLSlot_SetInt(FLMutableDict_Set(error, fleece::slice("code")), status->error.code);
  FLSlot_SetInt(FLMutableDict_Set(error, fleece::slice("domain")), status->error.domain);
  FLSlot_SetInt(FLMutableDict_Set(error, fleece::slice("internal_info")), status->error.internal_info);
  FLSliceResult message = CBLError_Message(&status->error);
  FLSlot_SetString(FLMutableDict_Set(error, fleece::slice("documentId")), (FLString) message);
  FLSliceResult_Release(message);


  FLMutableDict result = FLMutableDict_New();
  FLSlot_SetString(FLMutableDict_Set(error, fleece::slice("id")), fleece::slice((char *)id));
  FLSlot_SetString(FLMutableDict_Set(error, fleece::slice("type")), fleece::slice("status"));
  FLSlot_SetInt(FLMutableDict_Set(error, fleece::slice("activity")), status->activity);
  FLSlot_SetDict(FLMutableDict_Set(error, fleece::slice("progress")), progress);
  FLSlot_SetDict(FLMutableDict_Set(error, fleece::slice("error")), error);

  char *json = allocCString(FLValue_ToJSON((FLValue) result));

  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kString;
  dart_object.value.as_string = json;
  Dart_PostCObject_(replicatorStatusPort, &dart_object);
  free(json);
  FLMutableDict_Release(progress);
  FLMutableDict_Release(error);
  FLMutableDict_Release(result);
}
