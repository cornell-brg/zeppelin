//========================================================================
// sqrt-iter.c
//========================================================================
// Baseline implementation of the sqrt function

// #include "ece2400-stdlib.h"
#include "sqrt-iter.h"
// #include <stdio.h>
int sqrt_iter( int x )
{
  // This function will look to find the square root of parameter x,
  // rounded down to the nearest integer. If x is negative, no square root
  // exists, so the function should return -1.

  // This function will include a variable square_root, which is used to
  // keep track of the square root that we will eventually return.
  // In a continuous loop, we will check whether the value one above
  // square_root (stored in a variable called test_value) has a square
  // larger than x. If it doesn't, we know that we haven't gotten large
  // enough yet, so we increment square_root by copying over test_value
  // to it, and loop again with this larger value. If the square of
  // test_value is larger than x, we know that the value right before
  // that (stored in square_root) is the square root of x, rounded down
  //(the largest integer whose square isn't above x), so we can return
  // square_root, exiting the loop

  int square_root = 0;
  int test_value;
  // We initialize square_root (starting at 0 and later incrementing up),
  // as well as test_value

  if ( x < 0 ) {  // x is a negative number
    return -1;
  }

  while ( 1 ) {  // a continuous loop, only broken when we return a value
    test_value = square_root + 1;
    if ( test_value <= ( x / test_value ) ) {
      // We divide x by test_value to check instead of multiplying
      // test_value by itself to avoid possible overflow of the
      // resulting expressio`n
      square_root = test_value;
      // we haven't yet gotten bigger than x, so we're still
      // too small (or exactly on the square_root, in which case
      // square_root now has the correct value, and will be
      // returned once we check test_value in the next loop)
    }
    else {  // we've exceeded x, and should return the last known value
      return square_root;
    }
  }
}