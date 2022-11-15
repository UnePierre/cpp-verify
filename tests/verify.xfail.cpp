//////
/// \file       verify.xfail.cpp
///	\brief      Check that non-recognizable expressions in `verify()` indeed produces compiler errors.
///
//////


#include <verify.hpp>

using namespace CppVerify;


#if defined XFAIL_INDEX && XFAIL_INDEX == __COUNTER__

    int main()
    {
        int a, b;
        auto xfail_precedence_collides_with_implementation = verify(a << b);
    }

#elif XFAIL_INDEX == __COUNTER__

    int main()
    {
        int a, b;
        auto xfail_precedence_collides_with_implementation = verify(a >> b);
    }

#elif XFAIL_INDEX == __COUNTER__

    int main()
    {
        bool a, b;
        auto xfail_no_complex_expressions = verify(a && b);
    }

#elif XFAIL_INDEX == __COUNTER__

    int main()
    {
        bool a, b;
        auto xfail_no_complex_expressions = verify(a || b);
    }

#else

    int main()
    {
        int a = 1, b = 2;
        auto should_pass = verify(a < b);
        static_cast<void>(should_pass);

        return (XFAIL_AMOUNT - __COUNTER__);  // Check XFAIL_AMOUNT against counted amount.
    }

#endif
