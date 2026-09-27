file(MAKE_DIRECTORY "${OUT}")
execute_process(COMMAND "${NODE}" "${GENERATOR}" "${ROOT}" "/repo/tests/lifecycle_no_aot.das" "${OUT}"
    RESULT_VARIABLE code OUTPUT_VARIABLE output ERROR_VARIABLE error TIMEOUT 60)
if(code EQUAL 0 OR NOT "${output}${error}" MATCHES "standalone AOT cannot emit function interpreted_only")
    message(FATAL_ERROR "Expected a missing-AOT rejection, got ${code}: ${output}${error}")
endif()
message(STATUS "Missing AOT rejected; no fallback")
