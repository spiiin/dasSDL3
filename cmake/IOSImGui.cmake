include(FetchContent)
set(_das_imgui "${PROJECT_SOURCE_DIR}/third_party/daScript/modules/dasImgui")
set(_clipboard "${PROJECT_SOURCE_DIR}/third_party/daScript/modules/dasClipboard/src")
FetchContent_Declare(ios_imgui
    URL https://github.com/ocornut/imgui/archive/refs/tags/v1.92.6-docking.tar.gz
    URL_HASH SHA256=5e84cdaa6a6041586a0d11a3071b749734a0439d66fdbdad37ae5b27e37d396c
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
FetchContent_Declare(md4c_src
    URL https://github.com/mity/md4c/archive/refs/tags/release-0.5.3.tar.gz
    URL_HASH SHA256=353c346f376b87c954a13f3415ede2d51264cc61dc5abcd38ff1d2aa0d059b9e
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    SOURCE_SUBDIR __dasimgui_source_only)
FetchContent_MakeAvailable(ios_imgui md4c_src)
if(NOT TARGET freetype)
    foreach(_feature ZLIB BZIP2 PNG HARFBUZZ BROTLI)
        set(FT_DISABLE_${_feature} ON CACHE BOOL "Minimal iOS FreeType profile")
    endforeach()
    FetchContent_Declare(freetype_src
        URL https://download.savannah.gnu.org/releases/freetype/freetype-2.14.3.tar.xz
        URL_HASH SHA256=36bc4f1cc413335368ee656c42afca65c5a3987e8768cc28cf11ba775e785a5f
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    FetchContent_MakeAvailable(freetype_src)
endif()

# The pinned dasImgui desktop build adds ImVector::data() for daScript's managed
# vector annotation. Apply the same compatibility change to a build-local copy.
set(_imgui "${CMAKE_CURRENT_BINARY_DIR}/imgui-ios")
file(COPY "${ios_imgui_SOURCE_DIR}/" DESTINATION "${_imgui}"
    FILES_MATCHING PATTERN "*.h" PATTERN "*.cpp")
file(READ "${ios_imgui_SOURCE_DIR}/imgui.h" _header)
if(NOT _header MATCHES "inline T\\* +data\\(\\)")
    string(REPLACE
        "inline T*           end()"
        "inline T*           data()                              { return Data; }\n    inline const T*     data() const                        { return Data; }\n    inline T*           end()"
        _header "${_header}")
    file(WRITE "${_imgui}/imgui.h" "${_header}")
endif()

file(GLOB _bindings CONFIGURE_DEPENDS "${_das_imgui}/src/dasIMGUI*.cpp")
add_library(dasSDL3_imgui STATIC module_imgui_sdl.cpp ${_bindings}
    "${PROJECT_SOURCE_DIR}/ios/imgui_clipboard.cpp"
    "${md4c_src_SOURCE_DIR}/src/md4c.c"
    "${md4c_src_SOURCE_DIR}/src/entity.c"
    "${_imgui}/imgui.cpp"
    "${_imgui}/imgui_demo.cpp"
    "${_imgui}/imgui_draw.cpp"
    "${_imgui}/imgui_tables.cpp"
    "${_imgui}/imgui_widgets.cpp"
    "${_imgui}/misc/freetype/imgui_freetype.cpp"
    "${_imgui}/backends/imgui_impl_sdl3.cpp"
    "${_imgui}/backends/imgui_impl_sdlrenderer3.cpp"
    "${_imgui}/backends/imgui_impl_sdlgpu3.cpp")
target_include_directories(dasSDL3_imgui PUBLIC "${_imgui}" "${_imgui}/backends"
    PRIVATE "${_clipboard}" "${md4c_src_SOURCE_DIR}/src")
target_compile_definitions(dasSDL3_imgui PUBLIC
    IMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 IMGUI_ENABLE_FREETYPE=1 IMGUI_USE_WCHAR32=1)
target_link_libraries(dasSDL3_imgui PUBLIC dasSDL3 PRIVATE freetype)
