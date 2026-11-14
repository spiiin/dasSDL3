# Device app, not a desktop runner. The emitter is a macOS executable.
set(DASSDL3_IOS_AOT_TOOL "" CACHE FILEPATH "Host dasSDL3_macos_aot_tool for the iOS smoke app")
set(DASSDL3_IOS_BUNDLE_ID "org.dassdl3.iphone-smoke" CACHE STRING "iOS smoke bundle identifier")
set(DASSDL3_IOS_TEAM "" CACHE STRING "Apple development team for automatic Xcode signing")
set(_root "${PROJECT_SOURCE_DIR}")
set(_scripts
    "${_root}/examples/44_gpu_render_pass.das"
    "${_root}/examples/46_gpu_texture_uniform_bindings.das"
    "${_root}/examples/49_gpu_native_compute.das")
set(_triangle "${_root}/examples/48_gpu_native_graphics.das")
set(_support "${_root}/examples/gpu_port_bgfx/common/file_shader_support.das")
add_executable(dasSDL3_iphone MACOSX_BUNDLE "${_root}/ios/runner.cpp")
target_link_libraries(dasSDL3_iphone PRIVATE dasSDL3)
set_target_properties(dasSDL3_iphone PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST "${_root}/ios/Info.plist.in"
    MACOSX_BUNDLE_GUI_IDENTIFIER "${DASSDL3_IOS_BUNDLE_ID}"
    XCODE_GENERATE_SCHEME ON
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${DASSDL3_IOS_BUNDLE_ID}"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2")
if(DASSDL3_IOS_TEAM)
    set_target_properties(dasSDL3_iphone PROPERTIES
        XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${DASSDL3_IOS_TEAM}"
        XCODE_ATTRIBUTE_CODE_SIGN_STYLE Automatic)
endif()

function(_iphone_resource path subdir)
    target_sources(dasSDL3_iphone PRIVATE "${path}")
    set_source_files_properties("${path}" PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources/${subdir}")
endfunction()
foreach(_script IN LISTS _scripts)
    _iphone_resource("${_script}" examples)
endforeach()
_iphone_resource("${_triangle}" examples)
# Bundle the negative fixture without generating or linking AOT for it.
_iphone_resource("${_root}/tests/macos_missing_aot.das" tests)
_iphone_resource("${_support}" examples/gpu_port_bgfx/common)
foreach(_shader triangle.vert.msl triangle.frag.msl
        bindings.vert.msl bindings.frag.msl native.comp.msl)
    _iphone_resource("${_root}/examples/assets/shaders/${_shader}" assets/shaders)
endforeach()
file(GLOB_RECURSE _boost CONFIGURE_DEPENDS "${_root}/dassdl3/*.das")
file(GLOB_RECURSE _daslib CONFIGURE_DEPENDS "${_root}/third_party/daScript/daslib/*.das")
foreach(_file IN LISTS _boost)
    file(RELATIVE_PATH _rel "${_root}" "${_file}")
    get_filename_component(_dir "${_rel}" DIRECTORY)
    _iphone_resource("${_file}" "${_dir}")
endforeach()
foreach(_file IN LISTS _daslib)
    file(RELATIVE_PATH _rel "${_root}/third_party/daScript" "${_file}")
    get_filename_component(_dir "${_rel}" DIRECTORY)
    _iphone_resource("${_file}" "${_dir}")
endforeach()
_iphone_resource("${_root}/LICENSE" notices/dasSDL3)
foreach(_dep SDL daScript)
    file(GLOB _notices "${_root}/licenses/${_dep}/*")
    foreach(_notice IN LISTS _notices)
        _iphone_resource("${_notice}" "notices/${_dep}")
    endforeach()
endforeach()

if(DASSDL3_IOS_AOT_TOOL)
    if(NOT EXISTS "${DASSDL3_IOS_AOT_TOOL}")
        message(FATAL_ERROR "Build the macOS AOT emitter before configuring the iOS app")
    endif()
    # The application unit emits its own functions and template instances.
    # Shared imports also need their own registration units for strict linking.
    set(_pending ${_scripts} "${_triangle}" "${_support}")
    set(_aot_inputs)
    while(_pending)
        list(POP_FRONT _pending _input)
        if(_input IN_LIST _aot_inputs)
            continue()
        endif()
        list(APPEND _aot_inputs "${_input}")
        file(STRINGS "${_input}" _imports REGEX "^require ")
        foreach(_import IN LISTS _imports)
            string(REGEX MATCHALL "dassdl3/[A-Za-z0-9_]+" _modules "${_import}")
            foreach(_module IN LISTS _modules)
                list(APPEND _pending "${_root}/${_module}.das")
            endforeach()
        endforeach()
    endwhile()
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${_aot_inputs})
    foreach(_input IN LISTS _aot_inputs)
        file(RELATIVE_PATH _name "${_root}" "${_input}")
        string(REPLACE "/" "_" _name "${_name}")
        set(_aot "${CMAKE_CURRENT_BINARY_DIR}/iphone_${_name}.aot.cpp")
        add_custom_command(OUTPUT "${_aot}"
            COMMAND "${DASSDL3_IOS_AOT_TOOL}" "${_input}" "${_aot}"
            DEPENDS "${DASSDL3_IOS_AOT_TOOL}" ${_aot_inputs} ${_daslib}
            VERBATIM)
        target_sources(dasSDL3_iphone PRIVATE "${_aot}")
    endforeach()
    target_compile_definitions(dasSDL3_iphone PRIVATE DASSDL3_IPHONE_STRICT_AOT=1)
endif()
