# Native live pilot: the unmodified upstream host plus dynamically loaded SDL.
if(NOT DASSDL3_WITH_IMGUI OR NOT (APPLE OR (WIN32 AND MSVC)))
    message(FATAL_ERROR "Live pilot requires macOS or Windows/MSVC and DASSDL3_WITH_IMGUI=ON")
endif()
set(_das ${PROJECT_SOURCE_DIR}/third_party/daScript)
set(_imgui ${_das}/modules/dasImgui)
set(_live_output ${CMAKE_BINARY_DIR}/live)
add_executable(dasSDL3_live ${_das}/utils/daslang-live/main.cpp)
target_link_libraries(dasSDL3_live PRIVATE libDaScriptDyn)
target_include_directories(dasSDL3_live PRIVATE ${CMAKE_BINARY_DIR}/third_party/daScript/include
    ${_das}/include ${_das}/3rdparty/fmt/include)
target_compile_definitions(dasSDL3_live PRIVATE DAS_ENABLE_EXCEPTIONS=1)
if(MSVC)
    target_compile_options(dasSDL3_live PRIVATE /arch:AVX2)
elseif(APPLE)
    target_compile_options(dasSDL3_live PRIVATE -fno-rtti)
    target_link_libraries(dasSDL3_live PRIVATE "-framework Foundation")
endif()
set_target_properties(dasSDL3_live PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${_live_output})
add_library(dasSDL3_live_module SHARED ../module_sdl3.cpp ../libraries/module_imgui_sdl.cpp
    ${PROJECT_SOURCE_DIR}/examples/live/host.cpp
    ${_imgui}/imgui/backends/imgui_impl_sdl3.cpp
    ${_imgui}/imgui/backends/imgui_impl_sdlrenderer3.cpp)
target_link_libraries(dasSDL3_live_module PRIVATE libDaScriptDyn SDL3::SDL3 dasModuleImgui)
target_include_directories(dasSDL3_live_module PRIVATE .. ../libraries ${_imgui}/imgui ${_imgui}/src
    ${_das}/include ${_das}/3rdparty/fmt/include)
target_compile_definitions(dasSDL3_live_module PRIVATE DAS_MOD_EXPORTS DAS_ENABLE_EXCEPTIONS=1 "IMGUI_IMPL_API=")
if(MSVC)
    target_compile_definitions(dasSDL3_live_module PRIVATE "IMGUI_API=__declspec(dllimport)")
    target_compile_options(dasSDL3_live_module PRIVATE /bigobj /arch:AVX2)
elseif(APPLE)
    target_compile_options(dasSDL3_live_module PRIVATE -fno-rtti)
endif()
if(APPLE)
    target_compile_definitions(dasSDL3_live_module PRIVATE
        DASSDL3_TYPES_INCLUDE="generated/macos/sdl3_types.inc"
        DASSDL3_REGISTRATION_INCLUDE="generated/macos/sdl3_functions.inc")
elseif(DASSDL3_BINDING_BACKEND STREQUAL "clangbind")
    target_compile_definitions(dasSDL3_live_module PRIVATE
        DASSDL3_TYPES_INCLUDE="generated/clangbind/sdl3_types.inc"
        DASSDL3_REGISTRATION_INCLUDE="generated/clangbind/sdl3_functions.inc")
endif()
set_target_properties(dasSDL3_live_module PROPERTIES PREFIX "" SUFFIX ".shared_module"
    RUNTIME_OUTPUT_DIRECTORY ${_live_output}/module
    LIBRARY_OUTPUT_DIRECTORY ${_live_output}/module)
add_dependencies(dasSDL3_live dasSDL3_live_module dasModuleLiveHost)
add_custom_command(TARGET dasSDL3_live POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:libDaScriptDyn> $<TARGET_FILE:libDaScriptDyn_runtime> ${_live_output})
file(GLOB _boost CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/dassdl3/*.das")
set(_paths "")
foreach(script ${_boost})
    get_filename_component(name ${script} NAME_WE)
    string(APPEND _paths "    register_native_path(\"dassdl3\", \"${name}\", \"${script}\")\n")
endforeach()
configure_file(module.das.in ${_live_output}/module/.das_module @ONLY)

if(BUILD_TESTING)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    add_test(NAME sdl3_live_widgets COMMAND ${Python3_EXECUTABLE}
        ${PROJECT_SOURCE_DIR}/tests/test_live_widgets.py
        --host $<TARGET_FILE:dasSDL3_live> --module ${_live_output}/module)
    set_tests_properties(sdl3_live_widgets PROPERTIES TIMEOUT 180 RUN_SERIAL TRUE)
endif()
