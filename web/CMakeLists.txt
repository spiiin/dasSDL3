cmake_minimum_required(VERSION 3.24)
project(dasSDL3Web LANGUAGES C CXX)
if(NOT EMSCRIPTEN)
    message(FATAL_ERROR "Configure with emcmake; see web/README.md")
endif()
if(NOT EMSCRIPTEN_VERSION VERSION_EQUAL "5.0.3")
    message(FATAL_ERROR "This Web profile is validated with Emscripten 5.0.3; revalidate before upgrading")
endif()
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
get_filename_component(ROOT "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)
add_compile_options(-msimd128 -mnontrapping-fptoint -fwasm-exceptions -sWASM_LEGACY_EXCEPTIONS=0)
add_link_options(-fwasm-exceptions -sWASM_LEGACY_EXCEPTIONS=0)
add_compile_definitions(DAS_ENABLE_EXCEPTIONS=1 _EMSCRIPTEN_VER)
foreach(feature FLEX_BISON CLANG_BIND LLVM SMT HV GLFW IMGUI VULKAN AUDIO STDDLG
        MESHOPTIMIZER STBIMAGE METAL ACCELERATE CLIPBOARD PUGIXML SQLITE TREE_SITTER
        TERMINAL AOT_EXAMPLES TUTORIAL TESTS TOOLS)
    set(DAS_${feature}_DISABLED ON CACHE BOOL "Minimal Web runtime" FORCE)
endforeach()
add_subdirectory("${ROOT}/third_party/daScript" "${CMAKE_BINARY_DIR}/dascript" EXCLUDE_FROM_ALL)
function(isolate_outputs dir)
    get_property(targets DIRECTORY "${dir}" PROPERTY BUILDSYSTEM_TARGETS)
    foreach(t IN LISTS targets)
        set_target_properties(${t} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
            LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib" RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tools")
    endforeach()
    get_property(children DIRECTORY "${dir}" PROPERTY SUBDIRECTORIES)
    foreach(child IN LISTS children)
        isolate_outputs("${child}")
    endforeach()
endfunction()
isolate_outputs("${ROOT}/third_party/daScript")
include(FetchContent)
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_TEST_LIBRARY OFF CACHE BOOL "" FORCE)
set(SDL_TESTS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(SDL3 GIT_REPOSITORY https://github.com/libsdl-org/SDL.git GIT_TAG release-3.4.16 GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(SDL3)
add_executable(dassdl3_web runner.cpp module_web.cpp)
target_include_directories(dassdl3_web PRIVATE "${ROOT}/src" "${CMAKE_CURRENT_SOURCE_DIR}" "${ROOT}/third_party/daScript/include" "${ROOT}/third_party/daScript/3rdparty/fmt/include")
target_compile_options(dassdl3_web PRIVATE -fno-rtti)
target_link_libraries(dassdl3_web PRIVATE libDaScript libDasModuleOpenGL SDL3::SDL3)
set_target_properties(dassdl3_web PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/site" SUFFIX ".js")
# Emscripten moves JS from its private temporary directory; Windows retains that
# file ACL. Restore the output directory's permissions for static HTTP servers.
if(CMAKE_HOST_WIN32)
    add_custom_command(TARGET dassdl3_web POST_BUILD
        COMMAND icacls "$<TARGET_FILE:dassdl3_web>" /reset VERBATIM)
endif()
target_link_options(dassdl3_web PRIVATE
    -sSTACK_SIZE=4MB -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=128MB
    -sFULL_ES3=1 -sMAX_WEBGL_VERSION=2 -sMIN_WEBGL_VERSION=1 -sFORCE_FILESYSTEM=1
    -sMODULARIZE=1 -sEXPORT_NAME=createDasSDL3 -sINVOKE_RUN=0 -sEXIT_RUNTIME=0
    "-sEXPORTED_FUNCTIONS=['_main','_web_stop']"
    "-sEXPORTED_RUNTIME_METHODS=['callMain','FS']"
    "SHELL:--preload-file ${ROOT}/third_party/daScript/daslib@/daslib"
    "SHELL:--exclude-file */_aot_generated/*"
    "SHELL:--exclude-file */.jitted_scripts/*"
    "SHELL:--exclude-file */_llvm_aot_generated/*"
    "SHELL:--preload-file ${ROOT}/dassdl3@/dassdl3"
    "SHELL:--preload-file ${ROOT}/examples/web@/examples"
    "SHELL:--preload-file ${ROOT}/examples/assets/checker.bmp@/assets/checker.bmp")
file(GLOB_RECURSE WEB_SCRIPTS CONFIGURE_DEPENDS "${ROOT}/examples/web/*.das")
set_property(TARGET dassdl3_web APPEND PROPERTY LINK_DEPENDS ${WEB_SCRIPTS})
foreach(page index.html app.js style.css)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${page}" "${CMAKE_BINARY_DIR}/site/${page}" COPYONLY)
endforeach()
foreach(example 01_hello 02_square 03_input 04_textures 05_streaming 06_target 07_geometry 08_audio)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/example.html" "${CMAKE_BINARY_DIR}/site/${example}.html" COPYONLY)
endforeach()

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/example.html" GL_PAGE)
string(REPLACE "<head>" "<head><base href=\"../\">" GL_PAGE "${GL_PAGE}")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/site/opengl")
foreach(example 01_clear 02_triangle)
    file(WRITE "${CMAKE_BINARY_DIR}/site/opengl/${example}.html" "${GL_PAGE}")
endforeach()
