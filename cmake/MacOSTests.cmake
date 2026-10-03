# Native Metal evidence without requiring the Windows SPIR-V/DXIL fixtures.
foreach(script gpu_transfer gpu_texture_transfer gpu_formats gpu_native_fences gpu_swapchain gpu_volume)
    add_test(NAME macos_metal_${script} COMMAND dasSDL3_runner
        "${CMAKE_SOURCE_DIR}/tests/${script}.das" --smoke-test)
    set_tests_properties(macos_metal_${script} PROPERTIES
        ENVIRONMENT "SDL_GPU_DRIVER=metal" TIMEOUT 90 RUN_SERIAL TRUE)
endforeach()
add_test(NAME macos_metal_msl COMMAND dasSDL3_runner "${CMAKE_SOURCE_DIR}/tests/macos_msl.das" --smoke-test)
set_tests_properties(macos_metal_msl PROPERTIES
    ENVIRONMENT "SDL_GPU_DRIVER=metal" TIMEOUT 90 RUN_SERIAL TRUE WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")

# Reuse the strict generator/runner, with the native library and saved Mac ABI.
foreach(script 42_gpu_shaders 43_gpu_graphics_pipeline 44_gpu_render_pass
        45_gpu_vertex_index_buffers 46_gpu_texture_uniform_bindings
        48_gpu_native_graphics 49_gpu_native_compute 86_gpu_renderer)
    add_test(NAME macos_metal_example_${script} COMMAND dasSDL3_runner
        "${CMAKE_SOURCE_DIR}/examples/${script}.das" --smoke-test)
    set_tests_properties(macos_metal_example_${script} PROPERTIES
        ENVIRONMENT "SDL_GPU_DRIVER=metal" TIMEOUT 90 RUN_SERIAL TRUE)
endforeach()

if(DASSDL3_WITH_SHADERCROSS)
    foreach(script 01_triangle 02_texture 03_uniforms 04_compute)
        add_test(NAME macos_metal_dsl_example_${script} COMMAND dasSDL3_libraries_runner
            "${CMAKE_SOURCE_DIR}/examples/gpu_dsl/${script}.das" --smoke-test)
        set_tests_properties(macos_metal_dsl_example_${script} PROPERTIES
            ENVIRONMENT "SDL_GPU_DRIVER=metal" TIMEOUT 90 RUN_SERIAL TRUE)
    endforeach()
    foreach(script metaballs raymarch mesh instancing bump hdr fontsdf lod stencil
            shadowvolumes shadowvolumes_scene)
        add_test(NAME macos_metal_bgfx_${script} COMMAND dasSDL3_libraries_runner
            "${CMAKE_SOURCE_DIR}/tests/bgfx_${script}.das" --smoke-test)
        set_tests_properties(macos_metal_bgfx_${script} PROPERTIES
            ENVIRONMENT "SDL_GPU_DRIVER=metal" TIMEOUT 120 RUN_SERIAL TRUE)
    endforeach()
endif()

add_executable(dasSDL3_macos_aot_tool "${CMAKE_SOURCE_DIR}/tests/clangbind_parity/aot_tool.cpp")
target_link_libraries(dasSDL3_macos_aot_tool PRIVATE dasSDL3)
target_compile_definitions(dasSDL3_macos_aot_tool PRIVATE
    DASSDL3_DAS_ROOT="${CMAKE_SOURCE_DIR}/third_party/daScript"
    DASSDL3_MODULE_ROOT="${CMAKE_SOURCE_DIR}/dassdl3")
add_executable(dasSDL3_macos_aot_runner "${CMAKE_SOURCE_DIR}/tests/clangbind_parity/aot_runner.cpp")
target_link_libraries(dasSDL3_macos_aot_runner PRIVATE dasSDL3)
target_compile_definitions(dasSDL3_macos_aot_runner PRIVATE
    DASSDL3_DAS_ROOT="${CMAKE_SOURCE_DIR}/third_party/daScript"
    DASSDL3_MODULE_ROOT="${CMAKE_SOURCE_DIR}/dassdl3")
set_target_properties(dasSDL3_macos_aot_tool dasSDL3_macos_aot_runner PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
file(GLOB_RECURSE _macos_aot_dependencies CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/dassdl3/*.das" "${CMAKE_SOURCE_DIR}/third_party/daScript/daslib/*.das")
foreach(script tests/peripherals tests/filesystem tests/macos_msl
        tests/gpu_transfer tests/gpu_texture_transfer tests/gpu_formats
        tests/gpu_native_fences tests/gpu_swapchain tests/gpu_volume
        dassdl3/sdl3_result dassdl3/sdl3_boost
        dassdl3/sdl3_init_boost dassdl3/sdl3_peripherals_boost dassdl3/sdl3_try
        dassdl3/sdl3_filesystem_boost dassdl3/sdl3_gpu_result dassdl3/sdl3_gpu_boost
        dassdl3/sdl3_gpu_shader_boost dassdl3/sdl3_gpu_transfer_boost
        dassdl3/sdl3_gpu_texture_transfer_boost dassdl3/sdl3_gpu_formats_boost
        dassdl3/sdl3_gpu_volume_boost dassdl3/sdl3_gpu_swapchain_boost)
    string(REPLACE "/" "_" name "${script}")
    set(output "${CMAKE_CURRENT_BINARY_DIR}/${name}.macos.aot.cpp")
    add_custom_command(OUTPUT "${output}"
        COMMAND dasSDL3_macos_aot_tool "${CMAKE_SOURCE_DIR}/${script}.das" "${output}"
        DEPENDS dasSDL3_macos_aot_tool "${CMAKE_SOURCE_DIR}/${script}.das" ${_macos_aot_dependencies}
        VERBATIM)
    target_sources(dasSDL3_macos_aot_runner PRIVATE "${output}")
endforeach()
add_test(NAME macos_peripherals_strict_aot COMMAND dasSDL3_macos_aot_runner
    "${CMAKE_SOURCE_DIR}/tests/peripherals.das")
set_tests_properties(macos_peripherals_strict_aot PROPERTIES
    ENVIRONMENT "SDL_VIDEODRIVER=dummy" TIMEOUT 60)
add_test(NAME macos_metal_msl_strict_aot COMMAND dasSDL3_macos_aot_runner
    "${CMAKE_SOURCE_DIR}/tests/macos_msl.das")
set_tests_properties(macos_metal_msl_strict_aot PROPERTIES
    ENVIRONMENT "SDL_GPU_DRIVER=metal" TIMEOUT 90 RUN_SERIAL TRUE WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")

add_test(NAME macos_filesystem_strict_aot COMMAND dasSDL3_macos_aot_runner
    "${CMAKE_SOURCE_DIR}/tests/filesystem.das")
set_tests_properties(macos_filesystem_strict_aot PROPERTIES TIMEOUT 60)
foreach(script gpu_transfer gpu_texture_transfer gpu_formats gpu_native_fences gpu_swapchain gpu_volume)
    add_test(NAME macos_metal_${script}_strict_aot COMMAND dasSDL3_macos_aot_runner
        "${CMAKE_SOURCE_DIR}/tests/${script}.das")
    set_tests_properties(macos_metal_${script}_strict_aot PROPERTIES
        ENVIRONMENT "SDL_GPU_DRIVER=metal" TIMEOUT 90 RUN_SERIAL TRUE
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
endforeach()
# This source deliberately has no generated/linked translation unit.
add_test(NAME macos_missing_strict_aot COMMAND ${Python3_EXECUTABLE}
    "${CMAKE_SOURCE_DIR}/tests/clangbind/expect_aot_failure.py"
    $<TARGET_FILE:dasSDL3_macos_aot_runner> "${CMAKE_SOURCE_DIR}/tests/macos_missing_aot.das")
set_tests_properties(macos_missing_strict_aot PROPERTIES TIMEOUT 60)

# Keep GUI/Metal evidence separate from checks suitable for a headless runner.
get_property(_macos_tests DIRECTORY PROPERTY TESTS)
foreach(test IN LISTS _macos_tests)
    if(test MATCHES "^macos_metal_")
        set_tests_properties(${test} PROPERTIES LABELS "macos-native")
    elseif(test MATCHES "^macos_(peripherals|filesystem|missing)_strict_aot$")
        set_tests_properties(${test} PROPERTIES LABELS "macos-headless")
    endif()
endforeach()
