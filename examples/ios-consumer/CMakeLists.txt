cmake_minimum_required(VERSION 3.24)
project(HelloDasSDL3 VERSION 1.0.0 LANGUAGES C CXX)
if(NOT IOS)
    message(FATAL_ERROR "Configure this example with the iphoneos SDK")
endif()

set(DASSDL3_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../.." CACHE PATH "dasSDL3 source checkout")
set(DASSDL3_IOS_AOT_TOOL "" CACHE FILEPATH "macOS dasSDL3 AOT emitter")
set(CONSUMER_BUNDLE_ID "org.dassdl3.hello" CACHE STRING "Application bundle identifier")
set(CONSUMER_TEAM "" CACHE STRING "Apple development team")
if(NOT EXISTS "${DASSDL3_IOS_AOT_TOOL}")
    message(FATAL_ERROR "Set DASSDL3_IOS_AOT_TOOL to the macOS AOT emitter")
endif()
file(REAL_PATH "${DASSDL3_SOURCE_DIR}" DASSDL3_SOURCE_DIR BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
add_subdirectory("${DASSDL3_SOURCE_DIR}" dasSDL3 EXCLUDE_FROM_ALL)

add_executable(HelloDasSDL3 MACOSX_BUNDLE main.cpp)
target_link_libraries(HelloDasSDL3 PRIVATE dasSDL3)
target_include_directories(HelloDasSDL3 PRIVATE "${DASSDL3_SOURCE_DIR}/mobile")
set_target_properties(HelloDasSDL3 PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST "${DASSDL3_SOURCE_DIR}/ios/Info.plist.in"
    MACOSX_BUNDLE_GUI_IDENTIFIER "${CONSUMER_BUNDLE_ID}"
    MACOSX_BUNDLE_BUNDLE_NAME "Hello dasSDL3"
    XCODE_GENERATE_SCHEME ON
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${CONSUMER_BUNDLE_ID}"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1")
if(CONSUMER_TEAM)
    set_target_properties(HelloDasSDL3 PROPERTIES
        XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${CONSUMER_TEAM}"
        XCODE_ATTRIBUTE_CODE_SIGN_STYLE Automatic)
endif()

function(bundle_resource path directory)
    target_sources(HelloDasSDL3 PRIVATE "${path}")
    set_source_files_properties("${path}" PROPERTIES MACOSX_PACKAGE_LOCATION "Resources/${directory}")
endfunction()

set(script "${CMAKE_CURRENT_SOURCE_DIR}/hello.das")
set(dasroot "${DASSDL3_SOURCE_DIR}/third_party/daScript")
file(GLOB_RECURSE daslib CONFIGURE_DEPENDS "${dasroot}/daslib/*.das")
foreach(file IN LISTS daslib)
    file(RELATIVE_PATH relative "${dasroot}" "${file}")
    get_filename_component(directory "${relative}" DIRECTORY)
    bundle_resource("${file}" "${directory}")
endforeach()
bundle_resource("${script}" scripts)
bundle_resource("${CMAKE_CURRENT_SOURCE_DIR}/color.txt" assets)

set(aot "${CMAKE_CURRENT_BINARY_DIR}/hello.aot.cpp")
add_custom_command(OUTPUT "${aot}"
    COMMAND "${DASSDL3_IOS_AOT_TOOL}" "${script}" "${aot}"
    DEPENDS "${DASSDL3_IOS_AOT_TOOL}" "${script}" ${daslib}
    VERBATIM)
target_sources(HelloDasSDL3 PRIVATE "${aot}")
