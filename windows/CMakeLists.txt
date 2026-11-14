# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(tiebanana LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "tiebanana")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)
add_compile_options(/utf-8 /FS)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_options(${TARGET} PRIVATE /utf-8 /FS)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

# WebView2's current WIL dependency uses legacy coroutines under C++17.
# MSVC 14.51 requires explicit acknowledgement until the plugin adopts C++20.
if(TARGET flutter_inappwebview_windows_plugin)
  target_compile_definitions(flutter_inappwebview_windows_plugin PRIVATE
    _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)

  # 0.6.0 destroys WebView environments before the views which still reference
  # them, causing an access violation at shutdown. Patch only the build copy;
  # never modify the shared Pub cache. Fail closed if the upstream file changes.
  set(WEBVIEW_PLUGIN_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/flutter/ephemeral/.plugin_symlinks/flutter_inappwebview_windows/windows")
  set(WEBVIEW_PLUGIN_SOURCE "${WEBVIEW_PLUGIN_DIR}/flutter_inappwebview_windows_plugin.cpp")
  file(READ "${WEBVIEW_PLUGIN_SOURCE}" WEBVIEW_PLUGIN_CONTENT)
  set(WEBVIEW_OLD_ORDER "    webViewEnvironmentManager = nullptr;\n    inAppWebViewManager = nullptr;\n    inAppBrowserManager = nullptr;\n    headlessInAppWebViewManager = nullptr;\n    cookieManager = nullptr;")
  set(WEBVIEW_NEW_ORDER "    cookieManager = nullptr;\n    headlessInAppWebViewManager = nullptr;\n    inAppBrowserManager = nullptr;\n    inAppWebViewManager = nullptr;\n    webViewEnvironmentManager = nullptr;")
  string(REPLACE "\r\n" "\n" WEBVIEW_PLUGIN_CONTENT "${WEBVIEW_PLUGIN_CONTENT}")
  string(FIND "${WEBVIEW_PLUGIN_CONTENT}" "${WEBVIEW_OLD_ORDER}" WEBVIEW_ORDER_POSITION)
  if(WEBVIEW_ORDER_POSITION EQUAL -1)
    message(FATAL_ERROR "WebView shutdown workaround must be reviewed for this plugin version")
  endif()
  string(REPLACE "${WEBVIEW_OLD_ORDER}" "${WEBVIEW_NEW_ORDER}"
    WEBVIEW_PLUGIN_CONTENT "${WEBVIEW_PLUGIN_CONTENT}")
  set(WEBVIEW_PATCHED_SOURCE "${CMAKE_CURRENT_BINARY_DIR}/webview_plugin_shutdown.cpp")
  file(WRITE "${WEBVIEW_PATCHED_SOURCE}" "${WEBVIEW_PLUGIN_CONTENT}")
  get_target_property(WEBVIEW_SOURCES flutter_inappwebview_windows_plugin SOURCES)
  list(REMOVE_ITEM WEBVIEW_SOURCES "flutter_inappwebview_windows_plugin.cpp")
  set(WEBVIEW_ABSOLUTE_SOURCES)
  foreach(WEBVIEW_SOURCE IN LISTS WEBVIEW_SOURCES)
    if(IS_ABSOLUTE "${WEBVIEW_SOURCE}")
      list(APPEND WEBVIEW_ABSOLUTE_SOURCES "${WEBVIEW_SOURCE}")
    else()
      list(APPEND WEBVIEW_ABSOLUTE_SOURCES "${WEBVIEW_PLUGIN_DIR}/${WEBVIEW_SOURCE}")
    endif()
  endforeach()
  list(APPEND WEBVIEW_ABSOLUTE_SOURCES "${WEBVIEW_PATCHED_SOURCE}")
  set_property(TARGET flutter_inappwebview_windows_plugin PROPERTY SOURCES "${WEBVIEW_ABSOLUTE_SOURCES}")
  target_include_directories(flutter_inappwebview_windows_plugin PRIVATE "${WEBVIEW_PLUGIN_DIR}")
endif()


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)
