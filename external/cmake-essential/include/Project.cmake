include(FeatureSummary)

# Back-port PROJECT_IS_TOP_LEVEL functionality for CMake before 3.21.
#
# Determine whether the current project is either:
#
# * the main project (-> true), or
#
# * built as a subproject, e.g. using `add_subdirectory()` (-> false).
#
# Store the boolean into the given variable.
#
# Usually called as: `set_project_is_top_level(PROJECT_IS_TOP_LEVEL)`.
#
function(set_project_is_top_level VARNAME)

    if(${CMAKE_VERSION} VERSION_LESS 3.21)
        if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
            set(PROJECT_IS_TOP_LEVEL true)
        else()
            set(PROJECT_IS_TOP_LEVEL false)
        endif()
    endif()

    set(VARNAME ${PROJECT_IS_TOP_LEVEL} PARENT_SCOPE)

endfunction()

# project_message_context()
#
# Start a (sub-)project's context for nice messages.
#
# Print the PROJECT_NAME and PROJECT_VERSION.
#
# The context should be closed via `end_project_message_context()'.
#
# These two macros rely on CMAKE_MESSAGE_CONTEXT functionality,  and integrate well with `message_context()` and `end_message_context()`.
#
macro(project_message_context)
    message(CHECK_START "CMake project [${PROJECT_NAME}] v${PROJECT_VERSION}")
    list(APPEND CMAKE_MESSAGE_CONTEXT ${PROJECT_NAME})
    if(NOT CMAKE_MESSAGE_CONTEXT_SHOW)
        list(APPEND CMAKE_MESSAGE_INDENT "   ")
    endif()

    set_project_is_top_level(_project_is_top_level)
    if(_project_is_top_level)
        feature_summary(WHAT ALL)
    endif()
endmacro()

# end_project_message_context()
#
# Close a context opened via `project_message_context()`.
#
macro(end_project_message_context)
    list(POP_BACK CMAKE_MESSAGE_CONTEXT)
    if(NOT CMAKE_MESSAGE_CONTEXT_SHOW)
        list(POP_BACK CMAKE_MESSAGE_INDENT)
    endif()
    message(CHECK_PASS "ok")
endmacro()

# project_add_option(<varname> <description> <default-status>)
#
# Add a message to `option(${varname} "${description}" "${status}")`.
# Level STATUS for enabled options.
# Level VERBOSE for disabled options.
#
macro(project_add_option varname description status)
    option(${varname} "${description}" "${status}")

    if(${${varname}})
        message(STATUS  "- [x] ${description} (${varname}: ${${varname}})")
    else()
        message(VERBOSE "- [ ] ${description} (${varname}: ${${varname}})")
    endif()
endmacro()
