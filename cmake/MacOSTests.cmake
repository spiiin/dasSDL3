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
foreach(script tests/peripherals tests/macos_msl dassdl3/sdl3_result dassdl3/sdl3_boost
        dassdl3/sdl3_init_boost dassdl3/sdl3_peripherals_boost dassdl3/sdl3_try
        dassdl3/sdl3_gpu_result dassdl3/sdl3_gpu_boost dassdl3/sdl3_gpu_shader_boost)
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
