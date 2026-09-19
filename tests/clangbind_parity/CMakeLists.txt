cmake_minimum_required(VERSION 3.24)
project(SDLClangBindParity LANGUAGES CXX)
if(NOT MSVC OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "Parity currently validates Windows x64/MSVC only")
endif()
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
get_filename_component(ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(DAS "${ROOT}/third_party/daScript")
set(MAIN_BUILD "${ROOT}/build/ninja" CACHE PATH "Existing SDL build")
set(SDL_INCLUDE "${MAIN_BUILD}/_deps/sdl3-src/include" CACHE PATH "SDL include")
set(LLVM_SDK "" CACHE PATH "LLVM 22.1 SDK")
find_package(Python3 REQUIRED COMPONENTS Interpreter)
set(GEN "${CMAKE_CURRENT_BINARY_DIR}/generated")
file(GLOB SDL_HEADERS CONFIGURE_DEPENDS "${SDL_INCLUDE}/SDL3/*.h")
add_custom_command(OUTPUT "${GEN}/parity_functions.inc" "${GEN}/parity-api.json"
    COMMAND ${Python3_EXECUTABLE} "${ROOT}/tools/run_clangbind_parity.py"
        --daslang "${DAS}/bin/daslang.exe" --sdl-include "${SDL_INCLUDE}" --sdk "${LLVM_SDK}" --output "${GEN}"
    DEPENDS "${ROOT}/tools/clangbind_parity.das" "${ROOT}/tools/run_clangbind_parity.py"
        "${ROOT}/tools/bindings.json" "${ROOT}/src/generated/api.json" "${ROOT}/src/generated/sdl3_functions.inc" ${SDL_HEADERS}
    VERBATIM)
add_custom_target(generate_parity DEPENDS "${GEN}/parity_functions.inc")
foreach(backend baseline cppgenbind)
    add_library(${backend}_module STATIC "${ROOT}/src/module_sdl3.cpp")
    target_include_directories(${backend}_module PUBLIC "${ROOT}/src" "${GEN}" "${DAS}/include" "${DAS}/3rdparty/fmt/include" "${SDL_INCLUDE}")
    target_compile_definitions(${backend}_module PUBLIC DAS_ENABLE_EXCEPTIONS=1 DAS_FUSION=2 DAS_NO_ASSERTIONS
        DASSDL3_TESTING=1 DASSDL3_DAS_ROOT="${DAS}" DASSDL3_MODULE_ROOT="${ROOT}/dassdl3")
    target_compile_options(${backend}_module PUBLIC /EHsc /bigobj /arch:AVX2)
    target_link_libraries(${backend}_module PUBLIC "${DAS}/lib/libDaScript.lib" "${DAS}/lib/libDaScript_runtime.lib"
        "${DAS}/lib/libUriParser.lib" "${MAIN_BUILD}/_deps/sdl3-build/SDL3-static.lib"
        dbghelp ws2_32 mswsock rpcrt4 kernel32 user32 gdi32 winmm imm32 ole32 oleaut32 version uuid advapi32 setupapi shell32 dinput8)
    add_executable(${backend}_runner "${ROOT}/src/runner.cpp")
    target_link_libraries(${backend}_runner PRIVATE ${backend}_module)
    add_executable(${backend}_metadata metadata.cpp)
    target_link_libraries(${backend}_metadata PRIVATE ${backend}_module)
endforeach()
add_dependencies(cppgenbind_module generate_parity)
target_compile_definitions(cppgenbind_module PRIVATE DASSDL3_REGISTRATION_INCLUDE="parity_functions.inc")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/assets")
configure_file("${ROOT}/examples/assets/checker.bmp" "${CMAKE_CURRENT_BINARY_DIR}/assets/checker.bmp" COPYONLY)
configure_file("${ROOT}/examples/assets/tone.wav" "${CMAKE_CURRENT_BINARY_DIR}/assets/tone.wav" COPYONLY)
enable_testing()
add_test(NAME sdl3_parity_generation_errors COMMAND ${Python3_EXECUTABLE}
    "${CMAKE_CURRENT_SOURCE_DIR}/test_generation_errors.py"
    "${ROOT}/tools/run_clangbind_parity.py" "${DAS}/bin/daslang.exe" "${LLVM_SDK}")
set_tests_properties(sdl3_parity_generation_errors PROPERTIES TIMEOUT 30)
add_test(NAME sdl3_parity_metadata COMMAND ${Python3_EXECUTABLE} "${CMAKE_CURRENT_SOURCE_DIR}/compare_metadata.py"
    $<TARGET_FILE:baseline_metadata> $<TARGET_FILE:cppgenbind_metadata>)
foreach(backend baseline cppgenbind)
    foreach(script tests/bindings tests/boost tests/textures tests/input tests/audio examples/square examples/textures examples/input examples/audio)
        string(REPLACE "/" "_" name "${script}")
        add_test(NAME ${backend}_${name} COMMAND ${backend}_runner "${ROOT}/${script}.das" --smoke-test)
        set_tests_properties(${backend}_${name} PROPERTIES TIMEOUT 30)
        if(script MATCHES "audio$")
            set_tests_properties(${backend}_${name} PROPERTIES ENVIRONMENT "SDL_AUDIO_DRIVER=dummy")
        endif()
    endforeach()
endforeach()
