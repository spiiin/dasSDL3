# Pin both the library and its upstream SPIRV-Cross submodule. No DXC source build.
option(DASSDL3_SHADERCROSS_DXC "Enable HLSL/DXIL using the DXC runtime SDK" ON)
set(DASSDL3_DXC_ROOT "" CACHE PATH "DXC SDK root (inc, lib/<arch>, bin/<arch>)")
foreach(feature CLI ENABLE_TESTS SHARED)
    set(SPIRV_CROSS_${feature} OFF CACHE BOOL "Pinned shadercross dependency profile" FORCE)
endforeach()
set(SPIRV_CROSS_STATIC ON CACHE BOOL "" FORCE)
set(SPIRV_CROSS_SKIP_INSTALL ON CACHE BOOL "" FORCE)
FetchContent_Declare(dassdl3_spirvcross
    URL https://github.com/KhronosGroup/SPIRV-Cross/archive/1a6169566c73d3da552748fc372fe2bbb856e46e.tar.gz
    URL_HASH SHA256=0f295b214b164e42a1d21537c8da7b44569806c16220dda9798558edfaacd11e
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
FetchContent_MakeAvailable(dassdl3_spirvcross)
# SDL_shadercross unconditionally emits a build-tree export, including its static dependencies.
export(TARGETS spirv-cross-c spirv-cross-core spirv-cross-glsl spirv-cross-hlsl
    spirv-cross-msl spirv-cross-cpp spirv-cross-reflect spirv-cross-util
    FILE "${CMAKE_BINARY_DIR}/dassdl3-spirvcross-targets.cmake")
# Upstream's non-vendored probe checks this name before find_package.
if(NOT TARGET spirv_cross_c)
    add_library(spirv_cross_c ALIAS spirv-cross-c)
endif()
if(DASSDL3_SHADERCROSS_DXC)
    if(NOT DASSDL3_DXC_ROOT)
        if(NOT WIN32 OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8 OR CMAKE_SYSTEM_PROCESSOR MATCHES "ARM|arm")
            message(FATAL_ERROR "Set DASSDL3_DXC_ROOT for this platform, or DASSDL3_SHADERCROSS_DXC=OFF")
        endif()
        FetchContent_Declare(dassdl3_dxc
            URL https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.9.2602/dxc_2026_02_20.zip
            URL_HASH SHA256=a1e89031421cf3c1fca6627766ab3020ca4f962ac7e2caa7fab2b33a8436151e
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
        FetchContent_MakeAvailable(dassdl3_dxc)
        set(_dassdl3_dxc_root "${dassdl3_dxc_SOURCE_DIR}")
    else()
        set(_dassdl3_dxc_root "${DASSDL3_DXC_ROOT}")
    endif()
    if(WIN32)
        set(_dxc_arch x64)
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM|arm")
            set(_dxc_arch arm64)
        elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
            set(_dxc_arch x86)
        endif()
        set(DirectXShaderCompiler_INCLUDE_PATH "${_dassdl3_dxc_root}/inc" CACHE PATH "" FORCE)
        set(DirectXShaderCompiler_dxcompiler_LIBRARY "${_dassdl3_dxc_root}/lib/${_dxc_arch}/dxcompiler.lib" CACHE FILEPATH "" FORCE)
        foreach(dll dxcompiler dxil)
            set(DirectXShaderCompiler_${dll}_BINARY "${_dassdl3_dxc_root}/bin/${_dxc_arch}/${dll}.dll" CACHE FILEPATH "" FORCE)
        endforeach()
    else()
        list(PREPEND CMAKE_PREFIX_PATH "${_dassdl3_dxc_root}")
    endif()
endif()
foreach(feature SHARED VENDORED SPIRVCROSS_SHARED INSTALL TESTS)
    set(SDLSHADERCROSS_${feature} OFF CACHE BOOL "" FORCE)
endforeach()
foreach(feature STATIC CLI CLI_STATIC)
    set(SDLSHADERCROSS_${feature} ON CACHE BOOL "" FORCE)
endforeach()
set(SDLSHADERCROSS_DXC ${DASSDL3_SHADERCROSS_DXC} CACHE BOOL "" FORCE)
FetchContent_Declare(SDL3_shadercross
    URL https://github.com/libsdl-org/SDL_shadercross/archive/1ff05bec573988a98ef9e0260b4da44f512b8367.tar.gz
    URL_HASH SHA256=60aae35ff71bd1d5f85b363e9d077a86bb27dd36333c42685e56c2fd541174d2
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
FetchContent_MakeAvailable(SDL3_shadercross)
function(dassdl3_shadercross_runtime target)
    if(WIN32 AND DASSDL3_SHADERCROSS_DXC)
        add_custom_command(TARGET ${target} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DirectXShaderCompiler_dxcompiler_BINARY}" "${DirectXShaderCompiler_dxil_BINARY}"
            "$<TARGET_FILE_DIR:${target}>" VERBATIM)
    endif()
endfunction()
set_target_properties(shadercross PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
if(WIN32 AND DASSDL3_SHADERCROSS_DXC)
    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
    foreach(dll dxcompiler dxil)
        configure_file("${DirectXShaderCompiler_${dll}_BINARY}" "${CMAKE_BINARY_DIR}/bin/${dll}.dll" COPYONLY)
    endforeach()
endif()

if(WIN32 AND DASSDL3_SHADERCROSS_DXC)
    foreach(license LICENSE-LLVM.txt LICENSE-MIT.txt LICENSE-MS.txt)
        if(EXISTS "${_dassdl3_dxc_root}/${license}")
            configure_file("${_dassdl3_dxc_root}/${license}" "${CMAKE_BINARY_DIR}/bin/licenses/dxc/${license}" COPYONLY)
        endif()
    endforeach()
endif()
# A normal incremental build rule: compiler/source changes invalidate the output.
if(DASSDL3_SHADERCROSS_DXC)
    set(_cross_asset_source "${PROJECT_SOURCE_DIR}/examples/libraries/shaders/shadercross.frag.hlsl")
    set(_cross_asset_dir "${CMAKE_BINARY_DIR}/bin/assets/libraries/shadercross")
    set(_cross_outputs)
    foreach(format SPIRV DXIL MSL JSON)
        string(TOLOWER "${format}" extension)
        set(output "${_cross_asset_dir}/fragment.${extension}")
        add_custom_command(OUTPUT "${output}"
            COMMAND ${CMAKE_COMMAND} -E make_directory "${_cross_asset_dir}"
            COMMAND $<TARGET_FILE:shadercross> "${_cross_asset_source}" -s HLSL -d ${format} -t fragment -e main -o "${output}"
            DEPENDS shadercross "${_cross_asset_source}" "${DirectXShaderCompiler_dxcompiler_BINARY}" "${DirectXShaderCompiler_dxil_BINARY}"
            VERBATIM)
        list(APPEND _cross_outputs "${output}")
    endforeach()
    add_custom_target(dassdl3_shadercross_example_assets DEPENDS ${_cross_outputs})
endif()
