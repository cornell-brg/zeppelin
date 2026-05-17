//========================================================================
// sqrt-recur-adhoc.c
//========================================================================
// This file contains a simple main function using sqrt_recur function.
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
// % gcc -Wall -o sqrt-recur-adhoc ece2400-stdlib.c sqrt-recur.c
// sqrt-recur-adhoc.c % ./sqrt-recur-adhoc
//

#include "sqrt-recur.h"
// #include <stdio.h>
#include "utils/zeppelin_wprintf.h"

int main()
{
  // This is a simple program that calls sqrt_iter and prints out its
  // result

  int number = 5;
  int result = sqrt_recur( number );

  zeppelin_wprintf( L"Square root of %d is %d\n", number, result );

  return 0;
}
