include("${CMAKE_CURRENT_LIST_DIR}/ParseArguments.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/MessageContext.cmake")

# `test_by_compilation()`
#
# This function unifies two purposes:
# - test that something actually compiles, and 
# - test that something does indeed not compile.
#
# == A propos the second purpose
#
# Suppose a code construct that should prevent misuse of some kind.
# Any such construct ought to be tested!
#
# An appropriate test would be to tentatively compile an example and expect failure ("xfail").
# This function shall help in the construction of such expected-to-fail tests.
#
# == Additional considerations
#
# The construct may prevent several kinds of misuse, thus a couple of tests might be necessary.
# They are distinguished by defining XFAIL_INDEX=0, XFAIL_INDEX=1, ...
# This is only enabled, when the argument XFAIL_AMOUNT > 0 is given.
#
# The surroundings of such tests should compile without error.
# Otherwise, such compilation error would hide the expected failure.
# Thus, a compilation run with undefined XFAIL_INDEX is expected to succeed.
# This also serves the first purpose.
#
# The amount of expected-to-fail tests should be checked, too.
# But with cross-compilation, running the test code is problematic.
# Therefore, the XFAIL_AMOUNT is only checked in native environments.
#
# Both types are checked during testing with CTest, if the option BUILD_TESTING is enabled.
# The test invocation starts with `${CMAKE_COMMAND} --build ...`.
#
function(test_by_compilation NAME)
    parse_arguments(1 "" "SOURCE;XFAIL_AMOUNT" "ARGUMENTS;DEPENDENCIES")
    message_context("${NAME}" CONTEXT_VARIABLE TEST)

    # Target for compilation (and running) test at CTest testing time.
    add_executable("${NAME}" "${SOURCE}")
    add_dependencies("${NAME}" ${DEPENDENCIES})
    target_link_libraries("${NAME}" PRIVATE ${DEPENDENCIES})
    target_compile_definitions("${NAME}" PRIVATE "XFAIL_AMOUNT=${XFAIL_AMOUNT}")
    set_target_properties("${NAME}" PROPERTIES EXCLUDE_FROM_ALL On EXCLUDE_FROM_DEFAULT_BUILD On)

    message(STATUS "Add compilation test")
    set(CHECK_COMPILES "${TEST_CONTEXT}.compiles")
    add_test(NAME "${CHECK_COMPILES}" WORKING_DIRECTORY "${CMAKE_BINARY_DIR}" COMMAND "${CMAKE_COMMAND}" --build . --target "${NAME}")

    if(NOT XFAIL_AMOUNT)

        message(STATUS "Add execution test")
        set(CHECK_EXECUTES "${TEST_CONTEXT}.executes")
        add_test(NAME "${CHECK_EXECUTES}" COMMAND "${NAME}" ${ARGUMENTS})
        set_tests_properties("${CHECK_EXECUTES}" PROPERTIES DEPENDS "${CHECK_COMPILES}")
        if(CMAKE_CROSSCOMPILING AND NOT CROSSCOMPILING_EMULATOR)
            set_tests_properties("${CHECK_EXECUTES}" PROPERTIES DISABLED True)
        endif()

    elseif(XFAIL_AMOUNT GREATER 0)

        message(STATUS "Add ${XFAIL_AMOUNT} expected-to-fail compilation tests")
        foreach(INDEX RANGE 1 ${XFAIL_AMOUNT})
            math(EXPR XFAIL_INDEX "${INDEX} - 1")

            set(TEST_XFAILS_I "${NAME}.xfail-index-${XFAIL_INDEX}")

            # Target that is expected-to-fail compilation when tentatively built during CTest testing time.
            add_executable("${TEST_XFAILS_I}" ${SOURCE})
            add_dependencies("${TEST_XFAILS_I}" ${DEPENDENCIES})
            target_link_libraries("${TEST_XFAILS_I}" PRIVATE ${DEPENDENCIES})
            set_target_properties("${TEST_XFAILS_I}" PROPERTIES EXCLUDE_FROM_ALL On EXCLUDE_FROM_DEFAULT_BUILD On)
            target_compile_definitions("${TEST_XFAILS_I}" PRIVATE "XFAIL_AMOUNT=${XFAIL_AMOUNT}" "XFAIL_INDEX=${XFAIL_INDEX}")

            # Compilation tests expected to fail.
            add_test(NAME "${TEST_CONTEXT}.xfail-index-${XFAIL_INDEX}" WORKING_DIRECTORY "${CMAKE_BINARY_DIR}" COMMAND "${CMAKE_COMMAND}" --build . --target "${TEST_XFAILS_I}")
            set_tests_properties("${TEST_CONTEXT}.xfail-index-${XFAIL_INDEX}" PROPERTIES WILL_FAIL Yes)
        endforeach()

        message(STATUS "Add test to check amount thereof")
        set(CHECK_AMOUNT "${TEST_CONTEXT}.xfail-amount-${XFAIL_AMOUNT}")
        add_test(NAME "${CHECK_AMOUNT}" COMMAND "${NAME}" ${ARGUMENTS})
        set_tests_properties("${CHECK_AMOUNT}" PROPERTIES DEPENDS "${CHECK_COMPILES}")
        if(CMAKE_CROSSCOMPILING AND NOT CROSSCOMPILING_EMULATOR)
            set_tests_properties("${CHECK_AMOUNT}" PROPERTIES DISABLED True)
        endif()

    else()
        message(FATAL_ERROR "Expected an integer value or empty string for XFAIL_AMOUNT, but got '${XFAIL_AMOUNT}'!")
    endif()

    end_message_context()
endfunction()
