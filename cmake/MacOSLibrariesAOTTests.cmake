# Match the enabled companion profile, without requiring the Windows parity build.
get_target_property(_library_links dasSDL3_libraries_runner LINK_LIBRARIES)
get_target_property(_library_definitions dasSDL3_libraries_runner COMPILE_DEFINITIONS)
foreach(kind tool runner)
    add_executable(dasSDL3_macos_libraries_aot_${kind}
        "${PROJECT_SOURCE_DIR}/tests/clangbind_parity/aot_${kind}.cpp")
    target_link_libraries(dasSDL3_macos_libraries_aot_${kind} PRIVATE ${_library_links})
    target_compile_definitions(dasSDL3_macos_libraries_aot_${kind} PRIVATE ${_library_definitions})
    set_target_properties(dasSDL3_macos_libraries_aot_${kind} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
endforeach()
target_compile_definitions(dasSDL3_macos_libraries_aot_tool PRIVATE
    DASSDL3_AOT_IMGUI_COROUTINE_SCOPE=1)
set(_library_scripts tests/iostream)
set(_library_modules dassdl3/sdl3_result dassdl3/sdl3_boost dassdl3/sdl3_init_boost
    dassdl3/sdl3_pixels_boost dassdl3/sdl3_iostream_boost)
foreach(library IMAGE TTF NET MIXER SOUND)
    if(DASSDL3_WITH_${library})
        string(TOLOWER "${library}" name)
        list(APPEND _library_scripts tests/${name})
        list(APPEND _library_modules dassdl3/sdl3_${name}_boost)
    endif()
endforeach()
if(DASSDL3_WITH_TTF)
    list(APPEND _library_scripts tests/ttf_shaping tests/ttf_gpu)
    list(APPEND _library_modules dassdl3/sdl3_window_io_boost
        dassdl3/sdl3_gpu_native_boost dassdl3/sdl3_gpu_boost
        dassdl3/sdl3_gpu_result dassdl3/sdl3_properties_boost)
endif()
if(DASSDL3_WITH_SHADERCROSS)
    list(APPEND _library_scripts examples/libraries/09_shadercross)
    if(NOT DASSDL3_SHADERCROSS_DXC)
        list(APPEND _library_scripts tests/shadercross_no_dxc)
    endif()
    list(APPEND _library_modules dassdl3/sdl3_shadercross_boost)
endif()
if(DASSDL3_WITH_IMGUI)
    foreach(kind tool runner)
        target_include_directories(dasSDL3_macos_libraries_aot_${kind} PRIVATE
            "${PROJECT_SOURCE_DIR}/third_party/daScript/modules/dasLiveHost/src")
        target_compile_definitions(dasSDL3_macos_libraries_aot_${kind} PRIVATE
            IMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 IMGUI_ENABLE_FREETYPE=1 IMGUI_USE_WCHAR32=1)
    endforeach()
    target_compile_options(dasSDL3_macos_libraries_aot_runner PRIVATE
        -include "${PROJECT_SOURCE_DIR}/src/libraries/imgui_aot_compat.h")
    list(APPEND _library_scripts examples/libraries/01_imgui tests/imgui_lifetimes tests/imgui_widgets)
    list(APPEND _library_modules dassdl3/sdl3_imgui dassdl3/sdl3_imgui_widgets
        third_party/daScript/modules/dasImgui/widgets/imgui_boost_runtime
        third_party/daScript/modules/dasImgui/widgets/imgui_widgets_builtin
        third_party/daScript/modules/dasImgui/widgets/imgui_containers_builtin
        third_party/daScript/modules/dasImgui/widgets/imgui_theme_daslang
        third_party/daScript/modules/dasLiveHost/live/live_commands
        third_party/daScript/modules/dasLiveHost/live/live_vars
        third_party/daScript/daslib/json third_party/daScript/daslib/json_boost
        third_party/daScript/daslib/archive third_party/daScript/daslib/coroutines
        third_party/daScript/daslib/async_boost)
endif()
# Follow the shared boost imports; generic inlining does not replace module AOT.
set(_pending_modules ${_library_modules} ${_library_scripts})
set(_seen_modules)
while(_pending_modules)
    list(POP_FRONT _pending_modules module)
    if(module IN_LIST _seen_modules)
        continue()
    endif()
    list(APPEND _seen_modules "${module}")
    file(STRINGS "${PROJECT_SOURCE_DIR}/${module}.das" imports
        REGEX "^require dassdl3/")
    foreach(import IN LISTS imports)
        string(REGEX MATCH "dassdl3/[A-Za-z0-9_]+" dependency "${import}")
        if(NOT dependency IN_LIST _library_modules)
            list(APPEND _library_modules "${dependency}")
            list(APPEND _pending_modules "${dependency}")
        endif()
    endforeach()
endwhile()
file(GLOB_RECURSE _library_aot_dependencies CONFIGURE_DEPENDS
    "${PROJECT_SOURCE_DIR}/dassdl3/*.das" "${PROJECT_SOURCE_DIR}/third_party/daScript/daslib/*.das"
    "${PROJECT_SOURCE_DIR}/third_party/daScript/modules/dasImgui/widgets/*.das"
    "${PROJECT_SOURCE_DIR}/third_party/daScript/modules/dasLiveHost/live/*.das")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${_library_aot_dependencies})
foreach(script IN LISTS _library_scripts _library_modules)
    string(REPLACE "/" "_" name "${script}")
    set(output "${CMAKE_CURRENT_BINARY_DIR}/${name}.macos-library.aot.cpp")
    add_custom_command(OUTPUT "${output}"
        COMMAND dasSDL3_macos_libraries_aot_tool "${PROJECT_SOURCE_DIR}/${script}.das" "${output}"
        DEPENDS dasSDL3_macos_libraries_aot_tool "${PROJECT_SOURCE_DIR}/${script}.das"
            ${_library_aot_dependencies} VERBATIM)
    target_sources(dasSDL3_macos_libraries_aot_runner PRIVATE "${output}")
endforeach()
foreach(script IN LISTS _library_scripts)
    string(REPLACE "/" "_" name "${script}")
    add_test(NAME macos_libraries_${name}_strict_aot COMMAND dasSDL3_macos_libraries_aot_runner
        "${PROJECT_SOURCE_DIR}/${script}.das")
    set_tests_properties(macos_libraries_${name}_strict_aot PROPERTIES
        ENVIRONMENT "SDL_RENDER_DRIVER=software;SDL_AUDIODRIVER=dummy" TIMEOUT 90 RUN_SERIAL TRUE
        LABELS "macos-libraries-aot" WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
    if(script STREQUAL "tests/ttf_gpu")
        set_property(TEST macos_libraries_${name}_strict_aot APPEND PROPERTY
            ENVIRONMENT "SDL_GPU_DRIVER=metal")
    endif()
endforeach()
add_test(NAME macos_libraries_missing_strict_aot COMMAND ${Python3_EXECUTABLE}
    "${PROJECT_SOURCE_DIR}/tests/clangbind/expect_aot_failure.py"
    $<TARGET_FILE:dasSDL3_macos_libraries_aot_runner> "${PROJECT_SOURCE_DIR}/tests/macos_missing_aot.das")
set_tests_properties(macos_libraries_missing_strict_aot PROPERTIES TIMEOUT 60 LABELS "macos-libraries-aot")
