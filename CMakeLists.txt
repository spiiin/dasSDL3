cmake_minimum_required(VERSION 3.24)
project(dasSDL3 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
include(CTest)

# Build only the language runtime/compiler; unrelated native modules are optional.
foreach(feature FLEX_BISON CLANG_BIND LLVM SMT HV GLFW IMGUI VULKAN AUDIO
        STDDLG MESHOPTIMIZER STBIMAGE METAL ACCELERATE CLIPBOARD PUGIXML SQLITE
        TREE_SITTER TERMINAL AOT_EXAMPLES TUTORIAL TESTS)
    set(DAS_${feature}_DISABLED ON CACHE BOOL "Minimal dasSDL3 build")
endforeach()
set(DAS_TOOLS_DISABLED OFF CACHE BOOL "Build the standalone language executable")
option(DASSDL3_WITH_IMGUI "Build the optional daScript ImGui + SDL Renderer example host" OFF)
option(DASSDL3_WITH_IMAGE "Build the optional SDL_image bindings" OFF)
option(DASSDL3_WITH_TTF "Build the optional SDL_ttf bindings" OFF)
option(DASSDL3_WITH_NET "Build the optional SDL_net bindings" OFF)
option(DASSDL3_WITH_MIXER "Build the optional SDL_mixer bindings" OFF)
if(DASSDL3_WITH_IMGUI)
    # Upstream's ImGui CMake requires these modules even when its GLFW host
    # is unused. Keep the dependencies scoped to this opt-in configuration.
    set(DAS_IMGUI_DISABLED OFF)
    set(DAS_GLFW_DISABLED OFF)
    set(DAS_CLIPBOARD_DISABLED OFF)
endif()
add_subdirectory(third_party/daScript EXCLUDE_FROM_ALL)
if(MSVC)
    # MSVC 19.38 diagnoses intentional assignments in upstream's type inference.
    # Keep upstream /WX, suppress only this warning in the affected translation unit.
    set_source_files_properties(
        "${CMAKE_CURRENT_SOURCE_DIR}/third_party/daScript/src/ast/ast_infer_type.cpp"
        DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/third_party/daScript"
        PROPERTIES COMPILE_OPTIONS /wd4706)
endif()

include(FetchContent)
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_TEST_LIBRARY OFF CACHE BOOL "" FORCE)
set(SDL_TESTS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(SDL3
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG release-3.4.16
    GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(SDL3)
if(DASSDL3_WITH_IMAGE)
    # Deterministic built-in codec profile; no external codec DLLs.
    set(BUILD_SHARED_LIBS OFF)
    set(SDLIMAGE_VENDORED OFF CACHE BOOL "" FORCE)
    set(SDLIMAGE_SAMPLES OFF CACHE BOOL "" FORCE)
    set(SDLIMAGE_TESTS OFF CACHE BOOL "" FORCE)
    set(SDLIMAGE_BACKEND_STB ON CACHE BOOL "" FORCE)
    set(SDLIMAGE_BACKEND_WIC OFF CACHE BOOL "" FORCE)
    set(SDLIMAGE_BACKEND_IMAGEIO OFF CACHE BOOL "" FORCE)
    foreach(codec AVIF JXL TIF WEBP)
        set(SDLIMAGE_${codec} OFF CACHE BOOL "Optional external codecs are not in this profile" FORCE)
    endforeach()
    FetchContent_Declare(SDL3_image
        URL https://github.com/libsdl-org/SDL_image/archive/refs/tags/release-3.2.4.tar.gz
        URL_HASH SHA256=6a2f263e69d5cf0f218615e061f0d6cc1ae708e847ffe5372af98d5dd96bd037
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    FetchContent_MakeAvailable(SDL3_image)
endif()

if(DASSDL3_WITH_TTF)
    set(BUILD_SHARED_LIBS OFF)
    if(NOT TARGET freetype)
        foreach(dep ZLIB BZIP2 PNG HARFBUZZ BROTLI)
            set(FT_DISABLE_${dep} ON CACHE BOOL "Minimal shared FreeType profile" FORCE)
        endforeach()
        FetchContent_Declare(freetype_src
            URL https://download.savannah.gnu.org/releases/freetype/freetype-2.14.3.tar.xz
            URL_HASH SHA256=36bc4f1cc413335368ee656c42afca65c5a3987e8768cc28cf11ba775e785a5f
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
        FetchContent_MakeAvailable(freetype_src)
        if(WIN32)
            get_target_property(_ft_sources freetype SOURCES)
            list(FILTER _ft_sources EXCLUDE REGEX "ftver\\.rc$")
            set_property(TARGET freetype PROPERTY SOURCES ${_ft_sources})
        endif()
    endif()
    if(NOT TARGET Freetype::Freetype)
        add_library(Freetype::Freetype ALIAS freetype)
    endif()
    # SDL_ttf uses find_package; resolve it to the same target as optional ImGui.
    file(WRITE "${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/freetype-config.cmake"
        "set(Freetype_FOUND TRUE)\nset(FREETYPE_FOUND TRUE)\nset(FREETYPE_VERSION_STRING 2.14.3)\n")
    # FreeType is already built without HarfBuzz; HB's FT bridge reuses it.
    # This avoids the optional FreeType -> HarfBuzz -> FreeType build cycle.
    set(HB_HAVE_FREETYPE ON CACHE BOOL "SDL_ttf requires the hb-ft bridge" FORCE)
    foreach(feature CAIRO GRAPHITE2 GLIB ICU GOBJECT INTROSPECTION CORETEXT UNISCRIBE GDI DIRECTWRITE)
        set(HB_HAVE_${feature} OFF CACHE BOOL "Pinned OpenType shaping profile" FORCE)
    endforeach()
    set(HB_BUILD_UTILS OFF CACHE BOOL "" FORCE)
    set(HB_BUILD_SUBSET OFF CACHE BOOL "" FORCE)
    FetchContent_Declare(harfbuzz_src
        URL https://github.com/harfbuzz/harfbuzz/archive/refs/tags/10.4.0.tar.gz
        URL_HASH SHA256=0d25a3f74af4e8744700ac19050af5a80ae330378a5802a5cd71e523bb6fda1f
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    FetchContent_MakeAvailable(harfbuzz_src)
    if(NOT TARGET harfbuzz::harfbuzz)
        add_library(harfbuzz::harfbuzz ALIAS harfbuzz)
    endif()
    file(WRITE "${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/harfbuzz-config.cmake"
        "set(harfbuzz_FOUND TRUE)\nset(harfbuzz_VERSION 10.4.0)\n")
    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        "${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/harfbuzz-config-version.cmake"
        VERSION 10.4.0 COMPATIBILITY AnyNewerVersion)
    set(SDLTTF_VENDORED OFF CACHE BOOL "" FORCE)
    set(SDLTTF_HARFBUZZ ON CACHE BOOL "OpenType shaping via pinned HarfBuzz" FORCE)
    set(SDLTTF_PLUTOSVG OFF CACHE BOOL "SVG emoji is a separate follow-up" FORCE)
    set(SDLTTF_SAMPLES OFF CACHE BOOL "" FORCE)
    FetchContent_Declare(SDL3_ttf
        URL https://github.com/libsdl-org/SDL_ttf/archive/refs/tags/release-3.2.2.tar.gz
        URL_HASH SHA256=ff6b81d3dc39d843cc3ead6dedd68043a79513d266792ea89445547ef4e9b073
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    FetchContent_MakeAvailable(SDL3_ttf)
endif()
if(DASSDL3_WITH_NET)
    set(BUILD_SHARED_LIBS OFF)
    set(SDLNET_SAMPLES OFF CACHE BOOL "" FORCE)
    FetchContent_Declare(SDL3_net
        URL https://github.com/libsdl-org/SDL_net/archive/refs/tags/release-3.2.0.tar.gz
        URL_HASH SHA256=195036ba82322e03fd3562149634fb582e5e9298ccc6cb2c5e362bf40c5018be
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    FetchContent_MakeAvailable(SDL3_net)
endif()
if(DASSDL3_WITH_MIXER)
    set(BUILD_SHARED_LIBS OFF)
    foreach(feature INSTALL TESTS EXAMPLES VENDORED FLAC_LIBFLAC MP3_MPG123 GME MOD MIDI OPUS VORBIS_VORBISFILE VORBIS_TREMOR WAVPACK)
        set(SDLMIXER_${feature} OFF CACHE BOOL "Built-in SDL_mixer codec profile" FORCE)
    endforeach()
    foreach(feature AIFF WAVE VOC AU FLAC FLAC_DRFLAC MP3 MP3_DRMP3 VORBIS_STB)
        set(SDLMIXER_${feature} ON CACHE BOOL "Built-in SDL_mixer codec profile" FORCE)
    endforeach()
    FetchContent_Declare(SDL3_mixer
        URL https://github.com/libsdl-org/SDL_mixer/releases/download/release-3.2.4/SDL3_mixer-3.2.4.tar.gz
        URL_HASH SHA256=182a07c745375e113dc740d43964ff21b0be29f29f59876c4dbc4db3d32f6901
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    FetchContent_MakeAvailable(SDL3_mixer)
endif()
option(DASSDL3_WITH_SOUND "Build optional SDL_sound decoding bindings" OFF)
if(DASSDL3_WITH_SOUND)
    # SDL_sound unconditionally calls find_package; reuse our already-built SDL.
    file(WRITE "${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/sdl3-config.cmake"
        "set(SDL3_FOUND TRUE)\nset(SDL3_SDL3_FOUND TRUE)\n")
    foreach(feature INSTALL BUILD_SHARED BUILD_TEST BUILD_DOCS DECODER_MIDI)
        set(SDLSOUND_${feature} OFF CACHE BOOL "Pinned SDL_sound profile" FORCE)
    endforeach()
    set(SDLSOUND_BUILD_STATIC ON CACHE BOOL "" FORCE)
    FetchContent_Declare(SDL3_sound
        URL https://github.com/icculus/SDL_sound/archive/refs/tags/v3.2.0.tar.gz
        URL_HASH SHA256=a1db90a81b77f4ee0637c2f4b0eac5187853fe4905c63e075f92d67e9adc2079
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    FetchContent_MakeAvailable(SDL3_sound)
    # Embedded decoder symbols must remain private when linked beside SDL_mixer.
    target_compile_definitions(SDL3_sound-static PRIVATE DRFLAC_API=static DRMP3_API=static)
    # This bundled stb_vorbis predates STB_VORBIS_STATIC. Namespace its symbols.
    file(READ "${sdl3_sound_SOURCE_DIR}/src/stb_vorbis.h" _sound_vorbis_header)
    string(REGEX MATCHALL "stb_vorbis_[A-Za-z0-9_]+" _sound_vorbis_symbols "${_sound_vorbis_header}")
    list(REMOVE_DUPLICATES _sound_vorbis_symbols)
    foreach(symbol IN LISTS _sound_vorbis_symbols)
        target_compile_definitions(SDL3_sound-static PRIVATE "${symbol}=dassdl_sound_${symbol}")
    endforeach()
endif()
option(DASSDL3_WITH_SHADERCROSS "Build optional shader translation bindings and CLI" OFF)
if(DASSDL3_WITH_SHADERCROSS)
    include(cmake/ShaderCross.cmake)
endif()
add_subdirectory(src)

option(DASSDL3_INSTALL_SDK "Install the core Windows x64 Release SDK" OFF)
if(DASSDL3_INSTALL_SDK)
    include(cmake/InstallSDK.cmake)
endif()
