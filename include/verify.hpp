//////
/// \file     verify.hpp
/// \brief    Provide the verify() function, that makes pretty-printing of conditions easy.
///
/// \details  Implemented as a function-style macro,
///           verify(expr) can wrap any comparison or boolean expression into an object,
///           with nice test-output via iostream (and thus, fmt::format).
///
///           The expression is decomposed (one level deep) in order to print its composing values,
///           for example:
///           ```
///           int a = 23;
///           int b = 42;
///           std::cout << verify(a < b);
///           ```
///           will print something like: "verify(a < b) => verify(23 < 42) => true".
///
///           The negated return value (`!verify(...)`) is also storable and printable (e.g. "!verify(a < b) => !verify(23 < 42) => false").
///           Double negation cancels out, i.e. `!!verify(x)` behaves exactly like `verify(x)`, except for code length, maybe.
///
///           The return value is most conveniently stored in `auto`, possibly into the context of an if/else statement:
///           ```
///           if( auto fail = !verify(x) )
///               throw std::runtime_error(fmt::format("failed: {}", fail));
///           else
///               std::cout << "Yeah, we passed the test (" << !fail << ")!" << std::endl;
///           ```
///
///           TODO:
///           Aggregation into complex conditions via (short-circuit) `operator&&`, `operator||` might be added in the future.
///           Example: `if(auto pass = verify(a < b) && verify(c)) std::cout << "passed: " << pass << std::endl;`
///           Avoiding the evaluation of `c` might be tricky, thought. (Note: think about https://en.wikibooks.org/wiki/More_C%2B%2B_Idioms/Return_Type_Resolver)
///
///           Further expression decomposition (more operators, more depth) might be added, too (e.g. `verify(a < b && c < d)`).
///           But that involves careful decomposition along the operator precedence, and might be hard to test.
//////

#ifndef CPP_VERIFY_HPP
#define CPP_VERIFY_HPP

#if defined(__clang__)
    #define CPP_VERIFY__IGNORE_SUPERFLUOUS_WARNINGS(around) \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Woverloaded-shift-op-parentheses\"") \
        around \
        _Pragma("clang diagnostic pop")
#endif

#ifndef CPP_VERIFY__IGNORE_SUPERFLUOUS_WARNINGS
    #define CPP_VERIFY__IGNORE_SUPERFLUOUS_WARNINGS(around) \
        around
#endif

//////
// == This is Where the Magic Happens ==
//
// 1) Construct a `decompose` object, which stores the stringification of the expression (`#x`).
// 2) The object offers a type-templated `operator<<`, which captures ...
// 3a) all `x` into a `UnaryExpression`, when `x` is a unary expression,
// 4a) which is delivered to `make_decomposition()` via `finish()`
// - or -
// 3b) only the left-hand-side sub-expression in a `FirstOperand`, when `x` is a binary expression,
//     because the `operator<<` has precedence over all comparison operators.
// 4b) The `FirstOperand` itself offers the set of comparison operators (==,!=,<=,>=,<,>),
// 5b) which captures the right-hand-side sub-expression of the binary expression `x`,
// 6b) which is delivered as a `BinaryExpression` to `make_decomposition()` via `finish()`.

#define verify(x) \
    CPP_VERIFY__IGNORE_SUPERFLUOUS_WARNINGS( \
        \
        ((CppVerify::decompose(#x) << x).finish()) \
        \
    )   //                     (1)        (2)   (3ff)

// == Show is Over ==
//
// The rest is implementation.
//////

#include <iosfwd>
#include <sstream>

namespace CppVerify {

struct EQ { template<typename T1, typename T2> static constexpr bool evaluate(const T1 & op1, const T2 & op2){ return (op1 == op2); } };
struct NE { template<typename T1, typename T2> static constexpr bool evaluate(const T1 & op1, const T2 & op2){ return (op1 != op2); } };
struct LE { template<typename T1, typename T2> static constexpr bool evaluate(const T1 & op1, const T2 & op2){ return (op1 <= op2); } };
struct GE { template<typename T1, typename T2> static constexpr bool evaluate(const T1 & op1, const T2 & op2){ return (op1 >= op2); } };
struct LT { template<typename T1, typename T2> static constexpr bool evaluate(const T1 & op1, const T2 & op2){ return (op1 <  op2); } };
struct GT { template<typename T1, typename T2> static constexpr bool evaluate(const T1 & op1, const T2 & op2){ return (op1 >  op2); } };

inline ::std::ostream & operator<<(::std::ostream & os, const EQ) { return os << " == "; }
inline ::std::ostream & operator<<(::std::ostream & os, const NE) { return os << " != "; }
inline ::std::ostream & operator<<(::std::ostream & os, const LE) { return os << " <= "; }
inline ::std::ostream & operator<<(::std::ostream & os, const GE) { return os << " >= "; }
inline ::std::ostream & operator<<(::std::ostream & os, const LT) { return os << " < ";  }
inline ::std::ostream & operator<<(::std::ostream & os, const GT) { return os << " > ";  }


template<class Expression> struct NegatedDecomposition;


template<class Expression> struct [[nodiscard]] Decomposition
{
    const char * const code;
    const Expression expression;
    const bool value;

    constexpr Decomposition(const char * s, const Expression & x, bool v) : code(s), expression(x), value(v) { }
    Decomposition() = delete;
    ~Decomposition() = default;

    friend ::std::ostream & operator<<(::std::ostream & os, const Decomposition & this_)
    {
        // Printing to local stream avoids involuntary manipulation of the std::ostream.
        ::std::stringstream stream;
        stream << ::std::boolalpha << "verify(" << this_.code << ") => verify(" << this_.expression << ") => " << this_.value;
        return os << stream.str();
    }

    constexpr auto operator!() const { return NegatedDecomposition<Expression>(code, expression, value); }

    constexpr operator bool() const { return value; }
};

template<class E> constexpr auto make_decomposition(const char * code, const E & x)
{
    return Decomposition<E>(code, x, x.evaluate());
}


template<class Expression> struct [[nodiscard]] NegatedDecomposition : public Decomposition<Expression>
{
    using Decomposition<Expression>::code;
    using Decomposition<Expression>::expression;
    using Decomposition<Expression>::value;

    constexpr NegatedDecomposition(const char * s, const Expression & x, bool v) : Decomposition<Expression>(s,x,v) { }
    NegatedDecomposition() = delete;
    ~NegatedDecomposition() = default;

    friend ::std::ostream & operator<<(::std::ostream & os, const NegatedDecomposition & this_)
    {
        // Printing to local stream avoids involuntary manipulation of the std::ostream.
        const bool value = ! this_.value;
        ::std::stringstream stream;
        stream << ::std::boolalpha << "!verify(" << this_.code << ") => !verify(" << this_.expression << ") => " << value;
        return os << stream.str();
    }

    constexpr auto operator!() const { return Decomposition<Expression>(code, expression, value); }

    constexpr operator bool() const { return !value; }
};


template<typename T> struct UnaryExpression
{
    const T & operand;

    constexpr explicit UnaryExpression(const T & op) : operand(op) { }
    UnaryExpression() = delete;
    ~UnaryExpression() = default;

    constexpr bool evaluate() const { return static_cast<bool>(operand); }

    friend ::std::ostream & operator<<(::std::ostream & os, const UnaryExpression & this_)
    {
        // Printing to local stream avoids involuntary manipulation of the std::ostream.
        ::std::stringstream stream;
        stream << this_.operand;
        return os << stream.str();
    }
};


template<typename L, typename Comparison, typename R> struct BinaryExpression
{
    const L & operand1;
    const R & operand2;

    constexpr BinaryExpression(const L & op1, const R & op2) : operand1(op1), operand2(op2) { }
    BinaryExpression() = delete;
    ~BinaryExpression() = default;

    constexpr bool evaluate() const { return Comparison::evaluate(operand1, operand2); }

    friend ::std::ostream & operator<<(::std::ostream & os, const BinaryExpression & this_)
    {
        // Printing to local stream avoids involuntary manipulation of the std::ostream.
        ::std::stringstream stream;
        stream << this_.operand1 << Comparison() << this_.operand2;
        return os << stream.str();
    }
};


struct decompose
{
    const char * const code;

    decompose() = delete;
    constexpr explicit decompose(const char * code) : code(code) { }
    ~decompose() = default;

    template<typename T1> struct FirstOperand
    {
        const char * const code;
        const T1 & operand1;

        FirstOperand() = delete;
        constexpr FirstOperand(const char * code, const T1 & op1) : code(code), operand1(op1) { }
        ~FirstOperand() = default;

        constexpr auto finish() const { return make_decomposition(code, UnaryExpression<T1>(operand1)); }


        template<typename C, typename T2> struct SecondOperand
        {
            const char * const code;
            const T1 & operand1;
            const T2 & operand2;

            SecondOperand() = delete;
            constexpr SecondOperand(const char * code, const T1 & op1, const T2 & op2)
                : code(code), operand1(op1), operand2(op2)
            { }
            ~SecondOperand() = default;

            constexpr auto finish() const { return make_decomposition(code, BinaryExpression<T1,C,T2>(operand1,operand2)); }
        };

        template<typename T2> constexpr auto operator==(const T2 & op2) { return SecondOperand<EQ,T2>(code, operand1, op2); }
        template<typename T2> constexpr auto operator!=(const T2 & op2) { return SecondOperand<NE,T2>(code, operand1, op2); }
        template<typename T2> constexpr auto operator<=(const T2 & op2) { return SecondOperand<LE,T2>(code, operand1, op2); }
        template<typename T2> constexpr auto operator>=(const T2 & op2) { return SecondOperand<GE,T2>(code, operand1, op2); }
        template<typename T2> constexpr auto operator< (const T2 & op2) { return SecondOperand<LT,T2>(code, operand1, op2); }
        template<typename T2> constexpr auto operator> (const T2 & op2) { return SecondOperand<GT,T2>(code, operand1, op2); }
    };

    template<typename T> constexpr auto operator<<(const T & op1) const { return FirstOperand<T>(code, op1); }
};


}

#endif
