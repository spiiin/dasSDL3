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
    GIT_TAG release-3.2.18
    GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(SDL3)

add_subdirectory(src)
