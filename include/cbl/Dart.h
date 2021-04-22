
#pragma once
#include "CBLBase.h"
#include "CBLReplicator.h"
#include "fleece/Fleece.h"
#include "w:\flutter\bin\cache\dart-sdk\include\third_party\dart\dart_api.h"
#include "w:\flutter\bin\cache\dart-sdk\include\third_party\dart\dart_native_api.h"

typedef void (*Dart_Print_)(char *);

typedef bool (*Dart_PostCObjectType)(Dart_Port port_id, Dart_CObject* message);

typedef Dart_Port (*Dart_NewNativePortType)(const char* name,
                                            Dart_NativeMessageHandler handler,
                                            bool handle_concurrently);

typedef bool (*Dart_CloseNativePortType)(Dart_Port native_port_id);


DART_EXPORT void CBLDart_PostCObject(Dart_PostCObjectType function_pointer);

DART_EXPORT void CBLDart_NewNativePort(Dart_NewNativePortType function_pointer);

DART_EXPORT void CBLDart_CloseNativePort(Dart_CloseNativePortType function_pointer);

// ++ Replicator

typedef CBL_ENUM(uint8_t, CBLReplicatorFilterType){
    kCBLReplicatorFilterTypePush = 0, ///< Pushing changes to the target
    kCBLReplicatorFilterTypePull      ///< Pulling changes from the target
};

typedef bool (*CBLDart_ReplicatorFilterCallback)(CBLReplicatorFilterType type, char *id,
                            CBLDocument *document, bool isDeleted);

typedef const CBLDocument* (*CBLDart_ConflictResolverCallback)(const char *context,
                            const char *documentID,
                            const CBLDocument *localDocument,
                            const CBLDocument *remoteDocument);

typedef void (*CBLDart_ReplicatorStatusCallback)(char *id, FLDict status);

DART_EXPORT void CBLDart_RegisterPorts(
    uint64_t database_listener_port, 
    uint64_t document_listener_port, 
    uint64_t query_listener_port, 
    uint64_t replicator_status_port,
    uint64_t replicator_filter_port,
    uint64_t replicator_conflict_port,
    CBLDart_ReplicatorStatusCallback replicator_status_callback,
    CBLDart_ReplicatorFilterCallback replicator_filter_callback,
    CBLDart_ConflictResolverCallback replicator_conflict_callback
    );

DART_EXPORT void CBLDart_ExecuteCallback(Work *work_ptr);

DART_EXPORT void CBLDart_DatabaseChangeListener(void *context,
                            const CBLDatabase* db _cbl_nonnull,
                            unsigned numDocs,
                            const char **docIDs _cbl_nonnull);

DART_EXPORT void CBLDart_DocumentChangeListener(void *context,
                            const CBLDatabase* db _cbl_nonnull,
                            const char *docID _cbl_nonnull);

DART_EXPORT void CBLDart_QueryChangeListener(void *queryId, CBLQuery *query _cbl_nonnull);

DART_EXPORT void CBLDart_ReplicatorChangeListener(void *id, 
                            CBLReplicator *repl _cbl_nonnull,
                            const CBLReplicatorStatus *status);

DART_EXPORT bool CBLDart_PushReplicationFilter(void *context, CBLDocument *document,
                          bool isDeleted);

DART_EXPORT bool CBLDart_PullReplicationFilter(void *context, CBLDocument *document,
                          bool isDeleted);

DART_EXPORT const CBLDocument* CBLDart_conflictReplicationResolver(void *id,
                      const char *documentID,
                      const CBLDocument *localDocument,
                      const CBLDocument *remoteDocument)