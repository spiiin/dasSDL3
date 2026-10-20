if(NOT DASSDL3_LAZYFOO_AOT OR NOT WIN32)
    return()
endif()
target_compile_definitions(dasSDL3 PRIVATE DASSDL3_AOT_HEADER="sdl3_aot.h")
add_executable(lazyfoo_aot_tool "${PROJECT_SOURCE_DIR}/tests/clangbind_parity/aot_tool.cpp")
add_executable(lazyfoo_aot_runner "${PROJECT_SOURCE_DIR}/tests/clangbind_parity/aot_runner.cpp")
foreach(target lazyfoo_aot_tool lazyfoo_aot_runner)
    target_link_libraries(${target} PRIVATE dasSDL3 dasSDL3_image dasSDL3_ttf dasSDL3_mixer)
    target_compile_definitions(${target} PRIVATE DASSDL3_WITH_IMAGE=1 DASSDL3_WITH_TTF=1 DASSDL3_WITH_MIXER=1
        DASSDL3_DAS_ROOT="${PROJECT_SOURCE_DIR}/third_party/daScript" DASSDL3_MODULE_ROOT="${PROJECT_SOURCE_DIR}/dassdl3")
    target_compile_options(${target} PRIVATE /bigobj)
    set_target_properties(${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
endforeach()
file(GLOB_RECURSE scripts CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/examples/sdl_port_lazyfoo/*.das")
list(APPEND scripts "${PROJECT_SOURCE_DIR}/tests/lazyfoo_contracts.das")
foreach(name sdl3_result sdl3_boost sdl3_init_boost sdl3_events sdl3_keyboard_mouse_boost sdl3_renderer_operations_boost
    sdl3_pixels_boost sdl3_texture_state_boost sdl3_renderer_state_boost sdl3_image_boost sdl3_ttf_boost
    sdl3_mixer_boost sdl3_properties_boost sdl3_rect_clipboard_boost)
    list(APPEND scripts "${PROJECT_SOURCE_DIR}/dassdl3/${name}.das")
endforeach()
file(GLOB dependencies CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/examples/sdl_port_lazyfoo/common/*.das")
file(GLOB boost_dependencies CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/dassdl3/*.das")
foreach(script IN LISTS scripts)
    string(SHA256 key "${script}")
    set(output "${CMAKE_CURRENT_BINARY_DIR}/lazyfoo_${key}.aot.cpp")
    add_custom_command(OUTPUT "${output}" COMMAND lazyfoo_aot_tool "${script}" "${output}.tmp"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${output}.tmp" "${output}"
        DEPENDS lazyfoo_aot_tool "${script}" ${dependencies} ${boost_dependencies} VERBATIM)
    target_sources(lazyfoo_aot_runner PRIVATE "${output}")
endforeach()
if(BUILD_TESTING AND Python3_EXECUTABLE)
    add_test(NAME lazyfoo_aot_examples COMMAND "${Python3_EXECUTABLE}" "${PROJECT_SOURCE_DIR}/tests/test_lazyfoo_examples.py"
        --runner $<TARGET_FILE:lazyfoo_aot_runner> --aot --output "${CMAKE_BINARY_DIR}/lazyfoo-aot"
        --reference "${CMAKE_BINARY_DIR}/lazyfoo-interpreter")
    set_tests_properties(lazyfoo_aot_examples PROPERTIES TIMEOUT 300 RUN_SERIAL TRUE DEPENDS lazyfoo_examples)
endif()
