find_package(Git REQUIRED QUIET)
include("${CMAKE_CURRENT_LIST_DIR}/ParseArguments.cmake")

# git_dir(<variable_name>)
#
# Get the top-level directory of the git working copy (usually the parent directory of .git).
#
# Write it into the given variable.
#
function(git_dir variable_name)

    set(dir "${CMAKE_CURRENT_LIST_DIR}")
    if(NOT dir)
        set(dir "${PROJECT_SOURCE_DIR}")
    endif()

    execute_process(
        COMMAND "${GIT_EXECUTABLE}" rev-parse --show-toplevel
        WORKING_DIRECTORY "${dir}"
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE ok
        OUTPUT_VARIABLE output
        ERROR_VARIABLE error)
    if(ok EQUAL 0)
        set(${variable_name} "${output}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "'git rev-parse --show-toplevel' unsuccessful! (${error})")
    endif()

    message(TRACE "git_dir(): ${output}")

endfunction()

# git_describe_version(<variable_name>)
#
# Find the closest matching 3-digit version with `git describe`.
#
# The actual call is similar to `git describe --all --match "v*.*.*" --dirty --broken --always --long`, for details, see: https://git-scm.com/docs/git-describe
#
function(git_describe_version variable_name)

    git_dir(dir)

    execute_process(
        COMMAND "${GIT_EXECUTABLE}" describe --all --match "v*.*.*" --dirty --broken --always --long
        WORKING_DIRECTORY "${dir}"
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE ok
        OUTPUT_VARIABLE output
        ERROR_VARIABLE error)
    if(ok EQUAL 0)
        set(${variable_name} "${output}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "'git describe' unsuccessful! (${error})")
    endif()

endfunction()

# get_version_from_git_describe(<version> [DESCRIPTION <description>] [COMMIT <commit_id>] [DIRTY <is_dirty>])
#
# Extract the version from above `git_describe_version()` for use in `project()`.
#
# If the minor or patch part of the version is `x`, it will be replaced by `0`.
#
# This allows versions to be calculated from branch names like "v1.2.x".
#
# Optionally extract the output of `git describe`, the commit id and whether the working copy is dirty into the given variables.
#
function(get_version_from_git_describe version)
    parse_arguments(1 "" "DESCRIPTION;COMMIT;DIRTY" "")

    git_describe_version(git_description)

    if(DESCRIPTION)
        set(${DESCRIPTION} "${git_description}" PARENT_SCOPE)
    endif()

    string(REPLACE ".x" ".0" git_describe_version_x0 "${git_description}")

    if(NOT git_describe_version_x0 MATCHES [[v([0-9]+)\.([0-9]*)\.([0-9]*)-([0-9]+)-g([a-z0-9]+)(-dirty)?$]])
        message(FATAL_ERROR "Cannot match version numbers in output of 'git describe' (${git_description})!")
    endif()

    set(major "${CMAKE_MATCH_1}")
    set(minor "${CMAKE_MATCH_2}")
    set(patch "${CMAKE_MATCH_3}")
    set(tweak "${CMAKE_MATCH_4}")
    set(commit "${CMAKE_MATCH_5}")
    if(CMAKE_MATCH_6)
        set(dirty TRUE)
    else()
        set(dirty FALSE)
    endif()

    message(TRACE "major: '${major}'")
    message(TRACE "minor: '${minor}'")
    message(TRACE "patch: '${patch}'")
    message(TRACE "tweak: '${tweak}'")
    message(TRACE "commit: '${commit}'")
    message(TRACE "dirty: '${dirty}'")

    if(tweak GREATER 0)
        set(${version} "${major}.${minor}.${patch}.${tweak}" PARENT_SCOPE)
    else()
        set(${version} "${major}.${minor}.${patch}" PARENT_SCOPE)
    endif()

    if(COMMIT)
        set(${COMMIT} "${commit}" PARENT_SCOPE)
    endif()

    if(DIRTY)
        set(${DIRTY} "${dirty}" PARENT_SCOPE)
    endif()

endfunction()

# git_describe([<mode>])
#
# Print `git describe ...` at level <mode>, "STATUS", or "AUTHOR_WARNING" (when it's dirty).
#
function(git_describe)
    git_describe_version(git_description)

    if(ARGC GREATER 0)
        set(mode "${ARGV0}")
    elseif(git_description MATCHES "-dirty$")
        set(mode "AUTHOR_WARNING")
    else()
        set(mode "STATUS")
    endif()

    message("${mode}" "git describe: ${git_description}")

endfunction()

# git_status([<mode>])
#
# Print `git status --short` at level <mode>, or "NOTICE".
#
function(git_status)
    if(ARGC GREATER 0)
        set(mode "${ARGV0}")
    else()
        set(mode "NOTICE")
    endif()

    git_dir(dir)

    execute_process(
        COMMAND "${GIT_EXECUTABLE}" --no-optional-locks status --short -- "${CMAKE_CURRENT_LIST_DIR}"
        WORKING_DIRECTORY "${dir}"
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE ok
        OUTPUT_VARIABLE output
        ERROR_VARIABLE error)
    if(ok EQUAL 0)
        message("${mode}" "git status:\n${output}")
    else()
        message(FATAL_ERROR "'git status' unsuccessful! (${error})")
    endif()

endfunction()
