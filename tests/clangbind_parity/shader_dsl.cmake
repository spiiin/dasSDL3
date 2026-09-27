# Isolated AOT target: compile only the shader DSL and its runtime dependencies.
file(GLOB _dsl_boost_deps "${ROOT}/dassdl3/*.das")
file(GLOB _dsl_spirv_deps "${ROOT}/third_party/daScript/modules/dasSpirv/spirv/*.das")
file(GLOB _dsl_example_deps "${ROOT}/examples/gpu_dsl/*.das")
file(GLOB _dsl_test_deps "${ROOT}/tests/shader_dsl*.das")
set(_dsl_scripts tests/shader_dsl_resources tests/shader_dsl_storage tests/shader_dsl_resource_gpu
    tests/shader_dsl_resource_shaders tests/shader_dsl_resource_pixels
    dassdl3/sdl3_shader_resources dassdl3/sdl3_shader_storage dassdl3/sdl3_shader_storage_spirv
    third_party/daScript/modules/dasSpirv/spirv/spirv_dis
    third_party/daScript/modules/dasSpirv/spirv/spirv_builder
    third_party/daScript/modules/dasSpirv/spirv/spirv_grammar tests/shader_dsl_compute examples/gpu_dsl/04_compute examples/gpu_dsl/compute_shaders
    examples/gpu_dsl/compute_support dassdl3/sdl3_shader_compute tests/shader_dsl_uniforms tests/shader_dsl_uniform_pixels tests/shader_dsl_uniform_gpu
    examples/gpu_dsl/uniform_shaders examples/gpu_dsl/03_uniforms dassdl3/sdl3_shader_uniforms tests/shader_dsl_texture tests/shader_dsl_texture_pixels examples/gpu_dsl/texture_shaders
    examples/gpu_dsl/texture_support examples/gpu_dsl/02_texture tests/shader_dsl tests/shader_dsl_pixels examples/gpu_dsl/dsl_shaders examples/gpu_dsl/01_triangle
    dassdl3/sdl3_shader_dsl dassdl3/sdl3_result dassdl3/sdl3_boost dassdl3/sdl3_gpu_boost
    dassdl3/sdl3_gpu_result dassdl3/sdl3_gpu_shader_boost dassdl3/sdl3_gpu_native_boost
    third_party/daScript/modules/dasSpirv/spirv/spirv_reflect third_party/daScript/daslib/shader_lingua_franca)
if(DASSDL3_TEST_SHADERCROSS)
    list(APPEND _dsl_scripts tests/shader_dsl_resource_gpu_cross tests/shader_dsl_compute_cross tests/shader_dsl_uniform_gpu_cross tests/shader_dsl_texture_cross tests/shader_dsl_cross dassdl3/sdl3_shader_dsl_cross dassdl3/sdl3_shadercross_boost)
endif()
set(_dsl_outputs)
foreach(script IN LISTS _dsl_scripts)
    string(REPLACE "/" "_" name "${script}")
    set(output "${CMAKE_CURRENT_BINARY_DIR}/dsl_${name}.aot.cpp")
    add_custom_command(OUTPUT "${output}"
        COMMAND parity_aot_tool "${ROOT}/${script}.das" "${output}"
        DEPENDS parity_aot_tool ${_dsl_boost_deps} ${_dsl_spirv_deps} ${_dsl_example_deps} ${_dsl_test_deps}
            "${ROOT}/tests/shader_dsl_pixels.das" "${ROOT}/examples/gpu_dsl/dsl_shaders.das" "${ROOT}/${script}.das"
        VERBATIM)
    list(APPEND _dsl_outputs "${output}")
endforeach()
add_executable(shader_dsl_aot_runner aot_runner.cpp ${_dsl_outputs})
target_link_libraries(shader_dsl_aot_runner PRIVATE cppgenbind_module)
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
