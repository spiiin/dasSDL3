cmake_minimum_required(VERSION 3.24)
project(dasSDL3LiveHttp LANGUAGES C CXX)
if(NOT (APPLE OR (MSVC AND WIN32)))
    message(FATAL_ERROR "HTTP pilot requires macOS or MSVC/Windows")
endif()
if(APPLE AND NOT CMAKE_OSX_DEPLOYMENT_TARGET)
    set(CMAKE_OSX_DEPLOYMENT_TARGET 11.0 CACHE STRING "Minimum macOS version" FORCE)
endif()
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
get_filename_component(ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(DAS "${ROOT}/third_party/daScript")
if(APPLE)
    set(_compiler "${DAS}/lib/liblibDaScriptDyn.dylib")
    set(_runtime "${DAS}/lib/liblibDaScriptDyn_runtime.dylib")
    set(_live_host "${ROOT}/build/macos-live/live/dasSDL3_live")
    set(_live_module "${ROOT}/build/macos-live/live/module")
    set(_daslang "${DAS}/bin/daslang")
else()
    set(_compiler "${DAS}/lib/libDaScriptDyn.lib")
    set(_runtime "${DAS}/lib/libDaScriptDyn_runtime.lib")
    set(_live_host "${ROOT}/build/ninja/live/dasSDL3_live.exe")
    set(_live_module "${ROOT}/build/ninja/live/module")
    set(_daslang "${DAS}/bin/daslang.exe")
endif()
include(FetchContent)
# Same source/hash as pinned dasHV. This loopback-only pilot needs HTTP, not TLS.
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED OFF CACHE BOOL "" FORCE)
set(BUILD_STATIC ON CACHE BOOL "" FORCE)
set(WITH_OPENSSL OFF CACHE BOOL "" FORCE)
set(WITH_GNUTLS OFF CACHE BOOL "" FORCE)
set(WITH_MBEDTLS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(libhv URL https://github.com/ithewei/libhv/archive/5da5fc22cdfd1b59ba2b0520abb34f95d050975c.tar.gz
    URL_HASH SHA256=b4f774936ccd6981df74b23f9e033e0b3ab584f6682d889490377dc9450b5f54
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
FetchContent_MakeAvailable(libhv)
add_library(dasSDL3_live_hv SHARED "${DAS}/modules/dasHV/src/dasHV.cpp")
target_include_directories(dasSDL3_live_hv PRIVATE "${DAS}/include" "${DAS}/3rdparty/fmt/include"
    "${DAS}/modules/dasHV/src" "${libhv_SOURCE_DIR}/include")
target_compile_definitions(dasSDL3_live_hv PRIVATE DAS_ENABLE_DLL=1 DAS_MOD_EXPORTS DAS_ENABLE_EXCEPTIONS=1 DAS_FUSION=2 DAS_NO_ASSERTIONS HV_STATICLIB)
if(MSVC)
    target_compile_options(dasSDL3_live_hv PRIVATE /bigobj /arch:AVX2 /wd4251 /wd4275)
else()
    target_compile_options(dasSDL3_live_hv PRIVATE -fno-rtti)
endif()
target_link_libraries(dasSDL3_live_hv PRIVATE hv_static "${_compiler}" "${_runtime}")
set_target_properties(dasSDL3_live_hv PROPERTIES PREFIX "" SUFFIX ".shared_module"
    OUTPUT_NAME dasModuleHV RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/dasHV"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/dasHV")
configure_file(module.das.in "${CMAKE_BINARY_DIR}/dasHV/.das_module" @ONLY)

include(CTest)
if(BUILD_TESTING)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    set(DASSDL3_LIVE_HOST "${_live_host}" CACHE FILEPATH "Previously built live host")
    set(DASSDL3_LIVE_MODULE "${_live_module}" CACHE PATH "Previously built SDL dynamic module")
    set(DASSDL3_MCP_DASLANG "${_daslang}" CACHE FILEPATH "Matching upstream dynamic interpreter")
    add_test(NAME sdl3_live_mcp COMMAND ${Python3_EXECUTABLE} "${ROOT}/tests/test_live_mcp.py"
        --host ${DASSDL3_LIVE_HOST} --module ${DASSDL3_LIVE_MODULE}
        --http-module "${CMAKE_BINARY_DIR}/dasHV" --daslang ${DASSDL3_MCP_DASLANG})
    add_test(NAME sdl3_live_watch COMMAND ${Python3_EXECUTABLE} "${ROOT}/tests/test_live_mcp.py"
        --host ${DASSDL3_LIVE_HOST} --module ${DASSDL3_LIVE_MODULE}
        --http-module "${CMAKE_BINARY_DIR}/dasHV" --daslang ${DASSDL3_MCP_DASLANG} --watch)
    add_test(NAME sdl3_live_gui COMMAND ${Python3_EXECUTABLE} "${ROOT}/tests/test_live_mcp.py"
        --host ${DASSDL3_LIVE_HOST} --module ${DASSDL3_LIVE_MODULE}
        --http-module "${CMAKE_BINARY_DIR}/dasHV" --daslang ${DASSDL3_MCP_DASLANG} --gui)
    add_test(NAME sdl3_live_playwright COMMAND ${Python3_EXECUTABLE} "${ROOT}/tests/test_live_mcp.py"
        --host ${DASSDL3_LIVE_HOST} --module ${DASSDL3_LIVE_MODULE}
        --http-module "${CMAKE_BINARY_DIR}/dasHV" --daslang ${DASSDL3_MCP_DASLANG} --playwright)
    set_tests_properties(sdl3_live_playwright sdl3_live_gui sdl3_live_mcp sdl3_live_watch PROPERTIES TIMEOUT 180 RUN_SERIAL TRUE)
endif()

# Optional recording profile, using the pinned upstream APNG writer unchanged.
add_library(dasSDL3_live_stb SHARED "${DAS}/modules/dasStbImage/src/dasStbImage.cpp"
    "${DAS}/modules/dasStbImage/src/dasStbImage_impl.cpp")
target_include_directories(dasSDL3_live_stb PRIVATE "${DAS}/include" "${DAS}/3rdparty/fmt/include")
target_compile_definitions(dasSDL3_live_stb PRIVATE DAS_ENABLE_DLL=1 DAS_MOD_EXPORTS DAS_ENABLE_EXCEPTIONS=1 DAS_FUSION=2 DAS_NO_ASSERTIONS)
if(MSVC)
    target_compile_options(dasSDL3_live_stb PRIVATE /bigobj /arch:AVX2 /wd4251 /wd4275)
else()
    target_compile_options(dasSDL3_live_stb PRIVATE -fno-rtti)
endif()
target_link_libraries(dasSDL3_live_stb PRIVATE "${_compiler}" "${_runtime}")
set_target_properties(dasSDL3_live_stb PROPERTIES PREFIX "" SUFFIX ".shared_module"
    OUTPUT_NAME dasModuleStbImage RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/dasStbImage"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/dasStbImage")
configure_file(stb_module.das.in "${CMAKE_BINARY_DIR}/dasStbImage/.das_module" @ONLY)

if(BUILD_TESTING)
    add_test(NAME sdl3_live_recording COMMAND ${Python3_EXECUTABLE} "${ROOT}/tests/test_live_recording.py" --host "${DASSDL3_LIVE_HOST}" --module "${DASSDL3_LIVE_MODULE}" --http-module "${CMAKE_BINARY_DIR}/dasHV" --stb-module "${CMAKE_BINARY_DIR}/dasStbImage" --daslang "${DASSDL3_MCP_DASLANG}")
    add_test(NAME sdl3_live_recording_port COMMAND ${Python3_EXECUTABLE} "${ROOT}/tests/test_live_recording.py" --host "${DASSDL3_LIVE_HOST}" --module "${DASSDL3_LIVE_MODULE}" --http-module "${CMAKE_BINARY_DIR}/dasHV" --stb-module "${CMAKE_BINARY_DIR}/dasStbImage" --daslang "${DASSDL3_MCP_DASLANG}" --upstream-port)
    add_test(NAME sdl3_live_visual_aids COMMAND "${Python3_EXECUTABLE}" "${ROOT}/tests/test_live_recording.py" --host "${DASSDL3_LIVE_HOST}" --module "${DASSDL3_LIVE_MODULE}" --http-module "${CMAKE_BINARY_DIR}/dasHV" --stb-module "${CMAKE_BINARY_DIR}/dasStbImage" --daslang "${DASSDL3_MCP_DASLANG}" --visual-aids)
    set_tests_properties(sdl3_live_visual_aids sdl3_live_recording sdl3_live_recording_port PROPERTIES TIMEOUT 150 RUN_SERIAL TRUE)
endif()
