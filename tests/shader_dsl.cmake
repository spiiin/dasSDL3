if(BUILD_TESTING)
    add_test(NAME shader_dsl_pixels COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl.das --smoke-test)
    add_test(NAME shader_dsl_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/gpu_dsl/01_triangle.das --smoke-test)
    add_test(NAME shader_dsl_texture COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_texture.das --smoke-test)
    add_test(NAME shader_dsl_texture_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/gpu_dsl/02_texture.das --smoke-test)
    add_test(NAME shader_dsl_uniform_bytes COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_uniforms.das --smoke-test)
    add_test(NAME shader_dsl_uniform_gpu COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_uniform_gpu.das --smoke-test)
    add_test(NAME shader_dsl_uniform_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/gpu_dsl/03_uniforms.das --smoke-test)
    add_test(NAME shader_dsl_compute COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_compute.das --smoke-test)
    add_test(NAME shader_dsl_compute_example COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/examples/gpu_dsl/04_compute.das --smoke-test)
    add_test(NAME shader_dsl_resources COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_resources.das --smoke-test)
    add_test(NAME shader_dsl_storage COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_storage.das --smoke-test)
    add_test(NAME shader_dsl_resource_gpu COMMAND dasSDL3_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_resource_gpu.das --smoke-test)
    set_tests_properties(shader_dsl_resources shader_dsl_storage shader_dsl_resource_gpu shader_dsl_compute shader_dsl_compute_example shader_dsl_pixels shader_dsl_example shader_dsl_texture shader_dsl_texture_example shader_dsl_uniform_bytes shader_dsl_uniform_gpu shader_dsl_uniform_example PROPERTIES TIMEOUT 90 RUN_SERIAL TRUE
        FAIL_REGULAR_EXPRESSION "VUID-;Validation Error;D3D12 ERROR;D3D12 CORRUPTION")
    if(DASSDL3_WITH_SHADERCROSS)
        add_test(NAME shader_dsl_cross COMMAND dasSDL3_libraries_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_cross.das --smoke-test)
        add_test(NAME shader_dsl_texture_cross COMMAND dasSDL3_libraries_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_texture_cross.das --smoke-test)
        add_test(NAME shader_dsl_uniform_cross COMMAND dasSDL3_libraries_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_uniform_gpu_cross.das --smoke-test)
        add_test(NAME shader_dsl_compute_cross COMMAND dasSDL3_libraries_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_compute_cross.das --smoke-test)
        add_test(NAME shader_dsl_resource_gpu_cross COMMAND dasSDL3_libraries_runner ${CMAKE_SOURCE_DIR}/tests/shader_dsl_resource_gpu_cross.das --smoke-test)
        set_tests_properties(shader_dsl_resource_gpu_cross shader_dsl_compute_cross shader_dsl_uniform_cross shader_dsl_cross shader_dsl_texture_cross PROPERTIES TIMEOUT 90 RUN_SERIAL TRUE
            FAIL_REGULAR_EXPRESSION "VUID-;Validation Error;D3D12 ERROR;D3D12 CORRUPTION")
    endif()
endif()

if(BUILD_TESTING AND Python3_EXECUTABLE AND EXISTS "${CMAKE_SOURCE_DIR}/third_party/daScript/bin/daslang.exe")
    find_program(DASSDL3_SPIRV_VAL NAMES spirv-val HINTS "$ENV{VULKAN_SDK}/Bin")
    set(_dsl_validator)
    if(DASSDL3_SPIRV_VAL)
        set(_dsl_validator --spirv-val "${DASSDL3_SPIRV_VAL}")
    endif()
    add_test(NAME shader_dsl_compiler COMMAND "${Python3_EXECUTABLE}"
        "${CMAKE_SOURCE_DIR}/tests/test_shader_dsl_compile.py"
        --daslang "${CMAKE_SOURCE_DIR}/third_party/daScript/bin/daslang.exe" ${_dsl_validator})
    set_tests_properties(shader_dsl_compiler PROPERTIES TIMEOUT 90)
endif()

if(BUILD_TESTING AND Python3_EXECUTABLE)
    add_test(NAME shader_dsl_uniform_negative COMMAND "${Python3_EXECUTABLE}"
        "${CMAKE_SOURCE_DIR}/tests/test_shader_dsl_uniform_negative.py" --runner $<TARGET_FILE:dasSDL3_runner>)
    set_tests_properties(shader_dsl_uniform_negative PROPERTIES TIMEOUT 90)
endif()

if(BUILD_TESTING AND Python3_EXECUTABLE)
    add_test(NAME shader_dsl_resources_compiler COMMAND "${Python3_EXECUTABLE}"
        "${CMAKE_SOURCE_DIR}/tests/test_shader_dsl_resources.py" --runner $<TARGET_FILE:dasSDL3_runner> ${_dsl_validator})
    set_tests_properties(shader_dsl_resources_compiler PROPERTIES TIMEOUT 120)
endif()

if(BUILD_TESTING AND Python3_EXECUTABLE)
    add_test(NAME shader_dsl_gpu_examples_compiler COMMAND "${Python3_EXECUTABLE}"
        "${CMAKE_SOURCE_DIR}/tests/test_gpu_examples_dsl.py" --runner $<TARGET_FILE:dasSDL3_runner> ${_dsl_validator})
    set_tests_properties(shader_dsl_gpu_examples_compiler PROPERTIES TIMEOUT 180)
endif()
