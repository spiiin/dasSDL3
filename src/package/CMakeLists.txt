cmake_minimum_required(VERSION 3.24)
project(dasSDL3Package LANGUAGES C CXX)
if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8 OR (NOT APPLE AND NOT CMAKE_SYSTEM_PROCESSOR MATCHES "^(AMD64|amd64|x86_64)$"))
    message(FATAL_ERROR "Package requires 64-bit macOS or x86_64 Windows/Linux")
endif()
if(APPLE AND CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    set(_sdk_compiler lib/liblibDaScriptDyn.dylib)
    set(_sdk_runtime lib/liblibDaScriptDyn_runtime.dylib)
    set(_package_options -fno-rtti)
    set(_package_snapshot macos)
elseif(WIN32 AND MSVC)
    set(_sdk_compiler lib/libDaScriptDyn.lib)
    set(_sdk_runtime lib/libDaScriptDyn_runtime.lib)
    set(_package_options /bigobj /arch:AVX2 /wd4251 /wd4275)
    set(_package_snapshot clangbind)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_sdk_compiler lib/liblibDaScriptDyn.so)
    set(_sdk_runtime lib/liblibDaScriptDyn_runtime.so)
    set(_package_options -fno-rtti)
    set(_package_snapshot linux)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
else()
    message(FATAL_ERROR "Supported packages: macOS AppleClang, Windows MSVC and Linux x86_64")
endif()
# The dynamic SDK has a Release ABI. Visual Studio must not offer Debug.
get_property(_package_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(WIN32 AND MSVC AND _package_multi_config)
    set(CMAKE_CONFIGURATION_TYPES "Release" CACHE STRING "Supported package configurations" FORCE)
elseif(NOT CMAKE_BUILD_TYPE STREQUAL "Release" OR _package_multi_config)
    message(FATAL_ERROR "Use Release (Visual Studio on Windows or single-config Ninja) and the matching daScript dynamic SDK")
endif()
set(CMAKE_CXX_STANDARD 17)
set_property(GLOBAL PROPERTY JOB_POOLS package_compile=6 package_link=1)
set(CMAKE_JOB_POOL_COMPILE package_compile)
set(CMAKE_JOB_POOL_LINK package_link)
set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
set(DASLANG_DIR "" CACHE PATH "Matching built daScript dynamic SDK")
foreach(required include/daScript/daScript.h ${_sdk_compiler} ${_sdk_runtime})
    if(NOT EXISTS "${DASLANG_DIR}/${required}")
        message(FATAL_ERROR "Missing ${DASLANG_DIR}/${required}")
    endif()
endforeach()
set(DASSDL3_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/.." CACHE PATH "Binding sources")
set(DASSDL3_PACKAGE_OUTPUT "${CMAKE_BINARY_DIR}/module" CACHE PATH "Module destination")
# Source installs compile against the consumer SDK. Exact identity is opt-in.
set(_fingerprint_default OFF)
if(DEFINED ENV{DASSDL3_VALIDATE_SDK_FINGERPRINT})
    set(_fingerprint_default "$ENV{DASSDL3_VALIDATE_SDK_FINGERPRINT}")
endif()
option(DASSDL3_VALIDATE_SDK_FINGERPRINT "Require an exact reference SDK snapshot" ${_fingerprint_default})
if(DASSDL3_VALIDATE_SDK_FINGERPRINT)
    if(NOT DASSDL3_SDK_FINGERPRINT)
        message(FATAL_ERROR "Strict SDK validation requires DASSDL3_SDK_FINGERPRINT (on macOS repository installs set DASSDL3_PACKAGE_SDK_FINGERPRINT)")
    endif()
    # A candidate must match in full; never mix files from different SDKs.
    set(_sdk_match FALSE)
    set(_sdk_failures "")
    foreach(candidate IN LISTS DASSDL3_SDK_FINGERPRINT)
        file(STRINGS "${candidate}" _sdk_files)
        if(NOT _sdk_files)
            message(FATAL_ERROR "Empty SDK fingerprint: ${candidate}")
        endif()
        set(_candidate_match TRUE)
        foreach(entry IN LISTS _sdk_files)
            string(SUBSTRING "${entry}" 0 64 expected)
            string(SUBSTRING "${entry}" 65 -1 relative)
            if(NOT EXISTS "${DASLANG_DIR}/${relative}")
                set(_candidate_match FALSE)
                set(_reason "missing ${relative}")
                break()
            endif()
            file(SHA256 "${DASLANG_DIR}/${relative}" actual)
            if(NOT actual STREQUAL expected)
                set(_candidate_match FALSE)
                set(_reason "changed ${relative}")
                break()
            endif()
        endforeach()
        get_filename_component(_candidate_name "${candidate}" NAME)
        if(_candidate_match)
            set(_sdk_match TRUE)
            message(STATUS "Validated SDK snapshot: ${_candidate_name}")
            break()
        endif()
        string(APPEND _sdk_failures "\n  ${_candidate_name}: ${_reason}")
    endforeach()
    if(NOT _sdk_match)
        message(FATAL_ERROR "SDK fingerprint mismatch. No validated snapshot matched:${_sdk_failures}\nSee docs/daspkg.md for supported SDKs.")
    endif()
endif()
# Search only the selected SDK, never accidentally use a system fmt installation.
find_path(DASSDL3_FMT_INCLUDE_DIR NAMES fmt/format.h
    PATHS "${DASLANG_DIR}/3rdparty/fmt/include" "${DASLANG_DIR}/include"
          "${DASLANG_DIR}/include/fmt/include" "${DASLANG_DIR}/external/fmt/include"
    NO_DEFAULT_PATH)
if(NOT DASSDL3_FMT_INCLUDE_DIR OR
   NOT EXISTS "${DASSDL3_FMT_INCLUDE_DIR}/fmt/format.h")
    message(FATAL_ERROR "Missing fmt headers in SDK ${DASLANG_DIR}. Expected include/fmt/format.h or 3rdparty/fmt/include/fmt/format.h. Install the SDK development headers or set DASSDL3_FMT_INCLUDE_DIR to the matching fmt include directory.")
endif()
message(STATUS "SDK fmt headers: ${DASSDL3_FMT_INCLUDE_DIR}")

# Reuse an explicit SDL install, or fetch the pinned source for the source package.
option(DASSDL3_PACKAGE_FETCH_SDL "Fetch pinned SDL when no SDL3_DIR is supplied" OFF)
if(DASSDL3_PACKAGE_FETCH_SDL AND NOT SDL3_DIR AND NOT DEFINED ENV{SDL3_DIR})
    include(FetchContent)
    set(SDL_SHARED OFF CACHE BOOL "" FORCE)
    set(SDL_STATIC ON CACHE BOOL "" FORCE)
    set(SDL_TEST_LIBRARY OFF CACHE BOOL "" FORCE)
    set(SDL_TESTS OFF CACHE BOOL "" FORCE)
    FetchContent_Declare(SDL3 GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
        GIT_TAG release-3.4.16 GIT_SHALLOW TRUE)
    FetchContent_MakeAvailable(SDL3)
else()
    find_package(SDL3 3.4.16 EXACT CONFIG REQUIRED COMPONENTS SDL3-static)
endif()
add_library(dasSDL3_package SHARED "${DASSDL3_SOURCE_DIR}/module_sdl3.cpp")
target_include_directories(dasSDL3_package PRIVATE "${DASSDL3_SOURCE_DIR}" "${DASLANG_DIR}/include" "${DASSDL3_FMT_INCLUDE_DIR}")
target_compile_definitions(dasSDL3_package PRIVATE DAS_ENABLE_DLL=1 DAS_MOD_EXPORTS
    DAS_FUSION=2 DAS_NO_ASSERTIONS
    DASSDL3_TYPES_INCLUDE="generated/${_package_snapshot}/sdl3_types.inc"
    DASSDL3_REGISTRATION_INCLUDE="generated/${_package_snapshot}/sdl3_functions.inc")
if(NOT APPLE)
    target_compile_definitions(dasSDL3_package PRIVATE DAS_ENABLE_EXCEPTIONS=1)
endif()
target_compile_options(dasSDL3_package PRIVATE ${_package_options})
target_link_libraries(dasSDL3_package PRIVATE SDL3::SDL3-static
    "${DASLANG_DIR}/${_sdk_compiler}" "${DASLANG_DIR}/${_sdk_runtime}")
set_target_properties(dasSDL3_package PROPERTIES PREFIX "" SUFFIX ".shared_module"
    OUTPUT_NAME dasSDL3 RUNTIME_OUTPUT_DIRECTORY "${DASSDL3_PACKAGE_OUTPUT}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${DASSDL3_PACKAGE_OUTPUT}"
    LIBRARY_OUTPUT_DIRECTORY "${DASSDL3_PACKAGE_OUTPUT}")
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set_target_properties(dasSDL3_package PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE
        INSTALL_RPATH "$ORIGIN")
endif()


# GUI variant uses the same SDL instance as the core binding.
option(DASSDL3_PACKAGE_IMGUI "Include SDL platform/renderer backend for SDK dasImgui" OFF)
if(DASSDL3_PACKAGE_IMGUI)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        message(FATAL_ERROR "Linux daspkg currently supports only the core profile")
    endif()
    set(_imgui "${DASLANG_DIR}/modules/dasImgui")
    set(_imgui_source "${_imgui}/imgui")
    set(_imgui_library "${DASLANG_DIR}/lib/dasModuleImgui.lib")
    if(APPLE)
        set(_imgui_library "${_imgui}/dasModuleImgui.shared_module")
    endif()
    foreach(required "${_imgui_library}" "${_imgui}/dasModuleImgui.shared_module"
            "${_imgui_source}/imgui.h")
        if(NOT EXISTS "${required}")
            message(FATAL_ERROR "GUI profile needs a built SDK dasImgui: missing ${required}")
        endif()
    endforeach()
    target_sources(dasSDL3_package PRIVATE "${DASSDL3_SOURCE_DIR}/libraries/module_imgui_sdl.cpp"
        "${_imgui_source}/backends/imgui_impl_sdl3.cpp"
        "${_imgui_source}/backends/imgui_impl_sdlrenderer3.cpp"
        "${_imgui_source}/backends/imgui_impl_sdlgpu3.cpp")
    target_include_directories(dasSDL3_package PRIVATE "${DASSDL3_SOURCE_DIR}/libraries"
        "${_imgui_source}")
    if(WIN32)
        target_compile_definitions(dasSDL3_package PRIVATE "IMGUI_API=__declspec(dllimport)")
    endif()
    target_compile_definitions(dasSDL3_package PRIVATE
        "IMGUI_IMPL_API=" IMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 IMGUI_ENABLE_FREETYPE=1 IMGUI_USE_WCHAR32=1)
    target_link_libraries(dasSDL3_package PRIVATE "${_imgui_library}")
endif()

# Optional helper for this repository's minimal SDK: daspkg itself imports PUGIXML.
option(DASSDL3_DASPKG_CLI_SUPPORT "Build upstream PUGIXML separately for daspkg CLI" OFF)
if(DASSDL3_DASPKG_CLI_SUPPORT)
    set(_pugi "${DASLANG_DIR}/modules/dasPUGIXML")
    add_library(daspkg_pugixml SHARED "${_pugi}/src/dasPUGIXML.cpp" "${_pugi}/pugixml/pugixml.cpp")
    target_include_directories(daspkg_pugixml PRIVATE "${DASLANG_DIR}/include"
        "${DASSDL3_FMT_INCLUDE_DIR}" "${_pugi}/pugixml")
    target_compile_definitions(daspkg_pugixml PRIVATE DAS_ENABLE_DLL=1 DAS_MOD_EXPORTS
        DAS_FUSION=2 DAS_NO_ASSERTIONS)
    if(NOT APPLE)
        target_compile_definitions(daspkg_pugixml PRIVATE DAS_ENABLE_EXCEPTIONS=1)
    endif()
    target_compile_options(daspkg_pugixml PRIVATE ${_package_options})
    target_link_libraries(daspkg_pugixml PRIVATE "${DASLANG_DIR}/${_sdk_compiler}"
        "${DASLANG_DIR}/${_sdk_runtime}")
    set_target_properties(daspkg_pugixml PROPERTIES PREFIX "" SUFFIX ".shared_module"
        OUTPUT_NAME dasModulePUGIXML RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/cli"
        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/cli"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/cli")
    file(COPY "${_pugi}/.das_module" "${_pugi}/daslib" DESTINATION "${CMAKE_BINARY_DIR}/cli")
    set(_cli_args --cli-module "${CMAKE_BINARY_DIR}/cli")
endif()

include(CTest)
if(BUILD_TESTING)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    if(WIN32 AND MSVC AND SDL3_DIR)
        add_test(NAME sdl3_package_sdk_config COMMAND "${Python3_EXECUTABLE}"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/test_package_sdk_config.py"
            --sdl-dir "${SDL3_DIR}")
        set_tests_properties(sdl3_package_sdk_config PROPERTIES TIMEOUT 180)
    endif()
    add_test(NAME sdl3_daspkg_manifest COMMAND "${Python3_EXECUTABLE}"
        "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/test_daspkg_manifest.py"
        --das-root "${DASLANG_DIR}")
    set_tests_properties(sdl3_daspkg_manifest PROPERTIES TIMEOUT 120)
    add_test(NAME sdl3_daspkg_consumer COMMAND "${Python3_EXECUTABLE}"
        "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/test_daspkg.py"
        --module $<TARGET_FILE:dasSDL3_package> --das-root "${DASLANG_DIR}" ${_cli_args})
    set_tests_properties(sdl3_daspkg_consumer PROPERTIES TIMEOUT 240 RUN_SERIAL TRUE)
    add_test(NAME sdl3_daspkg_source COMMAND "${Python3_EXECUTABLE}"
        "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/test_daspkg.py"
        --module $<TARGET_FILE:dasSDL3_package> --das-root "${DASLANG_DIR}"
        --source --sdl-dir "${SDL3_DIR}" ${_cli_args})
    set_tests_properties(sdl3_daspkg_source PROPERTIES TIMEOUT 900 RUN_SERIAL TRUE)
    foreach(profile core imgui)
        if(profile STREQUAL "imgui" AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
            continue()
        endif()
        set(_profile_arg)
        if(profile STREQUAL "imgui")
            set(_profile_arg --imgui)
        endif()
        add_test(NAME sdl3_daspkg_repository_${profile} COMMAND "${Python3_EXECUTABLE}"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/test_daspkg.py"
            --module $<TARGET_FILE:dasSDL3_package> --das-root "${DASLANG_DIR}"
            --repository --sdl-dir "${SDL3_DIR}" ${_profile_arg} ${_cli_args})
        set_tests_properties(sdl3_daspkg_repository_${profile} PROPERTIES TIMEOUT 900 RUN_SERIAL TRUE)
    endforeach()
    if(DASSDL3_PACKAGE_IMGUI)
        foreach(mode binary source)
            set(_source_arg)
            if(mode STREQUAL "source")
                set(_source_arg --source --sdl-dir "${SDL3_DIR}")
            endif()
            add_test(NAME sdl3_daspkg_imgui_${mode} COMMAND "${Python3_EXECUTABLE}"
                "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/test_daspkg.py"
                --module $<TARGET_FILE:dasSDL3_package> --das-root "${DASLANG_DIR}"
                --imgui ${_source_arg} ${_cli_args})
            set_tests_properties(sdl3_daspkg_imgui_${mode} PROPERTIES TIMEOUT 900 RUN_SERIAL TRUE)
        endforeach()
    endif()
    option(DASSDL3_DASPKG_NETWORK_TESTS "Enable cold SDL download/install test" OFF)
    if(DASSDL3_DASPKG_NETWORK_TESTS)
        add_test(NAME sdl3_daspkg_source_fetch COMMAND "${Python3_EXECUTABLE}"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/test_daspkg.py"
            --module $<TARGET_FILE:dasSDL3_package> --das-root "${DASLANG_DIR}"
            --fetch-sdl ${_cli_args})
        set_tests_properties(sdl3_daspkg_source_fetch PROPERTIES TIMEOUT 900
            RUN_SERIAL TRUE LABELS "network")
    endif()
    set(DASSDL3_RELEASE_LLVM_DIR "" CACHE PATH "Optional pinned LLVM tools for release test")
    if(DASSDL3_RELEASE_LLVM_DIR)
        add_test(NAME sdl3_daspkg_release COMMAND "${Python3_EXECUTABLE}"
            "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/test_daspkg.py"
            --module $<TARGET_FILE:dasSDL3_package> --das-root "${DASLANG_DIR}"
            --release --llvm-dir "${DASSDL3_RELEASE_LLVM_DIR}" ${_cli_args})
        set_tests_properties(sdl3_daspkg_release PROPERTIES TIMEOUT 300 RUN_SERIAL TRUE)
        if(DASSDL3_PACKAGE_IMGUI)
            add_test(NAME sdl3_daspkg_imgui_release COMMAND "${Python3_EXECUTABLE}"
                "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/test_daspkg.py"
                --module $<TARGET_FILE:dasSDL3_package> --das-root "${DASLANG_DIR}"
                --imgui --release --llvm-dir "${DASSDL3_RELEASE_LLVM_DIR}" ${_cli_args})
            set_tests_properties(sdl3_daspkg_imgui_release PROPERTIES TIMEOUT 300 RUN_SERIAL TRUE)
        endif()
    endif()
endif()
