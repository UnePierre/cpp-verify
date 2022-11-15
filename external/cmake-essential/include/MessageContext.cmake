# message_context(<name [CONTEXT_VARIABLE <variable>])
#
# Components within CMake scripts can be placed recursively into contexts.
#
# The following two macros are a convenience wrapper around the `CMAKE_MESSAGE_CONTEXT` functionality.
#
# == Details
#
# A message is printed upon entry into the context via this `message_context(<name>)`.
# A corresponding message is printed upon exit from the context via `end_message_context()`.
#
# When CONTEXT_VARIABLE names a variable, two side-effects happen:
#
# * This macro calls `set(${variable} "${name}")` and thus fills the variable with the context's name.
# * `${variable}_CONTEXT` will get a string of dot-separated context names for use as breadcrumbs.
#
macro(message_context name)

    cmake_parse_arguments(_message_context "" "CONTEXT_VARIABLE" "" ${ARGN})

    message(CHECK_START "CMake [${name}]")

    if(NOT CMAKE_MESSAGE_CONTEXT_SHOW)
        list(APPEND CMAKE_MESSAGE_INDENT "  ")
    endif()

    set(_message_context_last_variable_name "${_message_context_CONTEXT_VARIABLE}") # Even if UNDEFINED.

    if(_message_context_CONTEXT_VARIABLE)
        set(${_message_context_CONTEXT_VARIABLE} "${name}")

        list(JOIN CMAKE_MESSAGE_CONTEXT "." ${_message_context_CONTEXT_VARIABLE}_CONTEXT)
        string(APPEND ${_message_context_CONTEXT_VARIABLE}_CONTEXT ".${name}") # Works with non-variable-like name, too.
    endif()

    list(APPEND CMAKE_MESSAGE_CONTEXT "${name}")

endmacro()

# end_message_context()
#
# Close a context opened via `message_context()`. Undo scope modifications.
#
macro(end_message_context)

    if(_message_context_last_variable_name)
        unset(${_message_context_last_variable_name}_CONTEXT)
        unset(${_message_context_last_variable_name})
        unset(_message_context_last_variable_name)
    endif()

    list(POP_BACK CMAKE_MESSAGE_CONTEXT)

    if(NOT CMAKE_MESSAGE_CONTEXT_SHOW)
        list(POP_BACK CMAKE_MESSAGE_INDENT)
    endif()

    message(CHECK_PASS "ok")

endmacro()
