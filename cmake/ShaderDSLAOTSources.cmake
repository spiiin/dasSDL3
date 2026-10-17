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
    third_party/daScript/modules/dasSpirv/spirv/spirv_builtins
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
    examples/gpu_port_bgfx/common/shader_support
    examples/gpu_port_bgfx/example_01_metaballs/shaders/metaballs_shaders
    examples/gpu_port_bgfx/example_02_raymarch/shaders/raymarch_shaders
    examples/gpu_port_bgfx/example_03_mesh/shaders/bunny_shaders
    examples/gpu_port_bgfx/common/cubes/shaders/cube_shaders
    examples/gpu_port_bgfx/example_06_hdr/shaders/hdr_shaders
    examples/gpu_port_bgfx/example_01_metaballs/metaballs_app
    examples/gpu_port_bgfx/example_02_raymarch/raymarch_app
    examples/gpu_port_bgfx/example_03_mesh/mesh_app
    examples/gpu_port_bgfx/common/bgfx_support
    examples/gpu_port_bgfx/common/cubes/cube_data
    examples/gpu_port_bgfx/common/cubes/cubes_app
    examples/gpu_port_bgfx/example_06_hdr/hdr_app
    examples/gpu_port_bgfx/example_01_metaballs/metaballs_field
    examples/gpu_port_bgfx/example_01_metaballs/metaballs_tables
    examples/gpu_port_bgfx/common/mesh_data
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
file(GLOB_RECURSE _dsl_gpu_deps "${ROOT}/examples/gpu_port_bgfx/*.das" "${ROOT}/tests/bgfx*.das")
list(APPEND _dsl_scripts
    third_party/daScript/daslib/math_bits third_party/daScript/daslib/math_boost
    examples/gpu_port_bgfx/common/port_geometry examples/gpu_port_bgfx/example_08_lod/lod_app examples/gpu_port_bgfx/common/stencil/stencil_support
    examples/gpu_port_bgfx/common/stencil/stencil_scene_support examples/gpu_port_bgfx/common/stencil/shaders/stencil_scene_shaders examples/gpu_port_bgfx/example_09_stencil/stencil_app examples/gpu_port_bgfx/example_10_shadowvolumes/shadowvolumes_geometry examples/gpu_port_bgfx/example_10_shadowvolumes/shadowvolumes_app
    examples/gpu_port_bgfx/example_08_lod/shaders/lod_shaders examples/gpu_port_bgfx/common/stencil/shaders/stencil_shaders examples/gpu_port_bgfx/example_10_shadowvolumes/shaders/shadowvolume_shaders
    tests/bgfx_lod tests/bgfx_stencil tests/bgfx_shadowvolumes tests/bgfx_shadowvolumes_scene
    examples/gpu_port_bgfx/example_10_shadowvolumes/shadowvolumes_scene examples/gpu_port_bgfx/example_10_shadowvolumes/shadowvolumes_topology tests/benchmark_shadowvolumes tests/profile_shadowvolumes tests/benchmark_volume_cpu)
if(DASSDL3_TEST_TTF)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/example_07_fontsdf/fontsdf_app examples/gpu_port_bgfx/example_07_fontsdf/shaders/fontsdf_shaders
        tests/bgfx_fontsdf dassdl3/sdl3_ttf_boost)
endif()

list(APPEND _dsl_scripts
    examples/gpu_port_bgfx/common/multipass_support
    examples/gpu_port_bgfx/common/shadowmaps/shadowmaps_app examples/gpu_port_bgfx/common/shadowmaps/shaders/shadowmap_shaders
    examples/gpu_port_bgfx/example_13_ibl/ibl_app examples/gpu_port_bgfx/example_13_ibl/shaders/ibl_shaders
    examples/gpu_port_bgfx/example_14_oit/oit_app examples/gpu_port_bgfx/example_14_oit/shaders/oit_shaders
    examples/gpu_port_bgfx/example_15_deferred/deferred_app examples/gpu_port_bgfx/example_15_deferred/shaders/deferred_shaders
    tests/bgfx_multipass_checks
    tests/bgfx_shadowmaps_simple tests/bgfx_shadowmaps tests/bgfx_ibl tests/bgfx_oit tests/bgfx_deferred)

# bgfx 23/24/26/27/28 ports: application modules and regression entry points.
list(APPEND _dsl_scripts
    examples/gpu_port_bgfx/common/compute_support
    tests/bgfx_buffer_checks
    examples/gpu_port_bgfx/example_16_vectordisplay/vectordisplay_app
    examples/gpu_port_bgfx/example_16_vectordisplay/shaders/vectordisplay_shaders
    tests/bgfx_vectordisplay
    examples/gpu_port_bgfx/example_17_nbody/nbody_app
    examples/gpu_port_bgfx/example_17_nbody/shaders/nbody_shaders
    tests/bgfx_nbody
    examples/gpu_port_bgfx/example_18_occlusion/occlusion_app
    examples/gpu_port_bgfx/example_18_occlusion/shaders/occlusion_shaders
    tests/bgfx_occlusion
    examples/gpu_port_bgfx/example_19_terrain/terrain_app
    examples/gpu_port_bgfx/example_19_terrain/shaders/terrain_shaders
    tests/bgfx_terrain
    examples/gpu_port_bgfx/example_20_wireframe/wireframe_app
    examples/gpu_port_bgfx/example_20_wireframe/shaders/wireframe_shaders
    tests/bgfx_wireframe
    examples/gpu_port_bgfx/example_16_vectordisplay/simplex_font)

# bgfx 30-34: picking, reflective shadow maps, particles, POM, vertex streams.
list(APPEND _dsl_scripts
    examples/gpu_port_bgfx/example_21_picking/picking_app
    examples/gpu_port_bgfx/example_21_picking/shaders/picking_shaders
    tests/bgfx_picking
    examples/gpu_port_bgfx/example_22_rsm/rsm_app
    examples/gpu_port_bgfx/example_22_rsm/shaders/rsm_shaders
    tests/bgfx_rsm
    examples/gpu_port_bgfx/example_23_particles/particles_app
    examples/gpu_port_bgfx/example_23_particles/shaders/particles_shaders
    tests/bgfx_particles
    examples/gpu_port_bgfx/example_24_pom/pom_app
    examples/gpu_port_bgfx/example_24_pom/shaders/pom_shaders
    tests/bgfx_pom
    examples/gpu_port_bgfx/example_25_mvs/mvs_app
    examples/gpu_port_bgfx/example_25_mvs/shaders/mvs_shaders
    tests/bgfx_mvs
)

# bgfx 35-39 ports.
list(APPEND _dsl_scripts
    examples/gpu_port_bgfx/example_26_dynamic/dynamic_app
    examples/gpu_port_bgfx/example_26_dynamic/shaders/dynamic_shaders
    tests/bgfx_dynamic
    examples/gpu_port_bgfx/example_27_sky/sky_app
    examples/gpu_port_bgfx/example_27_sky/shaders/sky_shaders
    tests/bgfx_sky
    examples/gpu_port_bgfx/example_28_gpudrivenrendering/gpudrivenrendering_app
    examples/gpu_port_bgfx/example_28_gpudrivenrendering/shaders/gpudrivenrendering_shaders
    tests/bgfx_gpudrivenrendering
    examples/gpu_port_bgfx/example_29_bloom/bloom_app
    examples/gpu_port_bgfx/example_29_bloom/shaders/bloom_shaders
    tests/bgfx_bloom
    examples/gpu_port_bgfx/example_30_assao/assao_app
    examples/gpu_port_bgfx/example_30_assao/shaders/assao_shaders
    tests/bgfx_assao
)

if(DASSDL3_TEST_IMGUI)
    list(APPEND _dsl_scripts dassdl3/sdl3_imgui
        examples/gpu_port_bgfx/example_30_assao/assao_gui
        examples/gpu_port_bgfx/example_30_assao/main tests/bgfx_assao_gui)
endif()

# bgfx 40-45 have ImGui settings panels; SVT additionally decodes streamed PNG pages.
if(DASSDL3_TEST_IMGUI)
    list(APPEND _dsl_scripts
        examples/gpu_port_bgfx/common/imgui_gpu
        examples/gpu_port_bgfx/common/post_scene/scene
        examples/gpu_port_bgfx/common/post_scene/scene_shaders)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/example_32_tess/tess_app examples/gpu_port_bgfx/example_32_tess/shaders/tess_shaders examples/gpu_port_bgfx/example_32_tess/main tests/bgfx_tess)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/example_33_bunnylod/bunnylod_app examples/gpu_port_bgfx/example_33_bunnylod/shaders/bunnylod_shaders examples/gpu_port_bgfx/example_33_bunnylod/main tests/bgfx_bunnylod)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/example_34_denoise/denoise_app examples/gpu_port_bgfx/example_34_denoise/shaders/denoise_shaders examples/gpu_port_bgfx/example_34_denoise/main tests/bgfx_denoise)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/example_35_sss/sss_app examples/gpu_port_bgfx/example_35_sss/shaders/sss_shaders examples/gpu_port_bgfx/example_35_sss/main tests/bgfx_sss)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/example_36_bokeh/bokeh_app examples/gpu_port_bgfx/example_36_bokeh/shaders/bokeh_shaders examples/gpu_port_bgfx/example_36_bokeh/main tests/bgfx_bokeh)
    if(DASSDL3_TEST_IMAGE)
        list(APPEND _dsl_scripts dassdl3/sdl3_image_boost dassdl3/sdl3_surface_pixels_boost dassdl3/sdl3_record_access
            examples/gpu_port_bgfx/example_31_svt/svt_app examples/gpu_port_bgfx/example_31_svt/shaders/svt_shaders
            examples/gpu_port_bgfx/example_31_svt/main tests/bgfx_svt)
    endif()
endif()

# bgfx 47-49 with ImGui panels.
if(DASSDL3_TEST_IMGUI)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/common/texture_payload examples/gpu_port_bgfx/example_37_pixelformats/format_catalog)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/example_37_pixelformats/pixelformats_app examples/gpu_port_bgfx/example_37_pixelformats/main examples/gpu_port_bgfx/example_37_pixelformats/shaders/pixelformats_shaders tests/bgfx_pixelformats)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/example_38_drawindirect/drawindirect_app examples/gpu_port_bgfx/example_38_drawindirect/main examples/gpu_port_bgfx/example_38_drawindirect/shaders/drawindirect_shaders tests/bgfx_drawindirect)
    list(APPEND _dsl_scripts examples/gpu_port_bgfx/example_39_hextile/hextile_app examples/gpu_port_bgfx/example_39_hextile/main examples/gpu_port_bgfx/example_39_hextile/shaders/hextile_shaders tests/bgfx_hextile)
endif()
