# Acquire CMake environment.
cmake_minimum_required(VERSION 3.18.4...3.24.2)
set(CMakeEssential_DIR "${CMAKE_CURRENT_LIST_DIR}/external/cmake-essential")
find_package(CMakeEssential REQUIRED QUIET)
set_property(GLOBAL PROPERTY USE_FOLDERS Off)

set(PROJECT_VENDOR "")

# Let git describe the project version.
get_version_from_git_describe(
    PROJECT_VERSION
    DESCRIPTION git_description
    COMMIT commit_id
    DIRTY is_dirty)

project(
    cpp-verify
    DESCRIPTION "Provide `+verify(<condition>)+` in modern C++ for easy  pretty-printing of conditions."
    VERSION "${PROJECT_VERSION}"
    HOMEPAGE_URL "https://github.com/UnePierre/cpp-verify"
    LANGUAGES CXX)
project_message_context()
set_project_is_top_level(PROJECT_IS_TOP_LEVEL)
message(STATUS "git describe: ${git_description}")

# List of options.
project_add_option(BUILD_TESTING_EXTERNAL "Enable testing of external libraries." Off)
project_add_option(BUILD_SHARED_LIBS "Build shared or static libraries." Off)

include(CTest)
enable_testing()

include(CPackComponent)
set(CPACK_COMPONENTS_ALL "")


if(PROJECT_IS_TOP_LEVEL)
    if(is_dirty)
        git_status(AUTHOR_WARNING)
    endif()

    # If the source is a git working copy itself, i.e. if this project isn't used as a git subtree...
    git_dir(git_dir)

    if(CMAKE_CURRENT_LIST_DIR STREQUAL git_dir)
        # Update README.adoc at the root of the project.
        configure_file(docs/README.in.adoc "${PROJECT_SOURCE_DIR}/README.adoc" @ONLY)
    endif()

    include(GNUInstallDirs)

    message_context(README)
    configure_file(README.adoc README.adoc COPYONLY)
    add_custom_command(
        OUTPUT README.pdf
        DEPENDS README.adoc
        COMMAND asciidoctor-pdf README.adoc
        COMMENT "asciidoctor-pdf README.adoc > README.pdf"
        VERBATIM)
    add_custom_target(README ALL DEPENDS README.pdf)
    install(FILES README.adoc DESTINATION "${CMAKE_INSTALL_DOCDIR}" COMPONENT README)
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/README.pdf" DESTINATION "${CMAKE_INSTALL_DOCDIR}" COMPONENT README OPTIONAL)
    list(APPEND CPACK_COMPONENTS_ALL README)
    end_message_context()
endif()

# Speed up compilation
enable_ccache()

# Set global compiler configuration defaults, also for external/*.
set(CMAKE_CXX_EXTENSIONS Off)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Fetch external dependencies.
add_subdirectory(external)
list(APPEND CPACK_COMPONENTS_ALL external-licenses)

# Add own sources

# Set global compiler configurations.
add_compile_definitions(GIT_DESCRIBE="${GIT_DESCRIBE}")
add_compile_definitions(PROJECT_VERSION="${PROJECT_VERSION}")
add_compile_definitions(PROJECT_SOURCE_DIR="${PROJECT_SOURCE_DIR}")

message_context(verify CONTEXT_VARIABLE LIB)

# This is a header-only library
add_library(${LIB} INTERFACE)
target_sources(${LIB} INTERFACE include/verify.hpp)
target_include_directories(${LIB} INTERFACE include)
target_compile_features(${LIB} INTERFACE cxx_std_11)
install(FILES include/verify.hpp DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/cpp-verify" COMPONENT ${LIB})
list(APPEND CPACK_COMPONENTS_ALL "${LIB}")
end_message_context()

# Add (regression) testing.
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

# Make package.
if(PROJECT_IS_TOP_LEVEL)
    # Setup packaging. Inherit most CPACK_ values from project().
    message_context(CPack)

    # MAYBE? set(CPACK_PACKAGE_VENDOR)

    # MAYBE? set(CPACK_PACKAGE_DESCRIPTION_FILE)
    # MAYBE? set(CPACK_PACKAGE_ICON)
    set(CPACK_PACKAGE_CHECKSUM SHA1)
    set(CPACK_RESOURCE_FILE_README README.adoc)

    # MAYBE? set(CPACK_RESOURCE_FILE_WELCOME)
    set(CPACK_STRIP_FILES TRUE) # TODO: maybe make this dependent on Release/Debug target?
    set(CPACK_VERBATIM_VARIABLES TRUE)
    set(CPACK_THREADS 0) # use all available CPU cores
    set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY false)

    # All components for installation have collected into CPACK_COMPONENTS_ALL.
    # Install only those and put them together into a single archive.
    set(CPACK_MONOLITHIC_INSTALL false)
    set(CPACK_GENERATOR TBZ2)
    set(CPACK_ARCHIVE_COMPONENT_INSTALL TRUE)
    set(CPACK_COMPONENTS_GROUPING ALL_COMPONENTS_IN_ONE)

    message(STATUS "CPACK_COMPONENTS_ALL: ${CPACK_COMPONENTS_ALL}")

    include(CPack)
    end_message_context()
endif()

end_project_message_context()
