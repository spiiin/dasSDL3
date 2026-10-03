# Focused native Linux interpreter/AOT regression profile.
set(ROOT "${CMAKE_SOURCE_DIR}")
target_compile_definitions(dasSDL3 PRIVATE DASSDL3_AOT_HEADER="${CMAKE_CURRENT_SOURCE_DIR}/aot.h")
add_executable(linux_aot_tool ../clangbind_parity/aot_tool.cpp)
target_link_libraries(linux_aot_tool PRIVATE dasSDL3)
target_compile_definitions(linux_aot_tool PRIVATE
    DASSDL3_DAS_ROOT="${ROOT}/third_party/daScript" DASSDL3_MODULE_ROOT="${ROOT}/dassdl3")
set(_scripts tests/linux/portability tests/peripherals)
set(_modules dassdl3/sdl3_result dassdl3/sdl3_boost dassdl3/sdl3_init_boost
    dassdl3/sdl3_peripherals_boost dassdl3/sdl3_platform_services)
file(GLOB _boost_deps CONFIGURE_DEPENDS "${ROOT}/dassdl3/*.das")
foreach(script IN LISTS _scripts _modules)
    string(REPLACE "/" "_" name "${script}")
    set(output "${CMAKE_CURRENT_BINARY_DIR}/${name}.aot.cpp")
    add_custom_command(OUTPUT "${output}"
        COMMAND linux_aot_tool "${ROOT}/${script}.das" "${output}"
        DEPENDS linux_aot_tool "${ROOT}/${script}.das" ${_boost_deps} VERBATIM)
    list(APPEND _outputs "${output}")
endforeach()
add_executable(linux_aot_runner ../clangbind_parity/aot_runner.cpp ${_outputs})
add_executable(linux_missing_aot ../clangbind_parity/aot_runner.cpp)
foreach(target linux_aot_runner linux_missing_aot)
    target_link_libraries(${target} PRIVATE dasSDL3)
    target_compile_definitions(${target} PRIVATE
        DASSDL3_DAS_ROOT="${ROOT}/third_party/daScript" DASSDL3_MODULE_ROOT="${ROOT}/dassdl3")
endforeach()
foreach(script IN LISTS _scripts)
    get_filename_component(name "${script}" NAME)
    add_test(NAME linux_aot_${name} COMMAND linux_aot_runner "${ROOT}/${script}.das")
    set_tests_properties(linux_aot_${name} PROPERTIES ENVIRONMENT "SDL_VIDEODRIVER=dummy" TIMEOUT 60 LABELS linux-core)
endforeach()
add_test(NAME linux_missing_aot COMMAND "${Python3_EXECUTABLE}"
    "${CMAKE_CURRENT_SOURCE_DIR}/check_missing_aot.py"
    $<TARGET_FILE:linux_missing_aot> "${ROOT}/tests/linux/portability.das")
set_tests_properties(linux_missing_aot PROPERTIES TIMEOUT 60 LABELS linux-core)
add_test(NAME linux_portability COMMAND dasSDL3_runner "${ROOT}/tests/linux/portability.das" --smoke-test)
set_tests_properties(linux_portability PROPERTIES TIMEOUT 30 LABELS linux-core)

add_executable(linux_allocator_test allocator.cpp)
target_link_libraries(linux_allocator_test PRIVATE dasSDL3)
target_include_directories(linux_allocator_test PRIVATE
    "${ROOT}/third_party/daScript/modules/dasVulkan/vendor/Vulkan-Headers/include")
add_test(NAME linux_allocator COMMAND linux_allocator_test)
set_tests_properties(linux_allocator PROPERTIES TIMEOUT 30 LABELS linux-core)
