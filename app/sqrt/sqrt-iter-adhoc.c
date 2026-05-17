//========================================================================
// sqrt-iter-adhoc.c
//========================================================================
// This file contains a simple main function using sqrt_iter function.
// This file is not included in the CMake build flow, so it needs to
// be built explicitly. This file is used to demonstrate how to build
// a simple C program directly without any build tool such as Makefile
// CMake. Students should use this simple program before attempting
// to use given CMake build tool.
//
// NOTE:
//
// Use the following commannds in the src directory to compile and run
// this adhoc test in the commandline:
//
// % gcc -Wall -o sqrt-iter-adhoc ece2400-stdlib.c sqrt-iter.c
// sqrt-iter-adhoc.c % ./sqrt-iter-adhoc
//

#include "sqrt-iter.h"
// #include <stdio.h>
#include "utils/zeppelin_wprintf.h"

int main()
{
  // This is a simple program that calls sqrt_iter and prints out its
  // result

  int number = 5;
  int result = sqrt_iter( number );

  zeppelin_wprintf( L"Square root of %d is %d\n", number, result );

  return 0;
}
