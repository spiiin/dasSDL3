include("${ROOT}/cmake/ShaderDSLAOTSources.cmake")
set(_dsl_outputs)
foreach(script IN LISTS _dsl_scripts)
    string(REPLACE "/" "_" name "${script}")
    set(output "${CMAKE_CURRENT_BINARY_DIR}/dsl_${name}.aot.cpp")
    add_custom_command(OUTPUT "${output}"
        COMMAND parity_aot_tool "${ROOT}/${script}.das" "${output}"
        DEPENDS parity_aot_tool ${_dsl_gpu_deps} ${_dsl_boost_deps} ${_dsl_spirv_deps} ${_dsl_example_deps} ${_dsl_test_deps}
            "${ROOT}/tests/shader_dsl_pixels.das" "${ROOT}/examples/gpu_dsl/dsl_shaders.das" "${ROOT}/${script}.das"
        VERBATIM)
    list(APPEND _dsl_outputs "${output}")
endforeach()
add_executable(shader_dsl_aot_runner aot_runner.cpp ${_dsl_outputs})
target_link_libraries(shader_dsl_aot_runner PRIVATE cppgenbind_module)
if(DASSDL3_TEST_TTF)
    target_link_libraries(shader_dsl_aot_runner PRIVATE ttf_test_dependencies)
endif()
foreach(backend baseline cppgenbind shader_dsl_aot)
    set(args --smoke-test)
    if(backend STREQUAL "shader_dsl_aot")
        set(args)
    endif()
    foreach(script tests/shader_dsl_resources tests/shader_dsl_storage tests/shader_dsl_resource_gpu tests/shader_dsl_compute examples/gpu_dsl/04_compute tests/shader_dsl_uniforms tests/shader_dsl_uniform_gpu examples/gpu_dsl/03_uniforms tests/shader_dsl tests/shader_dsl_texture examples/gpu_dsl/01_triangle examples/gpu_dsl/02_texture)
        string(REPLACE "/" "_" name "${script}")
        add_test(NAME shader_dsl_${backend}_${name} COMMAND ${backend}_runner "${ROOT}/${script}.das" ${args})
        set_tests_properties(shader_dsl_${backend}_${name} PROPERTIES TIMEOUT 90 RUN_SERIAL TRUE
            FAIL_REGULAR_EXPRESSION "VUID-;Validation Error;D3D12 ERROR;D3D12 CORRUPTION")
    endforeach()
endforeach()

if(DASSDL3_TEST_SHADERCROSS)
    target_link_libraries(shader_dsl_aot_runner PRIVATE shadercross_test_dependencies)
    foreach(backend baseline cppgenbind shader_dsl_aot)
        set(args --smoke-test)
        if(backend STREQUAL "shader_dsl_aot")
            set(args)
        endif()
        add_test(NAME shader_dsl_${backend}_resource_gpu_cross COMMAND ${backend}_runner "${ROOT}/tests/shader_dsl_resource_gpu_cross.das" ${args})
        set_tests_properties(shader_dsl_${backend}_resource_gpu_cross PROPERTIES TIMEOUT 90 RUN_SERIAL TRUE
            FAIL_REGULAR_EXPRESSION "VUID-;Validation Error;D3D12 ERROR;D3D12 CORRUPTION")
        add_test(NAME shader_dsl_${backend}_compute_cross COMMAND ${backend}_runner "${ROOT}/tests/shader_dsl_compute_cross.das" ${args})
        set_tests_properties(shader_dsl_${backend}_compute_cross PROPERTIES TIMEOUT 90 RUN_SERIAL TRUE
            FAIL_REGULAR_EXPRESSION "VUID-;Validation Error;D3D12 ERROR;D3D12 CORRUPTION")
        add_test(NAME shader_dsl_${backend}_uniform_cross COMMAND ${backend}_runner "${ROOT}/tests/shader_dsl_uniform_gpu_cross.das" ${args})
        set_tests_properties(shader_dsl_${backend}_uniform_cross PROPERTIES TIMEOUT 90 RUN_SERIAL TRUE
            FAIL_REGULAR_EXPRESSION "VUID-;Validation Error;D3D12 ERROR;D3D12 CORRUPTION")
        add_test(NAME shader_dsl_${backend}_texture_cross COMMAND ${backend}_runner "${ROOT}/tests/shader_dsl_texture_cross.das" ${args})
        set_tests_properties(shader_dsl_${backend}_texture_cross PROPERTIES TIMEOUT 90 RUN_SERIAL TRUE
            FAIL_REGULAR_EXPRESSION "VUID-;Validation Error;D3D12 ERROR;D3D12 CORRUPTION")
        add_test(NAME shader_dsl_${backend}_cross COMMAND ${backend}_runner "${ROOT}/tests/shader_dsl_cross.das" ${args})
        set_tests_properties(shader_dsl_${backend}_cross PROPERTIES TIMEOUT 90 RUN_SERIAL TRUE
            FAIL_REGULAR_EXPRESSION "VUID-;Validation Error;D3D12 ERROR;D3D12 CORRUPTION")
    endforeach()
endif()
