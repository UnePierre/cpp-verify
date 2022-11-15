message_context(external)

option(EXTERNAL_FETCHCONTENT_UPDATES_DISCONNECTED "FETCHCONTENT_UPDATES_DISCONNECTED default for external libraries." On)

if(BUILD_TESTING_EXTERNAL)
    option(DOCTEST_WITH_TESTS "[doctest] Build tests/examples" On)
else()
    set(DOCTEST_WITH_TESTS Off CACHE INTERNAL "[doctest] Build tests/examples")
endif()

add_subdirectory(cmake-essential)
add_subdirectory(doctest)

end_message_context()
