cmake_minimum_required(VERSION 3.24)
project(dasSDL3AndroidSmoke LANGUAGES C CXX)
if(NOT ANDROID)
    message(FATAL_ERROR "Configure with the Android NDK toolchain")
endif()
set(DASSDL3_HOST_AOT_TOOL "" CACHE FILEPATH "Native host dasSDL3 AOT emitter")
if(NOT EXISTS "${DASSDL3_HOST_AOT_TOOL}")
    message(FATAL_ERROR "Set DASSDL3_HOST_AOT_TOOL to the host executable (see docs/android.md)")
endif()
set(root "${CMAKE_CURRENT_SOURCE_DIR}/..")
set(BUILD_TESTING OFF)
add_subdirectory("${root}" dasSDL3 EXCLUDE_FROM_ALL)

set(script "${CMAKE_CURRENT_SOURCE_DIR}/smoke.das")
file(GLOB daslib CONFIGURE_DEPENDS "${root}/third_party/daScript/daslib/*.das")
set(aot "${CMAKE_CURRENT_BINARY_DIR}/smoke.aot.cpp")
add_custom_command(OUTPUT "${aot}"
    COMMAND "${DASSDL3_HOST_AOT_TOOL}" "${script}" "${aot}"
    DEPENDS "${DASSDL3_HOST_AOT_TOOL}" "${script}" ${daslib}
    VERBATIM)
add_library(main SHARED main.cpp "${aot}")
target_link_libraries(main PRIVATE dasSDL3)

# Stage the Java and native SDL from the same checkout. Gradle consumes this
# component so it never pulls a second SDL build from a Maven repository.
FetchContent_GetProperties(SDL3)
set(jni "jniLibs/${CMAKE_ANDROID_ARCH_ABI}")
install(TARGETS main SDL3-shared LIBRARY DESTINATION "${jni}" COMPONENT android-apk)
if(ANDROID_STL STREQUAL "c++_shared")
    install(FILES "${CMAKE_SYSROOT}/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/libc++_shared.so"
        DESTINATION "${jni}" COMPONENT android-apk)
endif()
install(DIRECTORY "${sdl3_SOURCE_DIR}/android-project/app/src/main/java/"
    DESTINATION java COMPONENT android-apk FILES_MATCHING PATTERN "*.java")
install(DIRECTORY "${root}/third_party/daScript/daslib/"
    DESTINATION assets/app/daslib COMPONENT android-apk FILES_MATCHING PATTERN "*.das")
install(DIRECTORY "${root}/dassdl3/"
    DESTINATION assets/app/dassdl3 COMPONENT android-apk FILES_MATCHING PATTERN "*.das")
install(FILES "${script}" "${root}/tests/macos_missing_aot.das"
    DESTINATION assets/app COMPONENT android-apk)
