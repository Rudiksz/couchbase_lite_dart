cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "cblite_flutter_libs")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "cblite_flutter_libs_plugin")

add_library(${PLUGIN_NAME} SHARED
  "cblite_flutter_libs_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin
set(cblite_flutter_libs_bundled_libraries
  ""
  PARENT_SCOPE
)

# ----------------------------------------------------------------------

set(cblite_VERSION 1.0.0)

set(cblite_ARCH ${CMAKE_SYSTEM_PROCESSOR})
if (${cblite_ARCH} MATCHES "AMD64")
    set(cblite_ARCH x64)
endif ()

include(FetchContent)
FetchContent_Declare(
    cblite-download
    URL https://github.com/yegobox/couchbase_lite_dart/releases/download/${cblite_VERSION}/cblite-windows-${cblite_ARCH}.zip
)

FetchContent_GetProperties(cblite-download)
if(NOT cblite-download_POPULATED)
  FetchContent_Populate(cblite-download)
endif()

set(cblite_flutter_libs_bundled_libraries
    "${cblite-download_SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}cblite${CMAKE_SHARED_LIBRARY_SUFFIX}"
    PARENT_SCOPE
)

add_library(cblite SHARED IMPORTED GLOBAL)
set_target_properties(cblite PROPERTIES
    IMPORTED_LOCATION ${cblite-download_SOURCE_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}cblite${CMAKE_SHARED_LIBRARY_SUFFIX}
    IMPORTED_IMPLIB ${cblite-download_SOURCE_DIR}/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}cblite${CMAKE_IMPORT_LIBRARY_SUFFIX}
)

# target_link_libraries(${PLUGIN_NAME} PRIVATE cblite)