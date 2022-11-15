include("${CMAKE_CURRENT_LIST_DIR}/ParseArguments.cmake")

# enable_ccache([REQUIRED])
#
# If the `ccache` executable can be found via `find_program(... ccache)`, use it for C and CXX in the entire project.
# The option REQUIRED is forwared to `find_program(... ccache REQUIRED)`.
#
# Adapted from:
# https://crascit.com/2016/04/09/using-ccache-with-cmake/
#
function(enable_ccache)
    parse_arguments(0 "REQUIRED" "" "")
    message_context(enable_ccache)

    if(REQUIRED)
        find_program(ccache ccache REQUIRED)
    else()
        find_program(ccache ccache)
    endif()

    if(NOT ccache)
        message(STATUS "ccache not found.")
    else()
        message(VERBOSE "ccache: ${ccache}")

        # Set up wrapper scripts
        set(ccache_for_c "${ccache}")
        set(ccache_for_cxx "${ccache}")
        configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Ccache/launch-ccache-for-c.in" tools/launch-ccache-for-c)
        configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Ccache/launch-ccache-for-cxx.in" tools/launch-ccache-for-cxx)

        macro(test_or_set varname value)
            if(${varname})
                message(STATUS "enable_ccache() superseeded by ${varname}: ${${varname}}")
            else()
                set(${varname} "${value}" PARENT_SCOPE)
            endif()
        endmacro()

        if(CMAKE_GENERATOR STREQUAL "Xcode")
            # Set Xcode project attributes to route compilation and linking through our scripts
            test_or_set(CMAKE_XCODE_ATTRIBUTE_CC "${CMAKE_BINARY_DIR}/tools/launch-ccache-for-c")
            test_or_set(CMAKE_XCODE_ATTRIBUTE_CXX "${CMAKE_BINARY_DIR}/tools/launch-ccache-for-cxx")
            test_or_set(CMAKE_XCODE_ATTRIBUTE_LD "${CMAKE_BINARY_DIR}/tools/launch-ccache-for-c")
            test_or_set(CMAKE_XCODE_ATTRIBUTE_LDPLUSPLUS "${CMAKE_BINARY_DIR}/tools/launch-ccache-for-cxx")
        else()
            # Support Unix Makefiles and Ninja
            test_or_set(CMAKE_C_COMPILER_LAUNCHER "${CMAKE_BINARY_DIR}/tools/launch-ccache-for-c")
            test_or_set(CMAKE_CXX_COMPILER_LAUNCHER "${CMAKE_BINARY_DIR}/tools/launch-ccache-for-cxx")
        endif()
    endif()

    end_message_context()
endfunction()
