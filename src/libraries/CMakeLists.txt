add_executable(dasSDL3_libraries_runner ../runner.cpp)
target_link_libraries(dasSDL3_libraries_runner PRIVATE dasSDL3)
target_compile_definitions(dasSDL3_libraries_runner PRIVATE
    DASSDL3_DAS_ROOT="${PROJECT_SOURCE_DIR}/third_party/daScript"
    DASSDL3_MODULE_ROOT="${PROJECT_SOURCE_DIR}/dassdl3")
set_target_properties(dasSDL3_libraries_runner PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
if(DASSDL3_WITH_IMAGE)
    add_library(dasSDL3_image STATIC module_image.cpp)
    target_link_libraries(dasSDL3_image PUBLIC dasSDL3 SDL3_image::SDL3_image)
    target_link_libraries(dasSDL3_libraries_runner PRIVATE dasSDL3_image)
    target_compile_definitions(dasSDL3_libraries_runner PRIVATE DASSDL3_WITH_IMAGE=1)
    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/bin/assets/libraries")
    foreach(asset alpha.png two_frames.gif sample.svg invalid.bin)
        configure_file(${PROJECT_SOURCE_DIR}/examples/libraries/assets/${asset}
            ${CMAKE_BINARY_DIR}/bin/assets/libraries/${asset} COPYONLY)
    endforeach()
    if(BUILD_TESTING)
        add_executable(dasSDL3_image_io_test ${PROJECT_SOURCE_DIR}/tests/image_io.cpp)
        target_link_libraries(dasSDL3_image_io_test PRIVATE dasSDL3_image)
        target_compile_definitions(dasSDL3_image_io_test PRIVATE
            DASSDL3_DAS_ROOT="${PROJECT_SOURCE_DIR}/third_party/daScript"
            DASSDL3_IMAGE_IO_SCRIPT="${PROJECT_SOURCE_DIR}/tests/image_io.das"
            DASSDL3_IMAGE_ASSETS="${PROJECT_SOURCE_DIR}/examples/libraries/assets")
        add_test(NAME sdl3_image_io COMMAND dasSDL3_image_io_test)
        set_tests_properties(sdl3_image_io PROPERTIES TIMEOUT 60)
        foreach(script examples/libraries/02_image tests/image)
            string(REPLACE "/" "_" name "${script}")
            add_test(NAME sdl3_${name} COMMAND dasSDL3_libraries_runner ${PROJECT_SOURCE_DIR}/${script}.das --smoke-test)
            set_tests_properties(sdl3_${name} PROPERTIES ENVIRONMENT "SDL_RENDER_DRIVER=software" TIMEOUT 60)
        endforeach()
    endif()
endif()
if(DASSDL3_WITH_IMGUI)
set(_imgui ${PROJECT_SOURCE_DIR}/third_party/daScript/modules/dasImgui)
add_library(dasSDL3_imgui STATIC module_imgui_sdl.cpp
    ${_imgui}/imgui/backends/imgui_impl_sdl3.cpp
    ${_imgui}/imgui/backends/imgui_impl_sdlrenderer3.cpp)
target_include_directories(dasSDL3_imgui PUBLIC ${_imgui}/imgui ${_imgui}/src)
target_link_libraries(dasSDL3_imgui PUBLIC dasSDL3 libDasModuleImgui)
target_link_libraries(dasSDL3_libraries_runner PRIVATE dasSDL3_imgui)
target_compile_definitions(dasSDL3_libraries_runner PRIVATE DASSDL3_WITH_IMGUI=1)
if(BUILD_TESTING)
    add_executable(dasSDL3_imgui_input_test ${PROJECT_SOURCE_DIR}/tests/imgui_input.cpp)
    target_link_libraries(dasSDL3_imgui_input_test PRIVATE dasSDL3_imgui)
    target_compile_definitions(dasSDL3_imgui_input_test PRIVATE
        DASSDL3_DAS_ROOT="${PROJECT_SOURCE_DIR}/third_party/daScript"
        DASSDL3_IMGUI_INPUT_SCRIPT="${PROJECT_SOURCE_DIR}/tests/imgui_input.das")
    add_test(NAME sdl3_imgui_input COMMAND dasSDL3_imgui_input_test)
    set_tests_properties(sdl3_imgui_input PROPERTIES TIMEOUT 60)
    add_test(NAME sdl3_imgui_example COMMAND dasSDL3_libraries_runner
        ${PROJECT_SOURCE_DIR}/examples/libraries/01_imgui.das --smoke-test)
    set_tests_properties(sdl3_imgui_example PROPERTIES ENVIRONMENT "SDL_RENDER_DRIVER=software" TIMEOUT 60)
    add_test(NAME sdl3_imgui_lifetimes COMMAND dasSDL3_libraries_runner
        ${PROJECT_SOURCE_DIR}/tests/imgui_lifetimes.das --smoke-test)
    set_tests_properties(sdl3_imgui_lifetimes PROPERTIES ENVIRONMENT "SDL_RENDER_DRIVER=software" TIMEOUT 60)
endif()

endif()
