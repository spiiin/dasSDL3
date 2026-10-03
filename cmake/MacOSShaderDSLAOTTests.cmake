# Keep source selection local; the shared list also serves Windows parity.
function(dassdl3_add_macos_shader_dsl_aot)
    set(ROOT "${PROJECT_SOURCE_DIR}")
    set(DASSDL3_TEST_SHADERCROSS ON)
    set(DASSDL3_TEST_TTF ${DASSDL3_WITH_TTF})
    include("${ROOT}/cmake/ShaderDSLAOTSources.cmake")
    list(APPEND _dsl_scripts examples/gpu_dsl/backend_support)
    add_executable(dasSDL3_macos_shader_dsl_aot_runner
        "${ROOT}/tests/clangbind_parity/aot_runner.cpp")
    get_target_property(links dasSDL3_libraries_runner LINK_LIBRARIES)
    get_target_property(definitions dasSDL3_libraries_runner COMPILE_DEFINITIONS)
    target_link_libraries(dasSDL3_macos_shader_dsl_aot_runner PRIVATE ${links})
    target_compile_definitions(dasSDL3_macos_shader_dsl_aot_runner PRIVATE ${definitions}
        DASSDL3_AOT_LINK_CHECK=1)
    set_target_properties(dasSDL3_macos_shader_dsl_aot_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
    file(GLOB_RECURSE dependencies CONFIGURE_DEPENDS
        "${ROOT}/dassdl3/*.das" "${ROOT}/third_party/daScript/daslib/*.das"
        "${ROOT}/third_party/daScript/modules/dasSpirv/spirv/*.das"
        "${ROOT}/examples/gpu/*.das" "${ROOT}/examples/gpu_dsl/*.das"
        "${ROOT}/tests/shader_dsl*.das" "${ROOT}/tests/bgfx*.das")
    # Include shared boost imports, including optional backend selection imports.
    set(pending ${_dsl_scripts})
    set(seen)
    while(pending)
        list(POP_FRONT pending script)
        if(script IN_LIST seen)
            continue()
        endif()
        list(APPEND seen "${script}")
        file(STRINGS "${ROOT}/${script}.das" imports REGEX "^require ")
        foreach(import IN LISTS imports)
            string(REGEX MATCHALL "dassdl3/[A-Za-z0-9_]+" modules "${import}")
            foreach(module IN LISTS modules)
                if(NOT module IN_LIST _dsl_scripts)
                    list(APPEND _dsl_scripts "${module}")
                    list(APPEND pending "${module}")
                endif()
            endforeach()
        endforeach()
    endwhile()
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${dependencies})
    foreach(script IN LISTS _dsl_scripts)
        string(REPLACE "/" "_" name "${script}")
        set(output "${CMAKE_CURRENT_BINARY_DIR}/${name}.macos-dsl.aot.cpp")
        add_custom_command(OUTPUT "${output}"
            COMMAND dasSDL3_macos_libraries_aot_tool "${ROOT}/${script}.das" "${output}"
            DEPENDS dasSDL3_macos_libraries_aot_tool "${ROOT}/${script}.das" ${dependencies}
            VERBATIM)
        target_sources(dasSDL3_macos_shader_dsl_aot_runner PRIVATE "${output}")
    endforeach()
    set(headless tests/shader_dsl_resources tests/shader_dsl_storage
        tests/shader_dsl_uniforms)
    set(native tests/shader_dsl_resource_gpu_cross tests/shader_dsl_compute_cross
        tests/shader_dsl_uniform_gpu_cross tests/shader_dsl_texture_cross tests/shader_dsl_cross
        examples/gpu_dsl/01_triangle examples/gpu_dsl/02_texture
        examples/gpu_dsl/03_uniforms examples/gpu_dsl/04_compute)
    foreach(name metaballs raymarch mesh instancing bump hdr lod stencil shadowvolumes shadowvolumes_scene)
        list(APPEND native tests/bgfx_${name})
    endforeach()
    if(DASSDL3_WITH_TTF)
        list(APPEND native tests/bgfx_fontsdf)
    endif()
    foreach(script IN LISTS headless native)
        string(REPLACE "/" "_" name "${script}")
        add_test(NAME macos_dsl_${name}_strict_aot COMMAND dasSDL3_macos_shader_dsl_aot_runner
            "${ROOT}/${script}.das")
        set_tests_properties(macos_dsl_${name}_strict_aot PROPERTIES
            TIMEOUT 120 RUN_SERIAL TRUE WORKING_DIRECTORY "${ROOT}"
            ENVIRONMENT "SDL_GPU_DRIVER=metal;SDL_AUDIODRIVER=dummy"
            LABELS "macos-dsl-aot")
        add_test(NAME macos_dsl_${name}_aot_link COMMAND dasSDL3_macos_shader_dsl_aot_runner
            "${ROOT}/${script}.das" --check-aot)
        set_tests_properties(macos_dsl_${name}_aot_link PROPERTIES TIMEOUT 60
            WORKING_DIRECTORY "${ROOT}" LABELS "macos-dsl-link")
        if(script IN_LIST headless)
            set_property(TEST macos_dsl_${name}_strict_aot APPEND PROPERTY LABELS "macos-dsl-headless")
        else()
            set_property(TEST macos_dsl_${name}_strict_aot APPEND PROPERTY LABELS "macos-dsl-native")
        endif()
    endforeach()
    add_test(NAME macos_dsl_missing_strict_aot COMMAND ${Python3_EXECUTABLE}
        "${ROOT}/tests/clangbind/expect_aot_failure.py"
        $<TARGET_FILE:dasSDL3_macos_shader_dsl_aot_runner> "${ROOT}/tests/macos_missing_aot.das")
    set_tests_properties(macos_dsl_missing_strict_aot PROPERTIES
        TIMEOUT 60 LABELS "macos-dsl-aot;macos-dsl-headless")
endfunction()
dassdl3_add_macos_shader_dsl_aot()
