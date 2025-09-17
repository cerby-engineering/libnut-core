# =========================================================================
# Merged CMake Configuration for Native Addons
# =========================================================================
# This file builds two separate Node.js native addon targets:
# 1. libnut: A cross-platform library for desktop automation.
# 2. permissions: A macOS-only library for checking system permissions.
# =========================================================================

cmake_minimum_required(VERSION 3.20)
project(native_addons)

# --- Global Settings & Dependencies ---

# Set the C++ standard to 17, which is the highest required by the projects.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable export of compile commands for tooling.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Find the include path for node-addon-api reliably.
# This is a more robust method than hardcoding the path.
execute_process(COMMAND node -p "require('node-addon-api').include"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE NODE_ADDON_API_DIR
)
string(REGEX REPLACE "[\r\n\"]" "" NODE_ADDON_API_DIR ${NODE_ADDON_API_DIR})
message(STATUS "Found node-addon-api at: ${NODE_ADDON_API_DIR}")


# =========================================================================
# Target: libnut
# =========================================================================

# --- Source Files for libnut ---
set(LIBNUT_SOURCE_FILES
        src/main.cc
        src/deadbeef_rand.c
        src/MMBitmap.c
)

if (UNIX AND NOT APPLE)
    list(APPEND LIBNUT_SOURCE_FILES
            src/linux/keycode.c
            src/linux/keypress.c
            src/linux/mouse.c
            src/linux/screen.c
            src/linux/screengrab.c
            src/linux/xdisplay.c
            src/linux/highlightwindow.c
            src/linux/window_manager.cc
    )
elseif (UNIX AND APPLE)
    list(APPEND LIBNUT_SOURCE_FILES
            src/macos/keycode.c
            src/macos/keypress.c
            src/macos/mouse.c
            src/macos/mouse_utils.mm
            src/macos/screen.c
            src/macos/screengrab.m
            src/macos/highlightwindow.m
            src/macos/window_manager.mm
    )
elseif (WIN32)
    list(APPEND LIBNUT_SOURCE_FILES
            src/win32/keycode.c
            src/win32/keypress.c
            src/win32/mouse.c
            src/win32/screen.c
            src/win32/screengrab.c
            src/win32/highlightwindow.c
            src/win32/window_manager.cc
    )
endif()

# --- Library Definition for libnut ---
add_library(libnut SHARED ${LIBNUT_SOURCE_FILES} ${CMAKE_JS_SRC})

# --- Target-Specific Properties for libnut ---
set_target_properties(libnut PROPERTIES PREFIX "" SUFFIX ".node")

# --- N-API and Include Directories for libnut ---
target_compile_definitions(libnut PRIVATE NAPI_CPP_EXCEPTIONS NAPI_VERSION=3)
target_include_directories(libnut PRIVATE
        ${NODE_ADDON_API_DIR}
        ${CMAKE_JS_INC}
)

# --- Platform-Specific Libraries and Settings for libnut ---
set(LIBNUT_LIBS ${CMAKE_JS_LIB})

if (UNIX AND APPLE)
    message(STATUS "Configuring libnut for macOS")
    # Set macOS deployment target to allow using older APIs
    set_target_properties(libnut PROPERTIES MACOSX_DEPLOYMENT_TARGET "10.15")
    list(APPEND LIBNUT_LIBS "-framework ApplicationServices" "-framework Cocoa")
elseif (WIN32)
    message(STATUS "Configuring libnut for Windows")
    # Copy runtime distributables on Windows
    add_custom_command(
            TARGET libnut POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_SOURCE_DIR}/3rdparty/win32/msvcp140.dll
            ${CMAKE_SOURCE_DIR}/3rdparty/win32/vcruntime140.dll
            ${CMAKE_SOURCE_DIR}/3rdparty/win32/vcruntime140_1.dll
            ${CMAKE_SOURCE_DIR}/3rdparty/win32/api-ms-win-crt-heap-l1-1-0.dll
            ${CMAKE_SOURCE_DIR}/3rdparty/win32/api-ms-win-crt-runtime-l1-1-0.dll
            ${CMAKE_SOURCE_DIR}/3rdparty/win32/api-ms-win-crt-string-l1-1-0.dll
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_BUILD_TYPE}/
    )
elseif (UNIX AND NOT APPLE)
    message(STATUS "Configuring libnut for Linux")
    list(APPEND LIBNUT_LIBS "-lX11" "-lXtst")
endif()

# --- Compiler Flags for libnut ---
if (NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(libnut PRIVATE -Wall -Wparentheses -Winline -Wbad-function-cast -Wdisabled-optimization -Wextra)
else()
    target_compile_options(libnut PRIVATE /Wall /W4 /EHsc)
endif()

# --- Final Linking for libnut ---
target_link_libraries(libnut PRIVATE ${LIBNUT_LIBS})


# =========================================================================
# Target: permissions
# This target is only configured and built on macOS.
# =========================================================================

if (UNIX AND APPLE)
    message(STATUS "Configuring target: permissions (macOS only)")

    # --- Source Files for permissions ---
    set(PERMISSIONS_SOURCE_FILES src/macos/permissions/permissions.mm)

    # --- Library Definition for permissions ---
    add_library(permissions SHARED ${PERMISSIONS_SOURCE_FILES} ${CMAKE_JS_SRC})

    # --- Target-Specific Properties for permissions ---
    set_target_properties(permissions PROPERTIES
            PREFIX ""
            SUFFIX ".node"
            MACOSX_DEPLOYMENT_TARGET "10.13"
    )

    # --- N-API and Include Directories for permissions ---
    target_compile_definitions(permissions PRIVATE NAPI_DISABLE_CPP_EXCEPTIONS NAPI_VERSION=4)
    target_include_directories(permissions PRIVATE
            ${NODE_ADDON_API_DIR}
            ${CMAKE_JS_INC}
    )

    # --- Frameworks and Libraries for permissions ---
    set(PERMISSIONS_LIBS
            ${CMAKE_JS_LIB}
            "-framework AppKit"
            "-framework AVFoundation"
            "-framework CoreBluetooth"
            "-framework CoreFoundation"
            "-framework CoreLocation"
            "-framework CoreGraphics"
            "-framework Contacts"
            "-framework EventKit"
            "-framework IOKit"
            "-framework Photos"
            "-framework Speech"
            "-framework Storekit"
    )

    # --- Final Linking for permissions ---
    target_link_libraries(permissions PRIVATE ${PERMISSIONS_LIBS})

endif()
