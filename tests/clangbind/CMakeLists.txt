cmake_minimum_required(VERSION 3.24)
project(SDLClangBindExperiment LANGUAGES CXX)
if(NOT MSVC OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "This experiment currently validates Windows x64/MSVC only")
endif()
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
get_filename_component(ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(DAS "${ROOT}/third_party/daScript")
set(MAIN_BUILD "${ROOT}/build/ninja" CACHE PATH "Existing dasSDL3 build with SDL static library")
set(SDL_INCLUDE "${MAIN_BUILD}/_deps/sdl3-src/include" CACHE PATH "Pinned SDL include directory")
set(LLVM_SDK "" CACHE PATH "Full LLVM 22.1 SDK")
find_package(Python3 REQUIRED COMPONENTS Interpreter)
set(DASLANG "${DAS}/bin/daslang.exe")
set(GEN "${CMAKE_CURRENT_BINARY_DIR}/generated")
file(MAKE_DIRECTORY "${GEN}")
configure_file(.das_module "${GEN}/.das_module" COPYONLY)
configure_file(probe_aot.h "${GEN}/probe_aot.h" COPYONLY)
file(GLOB SDL_HEADERS CONFIGURE_DEPENDS "${SDL_INCLUDE}/SDL3/*.h")
add_custom_command(OUTPUT "${GEN}/dasSDL3Probe.cpp" "${GEN}/dasSDL3Probe.func_1.cpp"
    COMMAND ${Python3_EXECUTABLE} "${ROOT}/tools/run_clangbind_generation.py"
        --daslang "${DASLANG}" --sdl-include "${SDL_INCLUDE}" --sdk "${LLVM_SDK}" --output "${GEN}"
    DEPENDS "${ROOT}/tools/clangbind_generate.das" "${ROOT}/tools/run_clangbind_generation.py" ${SDL_HEADERS}
    VERBATIM)
add_custom_target(generate_probe DEPENDS "${GEN}/dasSDL3Probe.cpp" "${GEN}/dasSDL3Probe.func_1.cpp")
set(NATIVE_SOURCES glue.cpp "${GEN}/dasSDL3Probe.cpp" "${GEN}/dasSDL3Probe.func_1.cpp")
function(configure_probe target)
    add_dependencies(${target} generate_probe)
    target_include_directories(${target} PRIVATE "${GEN}" "${DAS}/include" "${DAS}/3rdparty/fmt/include" "${SDL_INCLUDE}")
    target_compile_definitions(${target} PRIVATE DAS_ENABLE_DLL=1 DAS_MOD_EXPORTS DAS_ENABLE_EXCEPTIONS=1 DAS_FUSION=2 DAS_NO_ASSERTIONS)
    target_compile_options(${target} PRIVATE /EHsc /bigobj /arch:AVX2)
    target_link_libraries(${target} PRIVATE "${DAS}/lib/libDaScriptDyn.lib" "${DAS}/lib/libDaScriptDyn_runtime.lib"
        "${MAIN_BUILD}/_deps/sdl3-build/SDL3-static.lib"
        kernel32 user32 gdi32 winmm imm32 ole32 oleaut32 version uuid advapi32 setupapi shell32 dinput8)
endfunction()
add_library(probe SHARED ${NATIVE_SOURCES})
configure_probe(probe)
set_target_properties(probe PROPERTIES PREFIX "" SUFFIX ".shared_module" RUNTIME_OUTPUT_DIRECTORY "${GEN}")
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/smoke.das.cpp"
    COMMAND "${DASLANG}" -aot "${CMAKE_CURRENT_SOURCE_DIR}/smoke.das" "${CMAKE_CURRENT_BINARY_DIR}/smoke.das.cpp" -load_module "${GEN}"
    DEPENDS probe smoke.das probe_aot.h VERBATIM)
add_executable(probe_runner runner.cpp ${NATIVE_SOURCES} "${CMAKE_CURRENT_BINARY_DIR}/smoke.das.cpp")
configure_probe(probe_runner)
add_executable(probe_no_aot runner.cpp ${NATIVE_SOURCES})
configure_probe(probe_no_aot)
foreach(target probe_runner probe_no_aot)
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DAS}/bin/libDaScriptDyn.dll" "${DAS}/bin/libDaScriptDyn_runtime.dll" "$<TARGET_FILE_DIR:${target}>")
endforeach()
enable_testing()
add_test(NAME sdl3_clangbind_generation_errors COMMAND ${Python3_EXECUTABLE}
    "${CMAKE_CURRENT_SOURCE_DIR}/test_generation_errors.py"
    "${ROOT}/tools/run_clangbind_generation.py" "${DASLANG}" "${LLVM_SDK}")
add_test(NAME sdl3_clangbind_interpreter COMMAND probe_runner "${DAS}" "${CMAKE_CURRENT_SOURCE_DIR}/smoke.das" interpreter)
add_test(NAME sdl3_clangbind_aot COMMAND probe_runner "${DAS}" "${CMAKE_CURRENT_SOURCE_DIR}/smoke.das" aot)
add_test(NAME sdl3_clangbind_missing_aot COMMAND ${Python3_EXECUTABLE}
    "${CMAKE_CURRENT_SOURCE_DIR}/expect_aot_failure.py" $<TARGET_FILE:probe_no_aot>
    "${DAS}" "${CMAKE_CURRENT_SOURCE_DIR}/smoke.das" aot)
set_tests_properties(sdl3_clangbind_generation_errors sdl3_clangbind_interpreter sdl3_clangbind_aot sdl3_clangbind_missing_aot PROPERTIES TIMEOUT 30)
