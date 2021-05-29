cmake_minimum_required(VERSION 3.11)
set(PROJECT_NAME "couchbase_lite_dart_flutter_libs")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "couchbase_lite_dart_flutter_libs_plugin")

add_library(${PLUGIN_NAME} SHARED
  "couchbase_lite_dart_flutter_libs_plugin.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# List of absolute paths to libraries that should be bundled with the plugin
set(couchbase_lite_dart_flutter_libs_bundled_libraries
  ""
  PARENT_SCOPE
)

# ----------------------------------------------------------------------

set(COUCHBASELITE_VERSION 0.14.0)

set(couchbase_lite_dart_ARCH ${CMAKE_SYSTEM_PROCESSOR})
if (${couchbase_lite_dart_ARCH} MATCHES "x86_64")
    set(couchbase_lite_dart_ARCH x64)
elseif (${couchbase_lite_dart_ARCH} MATCHES "^armv7")
    set(couchbase_lite_dart_ARCH armv7hf)
elseif (${couchbase_lite_dart_ARCH} MATCHES "^arm")
    set(couchbase_lite_dart_ARCH armv6hf)
endif ()

include(FetchContent)
FetchContent_Declare(
    couchbase_lite_dart-download
    URL https://github.com/couchbase_lite_dart/couchbase_lite_dart-c/releases/download/v${COUCHBASELITE_VERSION}/couchbase_lite_dart-linux-${couchbase_lite_dart_ARCH}.tar.gz
)

FetchContent_GetProperties(couchbase_lite_dart-download)
if(NOT couchbase_lite_dart-download_POPULATED)
  FetchContent_Populate(couchbase_lite_dart-download)
endif()

set(couchbase_lite_dart_flutter_libs_bundled_libraries
    "${couchbaselite-download_SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}couchbase_lite_dart${CMAKE_SHARED_LIBRARY_SUFFIX}"
    PARENT_SCOPE
)

add_library(couchbase_lite_dart SHARED IMPORTED GLOBAL)
set_target_properties(couchbase_lite_dart PROPERTIES
    IMPORTED_LOCATION ${couchbaselite-download_SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}couchbase_lite_dart${CMAKE_SHARED_LIBRARY_SUFFIX}
    IMPORTED_IMPLIB ${couchbaselite-download_SOURCE_DIR}/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}couchbase_lite_dart${CMAKE_IMPORT_LIBRARY_SUFFIX}
)

target_link_libraries(${PLUGIN_NAME} PRIVATE couchbase_lite_dart)