cmake_minimum_required(VERSION 3.24)
project(dasSDL3StandaloneWeb LANGUAGES C CXX)
if(NOT EMSCRIPTEN OR NOT EMSCRIPTEN_VERSION VERSION_EQUAL "5.0.3")
    message(FATAL_ERROR "Use Emscripten 5.0.3")
endif()
set(CMAKE_CXX_STANDARD 17)
get_filename_component(ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(WEB_BUILD "${ROOT}/build/web" CACHE PATH "Built Web dependencies")
set(DAS "${ROOT}/third_party/daScript")
file(STRINGS "${WEB_BUILD}/CMakeCache.txt" sdl_line REGEX "^SDL3_SOURCE_DIR:STATIC=")
string(REGEX REPLACE "^[^=]*=" "" SDL "${sdl_line}")
set(NODE_EXECUTABLE "$ENV{EMSDK_NODE}" CACHE FILEPATH "Node from the activated Emscripten SDK")
if(NOT EXISTS "${NODE_EXECUTABLE}")
    message(FATAL_ERROR "Activate emsdk or set NODE_EXECUTABLE to its Node runtime")
endif()
add_library(runtime INTERFACE)
target_include_directories(runtime INTERFACE "${DAS}/include" "${DAS}/3rdparty/fmt/include"
    "${DAS}/3rdparty/uriparser/include" "${WEB_BUILD}/dascript/include"
    "${ROOT}/src" "${ROOT}/web" "${SDL}/include" "${WEB_BUILD}/_deps/sdl3-build/include-revision")
target_compile_definitions(runtime INTERFACE DAS_ENABLE_EXCEPTIONS=1 DAS_ENABLE_DYN_INCLUDES=1
    DAS_FUSION=2 DAS_NO_ASSERTIONS URIPARSER_BUILD_CHAR URI_STATIC_BUILD _EMSCRIPTEN_VER)
target_compile_options(runtime INTERFACE -msimd128 -mnontrapping-fptoint -fwasm-exceptions -sWASM_LEGACY_EXCEPTIONS=0 -fno-rtti)
target_link_options(runtime INTERFACE -fwasm-exceptions -sWASM_LEGACY_EXCEPTIONS=0 -sSTACK_SIZE=4MB
    -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=128MB -sFORCE_FILESYSTEM=1
    -sFULL_ES3=1 -sMAX_WEBGL_VERSION=2 -sMIN_WEBGL_VERSION=1 -O1)
target_link_libraries(runtime INTERFACE "${WEB_BUILD}/lib/liblibDaScript_runtime.a"
    "${WEB_BUILD}/lib/liblibUriParser.a" "${WEB_BUILD}/_deps/sdl3-build/libSDL3.a")
add_executable(generate_aot generate.cpp "${ROOT}/web/module_web.cpp")
target_link_libraries(generate_aot PRIVATE "${WEB_BUILD}/lib/liblibDaScript.a" runtime)
target_link_options(generate_aot PRIVATE -lnodefs.js -sENVIRONMENT=node)
set_target_properties(generate_aot PROPERTIES SUFFIX ".js")
file(GLOB_RECURSE AOT_INPUTS CONFIGURE_DEPENDS "${ROOT}/dassdl3/*.das" "${DAS}/daslib/*.das")
function(add_app name source)
    set(out "${CMAKE_BINARY_DIR}/aot/${name}")
    file(MAKE_DIRECTORY "${out}")
    add_custom_command(OUTPUT "${out}/app.das.cpp" "${out}/app.das.h"
        COMMAND "${NODE_EXECUTABLE}" "$<TARGET_FILE:generate_aot>" "${ROOT}" "/repo/${source}" "${out}"
        DEPENDS generate_aot "${ROOT}/${source}" "${CMAKE_CURRENT_SOURCE_DIR}/emit.das" ${AOT_INPUTS} VERBATIM)
    add_executable(${name} runner.cpp "${out}/app.das.cpp")
    target_include_directories(${name} PRIVATE "${out}")
    target_link_libraries(${name} PRIVATE runtime)
    set_target_properties(${name} PROPERTIES SUFFIX ".js" RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/site")
    target_link_options(${name} PRIVATE "-Wl,-Map,${CMAKE_BINARY_DIR}/${name}.map"
        -sMODULARIZE=1 -sEXPORT_NAME=createStandalone -sINVOKE_RUN=0 -sEXIT_RUNTIME=0
        "-sEXPORTED_FUNCTIONS=['_main','_web_stop']" "-sEXPORTED_RUNTIME_METHODS=['callMain','FS']")
    set_property(TARGET ${name} APPEND PROPERTY LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/check_link.cmake")
    add_custom_command(TARGET ${name} POST_BUILD COMMAND "${CMAKE_COMMAND}" "-DMAP_FILE=${CMAKE_BINARY_DIR}/${name}.map"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/check_link.cmake" VERBATIM)
    if(CMAKE_HOST_WIN32)
        add_custom_command(TARGET ${name} POST_BUILD COMMAND icacls "$<TARGET_FILE:${name}>" /reset VERBATIM)
    endif()
endfunction()
add_app(square examples/lifecycle/01_square.das)
add_app(gc tests/lifecycle_gc.das)
add_app(sdl_gc tests/lifecycle_sdl_gc.das)
add_app(faults tests/lifecycle_aot_faults.das)
target_compile_definitions(faults PRIVATE DASSDL3_FAULT_FIXTURE=1)
if(CMAKE_HOST_WIN32)
    add_custom_command(TARGET generate_aot POST_BUILD COMMAND icacls "$<TARGET_FILE:generate_aot>" /reset VERBATIM)
endif()
foreach(file index.html app.js)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${file}" "${CMAKE_BINARY_DIR}/site/${file}" COPYONLY)
endforeach()
configure_file("${ROOT}/web/style.css" "${CMAKE_BINARY_DIR}/site/style.css" COPYONLY)
# Source is a downloadable document only, never compiled or loaded into the runtime.
configure_file("${ROOT}/examples/lifecycle/01_square.das" "${CMAKE_BINARY_DIR}/site/square.das" COPYONLY)

include(CTest)
if(BUILD_TESTING)
    add_test(NAME standalone_reject_no_aot COMMAND "${CMAKE_COMMAND}"
        "-DNODE=${NODE_EXECUTABLE}" "-DGENERATOR=$<TARGET_FILE:generate_aot>" "-DROOT=${ROOT}"
        "-DOUT=${CMAKE_BINARY_DIR}/aot/negative" -P "${CMAKE_CURRENT_SOURCE_DIR}/check_reject.cmake")
    set_tests_properties(standalone_reject_no_aot PROPERTIES TIMEOUT 75)
    foreach(app square gc sdl_gc faults)
        add_test(NAME standalone_link_${app} COMMAND "${CMAKE_COMMAND}"
            "-DMAP_FILE=${CMAKE_BINARY_DIR}/${app}.map" -P "${CMAKE_CURRENT_SOURCE_DIR}/check_link.cmake")
    endforeach()
endif()
