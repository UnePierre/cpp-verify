test_by_compilation(unit-test SOURCE verify.test.cpp DEPENDENCIES doctest verify)

test_by_compilation(
    compilation-test
    SOURCE verify.xfail.cpp
    XFAIL_AMOUNT 4
    DEPENDENCIES verify)
