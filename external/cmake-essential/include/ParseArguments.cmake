# parse_arguments(N "list;of;options" "list;of;one-valued;keywords" "list;of;multi-valued;keywords")
#
# This macro is a convenience wrapper around `cmake_parse_arguments(PARSE_ARGV ...)` with error/debug/trace messages.
#
macro(parse_arguments number_of_positional_arguments options one_value_keywords multi_value_keywords)

    list(JOIN ARGV " " _argv_)
    message(DEBUG "${CMAKE_CURRENT_FUNCTION}(${_argv_})")

    message(TRACE "parse_arguments(${number_of_positional_arguments} \"${options}\" \"${one_value_keywords}\" \"${multi_value_keywords}\")")

    cmake_parse_arguments(PARSE_ARGV ${number_of_positional_arguments} "" "${options}" "${one_value_keywords}" "${multi_value_keywords}")

    if(_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unparsed arguments to ${CMAKE_CURRENT_FUNCTION}(): ${_UNPARSED_ARGUMENTS}")
    endif()
    if(_KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "Keywords missing values in arguments to ${CMAKE_CURRENT_FUNCTION}(): ${_KEYWORDS_MISSING_VALUES}")
    endif()

    foreach(VAR ${options})
        set(${VAR} "${_${VAR}}")
        message(TRACE "set option ${VAR}: ${${VAR}}")
    endforeach()

    foreach(VAR ${one_value_keywords})
        set(${VAR} "${_${VAR}}")
        message(TRACE "set one_value_keyword ${VAR}: ${${VAR}}")
    endforeach()

    foreach(VAR ${multi_value_keywords})
        set(${VAR} ${_${VAR}})
        list(LENGTH ${VAR} _length)
        message(TRACE "set multi_value_keyword ${VAR} of length ${_length}: ${${VAR}}")
    endforeach()

endmacro()
