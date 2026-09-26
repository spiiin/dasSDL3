# One deliberately bounded, reproducible binary profile. Other profiles stay source builds.
if(NOT WIN32 OR NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8 OR
   NOT CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "x64" OR
   NOT CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_CONFIGURATION_TYPES)
    message(FATAL_ERROR "SDK requires single-config MSVC Windows x64 Release (Ninja)")
endif()
if(BUILD_TESTING OR NOT DASSDL3_BINDING_BACKEND STREQUAL "clangbind")
    message(FATAL_ERROR "SDK requires BUILD_TESTING=OFF and saved clangbind bindings")
endif()
foreach(feature IMGUI IMAGE TTF NET MIXER SOUND SHADERCROSS)
    if(DASSDL3_WITH_${feature})
        message(FATAL_ERROR "SDK core profile requires DASSDL3_WITH_${feature}=OFF")
    endif()
endforeach()
if(NOT DAS_CLANG_BIND_DISABLED OR NOT DAS_LLVM_DISABLED)
    message(FATAL_ERROR "SDK core profile requires disabled ClangBind and LLVM")
endif()
include(CMakePackageConfigHelpers)
target_compile_definitions(dasSDL3 PRIVATE DASSDL3_AOT_HEADER="sdl3_aot.h")
add_executable(dasSDL3_aot tools/sdk/aot.cpp)
target_link_libraries(dasSDL3_aot PRIVATE dasSDL3)
set_target_properties(dasSDL3_aot PROPERTIES EXPORT_NAME aot)
# CMake carries the native compile definitions and system-link dependencies.
install(TARGETS dasSDL3 libDaScript libDaScript_runtime libUriParser SDL3-static SDL3_Headers dasSDL3_aot
    EXPORT dasSDL3SDKTargets
    ARCHIVE DESTINATION lib COMPONENT dasSDL3SDK
    RUNTIME DESTINATION bin COMPONENT dasSDL3SDK)
install(EXPORT dasSDL3SDKTargets NAMESPACE dasSDL3:: DESTINATION lib/cmake/dasSDL3 COMPONENT dasSDL3SDK)
install(DIRECTORY src/ DESTINATION include/dasSDL3 COMPONENT dasSDL3SDK
    FILES_MATCHING PATTERN "*.h" PATTERN "*.inc" PATTERN "libraries" EXCLUDE
    PATTERN "generated" EXCLUDE)
install(DIRECTORY src/generated/clangbind/ DESTINATION include/dasSDL3/generated/clangbind
    COMPONENT dasSDL3SDK FILES_MATCHING PATTERN "sdl3_types.inc")
install(FILES src/generated/gpu_handle_adapters.h src/generated/gpu_handle_types.h DESTINATION include/dasSDL3/generated COMPONENT dasSDL3SDK)
install(DIRECTORY third_party/daScript/include/ DESTINATION include COMPONENT dasSDL3SDK
    FILES_MATCHING PATTERN "*.h" PATTERN "*.inc")
install(DIRECTORY "${CMAKE_BINARY_DIR}/third_party/daScript/include/modules/"
    DESTINATION include/modules COMPONENT dasSDL3SDK FILES_MATCHING PATTERN "*.inc")
install(DIRECTORY third_party/daScript/3rdparty/fmt/include/ DESTINATION include COMPONENT dasSDL3SDK)
install(DIRECTORY third_party/daScript/3rdparty/uriparser/include/ DESTINATION include COMPONENT dasSDL3SDK)
install(DIRECTORY "${sdl3_SOURCE_DIR}/include/SDL3" DESTINATION include COMPONENT dasSDL3SDK FILES_MATCHING PATTERN "*.h")
install(DIRECTORY dassdl3/ DESTINATION share/dasSDL3/dassdl3 COMPONENT dasSDL3SDK
    FILES_MATCHING PATTERN "*.das" PATTERN "sdl3_image*" EXCLUDE PATTERN "sdl3_ttf*" EXCLUDE
    PATTERN "sdl3_net*" EXCLUDE PATTERN "sdl3_mixer*" EXCLUDE PATTERN "sdl3_sound*" EXCLUDE
    PATTERN "sdl3_shadercross*" EXCLUDE PATTERN "imgui*" EXCLUDE)
install(DIRECTORY third_party/daScript/daslib/ DESTINATION share/dasSDL3/dascript/daslib
    COMPONENT dasSDL3SDK FILES_MATCHING PATTERN "*.das")
configure_package_config_file(cmake/dasSDL3Config.cmake.in "${CMAKE_BINARY_DIR}/dasSDL3Config.cmake"
    INSTALL_DESTINATION lib/cmake/dasSDL3)
write_basic_package_version_file("${CMAKE_BINARY_DIR}/dasSDL3ConfigVersion.cmake"
    VERSION 0.1.0 COMPATIBILITY SameMinorVersion)
install(FILES "${CMAKE_BINARY_DIR}/dasSDL3Config.cmake" "${CMAKE_BINARY_DIR}/dasSDL3ConfigVersion.cmake"
    cmake/dasSDL3AOT.cmake DESTINATION lib/cmake/dasSDL3 COMPONENT dasSDL3SDK)
install(DIRECTORY examples/sdk-consumer/ DESTINATION share/dasSDL3/examples/sdk-consumer COMPONENT dasSDL3SDK)
install(FILES docs/sdk.md DESTINATION share/dasSDL3 COMPONENT dasSDL3SDK)
install(FILES third_party/daScript/LICENSE DESTINATION share/dasSDL3/licenses/daScript COMPONENT dasSDL3SDK)
install(FILES "${sdl3_SOURCE_DIR}/LICENSE.txt" DESTINATION share/dasSDL3/licenses/SDL COMPONENT dasSDL3SDK)
foreach(pair "fmt/LICENSE" "uriparser/COPYING")
    get_filename_component(folder "${pair}" DIRECTORY)
    install(FILES "third_party/daScript/3rdparty/${pair}" DESTINATION "share/dasSDL3/licenses/${folder}" COMPONENT dasSDL3SDK)
endforeach()

install(FILES third_party/daScript/THIRD_PARTY_NOTICES.md DESTINATION share/dasSDL3/licenses/daScript COMPONENT dasSDL3SDK)
foreach(folder dag_noise vecmath fast_float)
    install(FILES "third_party/daScript/include/${folder}/LICENSE" DESTINATION "share/dasSDL3/licenses/${folder}" COMPONENT dasSDL3SDK)
endforeach()
install(FILES third_party/daScript/src/misc/LUAU.LICENSE DESTINATION share/dasSDL3/licenses COMPONENT dasSDL3SDK)
