//////
/// \file     verify.test.cpp
/// \brief    Test the verify() functionality.
///
/// \details  TODO: test in at least the following dimensions:
///           - store return value in: { auto, const auto, auto&, const auto& }
///             - ("auto&" without const might fail at compile time --> verify.xfail.cpp)
///           - All 6 comparison operators.
///           - All unary operators on the inner expression.
///           - compile-time-error expected on `<<`-expresion (--> verfify.xfail.cpp)
///           - Several operand types:
///             - built-in
///             - classes
///             - arrays ?
///             - containers ?
///             - pointers
///             - lvalue-references
///             - rvalue-references
///           - operand storage:
///             - local, global, member, literal, function-return-value
///             - cv-qualifiers, constexpr, references
///           - Outer negation, outer double-negation, ...
//////

#include <verify.hpp> // DUT

#include <exception>
#include <iostream>
#include <sstream>

#include "pretty-file.h"

#define DOCTEST_CONFIG_VOID_CAST_EXPRESSIONS
#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>


TEST_SUITE(__PRETTY_FILE__)
{
    TEST_CASE("verify() on bool literals")
    {
        CHECK(verify(true));
        CHECK(!verify(false));
        CHECK(!!verify(true));
    }

    TEST_CASE("verify() double negation")
    {
        int x;
        auto t = verify(x);
        auto f = !t;

        static_assert(std::is_same_v<decltype(t), decltype(!!t)>);
        static_assert(std::is_same_v<decltype(f), decltype(!!f)>);

        static_cast<void>(f);
    }

    int a = 1;
    int b = 2;

    TEST_CASE("verify() of cast-to-bool")
    {
        // implicit cast to bool
        CHECK(verify(a));
        CHECK_FALSE(!verify(a));

        // negation -- usually a cast to bool
        CHECK_FALSE(verify(!a));
        CHECK(!verify(!a));

        // double negation
        CHECK(verify(!!a));
        CHECK_FALSE(!verify(!!a));

        // C-cast to bool
        CHECK(verify( (bool)(a) ));
        CHECK_FALSE(!verify( (bool)(a) ));

        // static_cast<bool>
        CHECK(verify(static_cast<bool>(a)));
        CHECK_FALSE(!verify(static_cast<bool>(a)));
    }

    TEST_CASE("verify() integer comparison")
    {
        CHECK(verify(a < b));
        CHECK(verify(b > a));
        CHECK(verify(a <= b));
        CHECK(verify(b >= a));

        CHECK(verify(a != b));
        CHECK_FALSE(verify(a == b));

        //TODO: operator<=>
    }

    TEST_CASE("verify() with if()")
    {
        if ( auto pass = verify(a < b) )
        {
            std::cout << "passes as expected: " << pass << std::endl;
        }
        else
        {
            std::cerr << "fails unexpectedly: " << pass << std::endl;
            FAIL_CHECK(pass);
        }

        if ( auto fail = !verify(a > b) )
        {
            std::cout << "fails as expected: " << fail << std::endl;
        }
        else
        {
            std::cerr << "passes unexpectedly: " << fail << std::endl;
            FAIL_CHECK(fail);
        }
    }


    int divide(int x, int y)
    {
        if(auto fail = !verify(y != 0))
        {
            std::stringstream os("Don't divide by zero: ");
            os << fail;
            throw std::runtime_error(os.str());
        }

        return ( x / y );
    }

    TEST_CASE("verify() with throw")
    {
        CHECK(3 == divide(10, 3));
        CHECK_THROWS(divide(10,0));
    }

    int foo_calls = 0;
    int bar_calls = 0;

    int foo()
    {
        ++foo_calls;
        return a;

    }
    int bar()
    {
        ++bar_calls;
        return b;
    }

    TEST_CASE("verify() of function calls")
    {
        foo_calls = 0;
        bar_calls = 0;
        auto pass1 = verify(foo() < bar());
        CHECK(pass1);
        CHECK(foo_calls == 1);
        CHECK(bar_calls == 1);

        auto fail = !pass1;
        CHECK_FALSE(fail);
        CHECK(!fail);
        CHECK(!!pass1);
        CHECK_FALSE(!!!pass1);
        CHECK(foo_calls == 1);
        CHECK(bar_calls == 1);

        auto pass2 = verify(foo() < bar());
        CHECK(pass2);
        CHECK(foo_calls == 2);
        CHECK(bar_calls == 2);
    }
}
