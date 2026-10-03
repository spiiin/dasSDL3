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
list(APPEND _dsl_scripts
    examples/gpu/shader_support
    examples/gpu/shaders/metaballs_shaders
    examples/gpu/shaders/raymarch_shaders
    examples/gpu/shaders/bunny_shaders
    examples/gpu/shaders/cube_shaders
    examples/gpu/shaders/hdr_shaders
    examples/gpu/metaballs_app
    examples/gpu/raymarch_app
    examples/gpu/mesh_app
    examples/gpu/bgfx_support
    examples/gpu/cube_data
    examples/gpu/cubes_app
    examples/gpu/hdr_app
    examples/gpu/metaballs_field
    examples/gpu/metaballs_tables
    examples/gpu/mesh_data
    tests/bgfx_metaballs
    tests/bgfx_raymarch
    tests/bgfx_mesh
    tests/bgfx_instancing
    tests/bgfx_bump
    tests/bgfx_hdr
    tests/bgfx_capture
    tests/bgfx_cubes_checks
    dassdl3/sdl3_window_boost
    dassdl3/sdl3_events
    dassdl3/sdl3_iostream_boost
    dassdl3/sdl3_init_boost
    dassdl3/sdl3_gpu_pipeline_boost
    dassdl3/sdl3_gpu_sampler_boost)
file(GLOB_RECURSE _dsl_gpu_deps "${ROOT}/examples/gpu/*.das" "${ROOT}/tests/bgfx*.das")
list(APPEND _dsl_scripts
    third_party/daScript/daslib/math_bits third_party/daScript/daslib/math_boost
    examples/gpu/port_geometry examples/gpu/lod_app examples/gpu/stencil_support
    examples/gpu/stencil_scene_support examples/gpu/shaders/stencil_scene_shaders examples/gpu/stencil_app examples/gpu/shadowvolumes_geometry examples/gpu/shadowvolumes_app
    examples/gpu/shaders/lod_shaders examples/gpu/shaders/stencil_shaders examples/gpu/shaders/shadowvolume_shaders
    tests/bgfx_lod tests/bgfx_stencil tests/bgfx_shadowvolumes tests/bgfx_shadowvolumes_scene
    examples/gpu/shadowvolumes_scene examples/gpu/shadowvolumes_topology tests/benchmark_shadowvolumes tests/profile_shadowvolumes tests/benchmark_volume_cpu)
if(DASSDL3_TEST_TTF)
    list(APPEND _dsl_scripts examples/gpu/fontsdf_app examples/gpu/shaders/fontsdf_shaders
        tests/bgfx_fontsdf dassdl3/sdl3_ttf_boost)
endif()
