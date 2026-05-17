//========================================================================
// sqrt-recur.c
//========================================================================
// Alternative implementation of the sqrt function

// #include "ece2400-stdlib.h"
#include "sqrt-recur.h"
// #include <stdio.h>

int sqrt_recur_helper( int lower_bound, int upper_bound, int x )
{
  // This function looks for the square root of x within the
  // given bounds

  // If the bounds are equal, then there's only one possibility
  //, and we return the value of the bounds

  if ( lower_bound == upper_bound ) {
    return lower_bound;
  }

  // Additionally, one other imporatant case that we have to
  // address separately is when x is 1. In theory, this should be fine,
  // but this will evaulate to test_value being zero (the only value where
  // this happens, as it's the only integer where lower_bound +
  // upper_bound will ever be less than 2). Since we divide by test_value,
  // we can't have this case get there in the code. We could potentially
  // short-circuit evaluate  the first conditional to exclude when
  // test_value is 0, but our code still  would realize that test_value is
  // equal to lower_bound, and would return  lower_bound, or in this case,
  // 0 (an error that arises since 1 is the only  number where the square
  // root is itself). Therefore, it is best to evaluate  this case
  // separately

  if ( x == 1 ) {
    return 1;
  }

  // If not, we divide the range by 2, and compare the square of that
  // term to see if the value we're looking for is above of below
  // it. We then recursively call sqrt_recur_helper with the appropriately
  // lesser bounds, until we get to the base case

  int test_value = ( lower_bound + upper_bound ) / 2;

  if ( test_value > x / test_value ) {
    // Our test_value is too large, so we should look in the
    // lower range

    return sqrt_recur_helper( lower_bound, test_value, x );
  }

  else {
    // This occurs one of two ways:
    //  - test_value is too small (we should raise lower_bound
    //    to x)

    //  - The range is one, and the integer division rounds
    //    test_value down to lower_bound. In this case, we
    //    want to return lower_bound, as we're rounding down the
    //    division, and lower_bound is the closest we can get to
    //    the square root while rounding down.
    //
    //    We can test this first by seeing if
    //    test_value is equal to lower_bound (test_value
    //    is only rounded down to lower_bound in this case)

    if ( test_value == lower_bound ) {
      return lower_bound;
    }

    else {
      return sqrt_recur_helper( test_value, upper_bound, x );
    }
  }
}

int sqrt_recur( int x )
{
  // One case that we don't need recursion for is with negative numbers,
  // where our function should always return -1

  if ( x < 0 ) {
    return -1;
  }

  // Implementing recursively, we want this function to do something on
  // each iteration. In my case, I want to change the range in which
  // we're looking for the square root. However, there's no room for
  // that in this function's parameters, so I will have it call
  // a helper function that includes parameters for the search range
  int lower_bound = 0;
  int upper_bound = x;
  return sqrt_recur_helper( lower_bound, upper_bound, x );
}
