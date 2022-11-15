set(CMakeEssential_VERSION @PROJECT_VERSION@)

@PACKAGE_INIT@

check_required_components(CMakeEssential)

include("${CMAKE_CURRENT_LIST_DIR}/CMakeEssential.cmake")
