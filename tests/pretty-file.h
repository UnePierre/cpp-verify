//////
/// \file       pretty-file.h
/// \brief      Define __PRETTY_FILE__ as PROJECT_SOURCE_DIR-relative __FILE__.
///
/// \details    __FILE__ is a macro constant that expands to the name of the current file, as a character string literal.
///             In many popular compilers, it includes the absolute path of the project. This makes file names rather long.
///             Any (debug) binary that includes such source file names will also depend on the source directory path. This impedes reproducibility.
///
///             __PRETTY_FILE__ shall help with both aspects:
///             If PROJECT_SOURCE_DIR is defined (by the surrounding CMake),
///             it shall be equal (in length) to the common prefix of all source file paths.
///             The macro __PRETTY_FILE__ then expands to the address of the first "individual" character within __FILE__.
///             This is done by simple offset calculation.
///
///             if PROJECT_SOURCE_DIR isn't defined, __PRETTY_FILE__ falls back onto __FILE__.
//////

#ifndef CPP_VERIFY_PRETTY_FILE_H
#define CPP_VERIFY_PRETTY_FILE_H


#ifdef PROJECT_SOURCE_DIR
    #define __PRETTY_FILE__  &__FILE__[sizeof(PROJECT_SOURCE_DIR)]
#else
    #define __PRETTY_FILE__  __FILE__
#endif


#endif
