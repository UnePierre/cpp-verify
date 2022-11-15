
include(FetchContent)

message_context(doctest)

set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME doctest)
set(FETCHCONTENT_UPDATES_DISCONNECTED_DOCTEST ${EXTERNAL_FETCHCONTENT_UPDATES_DISCONNECTED})

fetchcontent_declare(
    doctest
    GIT_REPOSITORY "git@github.com:doctest/doctest.git"
    GIT_TAG v2.4.9
    GIT_SHALLOW On)

# DOCTEST_WITH_TESTS "Build tests/examples"
set(DOCTEST_WITH_MAIN_IN_STATIC_LIB Off CACHE INTERNAL "Build a static lib (cmake target) with a default main entry point")
set(DOCTEST_NO_INSTALL On CACHE INTERNAL "Skip the installation process")
set(DOCTEST_USE_STD_HEADERS On CACHE INTERNAL "Use std headers") # Be 100% standards compliant.

fetchcontent_makeavailable(doctest)

if(NOT BUILD_SHARED_LIBS)
    set_property(DIRECTORY "${doctest_BINARY_DIR}" PROPERTY EXCLUDE_FROM_ALL TRUE) # Don't install the library itself.
endif()

install(FILES "${doctest_SOURCE_DIR}/LICENSE.txt" DESTINATION doc/licenses/doctest COMPONENT external-licenses)

end_message_context()
