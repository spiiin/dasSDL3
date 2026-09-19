set(_binding_default python)
if(WIN32 AND MSVC AND CMAKE_SIZEOF_VOID_P EQUAL 8 AND CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "x64")
    set(_binding_default clangbind)
endif()
set(DASSDL3_BINDING_BACKEND "${_binding_default}" CACHE STRING "Binding snapshots: clangbind or python")
set_property(CACHE DASSDL3_BINDING_BACKEND PROPERTY STRINGS clangbind python)
if(NOT DASSDL3_BINDING_BACKEND MATCHES "^(clangbind|python)$")
    message(FATAL_ERROR "Unknown DASSDL3_BINDING_BACKEND: ${DASSDL3_BINDING_BACKEND}")
endif()
if(DASSDL3_BINDING_BACKEND STREQUAL "clangbind" AND NOT _binding_default STREQUAL "clangbind")
    message(FATAL_ERROR "CppGenBind snapshots currently support only MSVC Windows x64")
endif()
message(STATUS "dasSDL3 binding backend: ${DASSDL3_BINDING_BACKEND} (saved snapshots)")
add_library(dasSDL3 STATIC module_sdl3.cpp)
if(DASSDL3_BINDING_BACKEND STREQUAL "clangbind")
    target_compile_definitions(dasSDL3 PRIVATE
        DASSDL3_TYPES_INCLUDE="generated/clangbind/sdl3_types.inc"
        DASSDL3_REGISTRATION_INCLUDE="generated/clangbind/sdl3_functions.inc")
endif()
target_include_directories(dasSDL3 PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/third_party/daScript/include
    ${CMAKE_SOURCE_DIR}/third_party/daScript/3rdparty/fmt/include)
target_link_libraries(dasSDL3 PUBLIC libDaScript SDL3::SDL3)
target_compile_features(dasSDL3 PUBLIC cxx_std_17)
if(WIN32)
    # Match daScript's ABI and exception handling configuration.
    target_compile_definitions(dasSDL3 PUBLIC DAS_ENABLE_EXCEPTIONS=1)
endif()

add_executable(dasSDL3_runner runner.cpp)
target_link_libraries(dasSDL3_runner PRIVATE dasSDL3)
target_compile_definitions(dasSDL3_runner PRIVATE DASSDL3_DAS_ROOT="${CMAKE_SOURCE_DIR}/third_party/daScript")
target_compile_definitions(dasSDL3_runner PRIVATE DASSDL3_MODULE_ROOT="${CMAKE_SOURCE_DIR}/dassdl3")
set_target_properties(dasSDL3_runner PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/bin/assets")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/bin/assets/shaders")
foreach(shader triangle.vert.spv triangle.frag.spv triangle.vert.dxil triangle.frag.dxil triangle.vert.hlsl)
    configure_file(${CMAKE_SOURCE_DIR}/examples/assets/shaders/${shader}
        ${CMAKE_BINARY_DIR}/bin/assets/shaders/${shader} COPYONLY)
endforeach()
configure_file(${CMAKE_SOURCE_DIR}/examples/assets/checker.bmp
    ${CMAKE_BINARY_DIR}/bin/assets/checker.bmp COPYONLY)
configure_file(${CMAKE_SOURCE_DIR}/examples/assets/tone.wav
    ${CMAKE_BINARY_DIR}/bin/assets/tone.wav COPYONLY)

option(DASSDL3_ENABLE_GENERATORS "Enable developer binding generation and freshness checks" OFF)
if(DASSDL3_ENABLE_GENERATORS)
find_package(Python3 REQUIRED COMPONENTS Interpreter)
if(BUILD_TESTING)
    add_test(NAME sdl3_triangle_assets COMMAND ${Python3_EXECUTABLE} -B ${CMAKE_SOURCE_DIR}/tests/test_triangle_assets.py)
endif()
if(DASSDL3_BINDING_BACKEND STREQUAL "clangbind")
    set(DASSDL3_GENERATOR_DASLANG "" CACHE FILEPATH "daslang executable with dasClangBind module")
    set(DASSDL3_LLVM_SDK "" CACHE PATH "LLVM SDK for binding generation")
    if(NOT EXISTS "${DASSDL3_GENERATOR_DASLANG}" OR NOT EXISTS "${DASSDL3_LLVM_SDK}/lib/clang/22/include/stddef.h")
        message(FATAL_ERROR "Set DASSDL3_GENERATOR_DASLANG and DASSDL3_LLVM_SDK; see docs/clangbind-production.md")
    endif()
    set(_generate_command ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/run_clangbind_parity.py
        --snapshot --daslang ${DASSDL3_GENERATOR_DASLANG} --sdk ${DASSDL3_LLVM_SDK}
        --sdl-include ${sdl3_SOURCE_DIR}/include --output ${CMAKE_CURRENT_SOURCE_DIR}/generated/clangbind)
    add_custom_target(generate_bindings COMMAND ${_generate_command}
        COMMENT "Updating saved CppGenBind bindings")
    if(BUILD_TESTING)
        add_test(NAME bindings_up_to_date COMMAND ${_generate_command} --check)
    endif()
endif()
find_program(DASSDL3_CLANG_EXECUTABLE NAMES clang)
if(Python3_FOUND AND DASSDL3_CLANG_EXECUTABLE)
    if(DASSDL3_BINDING_BACKEND STREQUAL "python")
    add_custom_target(generate_bindings
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/generate_bindings.py
            --clang ${DASSDL3_CLANG_EXECUTABLE} --sdl-include ${sdl3_SOURCE_DIR}/include
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Generating SDL3 bindings from Clang AST")
    if(BUILD_TESTING)
        add_test(NAME bindings_up_to_date
            COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/generate_bindings.py
                --clang ${DASSDL3_CLANG_EXECUTABLE} --sdl-include ${sdl3_SOURCE_DIR}/include --check)
    endif()
    endif()
    if(BUILD_TESTING)
        if(WIN32)
            # This committed snapshot deliberately describes one target profile.
            add_test(NAME sdl3_api_inventory
                COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/inventory_api.py
                    --clang ${DASSDL3_CLANG_EXECUTABLE} --sdl-include ${sdl3_SOURCE_DIR}/include --check)
            add_test(NAME sdl3_api_inventory_contracts
                COMMAND ${Python3_EXECUTABLE} -B ${CMAKE_SOURCE_DIR}/tests/test_api_inventory.py
                    --clang ${DASSDL3_CLANG_EXECUTABLE})
            set_tests_properties(sdl3_api_inventory sdl3_api_inventory_contracts PROPERTIES TIMEOUT 60)
        endif()
    endif()
endif()
endif()
if(BUILD_TESTING)
    target_compile_definitions(dasSDL3 PRIVATE DASSDL3_TESTING=1)
    # Optional tooling probe; never needed to consume the saved bindings.
    if(WIN32 AND TARGET dasModuleClangBind AND TARGET daslang AND PATH_TO_LIBCLANG)
        add_test(NAME sdl3_clangbind_probe
            COMMAND $<TARGET_FILE:daslang> ${CMAKE_SOURCE_DIR}/tools/clangbind_probe.das
                -- ${sdl3_SOURCE_DIR}/include ${PATH_TO_LIBCLANG})
        add_test(NAME sdl3_clangbind_preprocessor
            COMMAND $<TARGET_FILE:daslang>
                ${CMAKE_SOURCE_DIR}/third_party/daScript/modules/dasClangBind/tests/test_const_preproc.das)
        set_tests_properties(sdl3_clangbind_probe sdl3_clangbind_preprocessor
            PROPERTIES TIMEOUT 60 WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
    endif()
    add_test(NAME sdl3_audio COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/audio.das --smoke-test)
    add_test(NAME sdl3_pixels COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/pixels.das --smoke-test)
    add_test(NAME sdl3_geometry COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/geometry.das --smoke-test)
    add_test(NAME sdl3_gpu_state COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/gpu_state.das --smoke-test)
    add_test(NAME sdl3_gpu_triangle COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/gpu_triangle.das --smoke-test)
    add_test(NAME sdl3_gpu_triangle_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/gpu_triangle.das --smoke-test)
    set_tests_properties(sdl3_gpu_triangle sdl3_gpu_triangle_example PROPERTIES TIMEOUT 60 SKIP_RETURN_CODE 77)
    foreach(driver vulkan direct3d12)
        if(driver STREQUAL "vulkan" OR WIN32)
            add_test(NAME sdl3_gpu_triangle_${driver} COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/gpu_triangle.das --smoke-test)
            set_tests_properties(sdl3_gpu_triangle_${driver} PROPERTIES TIMEOUT 60 SKIP_RETURN_CODE 77 ENVIRONMENT "SDL_GPU_DRIVER=${driver}")
        endif()
    endforeach()
    add_test(NAME sdl3_gpu_windows COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/gpu_windows.das --smoke-test)
    set_tests_properties(sdl3_gpu_windows PROPERTIES TIMEOUT 60 SKIP_RETURN_CODE 77)
    add_test(NAME sdl3_gpu COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/gpu.das --smoke-test)
    add_test(NAME sdl3_gpu_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/gpu_clear.das --smoke-test)
    set_tests_properties(sdl3_gpu_state PROPERTIES TIMEOUT 30)
    set_tests_properties(sdl3_gpu sdl3_gpu_example PROPERTIES TIMEOUT 60 SKIP_RETURN_CODE 77)
    add_test(NAME sdl3_geometry_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/geometry.das --smoke-test)
    set_tests_properties(sdl3_geometry sdl3_geometry_example PROPERTIES TIMEOUT 30)
    add_test(NAME sdl3_streaming_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/streaming_texture.das --smoke-test)
    add_test(NAME sdl3_target_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/render_target.das --smoke-test)
    set_tests_properties(sdl3_pixels sdl3_streaming_example sdl3_target_example PROPERTIES TIMEOUT 30)
    add_test(NAME sdl3_audio_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/audio.das --smoke-test)
    set_tests_properties(sdl3_audio sdl3_audio_example PROPERTIES TIMEOUT 30 ENVIRONMENT "SDL_AUDIO_DRIVER=dummy")
    add_test(NAME sdl3_daslang_hello COMMAND daslang_static ${CMAKE_SOURCE_DIR}/examples/hello.das)
    add_test(NAME sdl3_bindings COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/bindings.das --smoke-test)
    add_test(NAME sdl3_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/square.das --smoke-test)
    add_test(NAME sdl3_boost COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/boost.das --smoke-test)
    add_test(NAME sdl3_textures_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/textures.das --smoke-test)
    set_tests_properties(sdl3_textures_example PROPERTIES TIMEOUT 30)
    add_test(NAME sdl3_textures COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/textures.das --smoke-test)
    add_test(NAME sdl3_input COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/input.das --smoke-test)
    add_test(NAME sdl3_input_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/input.das --smoke-test)
    set_tests_properties(sdl3_input sdl3_input_example PROPERTIES TIMEOUT 30)
    set_tests_properties(sdl3_textures PROPERTIES TIMEOUT 30)
    set_tests_properties(sdl3_bindings sdl3_example sdl3_boost PROPERTIES TIMEOUT 30)
endif()
